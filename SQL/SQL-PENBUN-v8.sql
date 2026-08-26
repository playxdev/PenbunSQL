/* =====================================================================================
   SQL-PENBUN-v8.sql   —   STANDALONE FULL BUILD
   -------------------------------------------------------------------------------------
   Generated : 2026-08-26
   Scope     : DROP & CREATE ทั้งฐานข้อมูล  32 ตาราง  ไม่มี ALTER แม้แต่บรรทัดเดียว
   Replaces  : SQL-PENBUN-v7.sql  (ห้ามรันร่วมกัน)

   !!! คำเตือน : SECTION 1 ลบข้อมูลทั้งหมด  สำรองก่อนรันเสมอ !!!

   ---------------------------------------------------------------------------------
   สิ่งที่ v8 แก้จาก v7
   ---------------------------------------------------------------------------------
   ไม่มีตารางใหม่ ไม่มีตารางที่หายไป  v8 คือ v7 ที่ปิดช่องว่างระหว่างฐานข้อมูลกับ
   PenbunAPI ให้หมด  ทุกข้อด้านล่างมาจากสิ่งที่โค้ดฝั่ง Go ต้องเขียนเองเพราะ v7
   ไม่ได้ให้ไว้

   [1] View ครบทุก resource ที่ API อ่าน  (12 master + 6 เอกสาร = 18 View ใหม่)
       v7 มี View 12 ตัวแต่ครอบแค่บางส่วน  ที่เหลือ PenbunAPI ต้องฝัง
       SELECT ... FROM dbo.tb_... ไว้ใน Go ทั้ง 9 จุด ซึ่งกำกับไว้ด้วยคอมเมนต์
       TEMP: ทุกจุด  แปลว่านิยามของ Read Model อยู่นอกฐานข้อมูลและไม่มีใครเห็น
       ตอนแก้ schema  v8 ย้ายกลับมาไว้ที่เดียวกับตาราง

       master   vw_company            vw_customer_type      vw_vendor_type
                vw_discount_type      vw_product_category   vw_product_format_type
                vw_unit_type          vw_book_type          vw_warehouse
                vw_product_group      vw_discount           vw_route
       เอกสาร   vw_receive_note · vw_receive_item
                vw_return_note  · vw_return_item
                vw_vendor_return_note · vw_vendor_return_item

   [2] vw_customer_route คืนคอลัมน์ audit ครบ
       v7 เลือกมาแค่ 10 คอลัมน์ ไม่มี is_active / id_status / update_by /
       update_date / description  หน้าจอจึงไม่มีคอลัมน์สถานะและ API กรองไม่ได้
       ฝั่งเว็บต้องประกาศ audit:false ไว้เพื่อไม่ให้ถามหาสิ่งที่ View ไม่มี

   [3] vw_book คืน description และคอลัมน์ของสินค้าที่ POST /book รับอยู่แล้ว
       barcode / weight_kg / pack_qty  v7 รับค่าพวกนี้ตอนบันทึกแต่ไม่คืนตอนอ่าน
       ช่องเหล่านั้นจึงเปิดมาว่างทุกครั้งที่แก้ไขหนังสือ กลายเป็นการแก้แบบ
       ลบค่าทิ้งโดยที่ผู้ใช้ไม่รู้ตัว

   [4] doc_no กว้าง 30 -> 50 ทั้งสี่เอกสาร
       schema.Field ของ PenbunAPI ประกาศ MaxLen 50 มาตลอด  ค่าที่ยาว 31-50
       ตัวอักษรจึงผ่าน validation ทั้งฝั่งเว็บและ API แล้วไปตายตอน INSERT
       กลายเป็น 500 ทั้งที่ผู้ใช้กรอกถูกตามที่ระบบบอก  50 คือค่าที่สัญญาไว้แล้ว

   [5] tb_book.complimentary_qty  (อภินันท์)
       legacy 7.4 ใบชำระให้เจ้าของหนังสือ และ 7.5 ใบรับเงินล่วงหน้า อ่านจำนวน
       อภินันท์จากแฟ้มหนังสือทั้งคู่  v7 ไม่มีคอลัมน์ไหนเก็บค่านี้เลย

   [6] tb_users.ref_warehouse_auto  — ผู้ใช้สังกัดคลังไหน
       PenbunWeb พิมพ์ชื่อสาขาคงที่ไว้บนทุกหน้าจอเพราะไม่มีที่ให้อ่าน
       ใช้ tb_warehouse ที่มีอยู่แล้วแทนการสร้างตารางสาขาขึ้นมาใหม่ —
       สาขาในระบบนี้คือคลัง

   [7] posted_date ให้ใบรับคืนและใบส่งคืนคู่ค้า
       v7 ประทับเวลาโพสต์ไว้เฉพาะใบรับ (posted_date) และใบส่ง (delivered_date)
       อีกสองเอกสารไม่ได้บันทึกไว้เลย  จะรู้ว่าโพสต์เมื่อไรต้องเดาจาก update_date
       ซึ่งการแก้ไขครั้งถัดไปทับทิ้ง

   [8] USP_POST_* จองล็อกเอง
       v7 พึ่งให้ PenbunAPI จอง sp_getapplock ก่อนเรียก proc ทุกครั้ง  ใครที่
       รัน proc จาก SSMS หรือ job จึงข้ามการป้องกันทั้งหมดและทำให้สต็อกติดลบได้
       v8 ย้ายการจองล็อกเข้าไปใน proc  เจ้าของกฎจึงเป็นฐานข้อมูล
       การจองฝั่ง API ยังคงอยู่ — sp_getapplock ซ้ำ resource เดิมใน transaction
       เดียวกันเป็น no-op และการจองซ้อนคือสิ่งที่ทำให้เทสต์ concurrency ล้มดัง ๆ
       เมื่อมีใครเพิ่มเส้นทางใหม่แล้วลืมจอง

   ---------------------------------------------------------------------------------
   Convention ของ PenbunSQL ที่รักษาไว้ 100%
   ---------------------------------------------------------------------------------
     autoID / prefix / <table>_id / update_by / update_date / is_active / is_delete / id_status
     Business ID สร้างโดย TRIGGER เท่านั้น  รูปแบบ <PREFIX><SERIES A-Z><NNNNNN>
     Creation is First Update (ไม่มี create_by / create_date)
     Soft Delete ด้วย is_delete = 1
     SE Asia Standard Time ทุกจุด
     SET NOCOUNT ON + TRIGGER_NESTLEVEL() guard
   ===================================================================================== */

USE [PENBUN]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET XACT_ABORT ON
GO

/* =====================================================================================
   SECTION 1 : DROP ALL   (ลบ FK ทั้งหมดก่อน แล้วค่อยลบ object)
   ===================================================================================== */
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'ALTER TABLE [dbo].[' + OBJECT_NAME(parent_object_id)
            + N'] DROP CONSTRAINT [' + name + N'];' + CHAR(10)
  FROM sys.foreign_keys;
EXEC sp_executesql @sql;

SET @sql = N'';
SELECT @sql = @sql + N'DROP VIEW [dbo].[' + name + N'];' + CHAR(10)
  FROM sys.views WHERE name LIKE 'vw_%';
EXEC sp_executesql @sql;

SET @sql = N'';
SELECT @sql = @sql + N'DROP PROCEDURE [dbo].[' + name + N'];' + CHAR(10)
  FROM sys.procedures WHERE name LIKE 'USP[_]%';
EXEC sp_executesql @sql;

SET @sql = N'';
SELECT @sql = @sql + N'DROP TABLE [dbo].[' + name + N'];' + CHAR(10)
  FROM sys.tables WHERE name LIKE 'tb[_]%';
EXEC sp_executesql @sql;
GO

/* =====================================================================================
   SECTION 2 : ID GENERATION
   ===================================================================================== */

/* USP_ALLOCATE_BUSINESS_ID_BLOCK — จองเลขรันนิ่งเป็นบล็อก
   v5 ใช้ CURSOR ยิงทีละแถว : ใบส่ง 500 บรรทัด = แตะ tb_reference 500 ครั้ง
   v7 แตะครั้งเดียวต่อ statement
   สัญญาข้อมูล : ref_id = ชื่อตาราง, ref_int = เลขล่าสุด, ref_text = Series (A-Z) */
CREATE PROCEDURE [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
    @TableName NVARCHAR(100),
    @BlockSize INT,
    @StartNo   INT         OUTPUT,
    @Series    NVARCHAR(1) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @BlockSize IS NULL OR @BlockSize < 1 SET @BlockSize = 1;

    DECLARE @cur INT;

    IF NOT EXISTS (SELECT 1 FROM dbo.tb_reference WITH (UPDLOCK, HOLDLOCK) WHERE ref_id = @TableName)
        INSERT INTO dbo.tb_reference (ref_id, ref_int, ref_text, prefix, update_by)
        VALUES (@TableName, 0, N'A', N'REF', N'System');

    -- UPDLOCK + HOLDLOCK : serialize เฉพาะแถวของตารางนี้
    SELECT @cur = ref_int, @Series = ISNULL(ref_text, N'A')
      FROM dbo.tb_reference WITH (UPDLOCK, HOLDLOCK)
     WHERE ref_id = @TableName;

    IF @cur + @BlockSize > 999999
    BEGIN
        IF @Series >= N'Z'
        BEGIN
            RAISERROR (N'ALLOCATE_ID: Series หมดที่ Z สำหรับตาราง %s', 16, 1, @TableName);
            RETURN;
        END
        SET @Series = NCHAR(UNICODE(@Series) + 1);
        SET @cur = 0;
    END

    UPDATE dbo.tb_reference
       SET ref_int = @cur + @BlockSize, ref_text = @Series, update_by = N'System'
     WHERE ref_id = @TableName;

    SET @StartNo = @cur + 1;
END
GO

/* USP_GENERATE_BUSINESS_ID — เก็บไว้เพื่อความเข้ากันได้กับโค้ด/สคริปต์เดิม */
CREATE PROCEDURE [dbo].[USP_GENERATE_BUSINESS_ID]
    @TableName NVARCHAR(100),
    @Prefix    NVARCHAR(3),
    @AutoID    INT,
    @OutputID  NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @s INT, @sr NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = @TableName, @BlockSize = 1, @StartNo = @s OUTPUT, @Series = @sr OUTPUT;
    SET @OutputID = @Prefix + @sr + RIGHT(N'000000' + CAST(@s AS NVARCHAR(10)), 6);
END
GO

/* =====================================================================================
   SECTION 3 : CREATE TABLES  (32 ตาราง เรียงตาม dependency)
   ===================================================================================== */

/* ═══════════ Layer 0 : System ═══════════ */
/****** [dbo].[tb_reference]  --  ตารางเลขรันนิ่งของ Business ID (PK = ref_id) ******/
CREATE TABLE [dbo].[tb_reference](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[ref_id] [varchar](50) NOT NULL,
	[ref_int] [int] NULL,
	[ref_text] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_reference] PRIMARY KEY CLUSTERED ([ref_id] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_users]  --  ผู้ใช้งานระบบ ******/
CREATE TABLE [dbo].[tb_users](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[user_id] [nvarchar](50) NULL,
	[user_name] [nvarchar](50) NOT NULL,
	[user_password] [nvarchar](255) NOT NULL,
	[user_level] [nvarchar](50) NOT NULL,
	[ref_warehouse_auto] [int] NULL,
	[full_name] [nvarchar](150) NULL,
	[email] [nvarchar](100) NULL,
	[counting_password_fail] [int] NOT NULL,
	[status_user_locked] [bit] NOT NULL,
	[status_change_pw] [bit] NOT NULL,
	[last_login_date] [datetime] NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_users] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 1 : Lookup / Master ชั้นต้น ═══════════ */
/****** [dbo].[tb_company]  --  นิติบุคคล / บริษัทในเครือ ******/
CREATE TABLE [dbo].[tb_company](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[company_id] [nvarchar](50) NULL,
	[company_code] [nvarchar](20) NOT NULL,
	[name_th] [nvarchar](200) NOT NULL,
	[name_en] [nvarchar](200) NULL,
	[description] [nvarchar](255) NULL,
	[tax_id] [nvarchar](20) NULL,
	[branch_code] [nvarchar](10) NULL,
	[contact_person] [nvarchar](100) NULL,
	[phone] [nvarchar](50) NULL,
	[mobile] [nvarchar](50) NULL,
	[fax] [nvarchar](50) NULL,
	[email] [nvarchar](100) NULL,
	[website] [nvarchar](100) NULL,
	[line_id] [nvarchar](50) NULL,
	[address] [nvarchar](max) NULL,
	[sub_district] [nvarchar](100) NULL,
	[district] [nvarchar](100) NULL,
	[province] [nvarchar](100) NULL,
	[zip_code] [nvarchar](20) NULL,
	[logo_url] [nvarchar](max) NULL,
	[vat_rate] [decimal](10, 2) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_company] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_customer_type]  --  ประเภทลูกค้า ******/
CREATE TABLE [dbo].[tb_customer_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_type_id] [nvarchar](50) NULL,
	[type_name] [nvarchar](255) NOT NULL,
	[description] [nvarchar](1000) NULL,
	[base_credit_day] [int] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_customer_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_vendor_type]  --  ประเภทคู่ค้า ******/
CREATE TABLE [dbo].[tb_vendor_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_type_id] [nvarchar](50) NULL,
	[type_name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_discount_type]  --  ประเภทส่วนลด ******/
CREATE TABLE [dbo].[tb_discount_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[discount_type_id] [nvarchar](50) NULL,
	[discount_type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_discount_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_product_category]  --  หมวดสินค้า (ชั้นบนสุด) ******/
CREATE TABLE [dbo].[tb_product_category](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_category_id] [nvarchar](50) NULL,
	[category_name] [nvarchar](100) NOT NULL,
	[category_code] [nvarchar](20) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_category] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_product_format_type]  --  รูปแบบสินค้า (ปกอ่อน/ปกแข็ง/ฯลฯ) ******/
CREATE TABLE [dbo].[tb_product_format_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_format_type_id] [nvarchar](50) NULL,
	[format_name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](250) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_format_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_unit_type]  --  หน่วยนับ ******/
CREATE TABLE [dbo].[tb_unit_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[unit_type_id] [nvarchar](50) NULL,
	[unit_type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_unit_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_book_type]  --  ประเภทหนังสือ (legacy: Bookcatgid) ******/
CREATE TABLE [dbo].[tb_book_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[book_type_id] [nvarchar](50) NULL,
	[type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_book_type] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 2 : Master ชั้นสอง ═══════════ */
/****** [dbo].[tb_product_group]  --  กลุ่มสินค้า (ชั้นกลาง) ******/
CREATE TABLE [dbo].[tb_product_group](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_group_id] [nvarchar](50) NULL,
	[ref_product_category_auto] [int] NOT NULL,
	[product_group_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_group] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_warehouse]  --  คลังสินค้า ******/
CREATE TABLE [dbo].[tb_warehouse](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[warehouse_id] [nvarchar](50) NULL,
	[ref_company_auto] [int] NULL,
	[warehouse_code] [nvarchar](20) NOT NULL,
	[warehouse_name] [nvarchar](150) NOT NULL,
	[warehouse_type] [nvarchar](20) NOT NULL,
	[is_main_dc] [bit] NOT NULL,
	[allow_negative_stock] [bit] NOT NULL,
	[address] [nvarchar](max) NULL,
	[province] [nvarchar](100) NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_warehouse] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 3 : Partner ═══════════ */
/****** [dbo].[tb_vendor]  --  คู่ค้า / เจ้าของหนังสือ / ผู้ให้บริการ ******/
CREATE TABLE [dbo].[tb_vendor](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_id] [nvarchar](50) NULL,
	[ref_vendor_type_auto] [int] NOT NULL,
	[vendor_name] [nvarchar](150) NOT NULL,
	[tax_id] [nvarchar](20) NULL,
	[branch_code] [nvarchar](10) NULL,
	[branch_name] [nvarchar](50) NULL,
	[contact_person] [nvarchar](100) NULL,
	[phone1] [nvarchar](50) NULL,
	[phone2] [nvarchar](50) NULL,
	[email] [nvarchar](100) NULL,
	[website] [nvarchar](100) NULL,
	[address] [nvarchar](max) NULL,
	[sub_district] [nvarchar](100) NULL,
	[district] [nvarchar](100) NULL,
	[province] [nvarchar](100) NULL,
	[zip_code] [nvarchar](20) NULL,
	[credit_term_day] [int] NULL,
	[currency] [nvarchar](10) NULL,
	[trade_type] [nvarchar](20) NOT NULL,
	[consign_share_percent] [decimal](5, 2) NULL,
	[settlement_cycle] [nvarchar](20) NULL,
	[settlement_day] [int] NULL,
	[return_window_day] [int] NULL,
	[withholding_tax_percent] [decimal](5, 2) NULL,
	[bank_name] [nvarchar](100) NULL,
	[bank_branch] [nvarchar](100) NULL,
	[bank_account_no] [nvarchar](30) NULL,
	[bank_account_name] [nvarchar](150) NULL,
	[note] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_customer]  --  ลูกค้า / ร้านหนังสือ ******/
CREATE TABLE [dbo].[tb_customer](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_id] [nvarchar](50) NULL,
	[ref_customer_type_auto] [int] NOT NULL,
	[customer_code] [nvarchar](20) NULL,
	[customer_name] [nvarchar](200) NOT NULL,
	[report_name] [nvarchar](200) NULL,
	[tax_id] [nvarchar](20) NULL,
	[branch_code] [nvarchar](10) NULL,
	[branch_name] [nvarchar](50) NULL,
	[contact_person] [nvarchar](100) NULL,
	[phone1] [nvarchar](50) NULL,
	[phone2] [nvarchar](50) NULL,
	[email] [nvarchar](100) NULL,
	[line_id] [nvarchar](50) NULL,
	[address] [nvarchar](max) NULL,
	[sub_district] [nvarchar](100) NULL,
	[district] [nvarchar](100) NULL,
	[province] [nvarchar](100) NULL,
	[zip_code] [nvarchar](20) NULL,
	[credit_limit] [decimal](18, 2) NULL,
	[credit_term_day] [int] NULL,
	[is_vat] [bit] NOT NULL,
	[invoice_format] [nvarchar](20) NULL,
	[discount_group] [nvarchar](20) NULL,
	[note] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_customer] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_discount]  --  แคมเปญส่วนลด ******/
