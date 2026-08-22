USE [PENBUN]
GO
/* =====================================================================================
   PenbunSQL v6.0.0 — Route / Consignment / Transaction Layer
   Generated: 2026-08-21
   Depends on: SQL-PENBUN-v5.sql (18 tables) — must be deployed first.

   ครอบคลุมข้อ 1-3:
     1) สายจัดจำหน่าย (Route)      -> tb_route_type, tb_route, tb_customer_route
     2) ฝากขาย (Consignment)      -> tb_vendor_term, tb_product_stock, tb_consign_balance,
                                      tb_receive_note/item, tb_order/item,
                                      tb_return_note/item, tb_vendor_return_note/item
     3) ดึงจากประวัติ (Allocation) -> tb_allocation_history + USP_PULL_ALLOCATION_FROM_HISTORY

   คงมาตรฐานเดิมทุกข้อ:
     - autoID / prefix / <table>_id / update_by / update_date / is_active / is_delete / id_status
     - Business ID สร้างโดย TRIGGER (ไม่ใช่ Application)
     - Creation is First Update (ไม่มี create_by / create_date)
     - Soft Delete ด้วย is_delete = 1
     - SE Asia Standard Time ทุกจุด
     - SET NOCOUNT ON + TRIGGER_NESTLEVEL() guard ทุก trigger

   สิ่งที่ v6 ทำต่างจาก v5 (โดยตั้งใจ — อ่าน SECTION 9 ก่อนใช้):
     - ID trigger เป็น SET-BASED (ไม่ใช้ CURSOR) เพื่อรองรับ INSERT หลายพันบรรทัดต่อใบ
     - เพิ่ม USP_ALLOCATE_BUSINESS_ID_BLOCK (จองเลขเป็นบล็อก, ปลอดภัยเมื่อชนกัน)
     - เพิ่ม CHECK constraint กับฟิลด์สถานะ
     - เพิ่ม trigger บังคับ invariant ของ 3 status field
   ===================================================================================== */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* =====================================================================================
   SECTION 0 : STORED PROCEDURES (ID GENERATION)
   ===================================================================================== */

/* 0.1 -- USP_GENERATE_BUSINESS_ID : Safety net
   v5 เรียกใช้ proc นี้ใน 24 trigger แต่ไม่มี source อยู่ใน repo
   ถ้ามีอยู่ใน DB จริงแล้ว block นี้จะไม่ทำอะไร (ไม่ทับของเดิม)
   ถ้ายังไม่มี จะสร้างเวอร์ชันที่เข้ากันได้กับรูปแบบ <PREFIX><SERIES A-Z><NNNNNN> */
IF OBJECT_ID(N'dbo.USP_GENERATE_BUSINESS_ID', N'P') IS NULL
BEGIN
    EXEC(N'
CREATE PROCEDURE [dbo].[USP_GENERATE_BUSINESS_ID]
    @TableName NVARCHAR(100),
    @Prefix    NVARCHAR(3),
    @AutoID    INT,
    @OutputID  NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = @TableName, @BlockSize = 1,
         @StartNo = @start OUTPUT, @Series = @series OUTPUT;
    SET @OutputID = @Prefix + @series + RIGHT(N''000000'' + CAST(@start AS NVARCHAR(10)), 6);
END');
END
GO

/* 0.2 -- USP_ALLOCATE_BUSINESS_ID_BLOCK
   จองเลขรันนิ่งเป็นบล็อก (N ใบพร้อมกัน) ด้วย UPDLOCK/HOLDLOCK บนแถวเดียวของ tb_reference
   ทำให้ INSERT 500 บรรทัด = แตะ tb_reference ครั้งเดียว ไม่ใช่ 500 ครั้ง
   สัญญาข้อมูล tb_reference:  ref_id = ชื่อตาราง, ref_int = เลขล่าสุดที่ใช้ไป, ref_text = Series (A-Z)

   หมายเหตุ: proc นี้ต้องถูกเรียกภายใน transaction (trigger มี transaction ให้อยู่แล้ว) */
IF OBJECT_ID(N'dbo.USP_ALLOCATE_BUSINESS_ID_BLOCK', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
GO
CREATE PROCEDURE [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
    @TableName NVARCHAR(100),
    @BlockSize INT,
    @StartNo   INT           OUTPUT,
    @Series    NVARCHAR(1)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF @BlockSize IS NULL OR @BlockSize < 1 SET @BlockSize = 1;

    DECLARE @cur INT;

    -- สร้างแถวตั้งต้นถ้ายังไม่มี (ครั้งแรกของตารางนั้น)
    IF NOT EXISTS (SELECT 1 FROM dbo.tb_reference WITH (UPDLOCK, HOLDLOCK) WHERE ref_id = @TableName)
    BEGIN
        INSERT INTO dbo.tb_reference (ref_id, ref_int, ref_text, prefix, update_by)
        VALUES (@TableName, 0, N'A', N'REF', N'System');
    END

    -- UPDLOCK + HOLDLOCK = serialize เฉพาะแถวของตารางนี้ ตารางอื่นไม่ถูกบล็อก
    SELECT @cur    = ref_int,
           @Series = ISNULL(ref_text, N'A')
      FROM dbo.tb_reference WITH (UPDLOCK, HOLDLOCK)
     WHERE ref_id = @TableName;

    -- ขึ้น Series ใหม่เมื่อเลขรันนิ่งเต็ม 999999
    IF @cur + @BlockSize > 999999
    BEGIN
        IF @Series >= N'Z'
        BEGIN
            RAISERROR (N'USP_ALLOCATE_BUSINESS_ID_BLOCK: Series หมดที่ Z สำหรับตาราง %s', 16, 1, @TableName);
            RETURN;
        END
        SET @Series = NCHAR(UNICODE(@Series) + 1);
        SET @cur    = 0;
    END

    UPDATE dbo.tb_reference
       SET ref_int   = @cur + @BlockSize,
           ref_text  = @Series,
           update_by = N'System'
     WHERE ref_id = @TableName;

    SET @StartNo = @cur + 1;
END
GO

/* =====================================================================================
   SECTION 1 : ALTER ตารางเดิมของ v5 (เท่าที่ข้อ 1-3 ต้องใช้)
   ===================================================================================== */

-- 1.1 tb_vendor : branch_code สำหรับออกเอกสารภาษี/จ่ายเงินเจ้าของหนังสือ
IF COL_LENGTH(N'dbo.tb_vendor', N'branch_code') IS NULL
    ALTER TABLE [dbo].[tb_vendor] ADD [branch_code] [nvarchar](10) NULL;
GO

-- 1.2 tb_product_sku : จำเป็นต่อ 'ฉบับ' และรอบรับคืน (legacy: จำนวนเล่ม/มัด, ราคาปก)
IF COL_LENGTH(N'dbo.tb_product_sku', N'cover_price') IS NULL
    ALTER TABLE [dbo].[tb_product_sku] ADD [cover_price] [decimal](18, 4) NULL;
GO
IF COL_LENGTH(N'dbo.tb_product_sku', N'pack_qty') IS NULL
    ALTER TABLE [dbo].[tb_product_sku] ADD [pack_qty] [int] NULL;
GO
IF COL_LENGTH(N'dbo.tb_product_sku', N'publication_date') IS NULL
    ALTER TABLE [dbo].[tb_product_sku] ADD [publication_date] [date] NULL;
GO
IF COL_LENGTH(N'dbo.tb_product_sku', N'return_deadline') IS NULL
    ALTER TABLE [dbo].[tb_product_sku] ADD [return_deadline] [date] NULL;
GO

-- 1.3 tb_warehouse : เพิ่มคลังพักของคืนรอส่งเจ้าของหนังสือ (ตอบคำถามข้อ 2)
IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_warehouse] WHERE [warehouse_code] = N'RET')
    INSERT INTO [dbo].[tb_warehouse]
        ([prefix], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by])
    VALUES
        (N'WHS', N'RET', N'คลังรับคืนรอส่งเจ้าของ', N'พักหนังสือที่ร้านคืนกลับมา ก่อนออกใบส่งคืนเจ้าของหนังสือ', 0, 0, N'System');
GO

/* =====================================================================================
   SECTION 2 : CREATE TABLES
   ===================================================================================== */

