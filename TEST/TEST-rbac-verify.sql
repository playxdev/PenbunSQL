/* =====================================================================================
   TEST-rbac-verify.sql  --  ยืนยันว่า RBAC ติดตั้งครบ ทั้งโครง (v12) และบทบาท (v13)
   -------------------------------------------------------------------------------------
   อ่านอย่างเดียวทั้งไฟล์ : ไม่ INSERT ไม่ UPDATE ไม่ DELETE ไม่ CREATE object ถาวร
   จึงรันบน production ได้ปลอดภัย รันซ้ำกี่รอบก็ได้ ไม่ทิ้งอะไรไว้

   ไม่มี USE โดยตั้งใจ — ระบุฐานตอนเรียก
       sqlcmd -S <host>,1433 -U sa -P '<pw>' -C -d PENBUN -b -i TEST/TEST-v12-verify.sql
   หรือเลือกฐานใน SSMS แล้วกด Execute

   ทุกบรรทัดพิมพ์ PASS หรือ FAIL — ไม่มีบรรทัดไหนต้องอ่านตัวเลขเอง
   ท้ายไฟล์สรุปเป็นคำเดียว : RBAC OK หรือ RBAC FAILED

   ต้องรัน SQL-PENBUN-v12.sql แล้วตามด้วย SQL-PENBUN-v13.sql ฐานที่มีแค่ v12
   จะตกที่หมวด seed เพราะยังมีสองบทบาท ไม่ใช่ห้า ซึ่งถูกต้อง — RBAC ยังไม่ครบ
   ===================================================================================== */

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'tempdb..#r') IS NOT NULL DROP TABLE #r;
CREATE TABLE #r (
    seq        INT IDENTITY(1,1),
    part       NVARCHAR(20),
    check_name NVARCHAR(90),
    expected   NVARCHAR(40),
    actual     NVARCHAR(40)
);
GO

/* ─────────────────── ส่วนที่ 1 : นับ object จาก catalog ───────────────────
   ชุดนี้คอมไพล์ได้เสมอ ไม่ว่าฐานจะเป็น v11 หรือ v12 หรือฐานเปล่า
   ตัวเลขที่คาดไว้มาจากการติดตั้งจริงบน SQL Server 2022 RTM-CU21 เมื่อ 13 ก.ย. 2026 */

INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'tables (tb_*)',   N'38',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.tables WHERE name LIKE 'tb[_]%';
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'views (vw_*)',    N'36',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.views WHERE name LIKE 'vw[_]%';
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'procedures (USP_*)', N'11',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.procedures WHERE name LIKE 'USP[_]%';
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'functions (UFN_*)', N'1',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.objects
 WHERE name LIKE 'UFN[_]%' AND type IN ('IF','FN','TF');
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'triggers',        N'152',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.triggers WHERE is_ms_shipped = 0;
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'foreign_keys',    N'59',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.foreign_keys;
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'check_constraints', N'19',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.check_constraints;
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'indexes (นอกจาก PK)', N'130',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.indexes
 WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name LIKE 'tb[_]%')
   AND index_id > 1;

/* FK ที่อยู่ในสถานะ not-trusted แปลว่าถูกสร้างแบบ WITH NOCHECK หรือมีข้อมูลละเมิดอยู่
   ต้องเป็นศูนย์เสมอ ทุกเวอร์ชัน */
INSERT #r (part, check_name, expected, actual)
SELECT N'1 · object', N'untrusted foreign keys', N'0',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.foreign_keys WHERE is_not_trusted = 1;

/* ─────────────────── ส่วนที่ 2 : ของใหม่ที่ v12 เพิ่ม ───────────────────
   ถ้าสี่ตารางนี้ไม่ครบ = ยังเป็น v11 อยู่ ไม่ใช่ v12 */

INSERT #r (part, check_name, expected, actual)
SELECT N'2 · ตาราง RBAC', N'tb_role · tb_user_role · tb_privilege_group · tb_privilege', N'4',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.tables
 WHERE name IN (N'tb_role', N'tb_user_role', N'tb_privilege_group', N'tb_privilege');

INSERT #r (part, check_name, expected, actual)
SELECT N'2 · View RBAC', N'vw_role · vw_privilege · vw_user_privilege', N'3',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.views
 WHERE name IN (N'vw_role', N'vw_privilege', N'vw_user_privilege');

/* ทุกตารางในระบบนี้ต้องมีทริกเกอร์ครบสี่ตัว — generate id / update date / sync status /
   block delete  ขาดตัวไหนแปลว่า Soft Delete หรือ Business ID พัง */