CREATE TABLE [dbo].[tb_discount](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[discount_id] [nvarchar](50) NULL,
	[ref_discount_type_auto] [int] NOT NULL,
	[discount_name] [nvarchar](150) NOT NULL,
	[discount_code] [nvarchar](20) NULL,
	[discount_value] [decimal](18, 4) NOT NULL,
	[is_percent] [bit] NOT NULL,
	[min_order_amount] [decimal](18, 4) NULL,
	[start_date] [datetime] NULL,
	[end_date] [datetime] NULL,
	[description] [nvarchar](500) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_discount] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 4 : Product (Hybrid Core) ═══════════ */
/****** [dbo].[tb_product]  --  สินค้า/บริการ (Hybrid Core — count_stock แยกของนับสต็อกกับไม่นับ) ******/
CREATE TABLE [dbo].[tb_product](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_id] [nvarchar](50) NULL,
	[ref_product_group_auto] [int] NOT NULL,
	[ref_product_format_type_auto] [int] NULL,
	[ref_unit_type_auto] [int] NULL,
	[ref_vendor_auto] [int] NULL,
	[product_code] [nvarchar](50) NOT NULL,
	[product_name] [nvarchar](255) NOT NULL,
	[count_stock] [bit] NOT NULL,
	[cost_price] [decimal](18, 4) NULL,
	[sell_price] [decimal](18, 4) NULL,
	[barcode] [nvarchar](50) NULL,
	[weight_kg] [decimal](10, 2) NULL,
	[pack_qty] [int] NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 5 : SKU / Book ═══════════ */
/****** [dbo].[tb_product_sku]  --  SKU / ฉบับ (legacy: เมนู Product = เพิ่มฉบับ) ******/
CREATE TABLE [dbo].[tb_product_sku](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[sku_id] [nvarchar](50) NULL,
	[ref_product_auto] [int] NOT NULL,
	[sku_code] [nvarchar](50) NOT NULL,
	[barcode] [nvarchar](50) NULL,
	[vendor_part_no] [nvarchar](50) NULL,
	[variation_name] [nvarchar](100) NULL,
	[issue_no] [nvarchar](50) NULL,
	[volume_no] [nvarchar](50) NULL,
	[edition_label] [nvarchar](50) NULL,
	[cost_price] [decimal](18, 4) NOT NULL,
	[sell_price] [decimal](18, 4) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[pack_qty] [int] NULL,
	[publication_date] [date] NULL,
	[return_deadline] [date] NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_sku] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_book]  --  ข้อมูลเฉพาะหนังสือ — extension 1:1 ของ tb_product (แก้ปัญหา tb_book ลอยใน v5) ******/
CREATE TABLE [dbo].[tb_book](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[book_id] [nvarchar](50) NULL,
	[ref_product_auto] [int] NOT NULL,
	[ref_book_type_auto] [int] NULL,
	[book_name] [nvarchar](255) NOT NULL,
	[author] [nvarchar](255) NULL,
	[isbn] [nvarchar](20) NULL,
	[publisher_name] [nvarchar](200) NULL,
	[page_count] [int] NULL,
	[cover_price] [decimal](18, 4) NULL,
	[net_price] [decimal](18, 4) NULL,
	[vendor_discount_percent] [decimal](5, 2) NULL,
	[customer_discount_percent] [decimal](5, 2) NULL,
	[complimentary_qty] [int] NOT NULL,
	[effective_date] [date] NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_book] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 6 : Route ═══════════ */
/****** [dbo].[tb_route]  --  สายจัดจำหน่าย / เส้นทางส่ง ******/
CREATE TABLE [dbo].[tb_route](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[route_id] [nvarchar](50) NULL,
	[ref_warehouse_auto] [int] NULL,
	[route_code] [nvarchar](20) NOT NULL,
	[route_name] [nvarchar](150) NOT NULL,
	[route_type] [nvarchar](20) NOT NULL,
	[region_name] [nvarchar](50) NULL,
	[sort_order] [int] NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_route] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_customer_route]  --  ผูกลูกค้ากับสาย (M:N) + ลำดับจุดจอด ******/
CREATE TABLE [dbo].[tb_customer_route](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_route_id] [nvarchar](50) NULL,
	[ref_customer_auto] [int] NOT NULL,
	[ref_route_auto] [int] NOT NULL,
	[is_primary] [bit] NOT NULL,
	[delivery_seq] [int] NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_customer_route] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 7 : Stock Ledger + Cache ═══════════ */
/****** [dbo].[tb_stock_movement]  --  สมุดรายวันสต็อก (LEDGER) — แหล่งความจริงเดียวของทุกการเคลื่อนไหว ******/
CREATE TABLE [dbo].[tb_stock_movement](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[stock_movement_id] [nvarchar](50) NULL,
	[ref_sku_auto] [int] NOT NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[ref_customer_auto] [int] NULL,
	[ref_vendor_auto] [int] NULL,
	[movement_date] [datetime] NOT NULL,
	[movement_type] [nvarchar](20) NOT NULL,
	[qty_change] [decimal](18, 2) NOT NULL,
	[unit_cost] [decimal](18, 4) NULL,
	[doc_table] [nvarchar](50) NULL,
	[doc_auto] [int] NULL,
	[doc_no] [nvarchar](30) NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_stock_movement] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_product_stock]  --  ยอดคงเหลือ ต่อ SKU x คลัง (CACHE ของ tb_stock_movement) ******/
CREATE TABLE [dbo].[tb_product_stock](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[stock_id] [nvarchar](50) NULL,
	[ref_sku_auto] [int] NOT NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[qty_onhand] [decimal](18, 2) NOT NULL,
	[qty_reserved] [decimal](18, 2) NOT NULL,
	[last_movement_date] [datetime] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_available]  AS ([qty_onhand]-[qty_reserved]) PERSISTED,
 CONSTRAINT [PK_tb_product_stock] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_consign_balance]  --  ยอดฝากขายคงค้างที่ร้าน ต่อ ลูกค้า x SKU (CACHE) ******/
CREATE TABLE [dbo].[tb_consign_balance](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[consign_balance_id] [nvarchar](50) NULL,
	[ref_customer_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[qty_delivered] [decimal](18, 2) NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[last_order_date] [datetime] NULL,
	[last_return_date] [datetime] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_outstanding]  AS ([qty_delivered]-[qty_returned]) PERSISTED,
 CONSTRAINT [PK_tb_consign_balance] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 8 : Transaction Documents ═══════════ */
/****** [dbo].[tb_receive_note]  --  ใบรับหนังสือเข้าคลัง (Header) ******/
CREATE TABLE [dbo].[tb_receive_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[receive_note_id] [nvarchar](50) NULL,
	[ref_vendor_auto] [int] NOT NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[ref_company_auto] [int] NULL,
	[doc_no] [nvarchar](50) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[vendor_doc_no] [nvarchar](50) NULL,
	[trade_type] [nvarchar](20) NOT NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[posted_date] [datetime] NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_receive_note] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_receive_item]  --  รายการในใบรับหนังสือ ******/
CREATE TABLE [dbo].[tb_receive_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[receive_item_id] [nvarchar](50) NULL,
	[ref_receive_note_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[line_no] [int] NOT NULL,
	[qty] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_cost] [decimal](18, 4) NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty]*[unit_cost]) PERSISTED,
 CONSTRAINT [PK_tb_receive_item] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_order]  --  ใบส่งหนังสือ (Header) ******/
CREATE TABLE [dbo].[tb_order](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[order_id] [nvarchar](50) NULL,
	[ref_customer_auto] [int] NOT NULL,
	[ref_route_auto] [int] NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[ref_company_auto] [int] NULL,
	[doc_no] [nvarchar](50) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[order_type] [nvarchar](20) NOT NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[period_key] [nvarchar](20) NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[discount_amount] [decimal](18, 4) NOT NULL,
	[invoice_no] [nvarchar](30) NULL,
	[invoice_date] [datetime] NULL,
	[delivered_date] [datetime] NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[net_amount]  AS ([total_amount]-[discount_amount]) PERSISTED,
 CONSTRAINT [PK_tb_order] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_order_item]  --  รายการในใบส่งหนังสือ ******/
CREATE TABLE [dbo].[tb_order_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[order_item_id] [nvarchar](50) NULL,
	[ref_order_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[line_no] [int] NOT NULL,
	[qty_ordered] [decimal](18, 2) NOT NULL,
	[qty_delivered] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_price] [decimal](18, 4) NOT NULL,
	[discount_percent] [decimal](5, 2) NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty_delivered]*[unit_price]) PERSISTED,
 CONSTRAINT [PK_tb_order_item] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_return_note]  --  ใบรับคืนหนังสือจากร้าน ******/
CREATE TABLE [dbo].[tb_return_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[return_note_id] [nvarchar](50) NULL,
	[ref_customer_auto] [int] NOT NULL,
	[ref_route_auto] [int] NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[ref_order_auto] [int] NULL,
	[doc_no] [nvarchar](50) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[period_key] [nvarchar](20) NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[posted_date] [datetime] NULL,
	[credit_note_no] [nvarchar](30) NULL,
	[credit_note_date] [datetime] NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_return_note] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_return_item]  --  รายการในใบรับคืนจากร้าน ******/
CREATE TABLE [dbo].[tb_return_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[return_item_id] [nvarchar](50) NULL,
	[ref_return_note_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[line_no] [int] NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_price] [decimal](18, 4) NOT NULL,
	[condition_status] [nvarchar](20) NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty_returned]*[unit_price]) PERSISTED,
 CONSTRAINT [PK_tb_return_item] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_vendor_return_note]  --  ใบส่งคืนหนังสือให้เจ้าของหนังสือ ******/
CREATE TABLE [dbo].[tb_vendor_return_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_return_note_id] [nvarchar](50) NULL,
	[ref_vendor_auto] [int] NOT NULL,
	[ref_warehouse_auto] [int] NOT NULL,
	[ref_company_auto] [int] NULL,
	[doc_no] [nvarchar](50) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[posted_date] [datetime] NULL,
	[settlement_no] [nvarchar](30) NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor_return_note] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** [dbo].[tb_vendor_return_item]  --  รายการในใบส่งคืนเจ้าของหนังสือ ******/
CREATE TABLE [dbo].[tb_vendor_return_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_return_item_id] [nvarchar](50) NULL,
	[ref_vendor_return_note_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[line_no] [int] NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_cost] [decimal](18, 4) NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty_returned]*[unit_cost]) PERSISTED,
 CONSTRAINT [PK_tb_vendor_return_item] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* ═══════════ Layer 9 : Allocation History ═══════════ */
/****** [dbo].[tb_allocation_history]  --  ประวัติยอดส่ง/คืน ต่องวด — ต้นทางของ 'ดึงจากประวัติ' ******/
CREATE TABLE [dbo].[tb_allocation_history](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[allocation_history_id] [nvarchar](50) NULL,
	[ref_customer_auto] [int] NOT NULL,
	[ref_sku_auto] [int] NOT NULL,
	[ref_route_auto] [int] NULL,
	[ref_order_auto] [int] NULL,
	[period_key] [nvarchar](20) NOT NULL,
	[period_seq] [int] NULL,
	[issue_label] [nvarchar](50) NULL,
	[qty_allocated] [decimal](18, 2) NOT NULL,
	[qty_delivered] [decimal](18, 2) NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[is_locked] [bit] NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_sold]  AS ([qty_delivered]-[qty_returned]) PERSISTED,
	[sell_through_pct]  AS (case when [qty_delivered]>(0) then CONVERT([decimal](5,2),(([qty_delivered]-[qty_returned])*(100.0))/[qty_delivered]) else (0) end) PERSISTED,
 CONSTRAINT [PK_tb_allocation_history] PRIMARY KEY CLUSTERED ([autoID] ASC)
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/* =====================================================================================
   SECTION 4 : DEFAULT CONSTRAINTS
   ===================================================================================== */

ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_prefix] DEFAULT (N'REF') FOR [prefix];
ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_reference] ADD CONSTRAINT [DF_tb_reference_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_prefix] DEFAULT (N'USR') FOR [prefix];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_user_level] DEFAULT (N'USER') FOR [user_level];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_counting_password_fail] DEFAULT (0) FOR [counting_password_fail];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_status_user_locked] DEFAULT (0) FOR [status_user_locked];
ALTER TABLE [dbo].[tb_users] ADD CONSTRAINT [DF_tb_users_status_change_pw] DEFAULT (1) FOR [status_change_pw];
GO

ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_prefix] DEFAULT (N'CPN') FOR [prefix];
ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_company] ADD CONSTRAINT [DF_tb_company_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_prefix] DEFAULT (N'CUT') FOR [prefix];
ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_customer_type] ADD CONSTRAINT [DF_tb_customer_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_prefix] DEFAULT (N'VET') FOR [prefix];
ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_vendor_type] ADD CONSTRAINT [DF_tb_vendor_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_prefix] DEFAULT (N'DCT') FOR [prefix];
ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_discount_type] ADD CONSTRAINT [DF_tb_discount_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_prefix] DEFAULT (N'PCT') FOR [prefix];
ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product_category] ADD CONSTRAINT [DF_tb_product_category_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_prefix] DEFAULT (N'PFM') FOR [prefix];
ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product_format_type] ADD CONSTRAINT [DF_tb_product_format_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_prefix] DEFAULT (N'UNT') FOR [prefix];
ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_unit_type] ADD CONSTRAINT [DF_tb_unit_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_prefix] DEFAULT (N'BKT') FOR [prefix];
ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_book_type] ADD CONSTRAINT [DF_tb_book_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_prefix] DEFAULT (N'PGT') FOR [prefix];
ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product_group] ADD CONSTRAINT [DF_tb_product_group_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_prefix] DEFAULT (N'WHS') FOR [prefix];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_warehouse_type] DEFAULT (N'BRANCH') FOR [warehouse_type];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_is_main_dc] DEFAULT (0) FOR [is_main_dc];
ALTER TABLE [dbo].[tb_warehouse] ADD CONSTRAINT [DF_tb_warehouse_allow_negative_stock] DEFAULT (0) FOR [allow_negative_stock];
GO

ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_prefix] DEFAULT (N'VEN') FOR [prefix];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_currency] DEFAULT (N'THB') FOR [currency];
ALTER TABLE [dbo].[tb_vendor] ADD CONSTRAINT [DF_tb_vendor_trade_type] DEFAULT (N'CONSIGN') FOR [trade_type];
GO

ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_prefix] DEFAULT (N'CUS') FOR [prefix];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_customer] ADD CONSTRAINT [DF_tb_customer_is_vat] DEFAULT (0) FOR [is_vat];
GO

ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_prefix] DEFAULT (N'DSC') FOR [prefix];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_discount_value] DEFAULT (0) FOR [discount_value];
ALTER TABLE [dbo].[tb_discount] ADD CONSTRAINT [DF_tb_discount_is_percent] DEFAULT (0) FOR [is_percent];
GO

ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_prefix] DEFAULT (N'PDT') FOR [prefix];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_count_stock] DEFAULT (1) FOR [count_stock];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_cost_price] DEFAULT (0) FOR [cost_price];
ALTER TABLE [dbo].[tb_product] ADD CONSTRAINT [DF_tb_product_sell_price] DEFAULT (0) FOR [sell_price];
GO

ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_prefix] DEFAULT (N'SKU') FOR [prefix];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_cost_price] DEFAULT (0) FOR [cost_price];
ALTER TABLE [dbo].[tb_product_sku] ADD CONSTRAINT [DF_tb_product_sku_sell_price] DEFAULT (0) FOR [sell_price];
GO

ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_prefix] DEFAULT (N'BOK') FOR [prefix];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_book] ADD CONSTRAINT [DF_tb_book_complimentary_qty] DEFAULT (0) FOR [complimentary_qty];
GO

ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_prefix] DEFAULT (N'RTE') FOR [prefix];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_route_type] DEFAULT (N'REGION') FOR [route_type];
GO

ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_prefix] DEFAULT (N'CRT') FOR [prefix];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_primary] DEFAULT (0) FOR [is_primary];
GO

ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_prefix] DEFAULT (N'STM') FOR [prefix];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_movement_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [movement_date];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_qty_change] DEFAULT (0) FOR [qty_change];
ALTER TABLE [dbo].[tb_stock_movement] ADD CONSTRAINT [DF_tb_stock_movement_unit_cost] DEFAULT (0) FOR [unit_cost];
GO

ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_prefix] DEFAULT (N'STK') FOR [prefix];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_qty_onhand] DEFAULT (0) FOR [qty_onhand];
ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_qty_reserved] DEFAULT (0) FOR [qty_reserved];
GO

ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_prefix] DEFAULT (N'CSB') FOR [prefix];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_qty_delivered] DEFAULT (0) FOR [qty_delivered];
ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_qty_returned] DEFAULT (0) FOR [qty_returned];
GO

ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_prefix] DEFAULT (N'RCV') FOR [prefix];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_trade_type] DEFAULT (N'CONSIGN') FOR [trade_type];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_total_qty] DEFAULT (0) FOR [total_qty];
ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_prefix] DEFAULT (N'RCI') FOR [prefix];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_qty] DEFAULT (0) FOR [qty];
ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_unit_cost] DEFAULT (0) FOR [unit_cost];
GO

ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_prefix] DEFAULT (N'ORD') FOR [prefix];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_order_type] DEFAULT (N'CONSIGN') FOR [order_type];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_total_qty] DEFAULT (0) FOR [total_qty];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_total_amount] DEFAULT (0) FOR [total_amount];
ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_discount_amount] DEFAULT (0) FOR [discount_amount];
GO

ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_prefix] DEFAULT (N'ODI') FOR [prefix];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_qty_ordered] DEFAULT (0) FOR [qty_ordered];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_qty_delivered] DEFAULT (0) FOR [qty_delivered];
ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_unit_price] DEFAULT (0) FOR [unit_price];
GO

ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_prefix] DEFAULT (N'RTN') FOR [prefix];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_total_qty] DEFAULT (0) FOR [total_qty];
ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_prefix] DEFAULT (N'RTI') FOR [prefix];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_qty_returned] DEFAULT (0) FOR [qty_returned];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_unit_price] DEFAULT (0) FOR [unit_price];
ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_condition_status] DEFAULT (N'GOOD') FOR [condition_status];
GO

ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_prefix] DEFAULT (N'VRN') FOR [prefix];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_total_qty] DEFAULT (0) FOR [total_qty];
ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_prefix] DEFAULT (N'VRI') FOR [prefix];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_qty_returned] DEFAULT (0) FOR [qty_returned];
ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_unit_cost] DEFAULT (0) FOR [unit_cost];
GO

ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_prefix] DEFAULT (N'AHS') FOR [prefix];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_update_by] DEFAULT (N'System') FOR [update_by];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_active] DEFAULT (1) FOR [is_active];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_delete] DEFAULT (0) FOR [is_delete];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_allocated] DEFAULT (0) FOR [qty_allocated];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_delivered] DEFAULT (0) FOR [qty_delivered];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_returned] DEFAULT (0) FOR [qty_returned];
ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_locked] DEFAULT (0) FOR [is_locked];
GO

