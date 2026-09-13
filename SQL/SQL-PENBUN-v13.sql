/* =====================================================================================
   SQL-PENBUN-v13.sql   —   INCREMENTAL  (บทบาทระดับที่สาม)
   -------------------------------------------------------------------------------------
   Generated : 2026-09-13
   Requires  : SQL-PENBUN-v12.sql ติดตั้งแล้ว
   Scope     : INSERT อย่างเดียว  ไม่ DROP ไม่ ALTER ไม่แตะตารางหรือ View ใด ๆ

   ปลอดภัยกับฐานที่มีข้อมูลจริง และ **รันซ้ำได้** ทุกคำสั่งข้ามแถวที่มีอยู่แล้ว

   ---------------------------------------------------------------------------------
   สิ่งที่ v13 เพิ่มจาก v12
   ---------------------------------------------------------------------------------
   v12 วางโครง RBAC ไว้แต่ seed แค่สองบทบาทที่เท่ากับ user_level เดิม คือ ADMIN กับ USER
   ซึ่งยังพูดไม่ได้ว่า "คนคลังออกใบรับสินค้าได้ แต่ออกใบส่งหนังสือไม่ได้" ทั้งที่นั่นคือ
   วิธีที่ศูนย์ทำงานจริง เอกสาร legacy แบ่งงานเป็น module ไม่ใช่ตำแหน่งคน
   บทบาทสามตัวนี้จึงตัดตามเส้นเดียวกับ module

   [A] WAREHOUSE  คลังสินค้า  —  Receive Module + Return Module
       ออกใบรับสินค้า ใบรับคืน และใบส่งคืนคู่ค้าได้ครบสี่การกระทำ
       ใบส่งหนังสือดูได้อย่างเดียว เพราะใบส่งผูกกับลูกหนี้และใบแจ้งเก็บ
       ซึ่งเป็นงานคนละสายกับการรับของเข้าคลัง

   [B] DELIVERY   จัดส่ง  —  Deliver Module
       ออกใบส่งหนังสือได้ครบ และดึงยอดจากประวัติได้ (allocation = view + insert
       เพราะ POST /allocation/pull คือ insert) เอกสารรับเข้าดูได้อย่างเดียว

   [C] VIEWER     ดูอย่างเดียว
       ไม่มีใน legacy — เพิ่มเพราะหัวหน้าหรือเจ้าของที่เปิดดูรายงานอย่างเดียว
       ไม่ควรถือบทบาทที่กดโพสต์เอกสารได้ ทุก resource เป็น view ยกเว้น users

   ทั้งสามตัวไม่มีแถวของ resource "users" เลย การจัดการผู้ใช้ยังเป็นของ ADMIN เท่านั้น

   is_system = 0 ต่างจาก ADMIN/USER ที่เป็น 1 เพราะไม่มีโค้ดไหนพึ่งพาสามตัวนี้
   ปิดหรือลบทิ้งแล้วระบบยังทำงานต่อได้ เสียแค่บัญชีที่ถือบทบาทนั้นจะไม่มีสิทธิ์

   ผู้ใช้ถือได้หลายบทบาท (tb_user_role เป็น M..N) คนที่ทำทั้งรับและส่งจึงถือสอง
   บทบาทได้เลย ไม่ต้องสร้างบทบาทลูกผสม vw_user_privilege รวมสิทธิ์แบบ union ให้แล้ว

   ---------------------------------------------------------------------------------
   ฝั่ง PenbunAPI
   ---------------------------------------------------------------------------------
   POST /users เคยมีรายการ user_level ที่รับได้เขียนตายไว้ใน Go เป็น ADMIN/USER
   ตั้งแต่ v13 มันอ่านจาก tb_role ที่ is_active = 1 แทน เพิ่มบทบาทที่นี่แล้ว API
   รับค่านั้นทันทีโดยไม่ต้อง deploy ใหม่
   ===================================================================================== */

SET NOCOUNT ON;
GO

USE [PENBUN]
GO

/* กันรันผิดฐาน — ต้องมีโครง RBAC ของ v12 อยู่ก่อน */
IF OBJECT_ID(N'dbo.tb_role', N'U') IS NULL
   OR OBJECT_ID(N'dbo.tb_privilege', N'U') IS NULL
BEGIN
    DECLARE @db NVARCHAR(128) = DB_NAME();
    RAISERROR (N'V13: ฐาน [%s] ยังไม่มี tb_role / tb_privilege — ติดตั้ง SQL-PENBUN-v12.sql ก่อน',
               16, 1, @db) WITH NOWAIT;
    SET NOEXEC ON;
END
GO

/* =====================================================================================
   SECTION 1 : บทบาทใหม่สามตัว
   ===================================================================================== */

INSERT INTO [dbo].[tb_role] ([prefix],[role_code],[role_name],[description],[is_system],[update_by])
SELECT v.role_code_prefix, v.role_code, v.role_name, v.description, 0, N'System'
  FROM (VALUES
     (N'RLE', N'WAREHOUSE', N'คลังสินค้า',  N'รับหนังสือเข้าคลัง รับคืนจากร้าน และส่งคืนเจ้าของหนังสือ'),
     (N'RLE', N'DELIVERY',  N'จัดส่ง',      N'ออกใบส่งหนังสือ และเตรียมยอดส่งจากประวัติ'),
     (N'RLE', N'VIEWER',    N'ดูอย่างเดียว', N'เปิดดูได้ทุกหน้าจอ แก้ไขไม่ได้เลย')
  ) AS v(role_code_prefix, role_code, role_name, description)
 WHERE NOT EXISTS (SELECT 1 FROM dbo.tb_role r WHERE r.role_code = v.role_code);
