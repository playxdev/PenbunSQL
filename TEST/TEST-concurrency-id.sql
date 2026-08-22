/* =====================================================================================
   TEST-concurrency-id.sql
   ทดสอบ Auto-ID Allocator ของ PenbunSQL v7 ภายใต้การใช้งานพร้อมกัน
   -------------------------------------------------------------------------------------
   วิธีใช้:
     1) รัน PATCH A (pre-seed) หนึ่งครั้ง — ปิดช่องโหว่ตอนแถวแรกของแต่ละตาราง
     2) เปิด SSMS หลาย ๆ tab (10 tab) แล้ววาง TEST 1 ลงทุก tab
        กด F5 พร้อมกัน (หรือใช้ ostress / sqlcmd loop)
     3) รัน VERIFY เพื่อดูผล
   ===================================================================================== */

USE [PENBUN]
GO

/* ═════════════════════════════════════════════════════════════════════════════════════
   PATCH A : PRE-SEED tb_reference ทั้ง 31 ตาราง
   -------------------------------------------------------------------------------------
   proc มีบรรทัด  IF NOT EXISTS (...) INSERT ...  ซึ่งทำงานเฉพาะ "ครั้งแรกสุด" ของตารางนั้น
   ถ้ามีคนยิงพร้อมกัน 10 คนใน "วินาทีแรกที่ระบบเปิดใช้" จะไปชนกันที่ path นี้
   การ pre-seed ทำให้ path นั้นไม่มีวันทำงานเลย
   ═════════════════════════════════════════════════════════════════════════════════════ */

INSERT INTO dbo.tb_reference (ref_id, ref_int, ref_text, prefix, update_by)
SELECT v.t, 0, N'A', N'REF', N'System'
  FROM (VALUES
    ('tb_users'),('tb_company'),('tb_customer_type'),('tb_vendor_type'),
    ('tb_discount_type'),('tb_product_category'),('tb_product_format_type'),
    ('tb_unit_type'),('tb_book_type'),('tb_product_group'),('tb_warehouse'),
    ('tb_vendor'),('tb_customer'),('tb_discount'),('tb_product'),
    ('tb_product_sku'),('tb_book'),('tb_route'),('tb_customer_route'),
    ('tb_stock_movement'),('tb_product_stock'),('tb_consign_balance'),
    ('tb_receive_note'),('tb_receive_item'),('tb_order'),('tb_order_item'),
    ('tb_return_note'),('tb_return_item'),('tb_vendor_return_note'),
    ('tb_vendor_return_item'),('tb_allocation_history')
  ) AS v(t)
 WHERE NOT EXISTS (SELECT 1 FROM dbo.tb_reference r WHERE r.ref_id = v.t);
GO

-- ตรวจว่า pre-seed ครบ (ควรได้ 31 แถวขึ้นไป)
SELECT COUNT(*) AS seeded_rows FROM dbo.tb_reference;
GO


/* ═════════════════════════════════════════════════════════════════════════════════════
   TEST 1 : Concurrent Multi-Row INSERT
   วางสคริปต์นี้ใน SSMS 10 tab แล้วกด F5 พร้อมกัน
   แต่ละ tab ยิง 20 รอบ รอบละ 25 แถว  ->  รวม 10 x 20 x 25 = 5,000 แถว
   ═════════════════════════════════════════════════════════════════════════════════════ */

SET NOCOUNT ON;

DECLARE @i INT = 0;
DECLARE @spid INT = @@SPID;

WHILE @i < 20
BEGIN
    BEGIN TRY
        INSERT INTO dbo.tb_book_type (prefix, type_name, description, update_by)
        SELECT TOP (25)
               N'BKT',
               N'LOAD-' + CAST(@spid AS NVARCHAR(10)) + N'-' + CAST(@i AS NVARCHAR(10))
                        + N'-' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS NVARCHAR(10)),
               N'concurrency test',
               N'LoadTest'
          FROM sys.all_objects;
    END TRY
    BEGIN CATCH
        PRINT CONCAT(N'SPID ', @spid, N' รอบ ', @i, N' ERROR ',
                     ERROR_NUMBER(), N' : ', ERROR_MESSAGE());
    END CATCH

    SET @i = @i + 1;
END

PRINT CONCAT(N'SPID ', @@SPID, N' เสร็จแล้ว');
GO


/* ═════════════════════════════════════════════════════════════════════════════════════
   VERIFY : ผลลัพธ์ที่ถูกต้อง
   ═════════════════════════════════════════════════════════════════════════════════════ */