/* =====================================================================================
   SECTION 5 : CHECK CONSTRAINTS
   ===================================================================================== */

ALTER TABLE [dbo].[tb_warehouse] WITH CHECK ADD CONSTRAINT [CK_tb_warehouse_type] CHECK ([warehouse_type] IN (N'DC', N'BRANCH', N'RETURN', N'DAMAGED', N'PROVINCE', N'INTERNATIONAL'));
ALTER TABLE [dbo].[tb_vendor] WITH CHECK ADD CONSTRAINT [CK_tb_vendor_trade_type] CHECK ([trade_type] IN (N'BUY', N'CONSIGN'));
ALTER TABLE [dbo].[tb_route] WITH CHECK ADD CONSTRAINT [CK_tb_route_type] CHECK ([route_type] IN (N'LEGACY_LINE', N'REGION', N'DAILY'));
ALTER TABLE [dbo].[tb_stock_movement] WITH CHECK ADD CONSTRAINT [CK_tb_stock_movement_type] CHECK ([movement_type] IN (N'RECEIVE', N'ISSUE', N'RETURN_IN', N'RETURN_OUT', N'TRANSFER_IN', N'TRANSFER_OUT', N'ADJUST'));
ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [CK_tb_receive_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'CANCELLED'));
ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [CK_tb_receive_note_trade] CHECK ([trade_type] IN (N'BUY', N'CONSIGN'));
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [CK_tb_order_type] CHECK ([order_type] IN (N'CONSIGN', N'SALE', N'TRANSFER'));
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [CK_tb_order_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'DELIVERED', N'INVOICED', N'CANCELLED'));
ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [CK_tb_return_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'CREDITED', N'CANCELLED'));
ALTER TABLE [dbo].[tb_return_item] WITH CHECK ADD CONSTRAINT [CK_tb_return_item_condition] CHECK ([condition_status] IN (N'GOOD', N'DAMAGED'));
ALTER TABLE [dbo].[tb_vendor_return_note] WITH CHECK ADD CONSTRAINT [CK_tb_vendor_return_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'SETTLED', N'CANCELLED'));
GO

/* =====================================================================================
   SECTION 6 : FOREIGN KEYS   (ON DELETE NO ACTION โดยตั้งใจ = บังคับ Soft Delete)
   ===================================================================================== */

ALTER TABLE [dbo].[tb_product_group] WITH CHECK ADD CONSTRAINT [FK_tb_product_group_ref_product_category_auto]
    FOREIGN KEY([ref_product_category_auto]) REFERENCES [dbo].[tb_product_category] ([autoID]);
ALTER TABLE [dbo].[tb_warehouse] WITH CHECK ADD CONSTRAINT [FK_tb_warehouse_ref_company_auto]
    FOREIGN KEY([ref_company_auto]) REFERENCES [dbo].[tb_company] ([autoID]);
ALTER TABLE [dbo].[tb_vendor] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_ref_vendor_type_auto]
    FOREIGN KEY([ref_vendor_type_auto]) REFERENCES [dbo].[tb_vendor_type] ([autoID]);
ALTER TABLE [dbo].[tb_customer] WITH CHECK ADD CONSTRAINT [FK_tb_customer_ref_customer_type_auto]
    FOREIGN KEY([ref_customer_type_auto]) REFERENCES [dbo].[tb_customer_type] ([autoID]);
ALTER TABLE [dbo].[tb_discount] WITH CHECK ADD CONSTRAINT [FK_tb_discount_ref_discount_type_auto]
    FOREIGN KEY([ref_discount_type_auto]) REFERENCES [dbo].[tb_discount_type] ([autoID]);
ALTER TABLE [dbo].[tb_product] WITH CHECK ADD CONSTRAINT [FK_tb_product_ref_product_group_auto]
    FOREIGN KEY([ref_product_group_auto]) REFERENCES [dbo].[tb_product_group] ([autoID]);
ALTER TABLE [dbo].[tb_product] WITH CHECK ADD CONSTRAINT [FK_tb_product_ref_product_format_type_auto]
    FOREIGN KEY([ref_product_format_type_auto]) REFERENCES [dbo].[tb_product_format_type] ([autoID]);
ALTER TABLE [dbo].[tb_product] WITH CHECK ADD CONSTRAINT [FK_tb_product_ref_unit_type_auto]
    FOREIGN KEY([ref_unit_type_auto]) REFERENCES [dbo].[tb_unit_type] ([autoID]);
ALTER TABLE [dbo].[tb_product] WITH CHECK ADD CONSTRAINT [FK_tb_product_ref_vendor_auto]
    FOREIGN KEY([ref_vendor_auto]) REFERENCES [dbo].[tb_vendor] ([autoID]);
ALTER TABLE [dbo].[tb_product_sku] WITH CHECK ADD CONSTRAINT [FK_tb_product_sku_ref_product_auto]
    FOREIGN KEY([ref_product_auto]) REFERENCES [dbo].[tb_product] ([autoID]);
ALTER TABLE [dbo].[tb_book] WITH CHECK ADD CONSTRAINT [FK_tb_book_ref_product_auto]
    FOREIGN KEY([ref_product_auto]) REFERENCES [dbo].[tb_product] ([autoID]);
ALTER TABLE [dbo].[tb_book] WITH CHECK ADD CONSTRAINT [FK_tb_book_ref_book_type_auto]
    FOREIGN KEY([ref_book_type_auto]) REFERENCES [dbo].[tb_book_type] ([autoID]);
ALTER TABLE [dbo].[tb_route] WITH CHECK ADD CONSTRAINT [FK_tb_route_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_customer_route] WITH CHECK ADD CONSTRAINT [FK_tb_customer_route_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_customer_route] WITH CHECK ADD CONSTRAINT [FK_tb_customer_route_ref_route_auto]
    FOREIGN KEY([ref_route_auto]) REFERENCES [dbo].[tb_route] ([autoID]);
ALTER TABLE [dbo].[tb_stock_movement] WITH CHECK ADD CONSTRAINT [FK_tb_stock_movement_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_stock_movement] WITH CHECK ADD CONSTRAINT [FK_tb_stock_movement_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_stock_movement] WITH CHECK ADD CONSTRAINT [FK_tb_stock_movement_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_stock_movement] WITH CHECK ADD CONSTRAINT [FK_tb_stock_movement_ref_vendor_auto]
    FOREIGN KEY([ref_vendor_auto]) REFERENCES [dbo].[tb_vendor] ([autoID]);
ALTER TABLE [dbo].[tb_product_stock] WITH CHECK ADD CONSTRAINT [FK_tb_product_stock_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_product_stock] WITH CHECK ADD CONSTRAINT [FK_tb_product_stock_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_consign_balance] WITH CHECK ADD CONSTRAINT [FK_tb_consign_balance_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_consign_balance] WITH CHECK ADD CONSTRAINT [FK_tb_consign_balance_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [FK_tb_receive_note_ref_vendor_auto]
    FOREIGN KEY([ref_vendor_auto]) REFERENCES [dbo].[tb_vendor] ([autoID]);
ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [FK_tb_receive_note_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [FK_tb_receive_note_ref_company_auto]
    FOREIGN KEY([ref_company_auto]) REFERENCES [dbo].[tb_company] ([autoID]);
ALTER TABLE [dbo].[tb_receive_item] WITH CHECK ADD CONSTRAINT [FK_tb_receive_item_ref_receive_note_auto]
    FOREIGN KEY([ref_receive_note_auto]) REFERENCES [dbo].[tb_receive_note] ([autoID]);
ALTER TABLE [dbo].[tb_receive_item] WITH CHECK ADD CONSTRAINT [FK_tb_receive_item_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [FK_tb_order_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [FK_tb_order_ref_route_auto]
    FOREIGN KEY([ref_route_auto]) REFERENCES [dbo].[tb_route] ([autoID]);
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [FK_tb_order_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [FK_tb_order_ref_company_auto]
    FOREIGN KEY([ref_company_auto]) REFERENCES [dbo].[tb_company] ([autoID]);
ALTER TABLE [dbo].[tb_order_item] WITH CHECK ADD CONSTRAINT [FK_tb_order_item_ref_order_auto]
    FOREIGN KEY([ref_order_auto]) REFERENCES [dbo].[tb_order] ([autoID]);
ALTER TABLE [dbo].[tb_order_item] WITH CHECK ADD CONSTRAINT [FK_tb_order_item_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_return_note_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_return_note_ref_route_auto]
    FOREIGN KEY([ref_route_auto]) REFERENCES [dbo].[tb_route] ([autoID]);
ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_return_note_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_return_note_ref_order_auto]
    FOREIGN KEY([ref_order_auto]) REFERENCES [dbo].[tb_order] ([autoID]);
ALTER TABLE [dbo].[tb_return_item] WITH CHECK ADD CONSTRAINT [FK_tb_return_item_ref_return_note_auto]
    FOREIGN KEY([ref_return_note_auto]) REFERENCES [dbo].[tb_return_note] ([autoID]);
ALTER TABLE [dbo].[tb_return_item] WITH CHECK ADD CONSTRAINT [FK_tb_return_item_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_vendor_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_return_note_ref_vendor_auto]
    FOREIGN KEY([ref_vendor_auto]) REFERENCES [dbo].[tb_vendor] ([autoID]);
ALTER TABLE [dbo].[tb_vendor_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_return_note_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
ALTER TABLE [dbo].[tb_vendor_return_note] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_return_note_ref_company_auto]
    FOREIGN KEY([ref_company_auto]) REFERENCES [dbo].[tb_company] ([autoID]);
ALTER TABLE [dbo].[tb_vendor_return_item] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_return_item_ref_vendor_return_note_auto]
    FOREIGN KEY([ref_vendor_return_note_auto]) REFERENCES [dbo].[tb_vendor_return_note] ([autoID]);
ALTER TABLE [dbo].[tb_vendor_return_item] WITH CHECK ADD CONSTRAINT [FK_tb_vendor_return_item_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_allocation_history] WITH CHECK ADD CONSTRAINT [FK_tb_allocation_history_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
ALTER TABLE [dbo].[tb_allocation_history] WITH CHECK ADD CONSTRAINT [FK_tb_allocation_history_ref_sku_auto]
    FOREIGN KEY([ref_sku_auto]) REFERENCES [dbo].[tb_product_sku] ([autoID]);
ALTER TABLE [dbo].[tb_allocation_history] WITH CHECK ADD CONSTRAINT [FK_tb_allocation_history_ref_route_auto]
    FOREIGN KEY([ref_route_auto]) REFERENCES [dbo].[tb_route] ([autoID]);
ALTER TABLE [dbo].[tb_allocation_history] WITH CHECK ADD CONSTRAINT [FK_tb_allocation_history_ref_order_auto]
    FOREIGN KEY([ref_order_auto]) REFERENCES [dbo].[tb_order] ([autoID]);
GO

/* ผู้ใช้สังกัดคลังไหน — NULL ได้ เพราะบัญชีระดับศูนย์กลางไม่ได้ผูกกับคลังใด
   และ NO ACTION ตามทั้งฐาน ทำให้ลบคลังที่ยังมีคนสังกัดอยู่ไม่ได้ */
ALTER TABLE [dbo].[tb_users] WITH CHECK ADD CONSTRAINT [FK_tb_users_ref_warehouse_auto]
    FOREIGN KEY([ref_warehouse_auto]) REFERENCES [dbo].[tb_warehouse] ([autoID]);
GO

/* =====================================================================================
   SECTION 7 : TRIGGERS
     TRIG_GENERATE_<T>_ID       AFTER INSERT      : Business ID (SET-BASED)
     TRIG_AUTO_UPDATE_DATE_<T>  AFTER UPDATE      : ประทับเวลา SE Asia
     TRIG_SYNC_STATUS_<T>       AFTER UPDATE      : is_delete=1 => is_active=0 + DELETED
     TRIG_BLOCK_DELETE_<T>      INSTEAD OF DELETE : แปลง Hard Delete เป็น Soft Delete
   ===================================================================================== */

/****** TRIG_AUTO_UPDATE_DATE_TB_REFERENCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_REFERENCE] ON [dbo].[tb_reference] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_reference t INNER JOIN inserted i ON t.ref_id = i.ref_id;
END
GO

/****** TRIG_SYNC_STATUS_TB_REFERENCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_REFERENCE] ON [dbo].[tb_reference] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_reference t INNER JOIN inserted i ON t.ref_id = i.ref_id
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_REFERENCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_REFERENCE] ON [dbo].[tb_reference] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_reference t INNER JOIN deleted d ON t.ref_id = d.ref_id;
END
GO

/****** TRIG_GENERATE_TB_USERS_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_USERS_ID] ON [dbo].[tb_users] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [user_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_users', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [user_id] IS NULL)
    UPDATE t SET t.[user_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_users t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_USERS ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_USERS] ON [dbo].[tb_users] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_users t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_USERS ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_USERS] ON [dbo].[tb_users] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_users t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_USERS ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_USERS] ON [dbo].[tb_users] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_users t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_COMPANY_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_COMPANY_ID] ON [dbo].[tb_company] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [company_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_company', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [company_id] IS NULL)
    UPDATE t SET t.[company_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_company t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_COMPANY ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_COMPANY] ON [dbo].[tb_company] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_company t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_COMPANY ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_COMPANY] ON [dbo].[tb_company] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_company t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_COMPANY ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_COMPANY] ON [dbo].[tb_company] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_company t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_CUSTOMER_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CUSTOMER_TYPE_ID] ON [dbo].[tb_customer_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [customer_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_customer_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [customer_type_id] IS NULL)
    UPDATE t SET t.[customer_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_customer_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_TYPE] ON [dbo].[tb_customer_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_CUSTOMER_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CUSTOMER_TYPE] ON [dbo].[tb_customer_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_customer_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_CUSTOMER_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_CUSTOMER_TYPE] ON [dbo].[tb_customer_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_VENDOR_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_TYPE_ID] ON [dbo].[tb_vendor_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_vendor_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [vendor_type_id] IS NULL)
    UPDATE t SET t.[vendor_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TYPE] ON [dbo].[tb_vendor_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_VENDOR_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_TYPE] ON [dbo].[tb_vendor_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_VENDOR_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_VENDOR_TYPE] ON [dbo].[tb_vendor_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_DISCOUNT_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_DISCOUNT_TYPE_ID] ON [dbo].[tb_discount_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [discount_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_discount_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [discount_type_id] IS NULL)
    UPDATE t SET t.[discount_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_discount_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT_TYPE] ON [dbo].[tb_discount_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_discount_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_DISCOUNT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_DISCOUNT_TYPE] ON [dbo].[tb_discount_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_discount_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_DISCOUNT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_DISCOUNT_TYPE] ON [dbo].[tb_discount_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_discount_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_CATEGORY_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_CATEGORY_ID] ON [dbo].[tb_product_category] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [product_category_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product_category', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [product_category_id] IS NULL)
    UPDATE t SET t.[product_category_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_category t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_CATEGORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_CATEGORY] ON [dbo].[tb_product_category] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_category t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT_CATEGORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_CATEGORY] ON [dbo].[tb_product_category] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_category t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT_CATEGORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT_CATEGORY] ON [dbo].[tb_product_category] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_category t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_FORMAT_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_FORMAT_TYPE_ID] ON [dbo].[tb_product_format_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [product_format_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product_format_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [product_format_type_id] IS NULL)
    UPDATE t SET t.[product_format_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_format_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_FORMAT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_FORMAT_TYPE] ON [dbo].[tb_product_format_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_format_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT_FORMAT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_FORMAT_TYPE] ON [dbo].[tb_product_format_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_format_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT_FORMAT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT_FORMAT_TYPE] ON [dbo].[tb_product_format_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_format_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_UNIT_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_UNIT_TYPE_ID] ON [dbo].[tb_unit_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [unit_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_unit_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [unit_type_id] IS NULL)
    UPDATE t SET t.[unit_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_unit_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_UNIT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_UNIT_TYPE] ON [dbo].[tb_unit_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_unit_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_UNIT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_UNIT_TYPE] ON [dbo].[tb_unit_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_unit_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_UNIT_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_UNIT_TYPE] ON [dbo].[tb_unit_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_unit_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_BOOK_TYPE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_BOOK_TYPE_ID] ON [dbo].[tb_book_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [book_type_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_book_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [book_type_id] IS NULL)
    UPDATE t SET t.[book_type_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_book_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_BOOK_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK_TYPE] ON [dbo].[tb_book_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_book_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_BOOK_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_BOOK_TYPE] ON [dbo].[tb_book_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_book_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_BOOK_TYPE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_BOOK_TYPE] ON [dbo].[tb_book_type] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_book_type t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_GROUP_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_GROUP_ID] ON [dbo].[tb_product_group] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [product_group_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product_group', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [product_group_id] IS NULL)
    UPDATE t SET t.[product_group_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_group t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_GROUP ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_GROUP] ON [dbo].[tb_product_group] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_group t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT_GROUP ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_GROUP] ON [dbo].[tb_product_group] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_group t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT_GROUP ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT_GROUP] ON [dbo].[tb_product_group] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_group t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_WAREHOUSE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_WAREHOUSE_ID] ON [dbo].[tb_warehouse] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [warehouse_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_warehouse', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [warehouse_id] IS NULL)
    UPDATE t SET t.[warehouse_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_warehouse t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_WAREHOUSE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_WAREHOUSE] ON [dbo].[tb_warehouse] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_warehouse t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_WAREHOUSE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_WAREHOUSE] ON [dbo].[tb_warehouse] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_warehouse t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_WAREHOUSE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_WAREHOUSE] ON [dbo].[tb_warehouse] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_warehouse t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_VENDOR_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_ID] ON [dbo].[tb_vendor] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_vendor', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [vendor_id] IS NULL)
    UPDATE t SET t.[vendor_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_VENDOR ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR] ON [dbo].[tb_vendor] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_VENDOR ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR] ON [dbo].[tb_vendor] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_VENDOR ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_VENDOR] ON [dbo].[tb_vendor] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_CUSTOMER_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CUSTOMER_ID] ON [dbo].[tb_customer] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [customer_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_customer', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [customer_id] IS NULL)
    UPDATE t SET t.[customer_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_customer t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER] ON [dbo].[tb_customer] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_CUSTOMER ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CUSTOMER] ON [dbo].[tb_customer] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_customer t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_CUSTOMER ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_CUSTOMER] ON [dbo].[tb_customer] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_DISCOUNT_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_DISCOUNT_ID] ON [dbo].[tb_discount] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [discount_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_discount', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [discount_id] IS NULL)
    UPDATE t SET t.[discount_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_discount t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT] ON [dbo].[tb_discount] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_discount t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_DISCOUNT ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_DISCOUNT] ON [dbo].[tb_discount] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_discount t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_DISCOUNT ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_DISCOUNT] ON [dbo].[tb_discount] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_discount t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_ID] ON [dbo].[tb_product] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [product_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [product_id] IS NULL)
    UPDATE t SET t.[product_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT] ON [dbo].[tb_product] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT] ON [dbo].[tb_product] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT] ON [dbo].[tb_product] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_SKU_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_SKU_ID] ON [dbo].[tb_product_sku] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [sku_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product_sku', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [sku_id] IS NULL)
    UPDATE t SET t.[sku_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_sku t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_SKU ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_SKU] ON [dbo].[tb_product_sku] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_sku t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT_SKU ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_SKU] ON [dbo].[tb_product_sku] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_sku t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT_SKU ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT_SKU] ON [dbo].[tb_product_sku] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_sku t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_BOOK_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_BOOK_ID] ON [dbo].[tb_book] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [book_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_book', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [book_id] IS NULL)
    UPDATE t SET t.[book_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_book t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_BOOK ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK] ON [dbo].[tb_book] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_book t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_BOOK ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_BOOK] ON [dbo].[tb_book] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_book t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_BOOK ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_BOOK] ON [dbo].[tb_book] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_book t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_ROUTE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ROUTE_ID] ON [dbo].[tb_route] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [route_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_route', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [route_id] IS NULL)
    UPDATE t SET t.[route_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_route t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ROUTE] ON [dbo].[tb_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_route t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ROUTE] ON [dbo].[tb_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_route t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_ROUTE] ON [dbo].[tb_route] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_route t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID] ON [dbo].[tb_customer_route] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [customer_route_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_customer_route', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [customer_route_id] IS NULL)
    UPDATE t SET t.[customer_route_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_customer_route t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE] ON [dbo].[tb_customer_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer_route t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE] ON [dbo].[tb_customer_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_customer_route t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_CUSTOMER_ROUTE] ON [dbo].[tb_customer_route] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer_route t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_STOCK_MOVEMENT_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_STOCK_MOVEMENT_ID] ON [dbo].[tb_stock_movement] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [stock_movement_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_stock_movement', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [stock_movement_id] IS NULL)
    UPDATE t SET t.[stock_movement_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_stock_movement t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_STOCK_MOVEMENT ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_STOCK_MOVEMENT] ON [dbo].[tb_stock_movement] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_stock_movement t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_STOCK_MOVEMENT ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_STOCK_MOVEMENT] ON [dbo].[tb_stock_movement] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_stock_movement t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_STOCK_MOVEMENT ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_STOCK_MOVEMENT] ON [dbo].[tb_stock_movement] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_stock_movement t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_PRODUCT_STOCK_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_STOCK_ID] ON [dbo].[tb_product_stock] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [stock_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_product_stock', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [stock_id] IS NULL)
    UPDATE t SET t.[stock_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_stock t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK] ON [dbo].[tb_product_stock] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_stock t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_PRODUCT_STOCK ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_STOCK] ON [dbo].[tb_product_stock] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_stock t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_PRODUCT_STOCK ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_PRODUCT_STOCK] ON [dbo].[tb_product_stock] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_stock t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_CONSIGN_BALANCE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CONSIGN_BALANCE_ID] ON [dbo].[tb_consign_balance] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [consign_balance_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_consign_balance', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [consign_balance_id] IS NULL)
    UPDATE t SET t.[consign_balance_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_consign_balance t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE] ON [dbo].[tb_consign_balance] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_consign_balance t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE] ON [dbo].[tb_consign_balance] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_consign_balance t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_CONSIGN_BALANCE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_CONSIGN_BALANCE] ON [dbo].[tb_consign_balance] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_consign_balance t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_RECEIVE_NOTE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_NOTE_ID] ON [dbo].[tb_receive_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [receive_note_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_receive_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [receive_note_id] IS NULL)
    UPDATE t SET t.[receive_note_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_receive_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE] ON [dbo].[tb_receive_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_RECEIVE_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_NOTE] ON [dbo].[tb_receive_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_receive_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_RECEIVE_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_RECEIVE_NOTE] ON [dbo].[tb_receive_note] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_note t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_RECEIVE_ITEM_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_ITEM_ID] ON [dbo].[tb_receive_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [receive_item_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_receive_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [receive_item_id] IS NULL)
    UPDATE t SET t.[receive_item_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_receive_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM] ON [dbo].[tb_receive_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_RECEIVE_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_ITEM] ON [dbo].[tb_receive_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_receive_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_RECEIVE_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_RECEIVE_ITEM] ON [dbo].[tb_receive_item] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_item t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_ORDER_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ID] ON [dbo].[tb_order] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [order_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_order', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [order_id] IS NULL)
    UPDATE t SET t.[order_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_order t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_ORDER ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER] ON [dbo].[tb_order] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_ORDER ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER] ON [dbo].[tb_order] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_order t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_ORDER ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_ORDER] ON [dbo].[tb_order] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_ORDER_ITEM_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ITEM_ID] ON [dbo].[tb_order_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [order_item_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_order_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [order_item_id] IS NULL)
    UPDATE t SET t.[order_item_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_order_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM] ON [dbo].[tb_order_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_ORDER_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER_ITEM] ON [dbo].[tb_order_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_order_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_ORDER_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_ORDER_ITEM] ON [dbo].[tb_order_item] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order_item t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_RETURN_NOTE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_NOTE_ID] ON [dbo].[tb_return_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [return_note_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_return_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [return_note_id] IS NULL)
    UPDATE t SET t.[return_note_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_return_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE] ON [dbo].[tb_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_NOTE] ON [dbo].[tb_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_return_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_RETURN_NOTE] ON [dbo].[tb_return_note] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_note t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_RETURN_ITEM_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_ITEM_ID] ON [dbo].[tb_return_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [return_item_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_return_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [return_item_id] IS NULL)
    UPDATE t SET t.[return_item_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_return_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM] ON [dbo].[tb_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_ITEM] ON [dbo].[tb_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_return_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_RETURN_ITEM] ON [dbo].[tb_return_item] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_item t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID] ON [dbo].[tb_vendor_return_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_return_note_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_vendor_return_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [vendor_return_note_id] IS NULL)
    UPDATE t SET t.[vendor_return_note_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_return_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE] ON [dbo].[tb_vendor_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE] ON [dbo].[tb_vendor_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_return_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_VENDOR_RETURN_NOTE ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_VENDOR_RETURN_NOTE] ON [dbo].[tb_vendor_return_note] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_note t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID] ON [dbo].[tb_vendor_return_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_return_item_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_vendor_return_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [vendor_return_item_id] IS NULL)
    UPDATE t SET t.[vendor_return_item_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_return_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM] ON [dbo].[tb_vendor_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM] ON [dbo].[tb_vendor_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_return_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_VENDOR_RETURN_ITEM ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_VENDOR_RETURN_ITEM] ON [dbo].[tb_vendor_return_item] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_item t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/****** TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID ******/
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID] ON [dbo].[tb_allocation_history] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [allocation_history_id] IS NULL);
    IF @cnt = 0 RETURN;
    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK] @TableName = N'tb_allocation_history', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;
    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [allocation_history_id] IS NULL)
    UPDATE t SET t.[allocation_history_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_allocation_history t INNER JOIN src ON t.autoID = src.autoID;
END
GO

/****** TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY] ON [dbo].[tb_allocation_history] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_allocation_history t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO

/****** TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY] ON [dbo].[tb_allocation_history] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_allocation_history t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO

/****** TRIG_BLOCK_DELETE_TB_ALLOCATION_HISTORY ******/
GO
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_ALLOCATION_HISTORY] ON [dbo].[tb_allocation_history] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_allocation_history t INNER JOIN deleted d ON t.autoID = d.autoID;
END
GO

