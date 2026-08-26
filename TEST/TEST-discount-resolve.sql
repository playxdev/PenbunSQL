/* =====================================================================================
   TEST-discount-resolve.sql  --  พิสูจน์ลำดับการคิดส่วนลดของ UFN_RESOLVE_DISCOUNT
   -------------------------------------------------------------------------------------
   ต้องรัน SQL-PENBUN-v9.sql มาก่อน
   รันบนฐานทดสอบเท่านั้น : สร้างลูกค้า/สินค้า/กฎ แล้วลบทิ้งท้ายสคริปต์
   ทุกเคสพิมพ์ PASS หรือ FAIL — ไม่มีเคสไหนต้องอ่านตัวเลขเอง
   ===================================================================================== */

SET NOCOUNT ON;
GO

/* กันรันผิดฐาน : สคริปต์นี้ไม่มี USE โดยตั้งใจ ให้ระบุฐานทดสอบตอนเรียกแทน
   (sqlcmd -d PENBUN_TEST  หรือเลือกฐานใน SSMS)  ผิดฐานแล้วหยุดทันที ไม่ทิ้งข้อมูลค้าง */
IF OBJECT_ID(N'dbo.tb_price_rule', N'U') IS NULL
   OR OBJECT_ID(N'dbo.UFN_RESOLVE_DISCOUNT', N'IF') IS NULL
BEGIN
    DECLARE @db NVARCHAR(128) = DB_NAME();
    RAISERROR (N'TEST_DISCOUNT: ฐาน [%s] ยังไม่มี tb_price_rule / UFN_RESOLVE_DISCOUNT — รัน SQL-PENBUN-v9.sql ก่อน',
               16, 1, @db) WITH NOWAIT;
    SET NOEXEC ON;
END
GO

/* ─────────────────────────── ล้างของรอบก่อน ─────────────────────────── */

/* ล้างข้อมูลทดสอบของรอบก่อน
   ตารางทุกตัวมี TRIG_BLOCK_DELETE_* ที่แปลง DELETE เป็น Soft Delete แถวเก่าจึงค้างอยู่
   และทำให้การค้นด้วย customer_code เจอหลายแถว — ที่นี่จึงปิดทริกเกอร์เพื่อลบจริง
   ทำได้เพราะสคริปต์นี้รันบนฐานทดสอบเท่านั้น */
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRICE_RULE     ON dbo.tb_price_rule;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE ON dbo.tb_customer_route;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_BOOK           ON dbo.tb_book;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT_SKU    ON dbo.tb_product_sku;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT        ON dbo.tb_product;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER       ON dbo.tb_customer;

DELETE FROM dbo.tb_price_rule     WHERE update_by = N'TEST';
DELETE FROM dbo.tb_customer_route WHERE update_by = N'TEST';
DELETE FROM dbo.tb_book           WHERE update_by = N'TEST';
DELETE FROM dbo.tb_product_sku    WHERE update_by = N'TEST';
DELETE FROM dbo.tb_product        WHERE update_by = N'TEST';
DELETE FROM dbo.tb_customer       WHERE update_by = N'TEST';

ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRICE_RULE     ON dbo.tb_price_rule;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE ON dbo.tb_customer_route;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_BOOK           ON dbo.tb_book;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT_SKU    ON dbo.tb_product_sku;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT        ON dbo.tb_product;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER       ON dbo.tb_customer;
GO

/* ─────────────────────────── เตรียมข้อมูล ─────────────────────────── */

DECLARE @ct INT = (SELECT TOP 1 autoID FROM dbo.tb_customer_type WHERE is_delete = 0 ORDER BY autoID);
DECLARE @pg INT = (SELECT TOP 1 autoID FROM dbo.tb_product_group WHERE is_delete = 0 ORDER BY autoID);
DECLARE @g1 INT = (SELECT autoID FROM dbo.tb_discount_group WHERE group_code = N'G1' AND is_delete = 0);
DECLARE @rt INT = (SELECT TOP 1 autoID FROM dbo.tb_route WHERE is_delete = 0 ORDER BY autoID);

INSERT INTO dbo.tb_customer ([prefix],[ref_customer_type_auto],[ref_discount_group_auto],[customer_code],[customer_name],[is_vat],[update_by])
VALUES (N'CUS', @ct, @g1, N'TST-A', N'ร้านทดสอบ A', 1, N'TEST'),
       (N'CUS', @ct, @g1, N'TST-B', N'ร้านทดสอบ B', 1, N'TEST');