/* ---------- Layer 6 : Route / สายจัดจำหน่าย ---------- */
/****** Object:  Table [dbo].[tb_route_type]  --  ประเภทสาย (สายเดิม / ภาค / สายรายวัน) ******/
IF OBJECT_ID(N'dbo.tb_route_type', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_route_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[route_type_id] [nvarchar](50) NULL,
	[type_code] [nvarchar](20) NOT NULL,
	[type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_route_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_route]  --  สายจัดจำหน่าย / เส้นทางส่ง ******/
IF OBJECT_ID(N'dbo.tb_route', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_route](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[route_id] [nvarchar](50) NULL,
	[ref_route_type_id] [nvarchar](50) NOT NULL,
	[route_code] [nvarchar](20) NOT NULL,
	[route_name] [nvarchar](150) NOT NULL,
	[ref_warehouse_id] [nvarchar](50) NULL,
	[region_name] [nvarchar](50) NULL,
	[sort_order] [int] NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_route] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_customer_route]  --  ผูกลูกค้ากับสาย (M:N + ลำดับจุดจอด) ******/
IF OBJECT_ID(N'dbo.tb_customer_route', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_customer_route](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_route_id] [nvarchar](50) NULL,
	[ref_customer_id] [nvarchar](50) NOT NULL,
	[ref_route_id] [nvarchar](50) NOT NULL,
	[is_primary] [bit] NOT NULL,
	[delivery_seq] [int] NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_customer_route] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* ---------- Layer 7 : Vendor Term / เงื่อนไขการค้า ---------- */
/****** Object:  Table [dbo].[tb_vendor_term]  --  เงื่อนไขการค้ากับคู่ค้า (ซื้อขาด/ฝากขาย + บัญชีธนาคาร) 1:1 กับ tb_vendor ******/
IF OBJECT_ID(N'dbo.tb_vendor_term', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_vendor_term](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_term_id] [nvarchar](50) NULL,
	[ref_vendor_id] [nvarchar](50) NOT NULL,
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
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor_term] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* ---------- Layer 8 : Stock / ยอดคงเหลือ ---------- */
/****** Object:  Table [dbo].[tb_product_stock]  --  ยอดคงเหลือ ต่อ SKU x คลัง ******/
IF OBJECT_ID(N'dbo.tb_product_stock', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_product_stock](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[stock_id] [nvarchar](50) NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
	[ref_warehouse_id] [nvarchar](50) NOT NULL,
	[qty_onhand] [decimal](18, 2) NOT NULL,
	[qty_reserved] [decimal](18, 2) NOT NULL,
	[last_movement_date] [datetime] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_available]  AS ([qty_onhand]-[qty_reserved]),
 CONSTRAINT [PK_tb_product_stock] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_consign_balance]  --  ยอดฝากขายคงค้างที่ร้าน ต่อ ลูกค้า x SKU ******/
IF OBJECT_ID(N'dbo.tb_consign_balance', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_consign_balance](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[consign_balance_id] [nvarchar](50) NULL,
	[ref_customer_id] [nvarchar](50) NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
	[qty_delivered] [decimal](18, 2) NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[last_order_date] [datetime] NULL,
	[last_return_date] [datetime] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_outstanding]  AS ([qty_delivered]-[qty_returned]),
 CONSTRAINT [PK_tb_consign_balance] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* ---------- Layer 9 : Transactions ---------- */
/****** Object:  Table [dbo].[tb_receive_note]  --  ใบรับหนังสือเข้าคลัง (Inbound Header) ******/
IF OBJECT_ID(N'dbo.tb_receive_note', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_receive_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[receive_note_id] [nvarchar](50) NULL,
	[doc_no] [nvarchar](30) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[ref_vendor_id] [nvarchar](50) NOT NULL,
	[ref_warehouse_id] [nvarchar](50) NOT NULL,
	[ref_company_id] [nvarchar](50) NULL,
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
 CONSTRAINT [PK_tb_receive_note] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_receive_item]  --  รายการในใบรับหนังสือ ******/
IF OBJECT_ID(N'dbo.tb_receive_item', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_receive_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[receive_item_id] [nvarchar](50) NULL,
	[ref_receive_note_id] [nvarchar](50) NOT NULL,
	[line_no] [int] NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
	[qty] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_cost] [decimal](18, 4) NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty]*isnull([unit_cost],(0))),
 CONSTRAINT [PK_tb_receive_item] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_order]  --  ใบส่งหนังสือ (Outbound Header) ******/
IF OBJECT_ID(N'dbo.tb_order', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_order](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[order_id] [nvarchar](50) NULL,
	[doc_no] [nvarchar](30) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[ref_customer_id] [nvarchar](50) NOT NULL,
	[ref_route_id] [nvarchar](50) NULL,
	[ref_warehouse_id] [nvarchar](50) NOT NULL,
	[ref_company_id] [nvarchar](50) NULL,
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
	[net_amount]  AS ([total_amount]-[discount_amount]),
 CONSTRAINT [PK_tb_order] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_order_item]  --  รายการในใบส่งหนังสือ ******/
IF OBJECT_ID(N'dbo.tb_order_item', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_order_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[order_item_id] [nvarchar](50) NULL,
	[ref_order_id] [nvarchar](50) NOT NULL,
	[line_no] [int] NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
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
	[amount]  AS ([qty_delivered]*[unit_price]),
 CONSTRAINT [PK_tb_order_item] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_return_note]  --  ใบรับคืนหนังสือจากร้าน ******/
IF OBJECT_ID(N'dbo.tb_return_note', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_return_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[return_note_id] [nvarchar](50) NULL,
	[doc_no] [nvarchar](30) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[ref_customer_id] [nvarchar](50) NOT NULL,
	[ref_route_id] [nvarchar](50) NULL,
	[ref_warehouse_id] [nvarchar](50) NOT NULL,
	[ref_order_id] [nvarchar](50) NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[period_key] [nvarchar](20) NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[credit_note_no] [nvarchar](30) NULL,
	[credit_note_date] [datetime] NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_return_note] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_return_item]  --  รายการในใบรับคืนจากร้าน ******/
IF OBJECT_ID(N'dbo.tb_return_item', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_return_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[return_item_id] [nvarchar](50) NULL,
	[ref_return_note_id] [nvarchar](50) NOT NULL,
	[line_no] [int] NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
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
	[amount]  AS ([qty_returned]*[unit_price]),
 CONSTRAINT [PK_tb_return_item] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_vendor_return_note]  --  ใบส่งคืนหนังสือให้เจ้าของหนังสือ ******/
IF OBJECT_ID(N'dbo.tb_vendor_return_note', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_vendor_return_note](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_return_note_id] [nvarchar](50) NULL,
	[doc_no] [nvarchar](30) NOT NULL,
	[doc_date] [datetime] NOT NULL,
	[ref_vendor_id] [nvarchar](50) NOT NULL,
	[ref_warehouse_id] [nvarchar](50) NOT NULL,
	[ref_company_id] [nvarchar](50) NULL,
	[doc_status] [nvarchar](20) NOT NULL,
	[total_qty] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 4) NOT NULL,
	[settlement_no] [nvarchar](30) NULL,
	[remark] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor_return_note] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Table [dbo].[tb_vendor_return_item]  --  รายการในใบส่งคืนเจ้าของหนังสือ ******/
IF OBJECT_ID(N'dbo.tb_vendor_return_item', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_vendor_return_item](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_return_item_id] [nvarchar](50) NULL,
	[ref_vendor_return_note_id] [nvarchar](50) NOT NULL,
	[line_no] [int] NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[cover_price] [decimal](18, 4) NULL,
	[unit_cost] [decimal](18, 4) NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[amount]  AS ([qty_returned]*[unit_cost]),
 CONSTRAINT [PK_tb_vendor_return_item] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* ---------- Layer 10 : Allocation History ---------- */