-- V1. จำนวนแถว vs จำนวน ID ที่ไม่ซ้ำ  ->  ต้องเท่ากันเป๊ะ
SELECT  COUNT(*)                     AS total_rows,
        COUNT(DISTINCT book_type_id) AS distinct_ids,
        SUM(CASE WHEN book_type_id IS NULL THEN 1 ELSE 0 END) AS null_ids,
        CASE WHEN COUNT(*) = COUNT(DISTINCT book_type_id)
              AND SUM(CASE WHEN book_type_id IS NULL THEN 1 ELSE 0 END) = 0
             THEN 'PASS' ELSE 'FAIL' END AS result
  FROM dbo.tb_book_type;
GO

-- V2. หา ID ที่ซ้ำ  ->  ต้องได้ 0 แถว
SELECT book_type_id, COUNT(*) AS dup_count
  FROM dbo.tb_book_type
 GROUP BY book_type_id
HAVING COUNT(*) > 1;
GO

-- V3. หาช่องว่างของเลขรันนิ่ง  ->  ปกติต้องได้ 0 แถว (allocator นี้ gapless)
--     ถ้ามี gap แปลว่ามี transaction ที่ rollback หลังจองเลขไปแล้ว
WITH x AS (
    SELECT CAST(SUBSTRING(book_type_id, 5, 6) AS INT) AS n
      FROM dbo.tb_book_type
     WHERE book_type_id IS NOT NULL AND LEFT(book_type_id, 4) = 'BKTA'
)
SELECT MIN(n) AS min_no, MAX(n) AS max_no, COUNT(*) AS cnt,
       MAX(n) - MIN(n) + 1 - COUNT(*) AS gap_count
  FROM x;
GO

-- V4. tb_reference ตรงกับจำนวนแถวจริงไหม
SELECT r.ref_id, r.ref_int AS allocated_to,
       (SELECT COUNT(*) FROM dbo.tb_book_type) AS actual_rows,
       CASE WHEN r.ref_int = (SELECT COUNT(*) FROM dbo.tb_book_type)
            THEN 'IN SYNC' ELSE 'DRIFT (มี rollback เกิดขึ้น)' END AS status
  FROM dbo.tb_reference r
 WHERE r.ref_id = 'tb_book_type';
GO


/* ═════════════════════════════════════════════════════════════════════════════════════
   MONITOR : รันใน tab แยกระหว่างที่ TEST 1 กำลังทำงาน
   ดูว่ามีการ block เกิดขึ้นจริงหรือไม่ และนานแค่ไหน
   ═════════════════════════════════════════════════════════════════════════════════════ */

SELECT  r.session_id,
        r.blocking_session_id,
        r.wait_type,
        r.wait_time      AS wait_ms,
        r.wait_resource,
        OBJECT_NAME(t.objectid) AS proc_name,
        SUBSTRING(t.text, (r.statement_start_offset/2) + 1,
                  ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text)
                        ELSE r.statement_end_offset END - r.statement_start_offset)/2) + 1
        ) AS running_stmt
  FROM sys.dm_exec_requests r
 CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
 WHERE r.session_id <> @@SPID
   AND (r.blocking_session_id <> 0 OR r.wait_type IS NOT NULL)
 ORDER BY r.wait_time DESC;
GO

-- นับ deadlock ที่เกิดขึ้นตั้งแต่ SQL Server start  ->  ควรเป็น 0
SELECT cntr_value AS deadlocks_per_sec_total
  FROM sys.dm_os_performance_counters
 WHERE counter_name LIKE 'Number of Deadlocks/sec%'
   AND instance_name = '_Total';
GO


/* ═════════════════════════════════════════════════════════════════════════════════════
   CLEANUP
   ═════════════════════════════════════════════════════════════════════════════════════ */

-- ลบข้อมูลทดสอบ (จะกลายเป็น soft delete เพราะ TRIG_BLOCK_DELETE)
-- ถ้าต้องการลบจริง ให้ปิด trigger ชั่วคราว
/*
ALTER TABLE dbo.tb_book_type DISABLE TRIGGER TRIG_BLOCK_DELETE_TB_BOOK_TYPE;
DELETE FROM dbo.tb_book_type WHERE update_by = N'LoadTest';
ALTER TABLE dbo.tb_book_type ENABLE TRIGGER TRIG_BLOCK_DELETE_TB_BOOK_TYPE;

UPDATE dbo.tb_reference
   SET ref_int = (SELECT COUNT(*) FROM dbo.tb_book_type)
 WHERE ref_id = 'tb_book_type';
*/
GO