/* =====================================================================================
   SECTION 8 : INDEXES
   ===================================================================================== */

-- 8.1 Business ID (filtered : Trigger เติมค่าหลัง INSERT จึงเป็น NULL ชั่วคราว)
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_users_id] ON [dbo].[tb_users]([user_id]) WHERE [user_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_company_id] ON [dbo].[tb_company]([company_id]) WHERE [company_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_type_id] ON [dbo].[tb_customer_type]([customer_type_id]) WHERE [customer_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_type_id] ON [dbo].[tb_vendor_type]([vendor_type_id]) WHERE [vendor_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_discount_type_id] ON [dbo].[tb_discount_type]([discount_type_id]) WHERE [discount_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_category_id] ON [dbo].[tb_product_category]([product_category_id]) WHERE [product_category_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_format_type_id] ON [dbo].[tb_product_format_type]([product_format_type_id]) WHERE [product_format_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_unit_type_id] ON [dbo].[tb_unit_type]([unit_type_id]) WHERE [unit_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_type_id] ON [dbo].[tb_book_type]([book_type_id]) WHERE [book_type_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_group_id] ON [dbo].[tb_product_group]([product_group_id]) WHERE [product_group_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_warehouse_id] ON [dbo].[tb_warehouse]([warehouse_id]) WHERE [warehouse_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_id] ON [dbo].[tb_vendor]([vendor_id]) WHERE [vendor_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_id] ON [dbo].[tb_customer]([customer_id]) WHERE [customer_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_discount_id] ON [dbo].[tb_discount]([discount_id]) WHERE [discount_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_id] ON [dbo].[tb_product]([product_id]) WHERE [product_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_sku_id] ON [dbo].[tb_product_sku]([sku_id]) WHERE [sku_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_id] ON [dbo].[tb_book]([book_id]) WHERE [book_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_route_id] ON [dbo].[tb_route]([route_id]) WHERE [route_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_id] ON [dbo].[tb_customer_route]([customer_route_id]) WHERE [customer_route_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_stock_movement_id] ON [dbo].[tb_stock_movement]([stock_movement_id]) WHERE [stock_movement_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_stock_id] ON [dbo].[tb_product_stock]([stock_id]) WHERE [stock_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_consign_balance_id] ON [dbo].[tb_consign_balance]([consign_balance_id]) WHERE [consign_balance_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_note_id] ON [dbo].[tb_receive_note]([receive_note_id]) WHERE [receive_note_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_item_id] ON [dbo].[tb_receive_item]([receive_item_id]) WHERE [receive_item_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_id] ON [dbo].[tb_order]([order_id]) WHERE [order_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_item_id] ON [dbo].[tb_order_item]([order_item_id]) WHERE [order_item_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_note_id] ON [dbo].[tb_return_note]([return_note_id]) WHERE [return_note_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_item_id] ON [dbo].[tb_return_item]([return_item_id]) WHERE [return_item_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_note_id] ON [dbo].[tb_vendor_return_note]([vendor_return_note_id]) WHERE [vendor_return_note_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_item_id] ON [dbo].[tb_vendor_return_item]([vendor_return_item_id]) WHERE [vendor_return_item_id] IS NOT NULL;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_allocation_history_id] ON [dbo].[tb_allocation_history]([allocation_history_id]) WHERE [allocation_history_id] IS NOT NULL;
GO