INSERT #r (part, check_name, expected, actual)
SELECT N'2 · Trigger RBAC', N'ทริกเกอร์บนสี่ตาราง RBAC (4 ตาราง x 4)', N'16',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.triggers t
  JOIN sys.tables tb ON tb.object_id = t.parent_id
 WHERE tb.name IN (N'tb_role', N'tb_user_role', N'tb_privilege_group', N'tb_privilege');

INSERT #r (part, check_name, expected, actual)
SELECT N'2 · FK RBAC', N'FK ของ tb_user_role และ tb_privilege', N'4',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.foreign_keys fk
  JOIN sys.tables tb ON tb.object_id = fk.parent_object_id
 WHERE tb.name IN (N'tb_user_role', N'tb_privilege');

/* คอลัมน์สี่ช่องที่หน้าจอ M002_P0004 ติ๊ก ถ้าขาดช่องใดช่องหนึ่งคือ schema ไม่ตรงสเปก */
INSERT #r (part, check_name, expected, actual)
SELECT N'2 · คอลัมน์', N'tb_privilege : can_view · can_insert · can_update · can_delete', N'4',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.columns
 WHERE object_id = OBJECT_ID(N'dbo.tb_privilege')
   AND name IN (N'can_view', N'can_insert', N'can_update', N'can_delete');

/* user_level ต้องยังอยู่ใน v12 — PenbunAPI รุ่นปัจจุบันยังใช้คอลัมน์นี้ตัดสินสิทธิ์จริง
   ตัดทิ้งได้เมื่อ API ย้ายไปอ่าน vw_user_privilege แล้วเท่านั้น */
INSERT #r (part, check_name, expected, actual)
SELECT N'2 · คอลัมน์', N'tb_users.user_level ยังอยู่ (v12 ยังไม่ตัด)', N'1',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM sys.columns
 WHERE object_id = OBJECT_ID(N'dbo.tb_users') AND name = N'user_level';
GO

/* ─────────────────── กันรันส่วนที่ 3 บนฐานที่ยังเป็น v11 ───────────────────
   ส่วนถัดไปอ้างชื่อตารางของ v12 ตรง ๆ ถ้าฐานยังไม่มี batch จะคอมไพล์ไม่ผ่าน
   จึงตัดจบตรงนี้แล้วพิมพ์สรุปเท่าที่ตรวจได้ */
IF OBJECT_ID(N'dbo.tb_privilege', N'U') IS NULL
   OR OBJECT_ID(N'dbo.vw_user_privilege', N'V') IS NULL
BEGIN
    PRINT N'';
    PRINT N'!! ฐานนี้ยังไม่มี tb_privilege / vw_user_privilege — ยังเป็น v11 หรือเก่ากว่า';
    PRINT N'!! ข้ามการตรวจ SEED  ผลด้านล่างคือเท่าที่ตรวจได้';
    SELECT part AS [part], check_name AS [check], expected AS [expected], actual AS [actual],
           CASE WHEN expected = actual THEN N'PASS' ELSE N'FAIL' END AS [result]
      FROM #r ORDER BY seq;
    PRINT N'';
    PRINT N'>>> RBAC FAILED — ยังไม่ได้ติดตั้ง v12';
    SET NOEXEC ON;
END
GO

/* ─────────────────── ส่วนที่ 3 : SEED และพฤติกรรมจริง ─────────────────── */

INSERT #r (part, check_name, expected, actual)
SELECT N'3 · seed', N'tb_role (ADMIN·USER·WAREHOUSE·DELIVERY·VIEWER)', N'5',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM dbo.tb_role WHERE is_delete = 0;
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · seed', N'tb_privilege_group (SYSTEM/MASTER/DOCUMENT/STOCK)', N'4',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM dbo.tb_privilege_group;
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · seed', N'tb_privilege (28+27 ของ v12 บวก 27x3 ของ v13)', N'136',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM dbo.tb_privilege WHERE is_delete = 0;
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · seed', N'tb_user_role (admin -> ADMIN)', N'1',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM dbo.tb_user_role;

/* Business ID ต้องถูกเติมโดยทริกเกอร์ ไม่มีแถวไหน NULL ค้าง
   ถ้า NULL แปลว่า TRIG_GENERATE_*_ID ไม่ทำงาน ซึ่งจะลามไปทุกแถวที่สร้างต่อจากนี้ */
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · trigger', N'Business ID ของสี่ตาราง RBAC ไม่มี NULL', N'0',
       CAST(
         (SELECT COUNT(*) FROM dbo.tb_role            WHERE role_id IS NULL)
       + (SELECT COUNT(*) FROM dbo.tb_user_role       WHERE user_role_id IS NULL)
       + (SELECT COUNT(*) FROM dbo.tb_privilege_group WHERE privilege_group_id IS NULL)
       + (SELECT COUNT(*) FROM dbo.tb_privilege       WHERE privilege_id IS NULL)
       AS NVARCHAR(40));