INSERT INTO dbo.tb_product ([prefix],[ref_product_group_auto],[product_code],[product_name],[count_stock],[sell_price],[update_by])
VALUES (N'PDT', @pg, N'TST-BOOK', N'หนังสือทดสอบ', 1, 100.0000, N'TEST');

DECLARE @prod INT = (SELECT autoID FROM dbo.tb_product WHERE product_code = N'TST-BOOK' AND is_delete = 0);

INSERT INTO dbo.tb_product_sku ([prefix],[ref_product_auto],[sku_code],[cost_price],[sell_price],[update_by])
VALUES (N'SKU', @prod, N'TST-BOOK-01', 60.0000, 100.0000, N'TEST');

/* หนังสือให้ส่วนลดพื้นฐาน 25% — ชั้นสุดท้ายเมื่อไม่มีกฎไหนเข้าเกณฑ์ */
INSERT INTO dbo.tb_book ([prefix],[ref_product_auto],[book_name],[cover_price],[customer_discount_percent],[complimentary_qty],[update_by])
VALUES (N'BOK', @prod, N'หนังสือทดสอบ', 100.0000, 25.00, 0, N'TEST');

DECLARE @cusA INT = (SELECT autoID FROM dbo.tb_customer WHERE customer_code = N'TST-A' AND is_delete = 0);
DECLARE @cusB INT = (SELECT autoID FROM dbo.tb_customer WHERE customer_code = N'TST-B' AND is_delete = 0);
DECLARE @sku  INT = (SELECT autoID FROM dbo.tb_product_sku WHERE sku_code = N'TST-BOOK-01' AND is_delete = 0);

INSERT INTO dbo.tb_customer_route ([prefix],[ref_customer_auto],[ref_route_auto],[is_primary],[update_by])
VALUES (N'CRT', @cusA, @rt, 1, N'TEST');
GO

/* ─────────────────────────── ตัวช่วยตรวจผล ─────────────────────────── */

IF OBJECT_ID(N'tempdb..#result') IS NOT NULL DROP TABLE #result;
CREATE TABLE #result (case_no INT, case_name NVARCHAR(100), expected NVARCHAR(100), actual NVARCHAR(100));
GO

DECLARE @cusA INT = (SELECT autoID FROM dbo.tb_customer WHERE customer_code = N'TST-A' AND is_delete = 0);
DECLARE @cusB INT = (SELECT autoID FROM dbo.tb_customer WHERE customer_code = N'TST-B' AND is_delete = 0);
DECLARE @sku  INT = (SELECT autoID FROM dbo.tb_product_sku WHERE sku_code = N'TST-BOOK-01' AND is_delete = 0);
DECLARE @g1   INT = (SELECT autoID FROM dbo.tb_discount_group WHERE group_code = N'G1' AND is_delete = 0);
DECLARE @rt   INT = (SELECT TOP 1 autoID FROM dbo.tb_route WHERE is_delete = 0 ORDER BY autoID);
DECLARE @today DATE = CAST(SYSDATETIME() AS DATE);

/* 1 · ไม่มีกฎเลย -> ตกไปที่ tb_book.customer_discount_percent */
INSERT INTO #result
SELECT 1, N'ไม่มีกฎ -> ส่วนลดหนังสือ', N'25.00 / BOOK_DEFAULT',
       CONCAT(FORMAT(r.discount_percent, N'0.00'), N' / ', r.source_scope)
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusA, @sku, 1, @today) r;

/* 2 · กฎระดับกลุ่ม 30% ชนะส่วนลดหนังสือ */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_discount_group_auto],[discount_percent],[update_by])
VALUES (N'PRL', N'กลุ่ม 1 พื้นฐาน 30%', N'GROUP', @g1, 30.00, N'TEST');

INSERT INTO #result
SELECT 2, N'กฎกลุ่มชนะส่วนลดหนังสือ', N'30.00 / GROUP',
       CONCAT(FORMAT(r.discount_percent, N'0.00'), N' / ', r.source_scope)
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusA, @sku, 1, @today) r;

/* 3 · on-top ระดับร้าน 5% บวกทับผู้ชนะ (legacy tb_OnTopDiscounts) */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_customer_auto],[discount_percent],[is_on_top],[update_by])
VALUES (N'PRL', N'on-top ร้าน A 5%', N'CUSTOMER', @cusA, 5.00, 1, N'TEST');