-- 8.2 Natural key
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_users_user_name] ON [dbo].[tb_users]([user_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_company_code] ON [dbo].[tb_company]([company_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_type_name] ON [dbo].[tb_customer_type]([type_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_type_name] ON [dbo].[tb_vendor_type]([type_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_discount_type_name] ON [dbo].[tb_discount_type]([discount_type_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_category_code] ON [dbo].[tb_product_category]([category_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_format_type_name] ON [dbo].[tb_product_format_type]([format_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_unit_type_name] ON [dbo].[tb_unit_type]([unit_type_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_type_name] ON [dbo].[tb_book_type]([type_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_group_name] ON [dbo].[tb_product_group]([ref_product_category_auto],[product_group_name]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_warehouse_code] ON [dbo].[tb_warehouse]([warehouse_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_tax] ON [dbo].[tb_vendor]([tax_id],[branch_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_code] ON [dbo].[tb_customer]([customer_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_code] ON [dbo].[tb_product]([product_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_sku_code] ON [dbo].[tb_product_sku]([sku_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_product] ON [dbo].[tb_book]([ref_product_auto]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_route_code] ON [dbo].[tb_route]([route_code]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_pair] ON [dbo].[tb_customer_route]([ref_customer_auto],[ref_route_auto]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_stock_sku_wh] ON [dbo].[tb_product_stock]([ref_sku_auto],[ref_warehouse_auto]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_consign_balance_pair] ON [dbo].[tb_consign_balance]([ref_customer_auto],[ref_sku_auto]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_note_doc_no] ON [dbo].[tb_receive_note]([doc_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_item_line] ON [dbo].[tb_receive_item]([ref_receive_note_auto],[line_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_doc_no] ON [dbo].[tb_order]([doc_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_item_line] ON [dbo].[tb_order_item]([ref_order_auto],[line_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_note_doc_no] ON [dbo].[tb_return_note]([doc_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_item_line] ON [dbo].[tb_return_item]([ref_return_note_auto],[line_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_note_doc_no] ON [dbo].[tb_vendor_return_note]([doc_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_item_line] ON [dbo].[tb_vendor_return_item]([ref_vendor_return_note_auto],[line_no]) WHERE [is_delete] = 0;
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_allocation_history_key] ON [dbo].[tb_allocation_history]([ref_customer_auto],[ref_sku_auto],[period_key]) WHERE [is_delete] = 0;
GO

-- 8.3 Foreign-key lookup (SQL Server ไม่สร้าง index ให้ FK อัตโนมัติ)
CREATE NONCLUSTERED INDEX [IX_tb_product_group_ref_product_category_auto] ON [dbo].[tb_product_group]([ref_product_category_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_warehouse_ref_company_auto] ON [dbo].[tb_warehouse]([ref_company_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_ref_vendor_type_auto] ON [dbo].[tb_vendor]([ref_vendor_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_customer_ref_customer_type_auto] ON [dbo].[tb_customer]([ref_customer_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_discount_ref_discount_type_auto] ON [dbo].[tb_discount]([ref_discount_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_ref_product_group_auto] ON [dbo].[tb_product]([ref_product_group_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_ref_product_format_type_auto] ON [dbo].[tb_product]([ref_product_format_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_ref_unit_type_auto] ON [dbo].[tb_product]([ref_unit_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_ref_vendor_auto] ON [dbo].[tb_product]([ref_vendor_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_sku_ref_product_auto] ON [dbo].[tb_product_sku]([ref_product_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_book_ref_product_auto] ON [dbo].[tb_book]([ref_product_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_book_ref_book_type_auto] ON [dbo].[tb_book]([ref_book_type_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_route_ref_warehouse_auto] ON [dbo].[tb_route]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_customer_route_ref_customer_auto] ON [dbo].[tb_customer_route]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_customer_route_ref_route_auto] ON [dbo].[tb_customer_route]([ref_route_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_ref_sku_auto] ON [dbo].[tb_stock_movement]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_ref_warehouse_auto] ON [dbo].[tb_stock_movement]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_ref_customer_auto] ON [dbo].[tb_stock_movement]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_ref_vendor_auto] ON [dbo].[tb_stock_movement]([ref_vendor_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_stock_ref_sku_auto] ON [dbo].[tb_product_stock]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_product_stock_ref_warehouse_auto] ON [dbo].[tb_product_stock]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_consign_balance_ref_customer_auto] ON [dbo].[tb_consign_balance]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_consign_balance_ref_sku_auto] ON [dbo].[tb_consign_balance]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_receive_note_ref_vendor_auto] ON [dbo].[tb_receive_note]([ref_vendor_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_receive_note_ref_warehouse_auto] ON [dbo].[tb_receive_note]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_receive_note_ref_company_auto] ON [dbo].[tb_receive_note]([ref_company_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_receive_item_ref_receive_note_auto] ON [dbo].[tb_receive_item]([ref_receive_note_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_receive_item_ref_sku_auto] ON [dbo].[tb_receive_item]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_ref_customer_auto] ON [dbo].[tb_order]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_ref_route_auto] ON [dbo].[tb_order]([ref_route_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_ref_warehouse_auto] ON [dbo].[tb_order]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_ref_company_auto] ON [dbo].[tb_order]([ref_company_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_item_ref_order_auto] ON [dbo].[tb_order_item]([ref_order_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_item_ref_sku_auto] ON [dbo].[tb_order_item]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_customer_auto] ON [dbo].[tb_return_note]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_route_auto] ON [dbo].[tb_return_note]([ref_route_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_warehouse_auto] ON [dbo].[tb_return_note]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_order_auto] ON [dbo].[tb_return_note]([ref_order_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_item_ref_return_note_auto] ON [dbo].[tb_return_item]([ref_return_note_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_return_item_ref_sku_auto] ON [dbo].[tb_return_item]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_note_ref_vendor_auto] ON [dbo].[tb_vendor_return_note]([ref_vendor_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_note_ref_warehouse_auto] ON [dbo].[tb_vendor_return_note]([ref_warehouse_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_note_ref_company_auto] ON [dbo].[tb_vendor_return_note]([ref_company_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_item_ref_vendor_return_note_auto] ON [dbo].[tb_vendor_return_item]([ref_vendor_return_note_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_item_ref_sku_auto] ON [dbo].[tb_vendor_return_item]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_customer_auto] ON [dbo].[tb_allocation_history]([ref_customer_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_sku_auto] ON [dbo].[tb_allocation_history]([ref_sku_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_route_auto] ON [dbo].[tb_allocation_history]([ref_route_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_order_auto] ON [dbo].[tb_allocation_history]([ref_order_auto]);
GO

CREATE NONCLUSTERED INDEX [IX_tb_users_ref_warehouse_auto] ON [dbo].[tb_users]([ref_warehouse_auto]);
GO

-- 8.4 Query-specific
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_primary] ON [dbo].[tb_customer_route]([ref_customer_auto]) WHERE [is_delete] = 0 AND [is_primary] = 1;
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_sku_wh_date] ON [dbo].[tb_stock_movement]([ref_sku_auto],[ref_warehouse_auto],[movement_date]) INCLUDE ([qty_change]);
CREATE NONCLUSTERED INDEX [IX_tb_stock_movement_doc] ON [dbo].[tb_stock_movement]([doc_table],[doc_auto]);
CREATE NONCLUSTERED INDEX [IX_tb_order_period] ON [dbo].[tb_order]([period_key],[ref_route_auto]) INCLUDE ([ref_customer_auto],[doc_status]);
CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_lookup] ON [dbo].[tb_allocation_history]([ref_sku_auto],[period_key]) INCLUDE ([ref_customer_auto],[qty_delivered],[qty_returned]);
GO

/* =====================================================================================
   SECTION 9 : VIEWS  (Read Model สำหรับ PenbunAPI)
   แปลง autoID -> business id ให้แล้ว  Go ไม่ต้องเขียน JOIN เอง
   ===================================================================================== */
GO
CREATE VIEW [dbo].[vw_product] AS
SELECT  p.autoID AS product_auto,
        p.product_id, p.product_code, p.product_name, p.count_stock,
        p.cost_price, p.sell_price, p.barcode, p.weight_kg, p.pack_qty,
        pg.product_group_id, pg.product_group_name,
        pc.product_category_id, pc.category_code, pc.category_name,
        ft.product_format_type_id, ft.format_name,
        ut.unit_type_id, ut.unit_type_name,
        v.vendor_id, v.vendor_name, v.trade_type,
        p.is_active, p.id_status, p.update_by, p.update_date
  FROM dbo.tb_product p
  INNER JOIN dbo.tb_product_group    pg ON pg.autoID = p.ref_product_group_auto
  INNER JOIN dbo.tb_product_category pc ON pc.autoID = pg.ref_product_category_auto
  LEFT  JOIN dbo.tb_product_format_type ft ON ft.autoID = p.ref_product_format_type_auto
  LEFT  JOIN dbo.tb_unit_type        ut ON ut.autoID = p.ref_unit_type_auto
  LEFT  JOIN dbo.tb_vendor           v  ON v.autoID  = p.ref_vendor_auto
 WHERE p.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_product_sku] AS
SELECT  sk.autoID AS sku_auto,
        sk.sku_id, sk.sku_code, sk.barcode, sk.variation_name,
        sk.issue_no, sk.volume_no, sk.edition_label,
        sk.cost_price, sk.sell_price, sk.cover_price, sk.pack_qty,
        sk.publication_date, sk.return_deadline,
        p.product_id, p.product_code, p.product_name, p.count_stock,
        sk.is_active, sk.id_status, sk.update_by, sk.update_date
  FROM dbo.tb_product_sku sk
  INNER JOIN dbo.tb_product p ON p.autoID = sk.ref_product_auto
 WHERE sk.is_delete = 0;
GO

/* v8: เพิ่ม description, complimentary_qty และ barcode / weight_kg / pack_qty
   ของสินค้า  POST /book รับค่าทั้งหมดนี้อยู่แล้วแต่ v7 ไม่คืนตอนอ่าน ช่องเหล่านั้น
   จึงเปิดมาว่างทุกครั้งที่แก้ไข กลายเป็นการลบค่าทิ้งโดยผู้ใช้ไม่รู้ตัว */
CREATE VIEW [dbo].[vw_book] AS
SELECT  b.autoID AS book_auto,
        b.book_id, b.book_name, b.author, b.isbn, b.publisher_name, b.page_count,
        b.cover_price, b.net_price, b.vendor_discount_percent, b.customer_discount_percent,
        b.complimentary_qty, b.effective_date, b.description,
        p.product_id, p.product_code, p.product_name,
        p.barcode, p.weight_kg, p.pack_qty,
        bt.book_type_id, bt.type_name AS book_type_name,
        v.vendor_id, v.vendor_name,
        b.is_active, b.id_status, b.update_by, b.update_date
  FROM dbo.tb_book b
  INNER JOIN dbo.tb_product p ON p.autoID = b.ref_product_auto
  LEFT  JOIN dbo.tb_book_type bt ON bt.autoID = b.ref_book_type_auto
  LEFT  JOIN dbo.tb_vendor    v  ON v.autoID  = p.ref_vendor_auto
 WHERE b.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_customer] AS
SELECT  c.autoID AS customer_auto,
        c.customer_id, c.customer_code, c.customer_name, c.report_name,
        c.tax_id, c.branch_code, c.branch_name, c.contact_person,
        c.phone1, c.phone2, c.email, c.address, c.sub_district, c.district, c.province, c.zip_code,
        c.credit_limit, c.credit_term_day, c.is_vat, c.invoice_format, c.discount_group,
        ct.customer_type_id, ct.type_name AS customer_type_name, ct.base_credit_day,
        c.is_active, c.id_status, c.update_by, c.update_date
  FROM dbo.tb_customer c
  INNER JOIN dbo.tb_customer_type ct ON ct.autoID = c.ref_customer_type_auto
 WHERE c.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_vendor] AS
SELECT  v.autoID AS vendor_auto,
        v.vendor_id, v.vendor_name, v.tax_id, v.branch_code, v.branch_name,
        v.contact_person, v.phone1, v.phone2, v.email, v.website,
        v.address, v.sub_district, v.district, v.province, v.zip_code,
        v.credit_term_day, v.currency,
        v.trade_type, v.consign_share_percent, v.settlement_cycle, v.settlement_day,
        v.return_window_day, v.withholding_tax_percent,
        v.bank_name, v.bank_branch, v.bank_account_no, v.bank_account_name,
        vt.vendor_type_id, vt.type_name AS vendor_type_name,
        v.is_active, v.id_status, v.update_by, v.update_date
  FROM dbo.tb_vendor v
  INNER JOIN dbo.tb_vendor_type vt ON vt.autoID = v.ref_vendor_type_auto
 WHERE v.is_delete = 0;
GO

/* v8: เพิ่ม description และคอลัมน์ audit ทั้งสี่
   v7 ไม่ได้เลือกมา หน้าจอจึงไม่มีคอลัมน์สถานะและ API กรอง ?is_active= ไม่ได้
   ฝั่งเว็บต้องประกาศ audit:false ไว้เพื่อไม่ให้ถามหาสิ่งที่ View ไม่มี */
CREATE VIEW [dbo].[vw_customer_route] AS
SELECT  cr.autoID AS customer_route_auto,
        cr.customer_route_id,
        c.customer_id, c.customer_name,
        r.route_id, r.route_code, r.route_name, r.route_type, r.region_name,
        cr.is_primary, cr.delivery_seq, cr.description,
        cr.is_active, cr.id_status, cr.update_by, cr.update_date
  FROM dbo.tb_customer_route cr
  INNER JOIN dbo.tb_customer c ON c.autoID = cr.ref_customer_auto
  INNER JOIN dbo.tb_route    r ON r.autoID = cr.ref_route_auto
 WHERE cr.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_stock_onhand] AS
SELECT  s.autoID AS stock_auto,
        s.stock_id,
        sk.sku_id, sk.sku_code, sk.variation_name, sk.issue_no,
        p.product_id, p.product_name,
        w.warehouse_id, w.warehouse_code, w.warehouse_name, w.warehouse_type,
        s.qty_onhand, s.qty_reserved, s.qty_available, s.last_movement_date
  FROM dbo.tb_product_stock s
  INNER JOIN dbo.tb_product_sku sk ON sk.autoID = s.ref_sku_auto
  INNER JOIN dbo.tb_product     p  ON p.autoID  = sk.ref_product_auto
  INNER JOIN dbo.tb_warehouse   w  ON w.autoID  = s.ref_warehouse_auto
 WHERE s.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_stock_movement] AS
SELECT  m.autoID AS stock_movement_auto,
        m.stock_movement_id, m.movement_date, m.movement_type, m.qty_change, m.unit_cost,
        m.doc_table, m.doc_no,
        sk.sku_id, sk.sku_code, p.product_name,
        w.warehouse_id, w.warehouse_code,
        c.customer_id, c.customer_name,
        v.vendor_id, v.vendor_name,
        m.remark, m.update_by, m.update_date
  FROM dbo.tb_stock_movement m
  INNER JOIN dbo.tb_product_sku sk ON sk.autoID = m.ref_sku_auto
  INNER JOIN dbo.tb_product     p  ON p.autoID  = sk.ref_product_auto
  INNER JOIN dbo.tb_warehouse   w  ON w.autoID  = m.ref_warehouse_auto
  LEFT  JOIN dbo.tb_customer    c  ON c.autoID  = m.ref_customer_auto
  LEFT  JOIN dbo.tb_vendor      v  ON v.autoID  = m.ref_vendor_auto
 WHERE m.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_consign_outstanding] AS
SELECT  b.autoID AS consign_balance_auto,
        b.consign_balance_id,
        c.customer_id, c.customer_name,
        sk.sku_id, sk.sku_code, sk.issue_no, p.product_name,
        b.qty_delivered, b.qty_returned, b.qty_outstanding,
        b.last_order_date, b.last_return_date
  FROM dbo.tb_consign_balance b
  INNER JOIN dbo.tb_customer    c  ON c.autoID  = b.ref_customer_auto
  INNER JOIN dbo.tb_product_sku sk ON sk.autoID = b.ref_sku_auto
  INNER JOIN dbo.tb_product     p  ON p.autoID  = sk.ref_product_auto
 WHERE b.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_order_header] AS
SELECT  o.autoID AS order_auto,
        o.order_id, o.doc_no, o.doc_date, o.order_type, o.doc_status, o.period_key,
        c.customer_id, c.customer_name,
        r.route_id, r.route_code, r.route_name,
        w.warehouse_id, w.warehouse_code,
        o.total_qty, o.total_amount, o.discount_amount, o.net_amount,
        o.invoice_no, o.invoice_date, o.delivered_date,
        o.update_by, o.update_date
  FROM dbo.tb_order o
  INNER JOIN dbo.tb_customer  c ON c.autoID = o.ref_customer_auto
  INNER JOIN dbo.tb_warehouse w ON w.autoID = o.ref_warehouse_auto
  LEFT  JOIN dbo.tb_route     r ON r.autoID = o.ref_route_auto
 WHERE o.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_order_item] AS
SELECT  oi.autoID AS order_item_auto,
        oi.order_item_id, o.order_id, o.doc_no, oi.line_no,
        sk.sku_id, sk.sku_code, sk.issue_no, p.product_name,
        oi.qty_ordered, oi.qty_delivered, oi.cover_price, oi.unit_price,
        oi.discount_percent, oi.amount
  FROM dbo.tb_order_item oi
  INNER JOIN dbo.tb_order       o  ON o.autoID  = oi.ref_order_auto
  INNER JOIN dbo.tb_product_sku sk ON sk.autoID = oi.ref_sku_auto
  INNER JOIN dbo.tb_product     p  ON p.autoID  = sk.ref_product_auto
 WHERE oi.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_allocation_history] AS
SELECT  a.autoID AS allocation_history_auto,
        a.allocation_history_id, a.period_key, a.period_seq, a.issue_label,
        c.customer_id, c.customer_name,
        sk.sku_id, sk.sku_code, sk.issue_no, p.product_name,
        r.route_code, r.route_name,
        a.qty_allocated, a.qty_delivered, a.qty_returned, a.qty_sold, a.sell_through_pct,
        a.is_locked, a.update_by, a.update_date
  FROM dbo.tb_allocation_history a
  INNER JOIN dbo.tb_customer    c  ON c.autoID  = a.ref_customer_auto
  INNER JOIN dbo.tb_product_sku sk ON sk.autoID = a.ref_sku_auto
  INNER JOIN dbo.tb_product     p  ON p.autoID  = sk.ref_product_auto
  LEFT  JOIN dbo.tb_route       r  ON r.autoID  = a.ref_route_auto
 WHERE a.is_delete = 0;
GO



/* ─────────────────────────────────────────────────────────────────────────────
   v8 : View ของ resource ที่ v7 ไม่ได้ให้ไว้
   PenbunAPI เคยเขียน SELECT ชุดนี้ฝังไว้ใน internal/resources/*.go พร้อม
   คอมเมนต์ TEMP: ทุกจุด  ย้ายกลับมาที่นี่แล้ว SELECT list ต้องตรงกับที่
   descriptor ประกาศไว้ทุกคอลัมน์ — ชื่อที่ View ไม่คืนจะพิมพ์ "—" ตลอดไป
   โดยไม่มีอะไรฟ้อง
   ───────────────────────────────────────────────────────────────────────── */
GO
CREATE VIEW [dbo].[vw_company] AS
SELECT  autoID AS company_auto,
        company_id, company_code, name_th, name_en,
        tax_id, branch_code, address, province, zip_code,
        phone, email, website,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_company
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_customer_type] AS
SELECT  autoID AS customer_type_auto,
        customer_type_id, type_name, description, base_credit_day,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_customer_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_vendor_type] AS
SELECT  autoID AS vendor_type_auto,
        vendor_type_id, type_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_vendor_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_discount_type] AS
SELECT  autoID AS discount_type_auto,
        discount_type_id, discount_type_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_discount_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_product_category] AS
SELECT  autoID AS product_category_auto,
        product_category_id, category_code, category_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_product_category
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_product_format_type] AS
SELECT  autoID AS product_format_type_auto,
        product_format_type_id, format_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_product_format_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_unit_type] AS
SELECT  autoID AS unit_type_auto,
        unit_type_id, unit_type_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_unit_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_book_type] AS
SELECT  autoID AS book_type_auto,
        book_type_id, type_name, description,
        is_active, id_status, update_by, update_date
  FROM dbo.tb_book_type
 WHERE is_delete = 0;
GO

CREATE VIEW [dbo].[vw_product_group] AS
SELECT  g.autoID AS product_group_auto,
        g.product_group_id, g.product_group_name, g.description,
        pc.product_category_id, pc.category_code, pc.category_name,
        g.is_active, g.id_status, g.update_by, g.update_date
  FROM dbo.tb_product_group g
  INNER JOIN dbo.tb_product_category pc ON pc.autoID = g.ref_product_category_auto
 WHERE g.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_warehouse] AS
SELECT  w.autoID AS warehouse_auto,
        w.warehouse_id, w.warehouse_code, w.warehouse_name,
        w.warehouse_type, w.is_main_dc, w.allow_negative_stock,
        w.address, w.province, w.description,
        co.company_id, co.name_th AS company_name,
        w.is_active, w.id_status, w.update_by, w.update_date
  FROM dbo.tb_warehouse w
  LEFT JOIN dbo.tb_company co ON co.autoID = w.ref_company_auto
 WHERE w.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_route] AS
SELECT  r.autoID AS route_auto,
        r.route_id, r.route_code, r.route_name,
        r.route_type, r.region_name, r.sort_order, r.description,
        w.warehouse_id, w.warehouse_code,
        r.is_active, r.id_status, r.update_by, r.update_date
  FROM dbo.tb_route r
  LEFT JOIN dbo.tb_warehouse w ON w.autoID = r.ref_warehouse_auto
 WHERE r.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_discount] AS
SELECT  d.autoID AS discount_auto,
        d.discount_id, d.discount_code, d.discount_name,
        d.discount_value, d.is_percent, d.min_order_amount,
        d.start_date, d.end_date, d.description,
        dt.discount_type_id, dt.discount_type_name,
        d.is_active, d.id_status, d.update_by, d.update_date
  FROM dbo.tb_discount d
  INNER JOIN dbo.tb_discount_type dt ON dt.autoID = d.ref_discount_type_auto
 WHERE d.is_delete = 0;
GO

/* ─────────────────────────────────────────────────────────────────────────────
   v8 : View ของเอกสาร  (ใบส่งหนังสือมีอยู่แล้วตั้งแต่ v7)
   header กับ item แยกกันคนละ View เพราะ document engine อ่านคนละครั้ง
   และ item ต้องเรียงตาม line_no เสมอ
   ───────────────────────────────────────────────────────────────────────── */
CREATE VIEW [dbo].[vw_receive_note] AS
SELECT  h.autoID AS receive_note_auto,
        h.receive_note_id, h.doc_no, h.doc_date, h.doc_status,
        h.trade_type, h.vendor_doc_no,
        h.total_qty, h.total_amount, h.remark, h.posted_date,
        v.vendor_id, v.vendor_name,
        w.warehouse_id, w.warehouse_code, w.warehouse_name,
        h.is_active, h.id_status, h.update_by, h.update_date
  FROM dbo.tb_receive_note h
  INNER JOIN dbo.tb_vendor    v ON v.autoID = h.ref_vendor_auto
  INNER JOIN dbo.tb_warehouse w ON w.autoID = h.ref_warehouse_auto
 WHERE h.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_receive_item] AS
SELECT  i.autoID AS receive_item_auto,
        h.receive_note_id, i.line_no,
        s.sku_id, s.sku_code, s.issue_no,
        p.product_id, p.product_name,
        i.qty, i.unit_cost, i.cover_price, i.amount, i.remark,
        i.update_by, i.update_date
  FROM dbo.tb_receive_item i
  INNER JOIN dbo.tb_receive_note h ON h.autoID = i.ref_receive_note_auto
  INNER JOIN dbo.tb_product_sku  s ON s.autoID = i.ref_sku_auto
  INNER JOIN dbo.tb_product      p ON p.autoID = s.ref_product_auto
 WHERE i.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_return_note] AS
SELECT  h.autoID AS return_note_auto,
        h.return_note_id, h.doc_no, h.doc_date, h.doc_status,
        h.period_key, h.total_qty, h.total_amount, h.remark, h.posted_date,
        c.customer_id, c.customer_name,
        o.order_id AS ref_order_id,
        h.is_active, h.id_status, h.update_by, h.update_date
  FROM dbo.tb_return_note h
  INNER JOIN dbo.tb_customer c ON c.autoID = h.ref_customer_auto
  LEFT  JOIN dbo.tb_order    o ON o.autoID = h.ref_order_auto
 WHERE h.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_return_item] AS
SELECT  i.autoID AS return_item_auto,
        h.return_note_id, i.line_no,
        s.sku_id, s.sku_code, s.issue_no,
        p.product_id, p.product_name,
        i.qty_returned, i.unit_price, i.cover_price, i.amount,
        i.condition_status, i.remark,
        i.update_by, i.update_date
  FROM dbo.tb_return_item i
  INNER JOIN dbo.tb_return_note h ON h.autoID = i.ref_return_note_auto
  INNER JOIN dbo.tb_product_sku s ON s.autoID = i.ref_sku_auto
  INNER JOIN dbo.tb_product     p ON p.autoID = s.ref_product_auto
 WHERE i.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_vendor_return_note] AS
SELECT  h.autoID AS vendor_return_note_auto,
        h.vendor_return_note_id, h.doc_no, h.doc_date, h.doc_status,
        h.total_qty, h.total_amount, h.remark, h.posted_date,
        v.vendor_id, v.vendor_name,
        w.warehouse_id, w.warehouse_code, w.warehouse_name,
        h.is_active, h.id_status, h.update_by, h.update_date
  FROM dbo.tb_vendor_return_note h
  INNER JOIN dbo.tb_vendor    v ON v.autoID = h.ref_vendor_auto
  INNER JOIN dbo.tb_warehouse w ON w.autoID = h.ref_warehouse_auto
 WHERE h.is_delete = 0;
GO

CREATE VIEW [dbo].[vw_vendor_return_item] AS
SELECT  i.autoID AS vendor_return_item_auto,
        h.vendor_return_note_id, i.line_no,
        s.sku_id, s.sku_code, s.issue_no,
        p.product_id, p.product_name,
        i.qty_returned, i.unit_cost, i.amount, i.remark,
        i.update_by, i.update_date
  FROM dbo.tb_vendor_return_item i
  INNER JOIN dbo.tb_vendor_return_note h ON h.autoID = i.ref_vendor_return_note_auto
  INNER JOIN dbo.tb_product_sku       s ON s.autoID = i.ref_sku_auto
  INNER JOIN dbo.tb_product           p ON p.autoID = s.ref_product_auto
 WHERE i.is_delete = 0;
GO

/* =====================================================================================
   SECTION 10 : BUSINESS PROCEDURES  (Write Model)
   ===================================================================================== */

/* 10.0 USP_LOCK_STOCK_KEY — จองล็อกของคู่ (SKU, คลัง) หนึ่งคู่
   -------------------------------------------------------------------------------
   การตรวจว่าสต็อกพอ กับการหักสต็อกจริง เป็นคนละคำสั่งกัน เอกสารสองใบที่กิน
   สินค้าตัวเดียวกันจากคลังเดียวกันพร้อมกันจะอ่านยอดค่าเดิม ผ่านการตรวจทั้งคู่
   แล้วหักซ้อนกันจนติดลบ ทั้งที่คลังไม่ได้เปิด allow_negative_stock

   ชื่อ resource ต้องตรงกับที่ PenbunAPI ใช้ทุกตัวอักษร (repository.AppLock)
   ไม่งั้นสองฝั่งจะจองคนละล็อกแล้วไม่กันกันเอง

       PENBUN:STOCK:<sku autoID>:<warehouse autoID>

   @LockOwner = 'Transaction' แปลว่าปล่อยล็อกอัตโนมัติเมื่อ COMMIT หรือ ROLLBACK
   ผู้เรียกจึงต้องอยู่ใน transaction เสมอ — ถ้าไม่อยู่ sp_getapplock จะคืน -999
   ซึ่งตกเข้าเงื่อนไข @rc < 0 ด้านล่างและหยุดงานทันที ไม่ใช่จองไม่ติดแบบเงียบ ๆ */
CREATE PROCEDURE [dbo].[USP_LOCK_STOCK_KEY]
    @SkuAuto       INT,
    @WarehouseAuto INT,
    @WaitMS        INT = 10000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @res NVARCHAR(255) = N'PENBUN:STOCK:'
          + CONVERT(NVARCHAR(20), @SkuAuto) + N':'
          + CONVERT(NVARCHAR(20), @WarehouseAuto);
    DECLARE @rc INT;

    EXEC @rc = sp_getapplock @Resource = @res, @LockMode = 'Exclusive',
                             @LockOwner = 'Transaction', @LockTimeout = @WaitMS;
    IF @rc < 0
        RAISERROR (N'APPLOCK: ไม่สามารถจองล็อก %s ได้ (rc=%d)', 16, 1, @res, @rc);
END
GO

/* 10.1 USP_APPLY_STOCK_MOVEMENT — จุดเดียวในระบบที่แตะสต็อกได้
   เขียน Ledger ก่อนเสมอ แล้วค่อยปรับ Cache */
GO
CREATE PROCEDURE [dbo].[USP_APPLY_STOCK_MOVEMENT]
    @SkuAuto       INT,
    @WarehouseAuto INT,
    @MovementType  NVARCHAR(20),
    @QtyChange     DECIMAL(18,2),
    @DocTable      NVARCHAR(50)  = NULL,
    @DocAuto       INT           = NULL,
    @DocNo         NVARCHAR(30)  = NULL,
    @CustomerAuto  INT           = NULL,
    @VendorAuto    INT           = NULL,
    @UnitCost      DECIMAL(18,4) = NULL,
    @MovementDate  DATETIME      = NULL,
    @UpdateBy      NVARCHAR(50)  = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @MovementDate IS NULL
        SET @MovementDate = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME);

    IF @QtyChange < 0
       AND NOT EXISTS (SELECT 1 FROM dbo.tb_warehouse
                        WHERE autoID = @WarehouseAuto AND allow_negative_stock = 1)
    BEGIN
        DECLARE @onhand DECIMAL(18,2) =
            ISNULL((SELECT qty_onhand FROM dbo.tb_product_stock
                     WHERE ref_sku_auto = @SkuAuto AND ref_warehouse_auto = @WarehouseAuto
                       AND is_delete = 0), 0);
        IF @onhand + @QtyChange < 0
        BEGIN
            DECLARE @onhandText   NVARCHAR(20) = CAST(@onhand AS NVARCHAR(20));
            DECLARE @requiredText NVARCHAR(20) = CAST(-@QtyChange AS NVARCHAR(20));
            RAISERROR (N'STOCK: สต็อกไม่พอ (SKU auto=%d, คลัง auto=%d, คงเหลือ %s, ต้องการ %s)',
                       16, 1, @SkuAuto, @WarehouseAuto,
                       @onhandText, @requiredText);
            RETURN;
        END
    END

    INSERT INTO dbo.tb_stock_movement
        (prefix, ref_sku_auto, ref_warehouse_auto, ref_customer_auto, ref_vendor_auto,
         movement_date, movement_type, qty_change, unit_cost, doc_table, doc_auto, doc_no, update_by)
    VALUES
        (N'STM', @SkuAuto, @WarehouseAuto, @CustomerAuto, @VendorAuto,
         @MovementDate, @MovementType, @QtyChange, @UnitCost, @DocTable, @DocAuto, @DocNo, @UpdateBy);

    UPDATE dbo.tb_product_stock
       SET qty_onhand = qty_onhand + @QtyChange,
           last_movement_date = @MovementDate, update_by = @UpdateBy
     WHERE ref_sku_auto = @SkuAuto AND ref_warehouse_auto = @WarehouseAuto AND is_delete = 0;

    IF @@ROWCOUNT = 0
        INSERT INTO dbo.tb_product_stock
            (prefix, ref_sku_auto, ref_warehouse_auto, qty_onhand, qty_reserved, last_movement_date, update_by)
        VALUES (N'STK', @SkuAuto, @WarehouseAuto, @QtyChange, 0, @MovementDate, @UpdateBy);
END
GO

/* 10.2 USP_REBUILD_STOCK_CACHE — สร้าง tb_product_stock ใหม่จาก Ledger */
CREATE PROCEDURE [dbo].[USP_REBUILD_STOCK_CACHE]
    @UpdateBy NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;
        MERGE dbo.tb_product_stock AS s
        USING (SELECT ref_sku_auto, ref_warehouse_auto,
                      SUM(qty_change) AS q, MAX(movement_date) AS d
                 FROM dbo.tb_stock_movement WHERE is_delete = 0
                GROUP BY ref_sku_auto, ref_warehouse_auto) AS m
           ON s.ref_sku_auto = m.ref_sku_auto
          AND s.ref_warehouse_auto = m.ref_warehouse_auto AND s.is_delete = 0
        WHEN MATCHED AND s.qty_onhand <> m.q THEN
            UPDATE SET s.qty_onhand = m.q, s.last_movement_date = m.d, s.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_sku_auto, ref_warehouse_auto, qty_onhand, qty_reserved, last_movement_date, update_by)
            VALUES (N'STK', m.ref_sku_auto, m.ref_warehouse_auto, m.q, 0, m.d, @UpdateBy);
    COMMIT TRAN;
END
GO

/* 10.3 USP_REBUILD_CONSIGN_BALANCE — สร้างยอดฝากขายใหม่จากใบส่ง/ใบคืนที่ POST แล้ว */
CREATE PROCEDURE [dbo].[USP_REBUILD_CONSIGN_BALANCE]
    @UpdateBy NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;
        WITH d AS (
            SELECT o.ref_customer_auto AS cus, oi.ref_sku_auto AS sku,
                   SUM(oi.qty_delivered) AS qd, CAST(0 AS DECIMAL(18,2)) AS qr,
                   MAX(o.doc_date) AS dd, CAST(NULL AS DATETIME) AS rd
              FROM dbo.tb_order_item oi
              INNER JOIN dbo.tb_order o ON o.autoID = oi.ref_order_auto
             WHERE oi.is_delete = 0 AND o.is_delete = 0
               AND o.doc_status IN (N'DELIVERED', N'INVOICED')
             GROUP BY o.ref_customer_auto, oi.ref_sku_auto
            UNION ALL
            SELECT r.ref_customer_auto, ri.ref_sku_auto,
                   0, SUM(ri.qty_returned), NULL, MAX(r.doc_date)
              FROM dbo.tb_return_item ri
              INNER JOIN dbo.tb_return_note r ON r.autoID = ri.ref_return_note_auto
             WHERE ri.is_delete = 0 AND r.is_delete = 0
               AND r.doc_status IN (N'POSTED', N'CREDITED')
             GROUP BY r.ref_customer_auto, ri.ref_sku_auto
        )
        MERGE dbo.tb_consign_balance AS b
        USING (SELECT cus, sku, SUM(qd) AS qd, SUM(qr) AS qr,
                      MAX(dd) AS dd, MAX(rd) AS rd
                 FROM d GROUP BY cus, sku) AS s
           ON b.ref_customer_auto = s.cus AND b.ref_sku_auto = s.sku AND b.is_delete = 0
        WHEN MATCHED THEN
            UPDATE SET b.qty_delivered = s.qd, b.qty_returned = s.qr,
                       b.last_order_date = s.dd, b.last_return_date = s.rd, b.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_customer_auto, ref_sku_auto, qty_delivered, qty_returned,
                    last_order_date, last_return_date, update_by)
            VALUES (N'CSB', s.cus, s.sku, s.qd, s.qr, s.dd, s.rd, @UpdateBy);
    COMMIT TRAN;
END
GO

/* 10.4 USP_PULL_ALLOCATION_FROM_HISTORY — "ดึงจากประวัติ"
   LAST = ยอดส่งงวดล่าสุด (พฤติกรรม legacy) | AVG = เฉลี่ย N งวด | SOLD = ยอดขายสุทธิ (default)
   คืนเป็นข้อเสนอ ไม่เขียนทับอัตโนมัติ */
CREATE PROCEDURE [dbo].[USP_PULL_ALLOCATION_FROM_HISTORY]
    @SkuAuto       INT          = NULL,
    @RouteAuto     INT          = NULL,
    @Mode          NVARCHAR(10) = N'SOLD',
    @LookbackCount INT          = 3
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH h AS (
        SELECT a.ref_customer_auto, a.ref_sku_auto, a.ref_route_auto, a.period_key,
               a.qty_delivered, a.qty_returned, a.qty_sold,
               ROW_NUMBER() OVER (PARTITION BY a.ref_customer_auto, a.ref_sku_auto
                                  ORDER BY a.period_key DESC, a.period_seq DESC) AS rn
          FROM dbo.tb_allocation_history a
         WHERE a.is_delete = 0
           AND (@SkuAuto   IS NULL OR a.ref_sku_auto   = @SkuAuto)
           AND (@RouteAuto IS NULL OR a.ref_route_auto = @RouteAuto)
    )
    SELECT  h.ref_customer_auto, c.customer_id, c.customer_name,
            h.ref_sku_auto, sk.sku_id, sk.sku_code, sk.issue_no,
            r.route_code,
            MAX(CASE WHEN h.rn = 1 THEN h.period_key    END) AS last_period_key,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_delivered END) AS last_qty_delivered,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_returned  END) AS last_qty_returned,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_sold      END) AS last_qty_sold,
            CAST(AVG(h.qty_delivered) AS DECIMAL(18,2))      AS avg_qty_delivered,
            CAST(AVG(h.qty_sold)      AS DECIMAL(18,2))      AS avg_qty_sold,
            CAST(CASE @Mode
                   WHEN N'LAST' THEN MAX(CASE WHEN h.rn = 1 THEN h.qty_delivered END)
                   WHEN N'AVG'  THEN AVG(h.qty_delivered)
                   ELSE              MAX(CASE WHEN h.rn = 1 THEN h.qty_sold END)
                 END AS DECIMAL(18,2))                        AS suggested_qty
      FROM h
      INNER JOIN dbo.tb_customer    c  ON c.autoID  = h.ref_customer_auto
      INNER JOIN dbo.tb_product_sku sk ON sk.autoID = h.ref_sku_auto
      LEFT  JOIN dbo.tb_route       r  ON r.autoID  = h.ref_route_auto
     WHERE h.rn <= @LookbackCount
     GROUP BY h.ref_customer_auto, c.customer_id, c.customer_name,
              h.ref_sku_auto, sk.sku_id, sk.sku_code, sk.issue_no, r.route_code
     ORDER BY c.customer_name;