GO

/* =====================================================================================
   SECTION 2 : สิทธิ์ของสามบทบาท

   WAREHOUSE 27 แถว · DELIVERY 27 แถว · VIEWER 27 แถว  รวม 81 แถว

   resource_code คือชื่อ descriptor ฝั่ง PenbunAPI (crud.Resource.Name) แถวสิทธิ์
   จึงชี้ไปยังเส้นทางที่ mount จริง ไม่ใช่รายการเมนูที่เขียนซ้ำไว้ต่างหาก
   ===================================================================================== */

INSERT INTO [dbo].[tb_privilege]
    ([prefix],[ref_role_auto],[ref_privilege_group_auto],[resource_code],
     [can_view],[can_insert],[can_update],[can_delete],[update_by])
SELECT N'PRV', r.autoID, g.autoID, v.resource_code,
       v.can_view, v.can_insert, v.can_update, v.can_delete, N'System'
  FROM (VALUES
     (N'WAREHOUSE', N'MASTER', N'company', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'customer-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'vendor-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'discount-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'discount-group', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'product-category', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'product-format-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'unit-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'book-type', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'warehouse', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'product-group', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'vendor', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'customer', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'discount', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'route', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'customer-route', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'product', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'product-sku', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'book', 1,0,0,0),
     (N'WAREHOUSE', N'MASTER', N'price-rule', 1,0,0,0),
     (N'WAREHOUSE', N'DOCUMENT', N'receive-note', 1,1,1,1),
     (N'WAREHOUSE', N'DOCUMENT', N'return-note', 1,1,1,1),
     (N'WAREHOUSE', N'DOCUMENT', N'vendor-return-note', 1,1,1,1),
     (N'WAREHOUSE', N'DOCUMENT', N'order', 1,0,0,0),
     (N'WAREHOUSE', N'STOCK', N'stock', 1,0,0,0),
     (N'WAREHOUSE', N'STOCK', N'consign', 1,0,0,0),
     (N'WAREHOUSE', N'STOCK', N'allocation', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'company', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'customer-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'vendor-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'discount-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'discount-group', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'product-category', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'product-format-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'unit-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'book-type', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'warehouse', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'product-group', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'vendor', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'customer', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'discount', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'route', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'customer-route', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'product', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'product-sku', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'book', 1,0,0,0),
     (N'DELIVERY', N'MASTER', N'price-rule', 1,0,0,0),
     (N'DELIVERY', N'DOCUMENT', N'order', 1,1,1,1),
     (N'DELIVERY', N'DOCUMENT', N'receive-note', 1,0,0,0),
     (N'DELIVERY', N'DOCUMENT', N'return-note', 1,0,0,0),
     (N'DELIVERY', N'DOCUMENT', N'vendor-return-note', 1,0,0,0),
     (N'DELIVERY', N'STOCK', N'allocation', 1,1,0,0),
     (N'DELIVERY', N'STOCK', N'stock', 1,0,0,0),
     (N'DELIVERY', N'STOCK', N'consign', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'company', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'customer-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'vendor-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'discount-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'discount-group', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'product-category', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'product-format-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'unit-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'book-type', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'warehouse', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'product-group', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'vendor', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'customer', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'discount', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'route', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'customer-route', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'product', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'product-sku', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'book', 1,0,0,0),
     (N'VIEWER', N'MASTER', N'price-rule', 1,0,0,0),
     (N'VIEWER', N'DOCUMENT', N'receive-note', 1,0,0,0),
     (N'VIEWER', N'DOCUMENT', N'order', 1,0,0,0),
     (N'VIEWER', N'DOCUMENT', N'return-note', 1,0,0,0),
     (N'VIEWER', N'DOCUMENT', N'vendor-return-note', 1,0,0,0),
     (N'VIEWER', N'STOCK', N'stock', 1,0,0,0),
     (N'VIEWER', N'STOCK', N'consign', 1,0,0,0),
     (N'VIEWER', N'STOCK', N'allocation', 1,0,0,0)
  ) AS v(role_code, group_code, resource_code, can_view, can_insert, can_update, can_delete)
  INNER JOIN dbo.tb_role            r ON r.role_code  = v.role_code
  INNER JOIN dbo.tb_privilege_group g ON g.group_code = v.group_code
 WHERE NOT EXISTS (
       SELECT 1 FROM dbo.tb_privilege p
        WHERE p.ref_role_auto = r.autoID
          AND p.resource_code = v.resource_code
          AND p.is_delete = 0);
GO

/* =====================================================================================
   SECTION 3 : VERIFY  (รันหลังติดตั้งเพื่อยืนยันว่าครบ)
   ตัวเลขที่ต้องได้ :
     roles 5 · privileges 136
     WAREHOUSE 27 · DELIVERY 27 · VIEWER 27 · ADMIN 28 · USER 27
   ===================================================================================== */
SELECT 'roles' AS object_type, COUNT(*) AS cnt FROM dbo.tb_role WHERE is_delete = 0
UNION ALL SELECT 'privileges', COUNT(*) FROM dbo.tb_privilege WHERE is_delete = 0;
GO

SELECT r.role_code, r.role_name, r.is_system, COUNT(p.autoID) AS privileges
  FROM dbo.tb_role r
  LEFT JOIN dbo.tb_privilege p ON p.ref_role_auto = r.autoID AND p.is_delete = 0
 WHERE r.is_delete = 0
 GROUP BY r.role_code, r.role_name, r.is_system
 ORDER BY r.role_code;
GO

SET NOEXEC OFF;
GO