/* vw_user_privilege รวมสิทธิ์แบบ union ข้ามบทบาท  admin ถือบทบาทเดียวคือ ADMIN
   ผลลัพธ์จึงต้องเท่าจำนวนแถวสิทธิ์ของ ADMIN พอดี */
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · view', N'vw_user_privilege ของ admin', N'28',
       CAST(COUNT(*) AS NVARCHAR(40)) FROM dbo.vw_user_privilege WHERE user_name = N'admin';

/* สองเคสนี้คือหัวใจของ v12 : สิทธิ์ที่ลอกมาจากกฎที่ PenbunAPI บังคับอยู่จริง
   ADMIN เขียนข้อมูลหลักได้  USER อ่านได้อย่างเดียว  ถ้าสลับกันแปลว่า SEED ผิด */
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · สิทธิ์', N'ADMIN : customer = view+insert+update+delete', N'1,1,1,1',
       ISNULL((SELECT CAST(p.can_view AS NVARCHAR(1)) + N',' + CAST(p.can_insert AS NVARCHAR(1)) + N','
                    + CAST(p.can_update AS NVARCHAR(1)) + N',' + CAST(p.can_delete AS NVARCHAR(1))
                 FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                WHERE r.role_code = N'ADMIN' AND p.resource_code = N'customer'), N'(ไม่มีแถว)');

INSERT #r (part, check_name, expected, actual)
SELECT N'3 · สิทธิ์', N'USER : customer = view อย่างเดียว', N'1,0,0,0',
       ISNULL((SELECT CAST(p.can_view AS NVARCHAR(1)) + N',' + CAST(p.can_insert AS NVARCHAR(1)) + N','
                    + CAST(p.can_update AS NVARCHAR(1)) + N',' + CAST(p.can_delete AS NVARCHAR(1))
                 FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                WHERE r.role_code = N'USER' AND p.resource_code = N'customer'), N'(ไม่มีแถว)');

/* เอกสารเป็นงานประจำวัน USER ต้องทำได้ครบ ไม่งั้นระบบใช้งานจริงไม่ได้ */
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · สิทธิ์', N'USER : order (ใบส่งหนังสือ) = ครบสี่', N'1,1,1,1',
       ISNULL((SELECT CAST(p.can_view AS NVARCHAR(1)) + N',' + CAST(p.can_insert AS NVARCHAR(1)) + N','
                    + CAST(p.can_update AS NVARCHAR(1)) + N',' + CAST(p.can_delete AS NVARCHAR(1))
                 FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                WHERE r.role_code = N'USER' AND p.resource_code = N'order'), N'(ไม่มีแถว)');

/* USER ต้องมองไม่เห็นตารางผู้ใช้เลย — ไม่มีแถวสิทธิ์ = ไม่มีสิทธิ์ */
INSERT #r (part, check_name, expected, actual)
SELECT N'3 · สิทธิ์', N'USER : users = ไม่มีแถวสิทธิ์', N'0',
       CAST(COUNT(*) AS NVARCHAR(40))
  FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
 WHERE r.role_code = N'USER' AND p.resource_code = N'users';
GO

/* ─────────────────── บทบาทของ v13 ───────────────────
   จำนวนแถวต่อบทบาท จับกรณี seed ลงไม่ครบหรือลงซ้ำ */

INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'จำนวนสิทธิ์ต่อบทบาท WAREHOUSE·DELIVERY·VIEWER', N'27,27,27',
       ISNULL((SELECT CAST(SUM(CASE WHEN r.role_code = N'WAREHOUSE' THEN 1 ELSE 0 END) AS NVARCHAR(10)) + N','
                   + CAST(SUM(CASE WHEN r.role_code = N'DELIVERY'  THEN 1 ELSE 0 END) AS NVARCHAR(10)) + N','
                   + CAST(SUM(CASE WHEN r.role_code = N'VIEWER'    THEN 1 ELSE 0 END) AS NVARCHAR(10))
                FROM dbo.tb_privilege p
                JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
               WHERE p.is_delete = 0), N'(ไม่มีแถว)');