END
GO

/* 10.5 USP_POST_RECEIVE — ยืนยันใบรับหนังสือเข้าคลัง */
CREATE PROCEDURE [dbo].[USP_POST_RECEIVE]
    @ReceiveNoteID NVARCHAR(50),
    @UpdateBy      NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @nAuto INT, @wh INT, @ven INT, @status NVARCHAR(20),
            @docDate DATETIME, @docNo NVARCHAR(50);

    SELECT @nAuto = autoID, @wh = ref_warehouse_auto, @ven = ref_vendor_auto,
           @status = doc_status, @docDate = doc_date, @docNo = doc_no
      FROM dbo.tb_receive_note WHERE receive_note_id = @ReceiveNoteID AND is_delete = 0;

    IF @nAuto IS NULL
    BEGIN RAISERROR (N'POST_RECEIVE: ไม่พบใบรับ %s', 16, 1, @ReceiveNoteID); RETURN; END
    IF @status <> N'CONFIRMED'
    BEGIN RAISERROR (N'POST_RECEIVE: ใบรับ %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @ReceiveNoteID, @status); RETURN; END

    BEGIN TRAN;
        /* v8: จองล็อกทุกคู่ (SKU, คลัง) ที่เอกสารนี้แตะ ก่อนแตะสต็อกแม้แต่แถวเดียว
           เรียงจากน้อยไปมากเสมอ — สองใบที่จองสลับลำดับกันจะ deadlock
           สินค้าเข้าคลังที่ระบุไว้ในหัวเอกสาร */
        DECLARE @lkSku INT, @lkWh INT;
        DECLARE cur_lock_rcv CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT i.ref_sku_auto, h.ref_warehouse_auto
              FROM dbo.tb_receive_item i
              INNER JOIN dbo.tb_receive_note h ON h.autoID = i.ref_receive_note_auto
             WHERE i.ref_receive_note_auto = @nAuto AND i.is_delete = 0
             ORDER BY i.ref_sku_auto ASC, h.ref_warehouse_auto ASC;
        OPEN cur_lock_rcv; FETCH NEXT FROM cur_lock_rcv INTO @lkSku, @lkWh;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_LOCK_STOCK_KEY @SkuAuto = @lkSku, @WarehouseAuto = @lkWh;
            FETCH NEXT FROM cur_lock_rcv INTO @lkSku, @lkWh;
        END
        CLOSE cur_lock_rcv; DEALLOCATE cur_lock_rcv;

        DECLARE @sku INT, @q DECIMAL(18,2), @cost DECIMAL(18,4);
        DECLARE cur_rcv CURSOR LOCAL FAST_FORWARD FOR
            SELECT ref_sku_auto, SUM(qty), AVG(unit_cost)
              FROM dbo.tb_receive_item
             WHERE ref_receive_note_auto = @nAuto AND is_delete = 0
             GROUP BY ref_sku_auto;
        OPEN cur_rcv; FETCH NEXT FROM cur_rcv INTO @sku, @q, @cost;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_APPLY_STOCK_MOVEMENT
                 @SkuAuto = @sku, @WarehouseAuto = @wh, @MovementType = N'RECEIVE',
                 @QtyChange = @q, @UnitCost = @cost,
                 @DocTable = N'tb_receive_note', @DocAuto = @nAuto, @DocNo = @docNo,
                 @VendorAuto = @ven, @MovementDate = @docDate, @UpdateBy = @UpdateBy;
            FETCH NEXT FROM cur_rcv INTO @sku, @q, @cost;
        END
        CLOSE cur_rcv; DEALLOCATE cur_rcv;

        UPDATE dbo.tb_receive_note
           SET doc_status = N'POSTED', posted_date = @docDate, update_by = @UpdateBy
         WHERE autoID = @nAuto;
    COMMIT TRAN;
END
GO

/* 10.6 USP_POST_ORDER — ยืนยันใบส่งหนังสือ
   ตัดสต็อก (ผ่าน Ledger) + เพิ่มยอดฝากขาย + บันทึกประวัติงวด + ปิดสถานะ */
CREATE PROCEDURE [dbo].[USP_POST_ORDER]
    @OrderID  NVARCHAR(50),
    @UpdateBy NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @oAuto INT, @wh INT, @cus INT, @route INT,
            @period NVARCHAR(20), @status NVARCHAR(20), @docDate DATETIME, @docNo NVARCHAR(50);

    SELECT @oAuto = autoID, @wh = ref_warehouse_auto, @cus = ref_customer_auto,
           @route = ref_route_auto, @period = period_key, @status = doc_status,
           @docDate = doc_date, @docNo = doc_no
      FROM dbo.tb_order WHERE order_id = @OrderID AND is_delete = 0;

    IF @oAuto IS NULL
    BEGIN RAISERROR (N'POST_ORDER: ไม่พบใบส่ง %s', 16, 1, @OrderID); RETURN; END
    IF @status <> N'CONFIRMED'
    BEGIN RAISERROR (N'POST_ORDER: ใบส่ง %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @OrderID, @status); RETURN; END

    BEGIN TRAN;
        /* v8: จองล็อกทุกคู่ (SKU, คลัง) ที่เอกสารนี้แตะ ก่อนแตะสต็อกแม้แต่แถวเดียว
           เรียงจากน้อยไปมากเสมอ — สองใบที่จองสลับลำดับกันจะ deadlock
           สินค้าออกจากคลังที่ระบุไว้ในหัวเอกสาร */
        DECLARE @lkSku INT, @lkWh INT;
        DECLARE cur_lock_ord CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT i.ref_sku_auto, h.ref_warehouse_auto
              FROM dbo.tb_order_item i
              INNER JOIN dbo.tb_order h ON h.autoID = i.ref_order_auto
             WHERE i.ref_order_auto = @oAuto AND i.is_delete = 0
             ORDER BY i.ref_sku_auto ASC, h.ref_warehouse_auto ASC;
        OPEN cur_lock_ord; FETCH NEXT FROM cur_lock_ord INTO @lkSku, @lkWh;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_LOCK_STOCK_KEY @SkuAuto = @lkSku, @WarehouseAuto = @lkWh;
            FETCH NEXT FROM cur_lock_ord INTO @lkSku, @lkWh;
        END
        CLOSE cur_lock_ord; DEALLOCATE cur_lock_ord;

        DECLARE @sku INT, @q DECIMAL(18,2);
        DECLARE cur_line CURSOR LOCAL FAST_FORWARD FOR
            SELECT ref_sku_auto, SUM(qty_delivered)
              FROM dbo.tb_order_item
             WHERE ref_order_auto = @oAuto AND is_delete = 0
             GROUP BY ref_sku_auto;
        OPEN cur_line; FETCH NEXT FROM cur_line INTO @sku, @q;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @qtyIssue DECIMAL(18,2) = -@q;
            EXEC dbo.USP_APPLY_STOCK_MOVEMENT
                 @SkuAuto = @sku, @WarehouseAuto = @wh, @MovementType = N'ISSUE',
                 @QtyChange = @qtyIssue, @DocTable = N'tb_order', @DocAuto = @oAuto, @DocNo = @docNo,
                 @CustomerAuto = @cus, @MovementDate = @docDate, @UpdateBy = @UpdateBy;
            FETCH NEXT FROM cur_line INTO @sku, @q;
        END
        CLOSE cur_line; DEALLOCATE cur_line;

        MERGE dbo.tb_consign_balance AS b
        USING (SELECT ref_sku_auto, SUM(qty_delivered) AS q
                 FROM dbo.tb_order_item
                WHERE ref_order_auto = @oAuto AND is_delete = 0
                GROUP BY ref_sku_auto) AS i
           ON b.ref_customer_auto = @cus AND b.ref_sku_auto = i.ref_sku_auto AND b.is_delete = 0
        WHEN MATCHED THEN
            UPDATE SET b.qty_delivered = b.qty_delivered + i.q,
                       b.last_order_date = @docDate, b.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_customer_auto, ref_sku_auto, qty_delivered, qty_returned, last_order_date, update_by)
            VALUES (N'CSB', @cus, i.ref_sku_auto, i.q, 0, @docDate, @UpdateBy);

        IF @period IS NOT NULL
        MERGE dbo.tb_allocation_history AS a
        USING (SELECT ref_sku_auto, SUM(qty_ordered) AS qa, SUM(qty_delivered) AS qd
                 FROM dbo.tb_order_item
                WHERE ref_order_auto = @oAuto AND is_delete = 0
                GROUP BY ref_sku_auto) AS i
           ON a.ref_customer_auto = @cus AND a.ref_sku_auto = i.ref_sku_auto
          AND a.period_key = @period AND a.is_delete = 0
        WHEN MATCHED AND a.is_locked = 0 THEN
            UPDATE SET a.qty_allocated = i.qa, a.qty_delivered = i.qd,
                       a.ref_order_auto = @oAuto, a.ref_route_auto = @route, a.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_customer_auto, ref_sku_auto, ref_route_auto, period_key,
                    qty_allocated, qty_delivered, qty_returned, ref_order_auto, is_locked, update_by)
            VALUES (N'AHS', @cus, i.ref_sku_auto, @route, @period, i.qa, i.qd, 0, @oAuto, 0, @UpdateBy);

        UPDATE dbo.tb_order
           SET doc_status = N'DELIVERED', delivered_date = @docDate, update_by = @UpdateBy
         WHERE autoID = @oAuto;
    COMMIT TRAN;