/****** Object:  Table [dbo].[tb_allocation_history]  --  ประวัติยอดส่ง/คืน ต่องวด — ต้นทางของ 'ดึงจากประวัติ' ******/
IF OBJECT_ID(N'dbo.tb_allocation_history', N'U') IS NULL
BEGIN
CREATE TABLE [dbo].[tb_allocation_history](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[allocation_history_id] [nvarchar](50) NULL,
	[ref_customer_id] [nvarchar](50) NOT NULL,
	[ref_sku_id] [nvarchar](50) NOT NULL,
	[ref_product_id] [nvarchar](50) NULL,
	[ref_route_id] [nvarchar](50) NULL,
	[period_key] [nvarchar](20) NOT NULL,
	[period_seq] [int] NULL,
	[issue_label] [nvarchar](50) NULL,
	[qty_allocated] [decimal](18, 2) NOT NULL,
	[qty_delivered] [decimal](18, 2) NOT NULL,
	[qty_returned] [decimal](18, 2) NOT NULL,
	[ref_order_id] [nvarchar](50) NULL,
	[is_locked] [bit] NOT NULL,
	[remark] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[qty_sold]  AS ([qty_delivered]-[qty_returned]),
	[sell_through_pct]  AS (case when [qty_delivered]>(0) then CONVERT([decimal](5,2),(([qty_delivered]-[qty_returned])*(100.0))/[qty_delivered]) else (0) end),
 CONSTRAINT [PK_tb_allocation_history] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* =====================================================================================
   SECTION 3 : DEFAULT CONSTRAINTS
   ===================================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_prefix')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_prefix] DEFAULT (N'RTT') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_update_by')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_update_date')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_is_active')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_is_delete')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_type_id_status')
    ALTER TABLE [dbo].[tb_route_type] ADD CONSTRAINT [DF_tb_route_type_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_prefix')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_prefix] DEFAULT (N'RTE') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_update_by')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_update_date')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_is_active')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_is_delete')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_route_id_status')
    ALTER TABLE [dbo].[tb_route] ADD CONSTRAINT [DF_tb_route_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_prefix')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_prefix] DEFAULT (N'CRT') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_update_by')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_update_date')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_is_active')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_is_delete')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_id_status')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_customer_route_is_primary')
    ALTER TABLE [dbo].[tb_customer_route] ADD CONSTRAINT [DF_tb_customer_route_is_primary] DEFAULT (0) FOR [is_primary];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_prefix')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_prefix] DEFAULT (N'VTM') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_update_by')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_update_date')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_is_active')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_is_delete')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_id_status')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_term_trade_type')
    ALTER TABLE [dbo].[tb_vendor_term] ADD CONSTRAINT [DF_tb_vendor_term_trade_type] DEFAULT (N'CONSIGN') FOR [trade_type];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_prefix')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_prefix] DEFAULT (N'STK') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_update_by')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_update_date')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_is_active')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_is_delete')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_id_status')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_qty_onhand')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_qty_onhand] DEFAULT (0) FOR [qty_onhand];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_product_stock_qty_reserved')
    ALTER TABLE [dbo].[tb_product_stock] ADD CONSTRAINT [DF_tb_product_stock_qty_reserved] DEFAULT (0) FOR [qty_reserved];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_prefix')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_prefix] DEFAULT (N'CSB') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_update_by')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_update_date')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_is_active')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_is_delete')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_id_status')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_qty_delivered')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_qty_delivered] DEFAULT (0) FOR [qty_delivered];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_consign_balance_qty_returned')
    ALTER TABLE [dbo].[tb_consign_balance] ADD CONSTRAINT [DF_tb_consign_balance_qty_returned] DEFAULT (0) FOR [qty_returned];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_prefix')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_prefix] DEFAULT (N'RCV') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_update_by')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_update_date')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_is_active')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_is_delete')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_id_status')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_doc_date')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_trade_type')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_trade_type] DEFAULT (N'CONSIGN') FOR [trade_type];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_doc_status')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_total_qty')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_total_qty] DEFAULT (0) FOR [total_qty];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_note_total_amount')
    ALTER TABLE [dbo].[tb_receive_note] ADD CONSTRAINT [DF_tb_receive_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_prefix')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_prefix] DEFAULT (N'RCI') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_update_by')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_update_date')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_is_active')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_is_delete')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_id_status')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_qty')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_qty] DEFAULT (0) FOR [qty];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_receive_item_unit_cost')
    ALTER TABLE [dbo].[tb_receive_item] ADD CONSTRAINT [DF_tb_receive_item_unit_cost] DEFAULT (0) FOR [unit_cost];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_prefix')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_prefix] DEFAULT (N'ORD') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_update_by')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_update_date')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_is_active')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_is_delete')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_id_status')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_doc_date')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_order_type')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_order_type] DEFAULT (N'CONSIGN') FOR [order_type];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_doc_status')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_total_qty')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_total_qty] DEFAULT (0) FOR [total_qty];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_total_amount')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_total_amount] DEFAULT (0) FOR [total_amount];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_discount_amount')
    ALTER TABLE [dbo].[tb_order] ADD CONSTRAINT [DF_tb_order_discount_amount] DEFAULT (0) FOR [discount_amount];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_prefix')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_prefix] DEFAULT (N'ODI') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_update_by')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_update_date')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_is_active')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_is_delete')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_id_status')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_qty_ordered')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_qty_ordered] DEFAULT (0) FOR [qty_ordered];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_qty_delivered')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_qty_delivered] DEFAULT (0) FOR [qty_delivered];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_order_item_unit_price')
    ALTER TABLE [dbo].[tb_order_item] ADD CONSTRAINT [DF_tb_order_item_unit_price] DEFAULT (0) FOR [unit_price];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_prefix')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_prefix] DEFAULT (N'RTN') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_update_by')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_update_date')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_is_active')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_is_delete')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_id_status')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_doc_date')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_doc_status')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_total_qty')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_total_qty] DEFAULT (0) FOR [total_qty];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_note_total_amount')
    ALTER TABLE [dbo].[tb_return_note] ADD CONSTRAINT [DF_tb_return_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_prefix')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_prefix] DEFAULT (N'RTI') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_update_by')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_update_date')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_is_active')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_is_delete')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_id_status')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_qty_returned')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_qty_returned] DEFAULT (0) FOR [qty_returned];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_unit_price')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_unit_price] DEFAULT (0) FOR [unit_price];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_return_item_condition_status')
    ALTER TABLE [dbo].[tb_return_item] ADD CONSTRAINT [DF_tb_return_item_condition_status] DEFAULT (N'GOOD') FOR [condition_status];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_prefix')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_prefix] DEFAULT (N'VRN') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_update_by')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_update_date')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_is_active')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_is_delete')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_id_status')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_doc_date')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_doc_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [doc_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_doc_status')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_doc_status] DEFAULT (N'DRAFT') FOR [doc_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_total_qty')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_total_qty] DEFAULT (0) FOR [total_qty];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_note_total_amount')
    ALTER TABLE [dbo].[tb_vendor_return_note] ADD CONSTRAINT [DF_tb_vendor_return_note_total_amount] DEFAULT (0) FOR [total_amount];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_prefix')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_prefix] DEFAULT (N'VRI') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_update_by')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_update_date')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_is_active')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_is_delete')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_id_status')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_qty_returned')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_qty_returned] DEFAULT (0) FOR [qty_returned];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_vendor_return_item_unit_cost')
    ALTER TABLE [dbo].[tb_vendor_return_item] ADD CONSTRAINT [DF_tb_vendor_return_item_unit_cost] DEFAULT (0) FOR [unit_cost];
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_prefix')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_prefix] DEFAULT (N'AHS') FOR [prefix];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_update_by')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_update_by] DEFAULT (N'System') FOR [update_by];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_update_date')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_update_date] DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_is_active')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_active] DEFAULT (1) FOR [is_active];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_is_delete')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_delete] DEFAULT (0) FOR [is_delete];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_id_status')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_id_status] DEFAULT (N'ACTIVE') FOR [id_status];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_qty_allocated')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_allocated] DEFAULT (0) FOR [qty_allocated];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_qty_delivered')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_delivered] DEFAULT (0) FOR [qty_delivered];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_qty_returned')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_qty_returned] DEFAULT (0) FOR [qty_returned];
GO
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = N'DF_tb_allocation_history_is_locked')
    ALTER TABLE [dbo].[tb_allocation_history] ADD CONSTRAINT [DF_tb_allocation_history_is_locked] DEFAULT (0) FOR [is_locked];
GO