/* เส้นแบ่งที่ทำให้สองบทบาทนี้ต่างกัน ถ้าสลับกันคือ seed ผิด */
INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'WAREHOUSE : receive-note ครบสี่ · order ดูอย่างเดียว', N'1111,1000',
       ISNULL((SELECT (SELECT CAST(p.can_view AS NVARCHAR(1))+CAST(p.can_insert AS NVARCHAR(1))
                            + CAST(p.can_update AS NVARCHAR(1))+CAST(p.can_delete AS NVARCHAR(1))
                         FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                        WHERE r.role_code = N'WAREHOUSE' AND p.resource_code = N'receive-note')
                   + N','
                   + (SELECT CAST(p.can_view AS NVARCHAR(1))+CAST(p.can_insert AS NVARCHAR(1))
                            + CAST(p.can_update AS NVARCHAR(1))+CAST(p.can_delete AS NVARCHAR(1))
                         FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                        WHERE r.role_code = N'WAREHOUSE' AND p.resource_code = N'order')), N'(ไม่มีแถว)');

INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'DELIVERY : order ครบสี่ · allocation ดึงได้ · receive-note ดูอย่างเดียว', N'1111,1100,1000',
       ISNULL((SELECT (SELECT CAST(p.can_view AS NVARCHAR(1))+CAST(p.can_insert AS NVARCHAR(1))
                            + CAST(p.can_update AS NVARCHAR(1))+CAST(p.can_delete AS NVARCHAR(1))
                         FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                        WHERE r.role_code = N'DELIVERY' AND p.resource_code = N'order')
                   + N','
                   + (SELECT CAST(p.can_view AS NVARCHAR(1))+CAST(p.can_insert AS NVARCHAR(1))
                            + CAST(p.can_update AS NVARCHAR(1))+CAST(p.can_delete AS NVARCHAR(1))
                         FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                        WHERE r.role_code = N'DELIVERY' AND p.resource_code = N'allocation')
                   + N','
                   + (SELECT CAST(p.can_view AS NVARCHAR(1))+CAST(p.can_insert AS NVARCHAR(1))
                            + CAST(p.can_update AS NVARCHAR(1))+CAST(p.can_delete AS NVARCHAR(1))
                         FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
                        WHERE r.role_code = N'DELIVERY' AND p.resource_code = N'receive-note')), N'(ไม่มีแถว)');

/* VIEWER ต้องไม่มีสิทธิ์เขียนสักแถวเดียวในทั้งระบบ */
INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'VIEWER : ไม่มีสิทธิ์เขียนเลยสักแถว', N'0',
       CAST(COUNT(*) AS NVARCHAR(40))
  FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
 WHERE r.role_code = N'VIEWER' AND p.is_delete = 0
   AND (p.can_insert = 1 OR p.can_update = 1 OR p.can_delete = 1);

/* การจัดการผู้ใช้ยังเป็นของ ADMIN เท่านั้น สามบทบาทใหม่ต้องไม่มีแถวของ users */
INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'WAREHOUSE·DELIVERY·VIEWER : ไม่มีแถวของ users', N'0',
       CAST(COUNT(*) AS NVARCHAR(40))
  FROM dbo.tb_privilege p JOIN dbo.tb_role r ON r.autoID = p.ref_role_auto
 WHERE r.role_code IN (N'WAREHOUSE', N'DELIVERY', N'VIEWER')
   AND p.resource_code = N'users' AND p.is_delete = 0;

/* ทุกบัญชีต้องมี user_level ที่มีบทบาทรองรับ ไม่งั้น login ได้แต่ไม่มีสิทธิ์ */
INSERT #r (part, check_name, expected, actual)
SELECT N'4 · v13', N'บัญชีที่ user_level ไม่มีบทบาทรองรับ', N'0',
       CAST(COUNT(*) AS NVARCHAR(40))
  FROM dbo.tb_users u
 WHERE u.is_delete = 0
   AND NOT EXISTS (SELECT 1 FROM dbo.tb_role r
                    WHERE r.role_code = u.user_level AND r.is_delete = 0 AND r.is_active = 1);
GO

/* ─────────────────────────────── สรุป ─────────────────────────────── */

SELECT part AS [part], check_name AS [check], expected AS [expected], actual AS [actual],
       CASE WHEN expected = actual THEN N'PASS' ELSE N'FAIL' END AS [result]
  FROM #r ORDER BY seq;

DECLARE @fail INT = (SELECT COUNT(*) FROM #r WHERE expected <> actual);
DECLARE @all  INT = (SELECT COUNT(*) FROM #r);
PRINT N'';
IF @fail = 0
    PRINT N'>>> RBAC OK  —  ผ่านครบ ' + CAST(@all AS NVARCHAR(10)) + N' รายการ';
ELSE
    PRINT N'>>> RBAC FAILED  —  ตก ' + CAST(@fail AS NVARCHAR(10))
        + N' จาก ' + CAST(@all AS NVARCHAR(10)) + N' รายการ ดูบรรทัดที่ขึ้น FAIL';
GO

SET NOEXEC OFF;
IF OBJECT_ID(N'tempdb..#r') IS NOT NULL DROP TABLE #r;
GO