END
GO

/* 10.7 USP_POST_RETURN — ยืนยันใบรับคืนจากร้าน
   ของดี -> คลัง RET (รอส่งคืนเจ้าของ) | ของเสีย -> คลัง DMG */
CREATE PROCEDURE [dbo].[USP_POST_RETURN]
    @ReturnNoteID NVARCHAR(50),
    @UpdateBy     NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @rAuto INT, @cus INT, @period NVARCHAR(20),
            @status NVARCHAR(20), @docDate DATETIME, @docNo NVARCHAR(50);
    DECLARE @whRET INT = (SELECT autoID FROM dbo.tb_warehouse WHERE warehouse_code = N'RET');
    DECLARE @whDMG INT = (SELECT autoID FROM dbo.tb_warehouse WHERE warehouse_code = N'DMG');

    SELECT @rAuto = autoID, @cus = ref_customer_auto, @period = period_key,
           @status = doc_status, @docDate = doc_date, @docNo = doc_no
      FROM dbo.tb_return_note WHERE return_note_id = @ReturnNoteID AND is_delete = 0;

    IF @rAuto IS NULL
    BEGIN RAISERROR (N'POST_RETURN: ไม่พบใบรับคืน %s', 16, 1, @ReturnNoteID); RETURN; END
    IF @status <> N'CONFIRMED'
    BEGIN RAISERROR (N'POST_RETURN: ใบรับคืน %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @ReturnNoteID, @status); RETURN; END

    BEGIN TRAN;
        /* v8: จองล็อกทุกคู่ (SKU, คลัง) ที่เอกสารนี้แตะ ก่อนแตะสต็อกแม้แต่แถวเดียว
           เรียงจากน้อยไปมากเสมอ — สองใบที่จองสลับลำดับกันจะ deadlock
           ใบรับคืนเลือกคลังปลายทางเป็นรายบรรทัดตามสภาพสินค้า จึงล็อกได้หลายคลังในใบเดียว */
        DECLARE @lkSku INT, @lkWh INT;
        DECLARE cur_lock_ret CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT i.ref_sku_auto,
                   CASE i.condition_status WHEN N'DAMAGED' THEN @whDMG ELSE @whRET END AS lock_wh
              FROM dbo.tb_return_item i
             WHERE i.ref_return_note_auto = @rAuto AND i.is_delete = 0
             ORDER BY i.ref_sku_auto ASC, lock_wh ASC;
        OPEN cur_lock_ret; FETCH NEXT FROM cur_lock_ret INTO @lkSku, @lkWh;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_LOCK_STOCK_KEY @SkuAuto = @lkSku, @WarehouseAuto = @lkWh;
            FETCH NEXT FROM cur_lock_ret INTO @lkSku, @lkWh;
        END
        CLOSE cur_lock_ret; DEALLOCATE cur_lock_ret;

        DECLARE @sku INT, @wh INT, @q DECIMAL(18,2);
        DECLARE cur_ret CURSOR LOCAL FAST_FORWARD FOR
            SELECT ri.ref_sku_auto,
                   CASE WHEN ri.condition_status = N'DAMAGED' THEN @whDMG ELSE @whRET END,
                   SUM(ri.qty_returned)
              FROM dbo.tb_return_item ri
             WHERE ri.ref_return_note_auto = @rAuto AND ri.is_delete = 0
             GROUP BY ri.ref_sku_auto,
                      CASE WHEN ri.condition_status = N'DAMAGED' THEN @whDMG ELSE @whRET END;
        OPEN cur_ret; FETCH NEXT FROM cur_ret INTO @sku, @wh, @q;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_APPLY_STOCK_MOVEMENT
                 @SkuAuto = @sku, @WarehouseAuto = @wh, @MovementType = N'RETURN_IN',
                 @QtyChange = @q, @DocTable = N'tb_return_note', @DocAuto = @rAuto, @DocNo = @docNo,
                 @CustomerAuto = @cus, @MovementDate = @docDate, @UpdateBy = @UpdateBy;
            FETCH NEXT FROM cur_ret INTO @sku, @wh, @q;
        END
        CLOSE cur_ret; DEALLOCATE cur_ret;

        UPDATE b
           SET b.qty_returned = b.qty_returned + i.q,
               b.last_return_date = @docDate, b.update_by = @UpdateBy
          FROM dbo.tb_consign_balance b
          INNER JOIN (SELECT ref_sku_auto, SUM(qty_returned) AS q
                        FROM dbo.tb_return_item
                       WHERE ref_return_note_auto = @rAuto AND is_delete = 0
                       GROUP BY ref_sku_auto) i ON i.ref_sku_auto = b.ref_sku_auto
         WHERE b.ref_customer_auto = @cus AND b.is_delete = 0;

        IF @period IS NOT NULL
        UPDATE a
           SET a.qty_returned = a.qty_returned + i.q, a.update_by = @UpdateBy
          FROM dbo.tb_allocation_history a
          INNER JOIN (SELECT ref_sku_auto, SUM(qty_returned) AS q
                        FROM dbo.tb_return_item
                       WHERE ref_return_note_auto = @rAuto AND is_delete = 0
                       GROUP BY ref_sku_auto) i ON i.ref_sku_auto = a.ref_sku_auto
         WHERE a.ref_customer_auto = @cus AND a.period_key = @period
           AND a.is_delete = 0 AND a.is_locked = 0;

        UPDATE dbo.tb_return_note
           SET doc_status = N'POSTED', posted_date = @docDate, update_by = @UpdateBy
         WHERE autoID = @rAuto;
    COMMIT TRAN;
END
GO

/* 10.8 USP_POST_VENDOR_RETURN — ยืนยันใบส่งคืนเจ้าของหนังสือ (ตัดออกจากคลัง RET) */
CREATE PROCEDURE [dbo].[USP_POST_VENDOR_RETURN]
    @VendorReturnNoteID NVARCHAR(50),
    @UpdateBy           NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @nAuto INT, @wh INT, @ven INT, @status NVARCHAR(20),
            @docDate DATETIME, @docNo NVARCHAR(50);

    SELECT @nAuto = autoID, @wh = ref_warehouse_auto, @ven = ref_vendor_auto,
           @status = doc_status, @docDate = doc_date, @docNo = doc_no
      FROM dbo.tb_vendor_return_note WHERE vendor_return_note_id = @VendorReturnNoteID AND is_delete = 0;

    IF @nAuto IS NULL
    BEGIN RAISERROR (N'POST_VENDOR_RETURN: ไม่พบใบส่งคืน %s', 16, 1, @VendorReturnNoteID); RETURN; END
    IF @status <> N'CONFIRMED'
    BEGIN RAISERROR (N'POST_VENDOR_RETURN: ใบส่งคืน %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @VendorReturnNoteID, @status); RETURN; END

    BEGIN TRAN;
        /* v8: จองล็อกทุกคู่ (SKU, คลัง) ที่เอกสารนี้แตะ ก่อนแตะสต็อกแม้แต่แถวเดียว
           เรียงจากน้อยไปมากเสมอ — สองใบที่จองสลับลำดับกันจะ deadlock
           สินค้าออกจากคลังที่ระบุไว้ในหัวเอกสาร */
        DECLARE @lkSku INT, @lkWh INT;
        DECLARE cur_lock_vrt CURSOR LOCAL FAST_FORWARD FOR
            SELECT DISTINCT i.ref_sku_auto, h.ref_warehouse_auto
              FROM dbo.tb_vendor_return_item i
              INNER JOIN dbo.tb_vendor_return_note h ON h.autoID = i.ref_vendor_return_note_auto
             WHERE i.ref_vendor_return_note_auto = @nAuto AND i.is_delete = 0
             ORDER BY i.ref_sku_auto ASC, h.ref_warehouse_auto ASC;
        OPEN cur_lock_vrt; FETCH NEXT FROM cur_lock_vrt INTO @lkSku, @lkWh;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC dbo.USP_LOCK_STOCK_KEY @SkuAuto = @lkSku, @WarehouseAuto = @lkWh;
            FETCH NEXT FROM cur_lock_vrt INTO @lkSku, @lkWh;
        END
        CLOSE cur_lock_vrt; DEALLOCATE cur_lock_vrt;

        DECLARE @sku INT, @q DECIMAL(18,2), @cost DECIMAL(18,4);
        DECLARE cur_vr CURSOR LOCAL FAST_FORWARD FOR
            SELECT ref_sku_auto, SUM(qty_returned), AVG(unit_cost)
              FROM dbo.tb_vendor_return_item
             WHERE ref_vendor_return_note_auto = @nAuto AND is_delete = 0
             GROUP BY ref_sku_auto;
        OPEN cur_vr; FETCH NEXT FROM cur_vr INTO @sku, @q, @cost;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @qtyReturnOut DECIMAL(18,2) = -@q;
            EXEC dbo.USP_APPLY_STOCK_MOVEMENT
                 @SkuAuto = @sku, @WarehouseAuto = @wh, @MovementType = N'RETURN_OUT',
                 @QtyChange = @qtyReturnOut, @UnitCost = @cost,
                 @DocTable = N'tb_vendor_return_note', @DocAuto = @nAuto, @DocNo = @docNo,
                 @VendorAuto = @ven, @MovementDate = @docDate, @UpdateBy = @UpdateBy;
            FETCH NEXT FROM cur_vr INTO @sku, @q, @cost;
        END
        CLOSE cur_vr; DEALLOCATE cur_vr;

        UPDATE dbo.tb_vendor_return_note
           SET doc_status = N'POSTED', posted_date = @docDate, update_by = @UpdateBy
         WHERE autoID = @nAuto;
    COMMIT TRAN;
END
GO


/* =====================================================================================
   SECTION 11 : SEED DATA
   ไม่ระบุ <table>_id / update_date / id_status — ปล่อยให้ Trigger + Default ทำงาน
   Seed เฉพาะ Reference / Lookup ที่ระบบต้องใช้  ไม่ใส่ demo data (customer/vendor/product)
   ===================================================================================== */

-- 11.1 บริษัท
INSERT INTO [dbo].[tb_company] ([prefix],[company_code],[name_th],[name_en],[tax_id],[branch_code],[vat_rate],[update_by])
VALUES (N'CPN', N'PENBUN-HQ', N'บริษัท เพ็ญบุญ จัดจำหน่าย จำกัด', N'Penbun Distribution Co., Ltd.',
        NULL, N'00000', 7.00, N'System');
GO

-- 11.2 คลังสินค้า
DECLARE @co INT = (SELECT autoID FROM [dbo].[tb_company] WHERE company_code = N'PENBUN-HQ');
INSERT INTO [dbo].[tb_warehouse]
    ([prefix],[ref_company_auto],[warehouse_code],[warehouse_name],[warehouse_type],[is_main_dc],[allow_negative_stock],[description],[update_by]) VALUES
 (N'WHS', @co, N'DC',  N'ศูนย์กระจายสินค้าหลัก',   N'DC',            1, 0, N'Distribution Center', N'System'),
 (N'WHS', @co, N'BKK', N'คลังกรุงเทพ',            N'BRANCH',        0, 0, N'สาขากรุงเทพ (รหัสเดิม 21)', N'System'),
 (N'WHS', @co, N'PRO', N'คลังต่างจังหวัด',        N'PROVINCE',      0, 0, N'สาขาต่างจังหวัด (รหัสเดิม 11)', N'System'),
 (N'WHS', @co, N'RET', N'คลังรับคืนรอส่งเจ้าของ',  N'RETURN',        0, 0, N'พักหนังสือที่ร้านคืน ก่อนออกใบส่งคืนเจ้าของ', N'System'),
 (N'WHS', @co, N'DMG', N'คลังสินค้าชำรุด',         N'DAMAGED',       0, 0, N'ของเสีย/ชำรุด', N'System'),
 (N'WHS', @co, N'INT', N'คลังต่างประเทศ',          N'INTERNATIONAL', 0, 1, N'อนุญาตติดลบ', N'System');
GO

-- 11.3 สายจัดจำหน่าย (legacy มี 3 ระบบซ้อนกัน จึงเก็บด้วย route_type)
DECLARE @whDC INT = (SELECT autoID FROM [dbo].[tb_warehouse] WHERE warehouse_code = N'DC');
DECLARE @whBK INT = (SELECT autoID FROM [dbo].[tb_warehouse] WHERE warehouse_code = N'BKK');
INSERT INTO [dbo].[tb_route]
    ([prefix],[ref_warehouse_auto],[route_code],[route_name],[route_type],[region_name],[sort_order],[update_by]) VALUES
 (N'RTE', @whBK, N'BKK', N'กรุงเทพ',            N'REGION',      N'กลาง',     1, N'System'),
 (N'RTE', @whDC, N'NTH', N'สายเหนือ',           N'REGION',      N'เหนือ',    2, N'System'),
 (N'RTE', @whDC, N'NEA', N'สายอีสาน',           N'REGION',      N'อีสาน',    3, N'System'),
 (N'RTE', @whDC, N'STH', N'สายใต้',             N'REGION',      N'ใต้',      4, N'System'),
 (N'RTE', @whDC, N'EST', N'สายตะวันออก',        N'REGION',      N'ตะวันออก', 5, N'System'),
 (N'RTE', @whDC, N'L1',  N'สายจัดจำหน่าย 1',    N'LEGACY_LINE', NULL,      11, N'System'),
 (N'RTE', @whDC, N'L2',  N'สายจัดจำหน่าย 2',    N'LEGACY_LINE', NULL,      12, N'System'),
 (N'RTE', @whDC, N'L3',  N'สายจัดจำหน่าย 3',    N'LEGACY_LINE', NULL,      13, N'System'),
 (N'RTE', @whDC, N'L4',  N'สายจัดจำหน่าย 4',    N'LEGACY_LINE', NULL,      14, N'System'),
 (N'RTE', @whDC, N'L5',  N'สายจัดจำหน่าย 5',    N'LEGACY_LINE', NULL,      15, N'System'),
 (N'RTE', @whDC, N'DLY', N'สายจัดจำหน่ายรายวัน', N'DAILY',       NULL,      21, N'System');
GO

-- 11.4 หน่วยนับ
INSERT INTO [dbo].[tb_unit_type] ([prefix],[unit_type_name],[description],[update_by]) VALUES
 (N'UNT', N'เล่ม',   N'หน่วยนับหนังสือ',            N'System'),
 (N'UNT', N'มัด',    N'มัด (ดู pack_qty ประกอบ)',   N'System'),
 (N'UNT', N'ชิ้น',   N'สินค้าทั่วไป',               N'System'),
 (N'UNT', N'กล่อง',  N'บรรจุภัณฑ์',                 N'System'),
 (N'UNT', N'ชุด',    N'ชุด/แพ็ก',                   N'System'),
 (N'UNT', N'ครั้ง',  N'บริการคิดตามครั้ง',           N'System'),
 (N'UNT', N'เดือน',  N'บริการรายเดือน เช่น Cloud',   N'System'),
 (N'UNT', N'ปี',     N'บริการรายปี เช่น License',    N'System');
GO

-- 11.5 หมวดสินค้า (ชั้นบน)
INSERT INTO [dbo].[tb_product_category] ([prefix],[category_code],[category_name],[description],[update_by]) VALUES
 (N'PCT', N'BOOK',    N'หนังสือ',            N'สินค้าหลัก นับสต็อก',           N'System'),
 (N'PCT', N'MAGZ',    N'นิตยสาร/สิ่งพิมพ์ตามงวด', N'ออกเป็นฉบับ มีกำหนดรับคืน',  N'System'),
 (N'PCT', N'STATION', N'เครื่องเขียน',        N'สินค้านับสต็อก',                N'System'),
 (N'PCT', N'PACK',    N'บรรจุภัณฑ์',          N'กล่อง/เทป/ฟิล์ม นับสต็อก',      N'System'),
 (N'PCT', N'SERVICE', N'บริการ',              N'ไม่นับสต็อก (count_stock = 0)',  N'System'),
 (N'PCT', N'IT',      N'ไอทีและซอฟต์แวร์',    N'ไม่นับสต็อก',                   N'System');
GO

-- 11.6 กลุ่มสินค้า
DECLARE @cBook INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'BOOK');
DECLARE @cMag  INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'MAGZ');
DECLARE @cSta  INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'STATION');
DECLARE @cPac  INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'PACK');
DECLARE @cSrv  INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'SERVICE');
DECLARE @cIT   INT = (SELECT autoID FROM [dbo].[tb_product_category] WHERE category_code = N'IT');
INSERT INTO [dbo].[tb_product_group] ([prefix],[ref_product_category_auto],[product_group_name],[description],[update_by]) VALUES
 (N'PGT', @cBook, N'วรรณกรรม/นิยาย',          NULL, N'System'),
 (N'PGT', @cBook, N'วิชาการ/ตำราเรียน',        NULL, N'System'),
 (N'PGT', @cBook, N'การ์ตูน/Light Novel',      NULL, N'System'),
 (N'PGT', @cBook, N'สารคดี/Non-fiction',       NULL, N'System'),
 (N'PGT', @cBook, N'เด็กและเยาวชน',            NULL, N'System'),
 (N'PGT', @cMag,  N'นิตยสารรายเดือน',          NULL, N'System'),
 (N'PGT', @cMag,  N'นิตยสารรายสัปดาห์',        NULL, N'System'),
 (N'PGT', @cMag,  N'หนังสือพิมพ์รายวัน',        NULL, N'System'),
 (N'PGT', @cSta,  N'เครื่องเขียนทั่วไป',        NULL, N'System'),
 (N'PGT', @cPac,  N'กล่อง/ลัง',                NULL, N'System'),
 (N'PGT', @cPac,  N'เทป/ฟิล์มหด',              NULL, N'System'),
 (N'PGT', @cSrv,  N'ค่าขนส่ง',                 N'EMS / ไปรษณีย์ / ขนส่งเอกชน', N'System'),
 (N'PGT', @cSrv,  N'ค่าบริการอื่น',            N'รปภ. / แม่บ้าน / งานจ้าง',    N'System'),
 (N'PGT', @cSrv,  N'ค่าสาธารณูปโภค',           N'ไฟฟ้า / ประปา',              N'System'),
 (N'PGT', @cIT,   N'ค่าเช่า Cloud / VPS',      NULL, N'System'),
 (N'PGT', @cIT,   N'License ซอฟต์แวร์',        NULL, N'System'),
 (N'PGT', @cIT,   N'อุปกรณ์ไอที',              NULL, N'System'),
 (N'PGT', @cIT,   N'ค่าอินเทอร์เน็ต/โทรคมนาคม', NULL, N'System');