INSERT INTO #result
SELECT 3, N'on-top บวกทับกฎกลุ่ม', N'35.00 / GROUP / base 30.00',
       CONCAT(FORMAT(r.discount_percent, N'0.00'), N' / ', r.source_scope, N' / base ', FORMAT(r.base_percent, N'0.00'))
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusA, @sku, 1, @today) r;

/* 4 · กฎเจาะจงที่สุด (ลูกค้า × SKU) ทับกฎกลุ่ม แต่ on-top ยังบวกอยู่ */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_customer_auto],[ref_sku_auto],[discount_percent],[update_by])
VALUES (N'PRL', N'ร้าน A เล่มนี้ 40%', N'CUSTOMER_SKU', @cusA, @sku, 40.00, N'TEST');

INSERT INTO #result
SELECT 4, N'ลูกค้า×SKU ทับกฎกลุ่ม', N'45.00 / CUSTOMER_SKU',
       CONCAT(FORMAT(r.discount_percent, N'0.00'), N' / ', r.source_scope)
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusA, @sku, 1, @today) r;

/* 5 · กฎกลุ่ม × SKU ให้ราคาสุทธิ (legacy 1.8) -> ตอบเป็นราคา ไม่ใช่ % */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_discount_group_auto],[ref_sku_auto],[net_price],[update_by])
VALUES (N'PRL', N'กลุ่ม 1 เล่มนี้ ราคาสุทธิ 68', N'GROUP_SKU', @g1, @sku, 68.0000, N'TEST');

INSERT INTO #result
SELECT 5, N'กลุ่ม×SKU ให้ราคาสุทธิ', N'68.0000 / GROUP_SKU / pct NULL',
       CONCAT(FORMAT(r.net_price, N'0.0000'), N' / ', r.source_scope, N' / pct ', ISNULL(FORMAT(r.discount_percent, N'0.00'), N'NULL'))
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusB, @sku, 1, @today) r;

/* 6 · ขั้นบันไดจำนวน : กฎสาย 10% เข้าเกณฑ์เฉพาะเมื่อสั่ง 10 เล่มขึ้นไป */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_route_auto],[discount_percent],[min_qty],[priority],[update_by])
VALUES (N'PRL', N'ทั้งสาย ซื้อ 10 เล่มขึ้นไป 10%', N'ROUTE', @rt, 10.00, 10, 0, N'TEST');

/* ร้าน B ไม่อยู่ในสาย -> ไม่โดนกฎนี้ ต่อให้สั่ง 50 เล่ม */
INSERT INTO #result
SELECT 6, N'ร้านนอกสายไม่โดนกฎสาย', N'GROUP_SKU',
       r.source_scope
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusB, @sku, 50, @today) r;

/* 7 · ช่วงวันหมดอายุแล้ว -> ไม่นับ */
INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_customer_auto],[discount_percent],[is_on_top],[start_date],[end_date],[update_by])
VALUES (N'PRL', N'on-top ร้าน B หมดอายุ', N'CUSTOMER', @cusB, 7.00, 1,
        DATEADD(DAY, -30, @today), DATEADD(DAY, -1, @today), N'TEST');

INSERT INTO #result
SELECT 7, N'กฎหมดอายุไม่ถูกนับ', N'0.00',
       FORMAT(r.on_top_percent, N'0.00')
  FROM dbo.UFN_RESOLVE_DISCOUNT(@cusB, @sku, 1, @today) r;
GO

/* 8 · Trigger กันช่วงวันซ้อนกันบนปลายทางเดียวกัน */
DECLARE @g1 INT = (SELECT autoID FROM dbo.tb_discount_group WHERE group_code = N'G1' AND is_delete = 0);
BEGIN TRY
    INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_discount_group_auto],[discount_percent],[update_by])
    VALUES (N'PRL', N'กลุ่ม 1 ซ้ำซ้อน', N'GROUP', @g1, 32.00, N'TEST');
    INSERT INTO #result VALUES (8, N'กันกฎซ้อนช่วงวัน', N'BLOCKED', N'ยอมให้เพิ่ม');
END TRY
BEGIN CATCH
    INSERT INTO #result VALUES (8, N'กันกฎซ้อนช่วงวัน', N'BLOCKED',
        CASE WHEN ERROR_MESSAGE() LIKE N'%PRICE_RULE_OVERLAP%' THEN N'BLOCKED' ELSE ERROR_MESSAGE() END);