/* =====================================================================================
   SECTION 4 : CHECK CONSTRAINTS (สถานะทางธุรกิจ)
   ===================================================================================== */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_vendor_term_trade_type')
    ALTER TABLE [dbo].[tb_vendor_term] WITH CHECK ADD CONSTRAINT [CK_tb_vendor_term_trade_type] CHECK ([trade_type] IN (N'BUY', N'CONSIGN'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_receive_note_status')
    ALTER TABLE [dbo].[tb_receive_note] WITH CHECK ADD CONSTRAINT [CK_tb_receive_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'CANCELLED'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_order_type')
    ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [CK_tb_order_type] CHECK ([order_type] IN (N'CONSIGN', N'SALE', N'TRANSFER'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_order_status')
    ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [CK_tb_order_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'DELIVERED', N'INVOICED', N'CANCELLED'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_return_note_status')
    ALTER TABLE [dbo].[tb_return_note] WITH CHECK ADD CONSTRAINT [CK_tb_return_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'CREDITED', N'CANCELLED'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_return_item_condition')
    ALTER TABLE [dbo].[tb_return_item] WITH CHECK ADD CONSTRAINT [CK_tb_return_item_condition] CHECK ([condition_status] IN (N'GOOD', N'DAMAGED'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_tb_vendor_return_note_status')
    ALTER TABLE [dbo].[tb_vendor_return_note] WITH CHECK ADD CONSTRAINT [CK_tb_vendor_return_note_status] CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'POSTED', N'SETTLED', N'CANCELLED'));
GO

/* =====================================================================================
   SECTION 5 : TRIGGERS
     5.x.1  TRIG_AUTO_UPDATE_DATE_<TABLE>   -- AFTER UPDATE : ประทับเวลา
     5.x.2  TRIG_GENERATE_<TABLE>_ID        -- AFTER INSERT : สร้าง Business ID (SET-BASED)
     5.x.3  TRIG_SYNC_STATUS_<TABLE>        -- AFTER UPDATE : บังคับ invariant ของ 3 status field
   ===================================================================================== */

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_ROUTE_TYPE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_ROUTE_TYPE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ROUTE_TYPE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ROUTE_TYPE]
ON [dbo].[tb_route_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_route_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_route_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_ROUTE_TYPE]
GO

/****** Trigger : TRIG_GENERATE_TB_ROUTE_TYPE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_ROUTE_TYPE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_ROUTE_TYPE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ROUTE_TYPE_ID]
ON [dbo].[tb_route_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [route_type_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_route_type', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [route_type_id] IS NULL
    )
    UPDATE t
       SET t.[route_type_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_route_type t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_route_type] ENABLE TRIGGER [TRIG_GENERATE_TB_ROUTE_TYPE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_ROUTE_TYPE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_ROUTE_TYPE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ROUTE_TYPE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ROUTE_TYPE]
ON [dbo].[tb_route_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_route_type t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_route_type] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_ROUTE_TYPE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_ROUTE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_ROUTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ROUTE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ROUTE]
ON [dbo].[tb_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_route t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_route] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_ROUTE]
GO

/****** Trigger : TRIG_GENERATE_TB_ROUTE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_ROUTE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_ROUTE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ROUTE_ID]
ON [dbo].[tb_route] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [route_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_route', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [route_id] IS NULL
    )
    UPDATE t
       SET t.[route_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_route t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_route] ENABLE TRIGGER [TRIG_GENERATE_TB_ROUTE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_ROUTE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_ROUTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ROUTE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ROUTE]
ON [dbo].[tb_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_route t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_route] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_ROUTE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE]
ON [dbo].[tb_customer_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_customer_route t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_customer_route] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER_ROUTE]
GO

/****** Trigger : TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID]
ON [dbo].[tb_customer_route] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [customer_route_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_customer_route', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [customer_route_id] IS NULL
    )
    UPDATE t
       SET t.[customer_route_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_customer_route t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_customer_route] ENABLE TRIGGER [TRIG_GENERATE_TB_CUSTOMER_ROUTE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE]
ON [dbo].[tb_customer_route] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_customer_route t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_customer_route] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_CUSTOMER_ROUTE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TERM ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TERM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TERM]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TERM]
ON [dbo].[tb_vendor_term] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_term t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_term] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TERM]
GO

/****** Trigger : TRIG_GENERATE_TB_VENDOR_TERM_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_VENDOR_TERM_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_TERM_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_TERM_ID]
ON [dbo].[tb_vendor_term] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_term_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_vendor_term', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [vendor_term_id] IS NULL
    )
    UPDATE t
       SET t.[vendor_term_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_term t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_term] ENABLE TRIGGER [TRIG_GENERATE_TB_VENDOR_TERM_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_VENDOR_TERM ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_VENDOR_TERM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_TERM]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_TERM]
ON [dbo].[tb_vendor_term] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_term t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_vendor_term] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_VENDOR_TERM]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK]
ON [dbo].[tb_product_stock] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_product_stock t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_product_stock] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_STOCK]
GO

/****** Trigger : TRIG_GENERATE_TB_PRODUCT_STOCK_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_PRODUCT_STOCK_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_STOCK_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_PRODUCT_STOCK_ID]
ON [dbo].[tb_product_stock] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [stock_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_product_stock', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [stock_id] IS NULL
    )
    UPDATE t
       SET t.[stock_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_product_stock t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_product_stock] ENABLE TRIGGER [TRIG_GENERATE_TB_PRODUCT_STOCK_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_PRODUCT_STOCK ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_PRODUCT_STOCK', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_STOCK]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_PRODUCT_STOCK]
ON [dbo].[tb_product_stock] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_product_stock t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_product_stock] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_PRODUCT_STOCK]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE]
ON [dbo].[tb_consign_balance] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_consign_balance t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_consign_balance] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_CONSIGN_BALANCE]
GO

/****** Trigger : TRIG_GENERATE_TB_CONSIGN_BALANCE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_CONSIGN_BALANCE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_CONSIGN_BALANCE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_CONSIGN_BALANCE_ID]
ON [dbo].[tb_consign_balance] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [consign_balance_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_consign_balance', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [consign_balance_id] IS NULL
    )
    UPDATE t
       SET t.[consign_balance_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_consign_balance t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_consign_balance] ENABLE TRIGGER [TRIG_GENERATE_TB_CONSIGN_BALANCE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE]
ON [dbo].[tb_consign_balance] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_consign_balance t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_consign_balance] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_CONSIGN_BALANCE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE]
ON [dbo].[tb_receive_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_receive_note] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_NOTE]
GO

/****** Trigger : TRIG_GENERATE_TB_RECEIVE_NOTE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_RECEIVE_NOTE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_NOTE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_NOTE_ID]
ON [dbo].[tb_receive_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [receive_note_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_receive_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [receive_note_id] IS NULL
    )
    UPDATE t
       SET t.[receive_note_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_receive_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_receive_note] ENABLE TRIGGER [TRIG_GENERATE_TB_RECEIVE_NOTE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_RECEIVE_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_RECEIVE_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_NOTE]
ON [dbo].[tb_receive_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_receive_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_receive_note] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_RECEIVE_NOTE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM]
ON [dbo].[tb_receive_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_receive_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_receive_item] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_RECEIVE_ITEM]
GO

/****** Trigger : TRIG_GENERATE_TB_RECEIVE_ITEM_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_RECEIVE_ITEM_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_ITEM_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RECEIVE_ITEM_ID]
ON [dbo].[tb_receive_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [receive_item_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_receive_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [receive_item_id] IS NULL
    )
    UPDATE t
       SET t.[receive_item_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_receive_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_receive_item] ENABLE TRIGGER [TRIG_GENERATE_TB_RECEIVE_ITEM_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_RECEIVE_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_RECEIVE_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RECEIVE_ITEM]
ON [dbo].[tb_receive_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_receive_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_receive_item] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_RECEIVE_ITEM]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_ORDER ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_ORDER', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER]
ON [dbo].[tb_order] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_order] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_ORDER]
GO

/****** Trigger : TRIG_GENERATE_TB_ORDER_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_ORDER_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ID]
ON [dbo].[tb_order] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [order_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_order', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [order_id] IS NULL
    )
    UPDATE t
       SET t.[order_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_order t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_order] ENABLE TRIGGER [TRIG_GENERATE_TB_ORDER_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_ORDER ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_ORDER', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER]
ON [dbo].[tb_order] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_order t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_order] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_ORDER]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM]
ON [dbo].[tb_order_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_order_item] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_ORDER_ITEM]
GO

/****** Trigger : TRIG_GENERATE_TB_ORDER_ITEM_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_ORDER_ITEM_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ITEM_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ITEM_ID]
ON [dbo].[tb_order_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [order_item_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_order_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [order_item_id] IS NULL
    )
    UPDATE t
       SET t.[order_item_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_order_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_order_item] ENABLE TRIGGER [TRIG_GENERATE_TB_ORDER_ITEM_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_ORDER_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_ORDER_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER_ITEM]
ON [dbo].[tb_order_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_order_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_order_item] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_ORDER_ITEM]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE]
ON [dbo].[tb_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_return_note] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_RETURN_NOTE]
GO

/****** Trigger : TRIG_GENERATE_TB_RETURN_NOTE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_RETURN_NOTE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_NOTE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_NOTE_ID]
ON [dbo].[tb_return_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [return_note_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_return_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [return_note_id] IS NULL
    )
    UPDATE t
       SET t.[return_note_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_return_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_return_note] ENABLE TRIGGER [TRIG_GENERATE_TB_RETURN_NOTE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_RETURN_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_RETURN_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_NOTE]
ON [dbo].[tb_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_return_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_return_note] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_RETURN_NOTE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM]
ON [dbo].[tb_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_return_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_return_item] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_RETURN_ITEM]
GO

/****** Trigger : TRIG_GENERATE_TB_RETURN_ITEM_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_RETURN_ITEM_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_ITEM_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_RETURN_ITEM_ID]
ON [dbo].[tb_return_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [return_item_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_return_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [return_item_id] IS NULL
    )
    UPDATE t
       SET t.[return_item_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_return_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_return_item] ENABLE TRIGGER [TRIG_GENERATE_TB_RETURN_ITEM_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_RETURN_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_RETURN_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_RETURN_ITEM]
ON [dbo].[tb_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_return_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_return_item] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_RETURN_ITEM]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE]
ON [dbo].[tb_vendor_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_note t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_return_note] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_NOTE]
GO

/****** Trigger : TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID]
ON [dbo].[tb_vendor_return_note] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_return_note_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_vendor_return_note', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [vendor_return_note_id] IS NULL
    )
    UPDATE t
       SET t.[vendor_return_note_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_return_note t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_return_note] ENABLE TRIGGER [TRIG_GENERATE_TB_VENDOR_RETURN_NOTE_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE]
ON [dbo].[tb_vendor_return_note] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_return_note t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_vendor_return_note] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_VENDOR_RETURN_NOTE]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM]
ON [dbo].[tb_vendor_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_vendor_return_item t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_return_item] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_VENDOR_RETURN_ITEM]
GO

/****** Trigger : TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID]
ON [dbo].[tb_vendor_return_item] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [vendor_return_item_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_vendor_return_item', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [vendor_return_item_id] IS NULL
    )
    UPDATE t
       SET t.[vendor_return_item_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_vendor_return_item t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_vendor_return_item] ENABLE TRIGGER [TRIG_GENERATE_TB_VENDOR_RETURN_ITEM_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM]
ON [dbo].[tb_vendor_return_item] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_vendor_return_item t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_vendor_return_item] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_VENDOR_RETURN_ITEM]
GO

/****** Trigger : TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY ******/
IF OBJECT_ID(N'dbo.TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY]
GO
CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY]
ON [dbo].[tb_allocation_history] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_allocation_history t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_allocation_history] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_ALLOCATION_HISTORY]
GO

/****** Trigger : TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID  (set-based) ******/
IF OBJECT_ID(N'dbo.TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID]
GO
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID]
ON [dbo].[tb_allocation_history] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard ที่นี่โดยตั้งใจ:
    -- ถ้า INSERT มาจาก proc/trigger อื่น (เช่น USP_POST_ORDER) ก็ยังต้องได้ Business ID

    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [allocation_history_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_allocation_history', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (
        SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
          FROM inserted WHERE [allocation_history_id] IS NULL
    )
    UPDATE t
       SET t.[allocation_history_id] = src.prefix + @series
                  + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_allocation_history t INNER JOIN src ON t.autoID = src.autoID;
END
GO
ALTER TABLE [dbo].[tb_allocation_history] ENABLE TRIGGER [TRIG_GENERATE_TB_ALLOCATION_HISTORY_ID]
GO

/****** Trigger : TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY ******/
IF OBJECT_ID(N'dbo.TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY', N'TR') IS NOT NULL DROP TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY]
GO
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY]
ON [dbo].[tb_allocation_history] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t
       SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_allocation_history t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
GO
ALTER TABLE [dbo].[tb_allocation_history] ENABLE TRIGGER [TRIG_SYNC_STATUS_TB_ALLOCATION_HISTORY]
GO

/* =====================================================================================
   SECTION 6 : INDEXES
     6.1  Business ID unique  (filtered : WHERE <id> IS NOT NULL)
     6.2  Natural key unique  (doc_no / composite)
     6.3  Foreign-key lookup indexes
   ===================================================================================== */

-- 6.1 Business ID
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_route_type_id' AND object_id = OBJECT_ID(N'dbo.tb_route_type'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_route_type_id] ON [dbo].[tb_route_type]([route_type_id]) WHERE [route_type_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_route_id' AND object_id = OBJECT_ID(N'dbo.tb_route'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_route_id] ON [dbo].[tb_route]([route_id]) WHERE [route_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_customer_route_id' AND object_id = OBJECT_ID(N'dbo.tb_customer_route'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_id] ON [dbo].[tb_customer_route]([customer_route_id]) WHERE [customer_route_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_term_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_term'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_term_id] ON [dbo].[tb_vendor_term]([vendor_term_id]) WHERE [vendor_term_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_product_stock_id' AND object_id = OBJECT_ID(N'dbo.tb_product_stock'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_stock_id] ON [dbo].[tb_product_stock]([stock_id]) WHERE [stock_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_consign_balance_id' AND object_id = OBJECT_ID(N'dbo.tb_consign_balance'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_consign_balance_id] ON [dbo].[tb_consign_balance]([consign_balance_id]) WHERE [consign_balance_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_receive_note_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_note_id] ON [dbo].[tb_receive_note]([receive_note_id]) WHERE [receive_note_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_receive_item_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_item_id] ON [dbo].[tb_receive_item]([receive_item_id]) WHERE [receive_item_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_order_id' AND object_id = OBJECT_ID(N'dbo.tb_order'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_id] ON [dbo].[tb_order]([order_id]) WHERE [order_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_order_item_id' AND object_id = OBJECT_ID(N'dbo.tb_order_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_item_id] ON [dbo].[tb_order_item]([order_item_id]) WHERE [order_item_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_return_note_id' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_note_id] ON [dbo].[tb_return_note]([return_note_id]) WHERE [return_note_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_return_item_id' AND object_id = OBJECT_ID(N'dbo.tb_return_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_item_id] ON [dbo].[tb_return_item]([return_item_id]) WHERE [return_item_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_return_note_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_note_id] ON [dbo].[tb_vendor_return_note]([vendor_return_note_id]) WHERE [vendor_return_note_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_return_item_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_item_id] ON [dbo].[tb_vendor_return_item]([vendor_return_item_id]) WHERE [vendor_return_item_id] IS NOT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_allocation_history_id' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_allocation_history_id] ON [dbo].[tb_allocation_history]([allocation_history_id]) WHERE [allocation_history_id] IS NOT NULL;
GO

-- 6.2 Natural key
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_customer_route_pair' AND object_id = OBJECT_ID(N'dbo.tb_customer_route'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_pair] ON [dbo].[tb_customer_route]([ref_customer_id],[ref_route_id]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_customer_route_primary' AND object_id = OBJECT_ID(N'dbo.tb_customer_route'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_route_primary] ON [dbo].[tb_customer_route]([ref_customer_id]) WHERE [is_delete] = 0 AND [is_primary] = 1;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_term_vendor' AND object_id = OBJECT_ID(N'dbo.tb_vendor_term'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_term_vendor] ON [dbo].[tb_vendor_term]([ref_vendor_id]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_product_stock_sku_wh' AND object_id = OBJECT_ID(N'dbo.tb_product_stock'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_stock_sku_wh] ON [dbo].[tb_product_stock]([ref_sku_id],[ref_warehouse_id]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_consign_balance_pair' AND object_id = OBJECT_ID(N'dbo.tb_consign_balance'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_consign_balance_pair] ON [dbo].[tb_consign_balance]([ref_customer_id],[ref_sku_id]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_receive_note_doc_no' AND object_id = OBJECT_ID(N'dbo.tb_receive_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_note_doc_no] ON [dbo].[tb_receive_note]([doc_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_receive_item_line' AND object_id = OBJECT_ID(N'dbo.tb_receive_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_receive_item_line] ON [dbo].[tb_receive_item]([ref_receive_note_id],[line_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_order_doc_no' AND object_id = OBJECT_ID(N'dbo.tb_order'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_doc_no] ON [dbo].[tb_order]([doc_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_order_item_line' AND object_id = OBJECT_ID(N'dbo.tb_order_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_order_item_line] ON [dbo].[tb_order_item]([ref_order_id],[line_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_return_note_doc_no' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_note_doc_no] ON [dbo].[tb_return_note]([doc_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_return_item_line' AND object_id = OBJECT_ID(N'dbo.tb_return_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_return_item_line] ON [dbo].[tb_return_item]([ref_return_note_id],[line_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_return_note_doc_no' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_note'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_note_doc_no] ON [dbo].[tb_vendor_return_note]([doc_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_vendor_return_item_line' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_item'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_return_item_line] ON [dbo].[tb_vendor_return_item]([ref_vendor_return_note_id],[line_no]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_tb_allocation_history_key' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_allocation_history_key] ON [dbo].[tb_allocation_history]([ref_customer_id],[ref_sku_id],[period_key]) WHERE [is_delete] = 0;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_allocation_history_lookup' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_lookup] ON [dbo].[tb_allocation_history]([ref_sku_id],[period_key]) INCLUDE ([ref_customer_id],[qty_delivered],[qty_returned]);
GO

-- 6.3 Foreign-key lookup
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_route_ref_route_type_id' AND object_id = OBJECT_ID(N'dbo.tb_route'))
    CREATE NONCLUSTERED INDEX [IX_tb_route_ref_route_type_id] ON [dbo].[tb_route]([ref_route_type_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_route_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_route'))
    CREATE NONCLUSTERED INDEX [IX_tb_route_ref_warehouse_id] ON [dbo].[tb_route]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_customer_route_ref_customer_id' AND object_id = OBJECT_ID(N'dbo.tb_customer_route'))
    CREATE NONCLUSTERED INDEX [IX_tb_customer_route_ref_customer_id] ON [dbo].[tb_customer_route]([ref_customer_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_customer_route_ref_route_id' AND object_id = OBJECT_ID(N'dbo.tb_customer_route'))
    CREATE NONCLUSTERED INDEX [IX_tb_customer_route_ref_route_id] ON [dbo].[tb_customer_route]([ref_route_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_product_stock_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_product_stock'))
    CREATE NONCLUSTERED INDEX [IX_tb_product_stock_ref_sku_id] ON [dbo].[tb_product_stock]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_product_stock_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_product_stock'))
    CREATE NONCLUSTERED INDEX [IX_tb_product_stock_ref_warehouse_id] ON [dbo].[tb_product_stock]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_consign_balance_ref_customer_id' AND object_id = OBJECT_ID(N'dbo.tb_consign_balance'))
    CREATE NONCLUSTERED INDEX [IX_tb_consign_balance_ref_customer_id] ON [dbo].[tb_consign_balance]([ref_customer_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_consign_balance_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_consign_balance'))
    CREATE NONCLUSTERED INDEX [IX_tb_consign_balance_ref_sku_id] ON [dbo].[tb_consign_balance]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_receive_note_ref_vendor_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_receive_note_ref_vendor_id] ON [dbo].[tb_receive_note]([ref_vendor_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_receive_note_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_receive_note_ref_warehouse_id] ON [dbo].[tb_receive_note]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_receive_item_ref_receive_note_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_receive_item_ref_receive_note_id] ON [dbo].[tb_receive_item]([ref_receive_note_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_receive_item_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_receive_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_receive_item_ref_sku_id] ON [dbo].[tb_receive_item]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_order_ref_customer_id' AND object_id = OBJECT_ID(N'dbo.tb_order'))
    CREATE NONCLUSTERED INDEX [IX_tb_order_ref_customer_id] ON [dbo].[tb_order]([ref_customer_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_order_ref_route_id' AND object_id = OBJECT_ID(N'dbo.tb_order'))
    CREATE NONCLUSTERED INDEX [IX_tb_order_ref_route_id] ON [dbo].[tb_order]([ref_route_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_order_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_order'))
    CREATE NONCLUSTERED INDEX [IX_tb_order_ref_warehouse_id] ON [dbo].[tb_order]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_order_item_ref_order_id' AND object_id = OBJECT_ID(N'dbo.tb_order_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_order_item_ref_order_id] ON [dbo].[tb_order_item]([ref_order_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_order_item_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_order_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_order_item_ref_sku_id] ON [dbo].[tb_order_item]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_note_ref_customer_id' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_customer_id] ON [dbo].[tb_return_note]([ref_customer_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_note_ref_route_id' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_route_id] ON [dbo].[tb_return_note]([ref_route_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_note_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_warehouse_id] ON [dbo].[tb_return_note]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_note_ref_order_id' AND object_id = OBJECT_ID(N'dbo.tb_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_note_ref_order_id] ON [dbo].[tb_return_note]([ref_order_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_item_ref_return_note_id' AND object_id = OBJECT_ID(N'dbo.tb_return_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_item_ref_return_note_id] ON [dbo].[tb_return_item]([ref_return_note_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_return_item_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_return_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_return_item_ref_sku_id] ON [dbo].[tb_return_item]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_vendor_return_note_ref_vendor_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_note_ref_vendor_id] ON [dbo].[tb_vendor_return_note]([ref_vendor_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_vendor_return_note_ref_warehouse_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_note'))
    CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_note_ref_warehouse_id] ON [dbo].[tb_vendor_return_note]([ref_warehouse_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_vendor_return_item_ref_vendor_return_note_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_item_ref_vendor_return_note_id] ON [dbo].[tb_vendor_return_item]([ref_vendor_return_note_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_vendor_return_item_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_vendor_return_item'))
    CREATE NONCLUSTERED INDEX [IX_tb_vendor_return_item_ref_sku_id] ON [dbo].[tb_vendor_return_item]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_allocation_history_ref_customer_id' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_customer_id] ON [dbo].[tb_allocation_history]([ref_customer_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_allocation_history_ref_sku_id' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_sku_id] ON [dbo].[tb_allocation_history]([ref_sku_id]);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tb_allocation_history_ref_route_id' AND object_id = OBJECT_ID(N'dbo.tb_allocation_history'))
    CREATE NONCLUSTERED INDEX [IX_tb_allocation_history_ref_route_id] ON [dbo].[tb_allocation_history]([ref_route_id]);
GO

/* =====================================================================================
   SECTION 7 : SEED DATA
   หมายเหตุ: ไม่ระบุ <table>_id / update_date / id_status — ปล่อยให้ Trigger + Default ทำงาน
   ===================================================================================== */

-- 7.1 ประเภทสาย : legacy มี 3 ระบบซ้อนกัน จึงทำเป็น type แทนที่จะ hard-code
IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_route_type] WHERE [type_code] = N'LEGACY_LINE')
INSERT INTO [dbo].[tb_route_type] ([prefix],[type_code],[type_name],[description],[update_by]) VALUES
 (N'RTT', N'LEGACY_LINE', N'สายจัดจำหน่ายเดิม',  N'สายที่ 1-5 ตามระบบเดิม',                 N'System'),
 (N'RTT', N'REGION',      N'ตามภาค',            N'กรุงเทพ / เหนือ / อีสาน / กลาง / ใต้ / ตะวันออก', N'System'),
 (N'RTT', N'DAILY',       N'สายจัดจำหน่ายรายวัน', N'สำหรับสิ่งพิมพ์รายวัน เช่น ทันหุ้น',        N'System');
GO

-- 7.2 สาย : ชุด REGION (ตรงกับหน้าจอปรับปรุงยอดส่งเดิม)
DECLARE @rtRegion NVARCHAR(50) = (SELECT route_type_id FROM [dbo].[tb_route_type] WHERE type_code = N'REGION');
DECLARE @whDC     NVARCHAR(50) = (SELECT warehouse_id  FROM [dbo].[tb_warehouse]  WHERE warehouse_code = N'DC');
DECLARE @whBKK    NVARCHAR(50) = (SELECT warehouse_id  FROM [dbo].[tb_warehouse]  WHERE warehouse_code = N'BKK');

IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_route] WHERE [route_code] = N'BKK')
INSERT INTO [dbo].[tb_route] ([prefix],[ref_route_type_id],[route_code],[route_name],[ref_warehouse_id],[region_name],[sort_order],[update_by]) VALUES
 (N'RTE', @rtRegion, N'BKK',  N'กรุงเทพ',      @whBKK, N'กลาง',      1, N'System'),
 (N'RTE', @rtRegion, N'NTH',  N'สายเหนือ',     @whDC,  N'เหนือ',     2, N'System'),
 (N'RTE', @rtRegion, N'NEA',  N'สายอีสาน',     @whDC,  N'อีสาน',     3, N'System'),
 (N'RTE', @rtRegion, N'STH',  N'สายใต้',       @whDC,  N'ใต้',       4, N'System'),
 (N'RTE', @rtRegion, N'EST',  N'สายตะวันออก',  @whDC,  N'ตะวันออก',  5, N'System');
GO

-- 7.3 สาย : ชุด LEGACY_LINE 1-5 (คงรหัสเดิมไว้เพื่อ map ข้อมูลเก่า)
DECLARE @rtLegacy NVARCHAR(50) = (SELECT route_type_id FROM [dbo].[tb_route_type] WHERE type_code = N'LEGACY_LINE');
DECLARE @whDC2    NVARCHAR(50) = (SELECT warehouse_id  FROM [dbo].[tb_warehouse]  WHERE warehouse_code = N'DC');

IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_route] WHERE [route_code] = N'L1')
INSERT INTO [dbo].[tb_route] ([prefix],[ref_route_type_id],[route_code],[route_name],[ref_warehouse_id],[sort_order],[update_by]) VALUES
 (N'RTE', @rtLegacy, N'L1', N'สายจัดจำหน่าย 1', @whDC2, 1, N'System'),
 (N'RTE', @rtLegacy, N'L2', N'สายจัดจำหน่าย 2', @whDC2, 2, N'System'),
 (N'RTE', @rtLegacy, N'L3', N'สายจัดจำหน่าย 3', @whDC2, 3, N'System'),
 (N'RTE', @rtLegacy, N'L4', N'สายจัดจำหน่าย 4', @whDC2, 4, N'System'),
 (N'RTE', @rtLegacy, N'L5', N'สายจัดจำหน่าย 5', @whDC2, 5, N'System');
GO

/* =====================================================================================
   SECTION 8 : BUSINESS PROCEDURES
   ===================================================================================== */

/* 8.1 -- USP_PULL_ALLOCATION_FROM_HISTORY  (ตอบข้อ 3 : "ดึงจากประวัติ")
   ดึงยอดส่งของงวดก่อนมาเป็นข้อเสนอสำหรับงวดใหม่ รองรับ 3 โหมด:
     LAST      = ใช้ยอดส่งงวดล่าสุด (พฤติกรรมเดิมของโปรแกรม legacy)
     AVG       = เฉลี่ยยอดส่ง N งวดล่าสุด
     SOLD      = ใช้ยอดขายสุทธิ (ส่ง - คืน) ของงวดล่าสุด  <-- แนะนำสำหรับฝากขาย
   คืนค่าเป็น result set ให้ API เอาไปแสดงก่อน แล้วผู้ใช้ค่อยปรับ (ไม่เขียนทับอัตโนมัติ) */
IF OBJECT_ID(N'dbo.USP_PULL_ALLOCATION_FROM_HISTORY', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[USP_PULL_ALLOCATION_FROM_HISTORY]
GO
CREATE PROCEDURE [dbo].[USP_PULL_ALLOCATION_FROM_HISTORY]
    @RefSkuID      NVARCHAR(50)  = NULL,   -- ฉบับที่จะจัดยอด (NULL = ทุก SKU ของ product)
    @RefProductID  NVARCHAR(50)  = NULL,   -- หรือระบุเป็นหัวหนังสือแทน
    @RefRouteID    NVARCHAR(50)  = NULL,   -- กรองเฉพาะสาย
    @Mode          NVARCHAR(10)  = N'SOLD',
    @LookbackCount INT           = 3
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH h AS (
        SELECT a.ref_customer_id, a.ref_sku_id, a.ref_route_id, a.period_key,
               a.qty_delivered, a.qty_returned, a.qty_sold,
               ROW_NUMBER() OVER (PARTITION BY a.ref_customer_id, a.ref_sku_id
                                  ORDER BY a.period_key DESC, a.period_seq DESC) AS rn
          FROM dbo.tb_allocation_history a
         WHERE a.is_delete = 0
           AND (@RefSkuID     IS NULL OR a.ref_sku_id     = @RefSkuID)
           AND (@RefProductID IS NULL OR a.ref_product_id = @RefProductID)
           AND (@RefRouteID   IS NULL OR a.ref_route_id   = @RefRouteID)
    )
    SELECT  h.ref_customer_id,
            c.customer_name,
            h.ref_sku_id,
            h.ref_route_id,
            MAX(CASE WHEN h.rn = 1 THEN h.period_key    END) AS last_period_key,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_delivered END) AS last_qty_delivered,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_returned  END) AS last_qty_returned,
            MAX(CASE WHEN h.rn = 1 THEN h.qty_sold      END) AS last_qty_sold,
            CAST(AVG(h.qty_delivered) AS DECIMAL(18,2))      AS avg_qty_delivered,
            CAST(AVG(h.qty_sold)      AS DECIMAL(18,2))      AS avg_qty_sold,
            CAST(
              CASE @Mode
                WHEN N'LAST' THEN MAX(CASE WHEN h.rn = 1 THEN h.qty_delivered END)
                WHEN N'AVG'  THEN AVG(h.qty_delivered)
                ELSE              MAX(CASE WHEN h.rn = 1 THEN h.qty_sold END)
              END AS DECIMAL(18,2))                          AS suggested_qty
      FROM h
      LEFT JOIN dbo.tb_customer c
             ON c.customer_id = h.ref_customer_id AND c.is_delete = 0
     WHERE h.rn <= @LookbackCount
     GROUP BY h.ref_customer_id, c.customer_name, h.ref_sku_id, h.ref_route_id
     ORDER BY c.customer_name;
END
GO

/* 8.2 -- USP_POST_ORDER : ยืนยันใบส่ง -> ตัดสต็อก + เพิ่มยอดฝากขาย + บันทึกประวัติ
   ทำเป็น proc เดียวเพื่อให้ 3 อย่างนี้เกิดพร้อมกันเสมอ (atomic)
   API ฝั่ง Go เรียก proc นี้ตัวเดียว ไม่ต้องรู้ลำดับ */
IF OBJECT_ID(N'dbo.USP_POST_ORDER', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[USP_POST_ORDER]
GO
CREATE PROCEDURE [dbo].[USP_POST_ORDER]
    @RefOrderID NVARCHAR(50),
    @UpdateBy   NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @wh NVARCHAR(50), @cus NVARCHAR(50), @period NVARCHAR(20),
            @route NVARCHAR(50), @status NVARCHAR(20), @docDate DATETIME;

    SELECT @wh = ref_warehouse_id, @cus = ref_customer_id, @period = period_key,
           @route = ref_route_id, @status = doc_status, @docDate = doc_date
      FROM dbo.tb_order WHERE order_id = @RefOrderID AND is_delete = 0;

    IF @wh IS NULL
    BEGIN
        RAISERROR (N'USP_POST_ORDER: ไม่พบใบส่ง %s', 16, 1, @RefOrderID); RETURN;
    END
    IF @status <> N'CONFIRMED'
    BEGIN
        RAISERROR (N'USP_POST_ORDER: ใบส่ง %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @RefOrderID, @status);
        RETURN;
    END

    -- ตรวจสต็อกก่อนตัด (ยกเว้นคลังที่อนุญาตติดลบ เช่น INT)
    IF NOT EXISTS (SELECT 1 FROM dbo.tb_warehouse
                    WHERE warehouse_id = @wh AND ISNULL(allow_negative_stock, 0) = 1)
    BEGIN
        DECLARE @shortSku NVARCHAR(50);
        SELECT TOP 1 @shortSku = i.ref_sku_id
          FROM (SELECT ref_sku_id, SUM(qty_delivered) AS q
                  FROM dbo.tb_order_item
                 WHERE ref_order_id = @RefOrderID AND is_delete = 0
                 GROUP BY ref_sku_id) i
          LEFT JOIN dbo.tb_product_stock s
                 ON s.ref_sku_id = i.ref_sku_id AND s.ref_warehouse_id = @wh AND s.is_delete = 0
         WHERE ISNULL(s.qty_onhand, 0) < i.q;

        IF @shortSku IS NOT NULL
        BEGIN
            RAISERROR (N'USP_POST_ORDER: สต็อกไม่พอสำหรับ SKU %s ที่คลัง %s', 16, 1, @shortSku, @wh);
            RETURN;
        END
    END

    BEGIN TRAN;

        -- (1) ตัดสต็อกคลังต้นทาง
        MERGE dbo.tb_product_stock AS s
        USING (SELECT ref_sku_id, SUM(qty_delivered) AS q
                 FROM dbo.tb_order_item
                WHERE ref_order_id = @RefOrderID AND is_delete = 0
                GROUP BY ref_sku_id) AS i
           ON s.ref_sku_id = i.ref_sku_id AND s.ref_warehouse_id = @wh AND s.is_delete = 0
        WHEN MATCHED THEN
            UPDATE SET s.qty_onhand = s.qty_onhand - i.q,
                       s.last_movement_date = @docDate,
                       s.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_sku_id, ref_warehouse_id, qty_onhand, qty_reserved, last_movement_date, update_by)
            VALUES (N'STK', i.ref_sku_id, @wh, -i.q, 0, @docDate, @UpdateBy);

        -- (2) เพิ่มยอดฝากขายคงค้างที่ร้าน
        MERGE dbo.tb_consign_balance AS b
        USING (SELECT ref_sku_id, SUM(qty_delivered) AS q
                 FROM dbo.tb_order_item
                WHERE ref_order_id = @RefOrderID AND is_delete = 0
                GROUP BY ref_sku_id) AS i
           ON b.ref_customer_id = @cus AND b.ref_sku_id = i.ref_sku_id AND b.is_delete = 0
        WHEN MATCHED THEN
            UPDATE SET b.qty_delivered = b.qty_delivered + i.q,
                       b.last_order_date = @docDate,
                       b.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_customer_id, ref_sku_id, qty_delivered, qty_returned, last_order_date, update_by)
            VALUES (N'CSB', @cus, i.ref_sku_id, i.q, 0, @docDate, @UpdateBy);

        -- (3) บันทึกประวัติงวด (ต้นทางของ "ดึงจากประวัติ")
        IF @period IS NOT NULL
        MERGE dbo.tb_allocation_history AS a
        USING (SELECT oi.ref_sku_id,
                      SUM(oi.qty_ordered)   AS qa,
                      SUM(oi.qty_delivered) AS qd
                 FROM dbo.tb_order_item oi
                WHERE oi.ref_order_id = @RefOrderID AND oi.is_delete = 0
                GROUP BY oi.ref_sku_id) AS i
           ON a.ref_customer_id = @cus AND a.ref_sku_id = i.ref_sku_id
          AND a.period_key = @period AND a.is_delete = 0
        WHEN MATCHED AND a.is_locked = 0 THEN
            UPDATE SET a.qty_allocated = i.qa, a.qty_delivered = i.qd,
                       a.ref_order_id = @RefOrderID, a.ref_route_id = @route,
                       a.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_customer_id, ref_sku_id, ref_route_id, period_key,
                    qty_allocated, qty_delivered, qty_returned, ref_order_id, is_locked, update_by)
            VALUES (N'AHS', @cus, i.ref_sku_id, @route, @period,
                    i.qa, i.qd, 0, @RefOrderID, 0, @UpdateBy);

        -- (4) ปิดสถานะเอกสาร
        UPDATE dbo.tb_order
           SET doc_status = N'DELIVERED', delivered_date = @docDate, update_by = @UpdateBy
         WHERE order_id = @RefOrderID;

    COMMIT TRAN;
END
GO

/* 8.3 -- USP_POST_RETURN : ยืนยันใบรับคืนจากร้าน
   ของดี  -> เข้าคลัง RET (รอส่งคืนเจ้าของหนังสือ)
   ของเสีย -> เข้าคลัง DMG
   พร้อมลดยอดฝากขายคงค้าง และอัปเดตประวัติงวด */
IF OBJECT_ID(N'dbo.USP_POST_RETURN', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[USP_POST_RETURN]
GO
CREATE PROCEDURE [dbo].[USP_POST_RETURN]
    @RefReturnNoteID NVARCHAR(50),
    @UpdateBy        NVARCHAR(50) = N'System'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @cus NVARCHAR(50), @period NVARCHAR(20), @status NVARCHAR(20), @docDate DATETIME;
    DECLARE @whRET NVARCHAR(50) = (SELECT warehouse_id FROM dbo.tb_warehouse WHERE warehouse_code = N'RET');
    DECLARE @whDMG NVARCHAR(50) = (SELECT warehouse_id FROM dbo.tb_warehouse WHERE warehouse_code = N'DMG');

    SELECT @cus = ref_customer_id, @period = period_key,
           @status = doc_status, @docDate = doc_date
      FROM dbo.tb_return_note WHERE return_note_id = @RefReturnNoteID AND is_delete = 0;

    IF @cus IS NULL
    BEGIN
        RAISERROR (N'USP_POST_RETURN: ไม่พบใบรับคืน %s', 16, 1, @RefReturnNoteID); RETURN;
    END
    IF @status <> N'CONFIRMED'
    BEGIN
        RAISERROR (N'USP_POST_RETURN: ใบรับคืน %s ต้องอยู่สถานะ CONFIRMED (ปัจจุบัน %s)', 16, 1, @RefReturnNoteID, @status);
        RETURN;
    END

    BEGIN TRAN;

        -- (1) รับเข้าคลังตามสภาพสินค้า
        MERGE dbo.tb_product_stock AS s
        USING (SELECT ri.ref_sku_id,
                      CASE WHEN ri.condition_status = N'DAMAGED' THEN @whDMG ELSE @whRET END AS wh,
                      SUM(ri.qty_returned) AS q
                 FROM dbo.tb_return_item ri
                WHERE ri.ref_return_note_id = @RefReturnNoteID AND ri.is_delete = 0
                GROUP BY ri.ref_sku_id, CASE WHEN ri.condition_status = N'DAMAGED' THEN @whDMG ELSE @whRET END) AS i
           ON s.ref_sku_id = i.ref_sku_id AND s.ref_warehouse_id = i.wh AND s.is_delete = 0
        WHEN MATCHED THEN
            UPDATE SET s.qty_onhand = s.qty_onhand + i.q,
                       s.last_movement_date = @docDate, s.update_by = @UpdateBy
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (prefix, ref_sku_id, ref_warehouse_id, qty_onhand, qty_reserved, last_movement_date, update_by)
            VALUES (N'STK', i.ref_sku_id, i.wh, i.q, 0, @docDate, @UpdateBy);

        -- (2) ลดยอดฝากขายคงค้าง
        UPDATE b
           SET b.qty_returned    = b.qty_returned + i.q,
               b.last_return_date = @docDate,
               b.update_by       = @UpdateBy
          FROM dbo.tb_consign_balance b
          INNER JOIN (SELECT ref_sku_id, SUM(qty_returned) AS q
                        FROM dbo.tb_return_item
                       WHERE ref_return_note_id = @RefReturnNoteID AND is_delete = 0
                       GROUP BY ref_sku_id) i
                  ON i.ref_sku_id = b.ref_sku_id
         WHERE b.ref_customer_id = @cus AND b.is_delete = 0;

        -- (3) อัปเดตประวัติงวด
        IF @period IS NOT NULL
        UPDATE a
           SET a.qty_returned = a.qty_returned + i.q, a.update_by = @UpdateBy
          FROM dbo.tb_allocation_history a
          INNER JOIN (SELECT ref_sku_id, SUM(qty_returned) AS q
                        FROM dbo.tb_return_item
                       WHERE ref_return_note_id = @RefReturnNoteID AND is_delete = 0
                       GROUP BY ref_sku_id) i
                  ON i.ref_sku_id = a.ref_sku_id
         WHERE a.ref_customer_id = @cus AND a.period_key = @period
           AND a.is_delete = 0 AND a.is_locked = 0;

        UPDATE dbo.tb_return_note
           SET doc_status = N'POSTED', update_by = @UpdateBy
         WHERE return_note_id = @RefReturnNoteID;

    COMMIT TRAN;
END
GO

/* =====================================================================================
   SECTION 9 : ข้อสังเกตที่ต้องอ่านก่อนใช้งานจริง
   -------------------------------------------------------------------------------------
   9.1  ทำไม v6 ยังไม่มี FOREIGN KEY
        Business ID (customer_id, sku_id, ...) เป็น NULL ตอน INSERT แล้วให้ Trigger เติมทีหลัง
        จึงต้องใช้ FILTERED UNIQUE INDEX (WHERE ... IS NOT NULL) ซึ่ง SQL Server
        "ไม่ยอมให้ใช้รองรับ FOREIGN KEY" -> ผูก FK บน business id ไม่ได้ทั้งระบบ
        ทางเลือกในอนาคต (แนะนำสำหรับ v7):
          (ก) ให้ Transaction Layer อ้าง autoID แทน business id  (ผูก FK ได้ทันที)
          (ข) เปลี่ยนไปสร้าง ID ใน INSTEAD OF INSERT trigger เพื่อให้คอลัมน์เป็น NOT NULL ได้
        v6 จึงใช้ index + CHECK + stored procedure คุมความถูกต้องแทนไปก่อน

   9.2  ID Trigger เป็น SET-BASED
        v5 ใช้ CURSOR + EXEC ทีละแถว -> ใบส่ง 500 บรรทัด = แตะ tb_reference 500 ครั้ง
        v6 จองเลขเป็นบล็อกครั้งเดียวแล้วแจกด้วย ROW_NUMBER()
        รูปแบบ ID เหมือนเดิมทุกประการ: <PREFIX><SERIES A-Z><NNNNNN>

   9.3  สมมติฐานที่ผมตั้งไว้ (ถ้าไม่ตรง แก้ตรงนี้ก่อนอย่างอื่น)
        - ข้อ 1 : "สาย" = เขตการขาย/เส้นทางส่ง ที่ลูกค้า 1 ราย อยู่ได้หลายสาย
                  แต่มี "สายหลัก" ได้เพียงสายเดียว (บังคับด้วย UQ_tb_customer_route_primary)
        - ข้อ 2 : ฝากขาย -> ส่งของออกบิลเต็ม แล้วออกใบลดหนี้ตอนคืน
                  จ่ายเจ้าของหนังสือตามยอดขายสุทธิ (ส่ง - คืน)
                  ของที่ร้านคืน เข้าคลัง RET (ของดี) หรือ DMG (ของเสีย) ไม่กลับเข้า DC
        - ข้อ 3 : "ดึงจากประวัติ" default = ยอดขายสุทธิงวดล่าสุด (Mode = SOLD)
                  ไม่เขียนทับอัตโนมัติ คืนเป็นข้อเสนอให้ผู้ใช้ปรับก่อน

   9.4  ยังไม่ได้ทำใน v6 (รอคำตอบข้อ 4-14)
        - โครงราคา/ส่วนลดหลายชั้น (tb_price_rule)
        - RBAC + History Log + Configuration
        - Invoice / Credit Note / Settlement เต็มรูปแบบ
        - ref_company_id บนตาราง master (รอคำตอบเรื่อง 11/21)
   ===================================================================================== */