GO

-- 11.7 รูปแบบสินค้า
INSERT INTO [dbo].[tb_product_format_type] ([prefix],[format_name],[description],[update_by]) VALUES
 (N'PFM', N'ปกอ่อน',       NULL, N'System'),
 (N'PFM', N'ปกแข็ง',       NULL, N'System'),
 (N'PFM', N'Boxset',       NULL, N'System'),
 (N'PFM', N'E-Book',       NULL, N'System'),
 (N'PFM', N'Audiobook',    NULL, N'System'),
 (N'PFM', N'ไม่ระบุรูปแบบ', N'สำหรับสินค้าที่ไม่ใช่สิ่งพิมพ์', N'System');
GO

-- 11.8 ประเภทหนังสือ (legacy: Bookcatgid)
INSERT INTO [dbo].[tb_book_type] ([prefix],[type_name],[description],[update_by]) VALUES
 (N'BKT', N'วิชาการ',          NULL, N'System'),
 (N'BKT', N'นวนิยาย',          NULL, N'System'),
 (N'BKT', N'การ์ตูน',          NULL, N'System'),
 (N'BKT', N'เด็ก',             NULL, N'System'),
 (N'BKT', N'ศาสนา',            NULL, N'System'),
 (N'BKT', N'ท่องเที่ยว',        NULL, N'System'),
 (N'BKT', N'อาหาร/สุขภาพ',      NULL, N'System'),
 (N'BKT', N'บริหาร/การตลาด',    NULL, N'System'),
 (N'BKT', N'คอมพิวเตอร์',       NULL, N'System'),
 (N'BKT', N'อุตสาหกรรม',        NULL, N'System');
GO

-- 11.9 ประเภทคู่ค้า  (v5 มี 24 แถวแต่ปนของที่เป็นลูกค้า + ขาดหมวด non-book -> ชุดนี้จัดใหม่)
INSERT INTO [dbo].[tb_vendor_type] ([prefix],[type_name],[description],[update_by]) VALUES
 (N'VET', N'สำนักพิมพ์ (วรรณกรรม/นิยาย)',      N'ผู้ผลิตงานวรรณกรรม นวนิยาย เรื่องสั้น',   N'System'),
 (N'VET', N'สำนักพิมพ์ (วิชาการ/การศึกษา)',    N'ตำราเรียน คู่มือสอบ งานวิจัย',           N'System'),
 (N'VET', N'สำนักพิมพ์ (การ์ตูน/Light Novel)', N'การ์ตูนและนิยายภาพ',                    N'System'),
 (N'VET', N'สำนักพิมพ์ (สารคดี/Non-fiction)',  N'ความรู้ ประวัติศาสตร์ ฮาวทู',           N'System'),
 (N'VET', N'สำนักพิมพ์ (เด็กและเยาวชน)',       N'นิทานและหนังสือเสริมพัฒนาการ',           N'System'),
 (N'VET', N'ผู้จัดจำหน่ายหนังสือ (Distributor)', N'ตัวแทนกระจายสินค้า',                  N'System'),
 (N'VET', N'โรงพิมพ์ (Offset)',                N'งานพิมพ์จำนวนมาก',                      N'System'),
 (N'VET', N'โรงพิมพ์ (Digital/On-Demand)',     N'งานพิมพ์จำนวนน้อย/ด่วน',                N'System'),
 (N'VET', N'ผู้เข้าเล่ม/ทำปก',                 N'เย็บกี่ ไสกาว',                         N'System'),
 (N'VET', N'ผู้จำหน่ายกระดาษ/เยื่อกระดาษ',      N'วัตถุดิบสำหรับโรงพิมพ์',                N'System'),
 (N'VET', N'นักเขียนอิสระ',                    N'ผู้ประพันธ์ต้นฉบับ',                     N'System'),
 (N'VET', N'นักวาดภาพประกอบ',                  N'ออกแบบปกและภาพประกอบ',                  N'System'),
 (N'VET', N'บรรณาธิการอิสระ',                  N'พิสูจน์อักษรและเรียบเรียง',              N'System'),
 (N'VET', N'ตัวแทนลิขสิทธิ์',                  N'นายหน้าซื้อขายลิขสิทธิ์',                N'System'),
 (N'VET', N'ผู้ผลิต E-Book/Audiobook',         N'แพลตฟอร์มหนังสือดิจิทัล',                N'System'),
 (N'VET', N'ผู้ผลิตสินค้าพรีเมียม',             N'ที่คั่นหนังสือ กระเป๋าผ้า ของแถม',        N'System'),
 (N'VET', N'สายส่ง/โลจิสติกส์สิ่งพิมพ์',        N'ขนส่งหนังสือและนิตยสารโดยเฉพาะ',         N'System'),
 (N'VET', N'ขนส่ง/ไปรษณีย์ (Courier)',         N'ไปรษณีย์ไทย / Kerry / Flash',           N'System'),
 (N'VET', N'ไอที - ซอฟต์แวร์และคลาวด์',        N'Microsoft / INET / SaaS',               N'System'),
 (N'VET', N'ไอที - อุปกรณ์ฮาร์ดแวร์',          N'Synnex / JIB / Advice',                 N'System'),
 (N'VET', N'โทรคมนาคม/อินเทอร์เน็ต',           N'True / AIS / 3BB',                      N'System'),
 (N'VET', N'สาธารณูปโภค',                      N'การไฟฟ้า / การประปา',                    N'System'),
 (N'VET', N'เครื่องเขียนและอุปกรณ์สำนักงาน',    N'OfficeMate และผู้ขายทั่วไป',             N'System'),
 (N'VET', N'บริการจ้างเหมา (Outsource)',       N'รปภ. / แม่บ้าน / บัญชี',                 N'System');
GO

-- 11.10 ประเภทลูกค้า
INSERT INTO [dbo].[tb_customer_type] ([prefix],[type_name],[description],[base_credit_day],[update_by]) VALUES
 (N'CUT', N'ร้านหนังสือเชน (Modern Trade)', N'B2S / นายอินทร์ / ซีเอ็ด',      60, N'System'),
 (N'CUT', N'ร้านหนังสืออิสระ',              N'ร้านขนาดเล็ก',                  30, N'System'),
 (N'CUT', N'ร้านหนังสือต่างจังหวัด',        N'ผ่านสายจัดจำหน่าย',              30, N'System'),
 (N'CUT', N'ห้องสมุด/สถาบันการศึกษา',       N'สั่งซื้อเพื่อการศึกษา',           45, N'System'),
 (N'CUT', N'หน่วยงานราชการ',                N'จัดซื้อภาครัฐ',                  60, N'System'),
 (N'CUT', N'ตัวแทนจำหน่ายย่อย (Sub-agent)', N'แผงหนังสือ/ตัวแทนรายย่อย',       15, N'System'),
 (N'CUT', N'ลูกค้าออนไลน์',                 N'ขายตรงผ่านช่องทางออนไลน์',        0, N'System'),
 (N'CUT', N'ลูกค้าเงินสด',                  N'ชำระทันที ไม่มีเครดิต',           0, N'System');
GO

-- 11.11 ประเภทส่วนลด
INSERT INTO [dbo].[tb_discount_type] ([prefix],[discount_type_name],[description],[update_by]) VALUES
 (N'DCT', N'ส่วนลดตามกลุ่มลูกค้า',   N'อิงกลุ่มส่วนลดของร้านค้า',      N'System'),
 (N'DCT', N'ส่วนลดเฉพาะร้าน',        N'legacy: แฟ้มส่วนลดพิเศษ',       N'System'),
 (N'DCT', N'ส่วนลดตามสาย',           N'legacy: ปรับทั้งสาย',           N'System'),
 (N'DCT', N'ส่วนลดเจ้าของหนังสือ',    N'ส่วนลดที่ได้รับจากสำนักพิมพ์',   N'System'),
 (N'DCT', N'ส่วนลดตามปริมาณ',        N'ซื้อมากลดมาก',                  N'System'),
 (N'DCT', N'ส่วนลดตามฤดูกาล/แคมเปญ', N'งานสัปดาห์หนังสือ ฯลฯ',         N'System'),
 (N'DCT', N'ส่วนลดชำระเงินสด',       N'Cash discount',                 N'System'),
 (N'DCT', N'ส่วนลดสินค้าค้างสต็อก',   N'Clearance',                     N'System');
GO

-- 11.12 ผู้ใช้งานตั้งต้น
--       รหัสผ่านเป็น bcrypt ของ 'Penbun@2026' -> เปลี่ยนทันทีหลัง login ครั้งแรก
--       status_change_pw = 1 (default) จะบังคับเปลี่ยนรหัสตาม Authentication Spec M001
INSERT INTO [dbo].[tb_users]
    ([prefix],[user_name],[user_password],[user_level],[full_name],[update_by])
VALUES
    (N'USR', N'admin', N'$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
     N'ADMIN', N'ผู้ดูแลระบบ', N'System');
GO


/* =====================================================================================
   SECTION 12 : VERIFY  (รันหลังติดตั้งเพื่อยืนยันว่าครบ)
   ===================================================================================== */
SELECT 'tables'      AS object_type, COUNT(*) AS cnt FROM sys.tables       WHERE name LIKE 'tb[_]%'
UNION ALL SELECT 'views',       COUNT(*) FROM sys.views        WHERE name LIKE 'vw[_]%'
UNION ALL SELECT 'procedures',  COUNT(*) FROM sys.procedures   WHERE name LIKE 'USP[_]%'
UNION ALL SELECT 'triggers',    COUNT(*) FROM sys.triggers     WHERE is_ms_shipped = 0
UNION ALL SELECT 'foreign_keys',COUNT(*) FROM sys.foreign_keys
UNION ALL SELECT 'check_const', COUNT(*) FROM sys.check_constraints
UNION ALL SELECT 'indexes',     COUNT(*) FROM sys.indexes
       WHERE object_id IN (SELECT object_id FROM sys.tables WHERE name LIKE 'tb[_]%') AND index_id > 1;
GO

-- ตรวจว่าไม่มี FK ตัวไหนอยู่ในสถานะ not-trusted
SELECT name AS untrusted_fk FROM sys.foreign_keys WHERE is_not_trusted = 1;
GO


/* =====================================================================================
   SECTION 13 : ข้อควรรู้
   -------------------------------------------------------------------------------------
   13.1  ทำไมอ้างอิงด้วย autoID ไม่ใช่ business id
         business id เป็น NULL ตอน INSERT (Trigger เติมทีหลัง) จึงต้องใช้ filtered
         unique index ซึ่ง SQL Server ไม่ยอมให้รองรับ FOREIGN KEY
         การอ้าง autoID (PK, INT, NOT NULL) แก้ปัญหานี้ และได้ index เล็กลง ~25 เท่า
         business id ยังเป็น key ที่ผู้ใช้เห็น -> อ่านผ่าน VIEW ใน SECTION 9

   13.2  Ledger vs Cache
         tb_stock_movement  = ความจริง (append-only)
         tb_product_stock   = cache  -> USP_REBUILD_STOCK_CACHE
         tb_consign_balance = cache  -> USP_REBUILD_CONSIGN_BALANCE
         ห้าม UPDATE ตาราง cache ตรง ๆ  ให้เรียก USP_APPLY_STOCK_MOVEMENT เสมอ

   13.3  Hard Delete ถูกปิดสองชั้น
         TRIG_BLOCK_DELETE_*  : DELETE กลายเป็น Soft Delete อัตโนมัติ
         FOREIGN KEY NO ACTION : ลบตารางแม่ที่มีลูกอ้างอยู่ไม่ได้

   13.4  สิ่งที่ PenbunAPI ต้องแก้
         - INSERT ต้องส่ง ref_*_auto (INT)  ทำ helper resolveAuto(table, businessID) ตัวเดียวพอ
         - อ่านข้อมูลให้ยิงที่ VIEW จะได้ business id ครบโดยไม่ต้อง JOIN
         - ยืนยันเอกสารเรียก USP_POST_RECEIVE / USP_POST_ORDER / USP_POST_RETURN / USP_POST_VENDOR_RETURN
         - เลิกใช้ endpoint DELETE แบบ hard delete (ตอนนี้ DB แปลงให้เป็น soft delete แล้ว)
         - update_by ต้องมาจาก JWT claim ไม่ใช่ query string (v5 มีค่า 'UNKNOWN' หลุดเข้าฐาน)

   13.5  สมมติฐานที่ตั้งไว้ (ถ้าไม่ตรง แก้ก่อนอย่างอื่น)
         สาย     : เขตขาย/เส้นทางส่ง  ลูกค้าอยู่ได้หลายสาย แต่สายหลักได้สายเดียว
         ฝากขาย  : ส่งออกบิลเต็ม แล้วออกใบลดหนี้ตอนคืน  จ่ายเจ้าของตามยอดขายสุทธิ
                   ของคืนเข้า RET (ของดี) / DMG (ของเสีย) ไม่กลับเข้า DC
         ประวัติ  : "ดึงจากประวัติ" default = ยอดขายสุทธิงวดล่าสุด (Mode = SOLD)
         11 / 21 : ถือเป็นหน่วยงานในนิติบุคคลเดียว แยกด้วย warehouse (BKK / PRO)
                   ถ้าเป็นคนละนิติบุคคลจริง ให้เพิ่มแถวใน tb_company แล้วผูก ref_company_auto

   13.6  ยังไม่ได้ทำ (รอคำตอบข้อ 4-14)
         - โครงราคา/ส่วนลดหลายชั้น (tb_price_rule : product x customer x route)
         - RBAC (tb_role / tb_user_role / tb_privilege_group / tb_privilege)
         - History Log (tb_history_group / tb_history_log) + tb_configuration
         - Invoice / Credit Note / Vendor Settlement
   ===================================================================================== */