END CATCH
GO

/* 9 · CHECK กันแถวที่ปลายทางไม่ตรง scope */
DECLARE @sku INT = (SELECT autoID FROM dbo.tb_product_sku WHERE sku_code = N'TST-BOOK-01' AND is_delete = 0);
BEGIN TRY
    INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_sku_auto],[discount_percent],[update_by])
    VALUES (N'PRL', N'scope CUSTOMER แต่ชี้ SKU', N'CUSTOMER', @sku, 5.00, N'TEST');
    INSERT INTO #result VALUES (9, N'กันปลายทางไม่ตรง scope', N'BLOCKED', N'ยอมให้เพิ่ม');
END TRY
BEGIN CATCH
    INSERT INTO #result VALUES (9, N'กันปลายทางไม่ตรง scope', N'BLOCKED',
        CASE WHEN ERROR_MESSAGE() LIKE N'%CK_tb_price_rule_target%' THEN N'BLOCKED' ELSE ERROR_MESSAGE() END);
END CATCH
GO

/* 10 · CHECK กันแถวที่ใส่ทั้ง % และราคาสุทธิ */
DECLARE @g1 INT = (SELECT autoID FROM dbo.tb_discount_group WHERE group_code = N'G1' AND is_delete = 0);
BEGIN TRY
    INSERT INTO dbo.tb_price_rule ([prefix],[rule_name],[rule_scope],[ref_discount_group_auto],[discount_percent],[net_price],[update_by])
    VALUES (N'PRL', N'ใส่มาทั้งสองค่า', N'GROUP', @g1, 10.00, 90.0000, N'TEST');
    INSERT INTO #result VALUES (10, N'กัน % ปนราคาสุทธิ', N'BLOCKED', N'ยอมให้เพิ่ม');
END TRY
BEGIN CATCH
    INSERT INTO #result VALUES (10, N'กัน % ปนราคาสุทธิ', N'BLOCKED',
        CASE WHEN ERROR_MESSAGE() LIKE N'%CK_tb_price_rule_value%' THEN N'BLOCKED' ELSE ERROR_MESSAGE() END);
END CATCH
GO

/* ─────────────────────────── สรุปผล ─────────────────────────── */

SELECT case_no, case_name, expected, actual,
       CASE WHEN actual = expected THEN N'PASS' ELSE N'FAIL' END AS result
  FROM #result ORDER BY case_no;

SELECT CASE WHEN EXISTS (SELECT 1 FROM #result WHERE actual <> expected)
            THEN N'FAIL — มีเคสไม่ผ่าน' ELSE N'ALL PASS' END AS summary;
GO

/* ─────────────────────────── ล้างข้อมูลทดสอบ ─────────────────────────── */

/* ล้างข้อมูลทดสอบของรอบนี้
   ตารางทุกตัวมี TRIG_BLOCK_DELETE_* ที่แปลง DELETE เป็น Soft Delete แถวเก่าจึงค้างอยู่
   และทำให้การค้นด้วย customer_code เจอหลายแถว — ที่นี่จึงปิดทริกเกอร์เพื่อลบจริง
   ทำได้เพราะสคริปต์นี้รันบนฐานทดสอบเท่านั้น */
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRICE_RULE     ON dbo.tb_price_rule;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE ON dbo.tb_customer_route;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_BOOK           ON dbo.tb_book;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT_SKU    ON dbo.tb_product_sku;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT        ON dbo.tb_product;
DISABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER       ON dbo.tb_customer;

DELETE FROM dbo.tb_price_rule     WHERE update_by = N'TEST';
DELETE FROM dbo.tb_customer_route WHERE update_by = N'TEST';
DELETE FROM dbo.tb_book           WHERE update_by = N'TEST';
DELETE FROM dbo.tb_product_sku    WHERE update_by = N'TEST';
DELETE FROM dbo.tb_product        WHERE update_by = N'TEST';
DELETE FROM dbo.tb_customer       WHERE update_by = N'TEST';

ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRICE_RULE     ON dbo.tb_price_rule;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE ON dbo.tb_customer_route;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_BOOK           ON dbo.tb_book;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT_SKU    ON dbo.tb_product_sku;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_PRODUCT        ON dbo.tb_product;
ENABLE TRIGGER dbo.TRIG_BLOCK_DELETE_TB_CUSTOMER       ON dbo.tb_customer;
GO

DROP TABLE #result;
GO

SET NOEXEC OFF;
GO
