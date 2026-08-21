-- =============================================================
-- PenbunSQL v5.0.0 — Full Database Schema
-- Database: PENBUN
-- Generated: 2026-07-03
-- Architect: PlayDevX
-- 
-- v5 Change Log:
--   * Added: missing triggers for tb_book, tb_book_type (auto-update-date + generate-ID)
--   * Fixed: tb_users common fields changed from NULL to NOT NULL
--   * Fixed: tb_reference data types (varchar→nvarchar), prefix+update_date→NOT NULL
--   * Fixed: TRIG_AUTO_UPDATE_DATE_USERS now AFTER UPDATE only (INSERT uses DEFAULT)
--   * Fixed: Removed broken TRIG_AUTO_UPDATE_DATE on tb_reference (was referencing non-existent row_id)
--   * Fixed: Removed duplicate TRG_tb_customer_type_Update (superseded by TRIG_AUTO_UPDATE_DATE_tb_customer_type)
--   * Fixed: Replaced GETDATE() with SE Asia Standard Time in TRG_tb_reference_Update, TRIG_AUTO_UPDATE_DATE_USERS
--   * Fixed: Added missing SET NOCOUNT ON / NESTLEVEL guards to 5 triggers
--   * Added: Business ID unique indexes (18 tables) per Section 6.1
--   * Added: Foreign Key indexes (9 FK columns) per Section 6.1
-- =============================================================
USE [PENBUN]
GO
/****** Object:  Table [dbo].[tb_book]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_book](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[book_id] [nvarchar](50) NULL,
	[book_name] [nvarchar](255) NOT NULL,
	[author] [nvarchar](255) NULL,
	[price] [decimal](18, 4) NULL,
	[is_active] [bit] NOT NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_book] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_book_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_book_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[book_type_id] [nvarchar](50) NULL,
	[type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](250) NULL,
	[is_active] [bit] NOT NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_book_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_company]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 CONSTRAINT [PK_tb_company] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_customer]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_customer](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_id] [nvarchar](50) NULL,
	[customer_type_id] [nvarchar](50) NOT NULL,
	[customer_name] [nvarchar](200) NOT NULL,
	[tax_id] [nvarchar](20) NULL,
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
	[note] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_customer] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_customer_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_customer_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[customer_type_id] [nvarchar](50) NULL,
	[type_name] [nvarchar](255) NOT NULL,
	[description] [nvarchar](1000) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[base_credit_day] [int] NULL,
 CONSTRAINT [pk_tb_customer_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_discount]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_discount](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[discount_id] [nvarchar](50) NULL,
	[discount_type_id] [nvarchar](50) NOT NULL,
	[discount_name] [nvarchar](150) NOT NULL,
	[discount_code] [nvarchar](20) NULL,
	[description] [nvarchar](500) NULL,
	[discount_value] [decimal](18, 4) NOT NULL,
	[is_percent] [bit] NOT NULL,
	[min_order_amount] [decimal](18, 4) NULL,
	[start_date] [datetime] NULL,
	[end_date] [datetime] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_discount] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_discount_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 CONSTRAINT [PK_tb_discount_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_product]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_product](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_id] [nvarchar](50) NULL,
	[product_code] [nvarchar](50) NOT NULL,
	[product_name] [nvarchar](255) NOT NULL,
	[product_group_id] [nvarchar](50) NOT NULL,
	[product_format_type_id] [nvarchar](50) NULL,
	[unit_type_id] [nvarchar](50) NULL,
	[vendor_id] [nvarchar](50) NULL,
	[count_stock] [bit] NOT NULL,
	[cost_price] [decimal](18, 4) NULL,
	[sell_price] [decimal](18, 4) NULL,
	[barcode] [nvarchar](50) NULL,
	[weight_kg] [decimal](10, 2) NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_product_category]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 CONSTRAINT [PK_tb_product_category] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_product_format_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 CONSTRAINT [PK_tb_product_format_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_product_group]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_product_group](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[product_group_id] [nvarchar](50) NULL,
	[product_category_id] [nvarchar](50) NOT NULL,
	[product_group_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_group] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_product_sku]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_product_sku](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[sku_id] [nvarchar](50) NULL,
	[ref_product_id] [nvarchar](50) NOT NULL,
	[barcode] [nvarchar](50) NULL,
	[vendor_part_no] [nvarchar](50) NULL,
	[variation_name] [nvarchar](100) NULL,
	[issue_no] [nvarchar](50) NULL,
	[volume_no] [nvarchar](50) NULL,
	[edition_label] [nvarchar](50) NULL,
	[cost_price] [decimal](18, 4) NOT NULL,
	[sell_price] [decimal](18, 4) NOT NULL,
	[description] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_product_sku] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_reference]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_reference](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[ref_id] [varchar](50) NOT NULL,
	[ref_int] [int] NULL,
	[ref_text] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NULL,
	[update_date] [datetime] NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_reference] PRIMARY KEY CLUSTERED 
(
	[ref_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_unit_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_unit_type](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[unit_type_id] [nvarchar](50) NULL,
	[unit_type_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](255) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[is_active] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [pk_tb_unit_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_users]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_users](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[user_name] [nvarchar](50) NOT NULL,
	[user_password] [nvarchar](255) NOT NULL,
	[user_level] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[user_id] [nvarchar](50) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_vendor]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_vendor](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[vendor_id] [nvarchar](50) NULL,
	[vendor_type_id] [nvarchar](50) NOT NULL,
	[vendor_name] [nvarchar](150) NOT NULL,
	[tax_id] [nvarchar](20) NULL,
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
	[note] [nvarchar](max) NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_tb_vendor] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_vendor_type]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
 CONSTRAINT [PK_tb_vendor_type] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tb_warehouse]    Script Date: 2026-06-17 2:45:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_warehouse](
	[autoID] [int] IDENTITY(1,1) NOT NULL,
	[prefix] [nvarchar](3) NOT NULL,
	[warehouse_id] [nvarchar](50) NULL,
	[warehouse_code] [nvarchar](20) NOT NULL,
	[warehouse_name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](255) NULL,
	[is_main_dc] [bit] NULL,
	[allow_negative_stock] [bit] NULL,
	[update_by] [nvarchar](50) NOT NULL,
	[update_date] [datetime] NOT NULL,
	[is_active] [bit] NOT NULL,
	[is_delete] [bit] NOT NULL,
	[id_status] [nvarchar](20) NOT NULL,
	[location]  AS ([description]),
 CONSTRAINT [PK_tb_warehouse] PRIMARY KEY CLUSTERED 
(
	[autoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[tb_company] ON 

INSERT [dbo].[tb_company] ([autoID], [prefix], [company_id], [company_code], [name_th], [name_en], [description], [tax_id], [branch_code], [contact_person], [phone], [mobile], [fax], [email], [website], [line_id], [address], [sub_district], [district], [province], [zip_code], [logo_url], [vat_rate], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'CPN', N'CPNA000001', N'PENBUN-HQ', N'บริษัท เพ็ญบุญจัดจำหน่าย จำกัด', NULL, N'หนังสือ-นิตยสาร-ผู้จำหน่ายและจัดจำหน่าย', N'0105535145491', N'00000', N'คุณอภิวัฒน์ (Aphiwat Tamrongtanyalak)', N'02-278-0709', N'02-278-0709', NULL, NULL, NULL, NULL, N'เลขที่ 5, ซอยประดิพัทธ์ 23 ถนนประดิพัทธ์', N'สามเสนใน', N'พญาไท', N'กรุงเทพมหานคร', N'10400', NULL, CAST(7.00 AS Decimal(10, 2)), N'System', CAST(N'2025-12-17T02:35:26.637' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_company] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_customer] ON 

INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'CUS', N'CUSA000001', N'CUTA000001', N'ลูกค้าทั่วไป (Walk-in)', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'System', CAST(N'2025-12-08T22:52:25.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'CUS', N'CUSA000002', N'CUTA000001', N'คุณสมชาย ใจดี (ลูกค้าขาจร)', NULL, NULL, NULL, N'081-111-2222', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'System', CAST(N'2025-12-08T22:52:25.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'CUS', N'CUSA000003', N'CUTA000001', N'คุณวินัย ขับรถรับจ้าง', NULL, NULL, NULL, N'089-999-8888', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'System', CAST(N'2025-12-08T22:52:25.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'CUS', N'CUSA000004', N'CUTA000001', N'Guest Online User', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'System', CAST(N'2025-12-08T22:52:25.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'CUS', N'CUSA000005', N'CUTA000001', N'คุณป้าข้างบ้าน', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'System', CAST(N'2025-12-08T22:52:25.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'CUS', N'CUSA000006', N'CUTA000003', N'คุณวิภาดา รักการอ่าน', NULL, NULL, NULL, N'089-555-6666', N'089-555-6666', N'wipada.read@email.com', NULL, N'55/8 หมู่บ้านมัณฑนา', N'ดอกไม้', N'ประเวศ', N'กรุงเทพมหานคร', N'10250', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff01', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'CUS', N'CUSA000007', N'CUTA000003', N'คุณเอกภพ ชอบเรียนรู้', NULL, NULL, NULL, N'090-123-4567', N'090-123-4567', N'ekkapop@email.com', NULL, N'คอนโดลุมพินี รามคำแหง', N'หัวหมาก', N'บางกะปิ', N'กรุงเทพมหานคร', N'10240', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff01', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'CUS', N'CUSA000008', N'CUTA000003', N'คุณสุดาพร สอนใจ', NULL, NULL, NULL, N'081-234-5678', NULL, N'suda.p@email.com', NULL, N'123 ถ.สุขุมวิท 71', N'พระโขนงเหนือ', N'วัฒนา', N'กรุงเทพมหานคร', N'10110', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff01', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'CUS', N'CUSA000009', N'CUTA000003', N'นายแพทย์สมเกียรติ', NULL, NULL, NULL, N'082-345-6789', NULL, N'dr.somkiat@hospital.com', NULL, N'รพ.เอกชนชื่อดัง', N'คลองตัน', N'คลองเตย', N'กรุงเทพมหานคร', N'10110', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff02', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'CUS', N'CUSA000010', N'CUTA000003', N'คุณครูมานะ อดทน', NULL, NULL, NULL, N'083-456-7890', NULL, N'mana.teacher@school.ac.th', NULL, N'โรงเรียนวัดลิงขบ', N'บางยี่ขัน', N'บางพลัด', N'กรุงเทพมหานคร', N'10700', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff02', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'CUS', N'CUSA000011', N'CUTA000003', N'น้องพลอย เด็กเรียน', NULL, NULL, NULL, N'084-567-8901', NULL, N'ploy.study@student.com', NULL, N'หอพักนักศึกษาจุฬาฯ', N'วังใหม่', N'ปทุมวัน', N'กรุงเทพมหานคร', N'10330', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff01', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'CUS', N'CUSA000012', N'CUTA000003', N'คุณลุงบุญมี มีบุญ', NULL, NULL, NULL, N'085-678-9012', NULL, NULL, NULL, N'บ้านสวนนนทบุรี', N'บางกร่าง', N'เมืองนนทบุรี', N'นนทบุรี', N'11000', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff01', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'CUS', N'CUSA000013', N'CUTA000003', N'คุณเจนนี่ Blackpink (FC)', NULL, NULL, NULL, N'086-789-0123', NULL, N'jenny.fc@email.com', NULL, N'คอนโดหรูริมแม่น้ำ', N'คลองต้นไทร', N'คลองสาน', N'กรุงเทพมหานคร', N'10600', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff03', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'CUS', N'CUSA000014', N'CUTA000003', N'คุณธนาธร นักธุรกิจรุ่นใหม่', NULL, NULL, NULL, N'087-890-1234', NULL, N'thanatorn@start-up.com', NULL, N'Co-working Space อารีย์', N'พญาไท', N'พญาไท', N'กรุงเทพมหานคร', N'10400', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff03', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'CUS', N'CUSA000015', N'CUTA000003', N'คุณกรรชัย ข่าวใส่ไข่', NULL, NULL, NULL, N'088-901-2345', NULL, N'kanchai.news@tv.com', NULL, N'สถานีโทรทัศน์ช่องหนึ่ง', N'จอมพล', N'จตุจักร', N'กรุงเทพมหานคร', N'10900', CAST(0.00 AS Decimal(18, 2)), 0, NULL, N'Staff03', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'CUS', N'CUSA000016', N'CUTA000006', N'ดร.สมศักดิ์ ผู้เชี่ยวชาญ', NULL, NULL, NULL, N'081-987-6543', NULL, N'somsak.phd@univ.ac.th', NULL, NULL, NULL, NULL, NULL, NULL, CAST(50000.00 AS Decimal(18, 2)), 30, NULL, N'Manager', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'CUS', N'CUSA000017', N'CUTA000006', N'คุณหญิงสุดารัตน์ (VIP)', NULL, NULL, NULL, N'02-123-9999', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(100000.00 AS Decimal(18, 2)), 30, NULL, N'Manager', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'CUS', N'CUSA000018', N'CUTA000006', N'ท่านประธานบริษัท', NULL, NULL, NULL, N'089-111-1111', NULL, N'ceo@bigcorp.com', NULL, NULL, NULL, NULL, NULL, NULL, CAST(500000.00 AS Decimal(18, 2)), 45, NULL, N'Director', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'CUS', N'CUSA000019', N'CUTA000006', N'คุณลูกค้า รายใหญ่มาก', NULL, NULL, NULL, N'081-222-2222', NULL, N'vip.whale@investor.com', NULL, NULL, NULL, NULL, NULL, NULL, CAST(200000.00 AS Decimal(18, 2)), 30, NULL, N'Manager', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'CUS', N'CUSA000020', N'CUTA000006', N'Professor John Smith', NULL, NULL, NULL, N'081-333-3333', NULL, N'john.smith@harvard.edu', NULL, NULL, NULL, NULL, NULL, NULL, CAST(50000.00 AS Decimal(18, 2)), 30, NULL, N'Manager', CAST(N'2025-12-08T22:52:25.920' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'CUS', N'CUSA000021', N'CUTA000007', N'บริษัท ปัญญาภิวัฒน์ จำกัด', N'0105558001111', N'สำนักงานใหญ่', N'ฝ่ายจัดซื้อ (คุณกานดา)', N'02-888-9999', NULL, N'procurement@panyapiwat.co.th', NULL, N'99 ถนนแจ้งวัฒนะ', N'บางตลาด', N'ปากเกร็ด', N'นนทบุรี', N'11120', CAST(500000.00 AS Decimal(18, 2)), 45, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.923' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'CUS', N'CUSA000022', N'CUTA000007', N'บริษัท ปูนซิเมนต์ไทย จำกัด (มหาชน)', N'0107537000114', N'สำนักงานใหญ่', N'แผนกห้องสมุด', N'02-586-3333', NULL, N'library@scg.com', NULL, N'1 ถนนปูนซิเมนต์ไทย', N'บางซื่อ', N'บางซื่อ', N'กรุงเทพมหานคร', N'10800', CAST(1000000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.923' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (23, N'CUS', N'CUSA000023', N'CUTA000007', N'บริษัท ปตท. จำกัด (มหาชน)', N'0107544000108', N'สำนักงานใหญ่', N'ฝ่ายทรัพยากรบุคคล', N'02-537-2000', NULL, N'hr@pttplc.com', NULL, N'555 ถนนวิภาวดีรังสิต', N'จตุจักร', N'จตุจักร', N'กรุงเทพมหานคร', N'10900', CAST(1000000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.923' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (24, N'CUS', N'CUSA000024', N'CUTA000007', N'ธนาคารกสิกรไทย จำกัด (มหาชน)', N'0107536000315', N'สำนักงานใหญ่', N'ฝ่ายจัดซื้อ', N'02-888-8888', NULL, N'procure@kasikornbank.com', NULL, N'400/22 ถนนพหลโยธิน', N'สามเสนใน', N'พญาไท', N'กรุงเทพมหานคร', N'10400', CAST(800000.00 AS Decimal(18, 2)), 45, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.923' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (25, N'CUS', N'CUSA000025', N'CUTA000007', N'บริษัท แอดวานซ์ อินโฟร์ เซอร์วิส จำกัด (AIS)', N'0107535000265', N'อาคารชินวัตร 1', N'Admin Support', N'02-029-5000', NULL, N'admin@ais.co.th', NULL, N'414 ถนนพหลโยธิน', N'สามเสนใน', N'พญาไท', N'กรุงเทพมหานคร', N'10400', CAST(800000.00 AS Decimal(18, 2)), 45, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.923' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (26, N'CUS', N'CUSA000026', N'CUTA000008', N'โรงเรียนนานาชาติร่วมฤดี', N'0994000155555', N'สำนักงานใหญ่', N'Librarian (Mrs. Smith)', N'02-791-8900', NULL, N'library@rism.ac.th', NULL, N'6 ซอยรามคำแหง 184', N'มีนบุรี', N'มีนบุรี', N'กรุงเทพมหานคร', N'10510', CAST(200000.00 AS Decimal(18, 2)), 30, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.930' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (27, N'CUS', N'CUSA000027', N'CUTA000008', N'มหาวิทยาลัยเกษตรศาสตร์', N'0994000161111', N'คณะวิศวกรรมศาสตร์', N'ธุรการภาควิชา', N'02-942-8555', NULL, N'eng@ku.ac.th', NULL, N'50 ถนนงามวงศ์วาน', N'ลาดยาว', N'จตุจักร', N'กรุงเทพมหานคร', N'10900', CAST(1000000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.930' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (28, N'CUS', N'CUSA000028', N'CUTA000008', N'หอสมุดแห่งชาติ', N'0994000361111', N'ท่าวาสุกรี', N'ฝ่ายจัดหาทรัพยากร', N'02-281-5212', NULL, N'nlt@finearts.go.th', NULL, N'ถนนสามเสน', N'วชิรพยาบาล', N'ดุสิต', N'กรุงเทพมหานคร', N'10300', CAST(500000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.930' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (29, N'CUS', N'CUSA000029', N'CUTA000008', N'กระทรวงศึกษาธิการ', N'0994000008888', N'สำนักงานปลัด', N'กองคลัง', N'02-281-9264', NULL, N'finance@moe.go.th', NULL, N'319 ถนนราชดำเนินนอก', N'ดุสิต', N'ดุสิต', N'กรุงเทพมหานคร', N'10300', CAST(2000000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.930' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (30, N'CUS', N'CUSA000030', N'CUTA000008', N'จุฬาลงกรณ์มหาวิทยาลัย', N'0994000160081', N'สำนักวิทยทรัพยากร', N'ฝ่ายจัดซื้อหนังสือ', N'02-218-2929', NULL, N'office@car.chula.ac.th', NULL, N'254 ถนนพญาไท', N'วังใหม่', N'ปทุมวัน', N'กรุงเทพมหานคร', N'10330', CAST(1500000.00 AS Decimal(18, 2)), 60, NULL, N'SalesB2B', CAST(N'2025-12-08T22:52:25.930' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (31, N'CUS', N'CUSA000031', N'CUTMT0007', N'บริษัท ทดสอบ จำกัด', N'1234567890123', NULL, NULL, N'0891234567', N'021234567', N'somchai@example.com', NULL, N'123 ถนนสุขุมวิท', NULL, N'คลองเตย', N'กรุงเทพมหานคร', N'10110', CAST(0.00 AS Decimal(18, 2)), 0, N'ลูกค้าระดับ VIP', N'root', CAST(N'2025-12-15T19:47:06.230' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (32, N'CUS', N'CUSA000032', N'CUTA000001', N'Global Tech Solutions', N'1234567890123', N'Headquarters', N'John Doe', N'021234567', N'0812345678', N'contact@globaltech.com', N'@globaltech', N'123 Tech Park, Innovation Road', N'Silom', N'Bang Rak', N'Bangkok', N'10500', CAST(100000.00 AS Decimal(18, 2)), 30, N'Key account client', N'VXRZ', CAST(N'2025-12-15T19:51:00.730' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_customer] ([autoID], [prefix], [customer_id], [customer_type_id], [customer_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [line_id], [address], [sub_district], [district], [province], [zip_code], [credit_limit], [credit_term_day], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (33, N'CUS', N'CUSA000033', N'CUTA000001', N'X Tech', N'887766552442221', N'Sub Brance', N'JACK', N'02123433339', N'08123444444', N'contact1@globaltech.com', N'@globaltech', N'123 Tech Park, Innovation Road', N'Silom1', N'Bang Rak1', N'Bangkok1', N'10500', CAST(50000000.00 AS Decimal(18, 2)), 45, N'Key account client', N'UNKNOWN', CAST(N'2025-12-15T19:56:52.767' AS DateTime), 0, 1, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_customer] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_customer_type] ON 

INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (1, N'CUT', N'CUTA000001', N'General Customer', N'ลูกค้าทั่วไป (Walk-in / Online) ชำระเงินสดทันที', N'System', CAST(N'2025-12-08T22:25:08.047' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (2, N'CUT', N'CUTA000002', N'Guest User', N'ผู้ใช้งานชั่วคราว ไม่ได้ลงทะเบียนสมาชิก', N'System', CAST(N'2025-12-08T22:25:08.047' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (3, N'CUT', N'CUTA000003', N'Member (Standard)', N'สมาชิกทั่วไป สะสมแต้มได้', N'System', CAST(N'2025-12-08T22:25:08.063' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (4, N'CUT', N'CUTA000004', N'Member (Silver)', N'สมาชิกระดับกลาง รับส่วนลด 5%', N'System', CAST(N'2025-12-08T22:25:08.063' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (5, N'CUT', N'CUTA000005', N'Member (Gold)', N'สมาชิกระดับสูง รับส่วนลด 10% + ส่งฟรี', N'System', CAST(N'2025-12-08T22:25:08.063' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (6, N'CUT', N'CUTA000006', N'Member (VIP)', N'ลูกค้า VIP เครดิตเทอม 30 วัน', N'System', CAST(N'2025-12-08T22:25:08.073' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (7, N'CUT', N'CUTA000007', N'Corporate / B2B', N'ลูกค้าองค์กร นิติบุคคล เครดิตเทอม 45 วัน', N'System', CAST(N'2025-12-08T22:25:08.073' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (8, N'CUT', N'CUTA000008', N'Government', N'หน่วยงานราชการ เครดิตเทอม 60 วัน', N'System', CAST(N'2025-12-08T22:25:08.073' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (9, N'CUT', N'CUTA000009', N'Internal Dept', N'เบิกใช้ภายในบริษัท / ตัดงบแผนก', N'System', CAST(N'2025-12-08T22:25:08.077' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (10, N'CUT', N'CUTA000010', N'Affiliate Partner', N'พันธมิตรทางการค้า', N'System', CAST(N'2025-12-08T22:25:08.077' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (12, N'CUT', N'CUTA000012', N'X Customer', N'ลูกค้า X', N'root', CAST(N'2025-12-17T00:31:49.663' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (13, N'CUT', N'CUTA000013', N'Z Customer', N'ลูกค้า Z', N'VXZRZ', CAST(N'2025-12-12T17:21:56.733' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (14, N'CUT', N'CUTA000014', N'Y Customer', N'ลูกค้า Y', N'root', CAST(N'2025-12-17T00:31:31.843' AS DateTime), 0, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (15, N'CUT', N'CUTA000015', N'A Customer', N'A Customer', N'root', CAST(N'2025-12-17T00:47:10.690' AS DateTime), 1, 0, N'ACTIVE', NULL)
INSERT [dbo].[tb_customer_type] ([autoID], [prefix], [customer_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status], [base_credit_day]) VALUES (16, N'CUT', N'CUTA000016', N'A Customer', N'A Customer', N'root', CAST(N'2025-12-17T00:47:20.157' AS DateTime), 0, 0, N'ACTIVE', NULL)
SET IDENTITY_INSERT [dbo].[tb_customer_type] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_discount] ON 

INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'DSC', N'DSCA000001', N'DCTA000001', N'ส่วนลดทั่วไป 5%', NULL, N'ลด 5% ทันทีไม่มีขั้นต่ำ', CAST(5.0000 AS Decimal(18, 4)), 1, CAST(0.0000 AS Decimal(18, 4)), NULL, NULL, N'Admin', CAST(N'2025-12-08T22:18:42.867' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'DSC', N'DSCA000002', N'DCTA000002', N'ลดทันที 100 บาท', NULL, N'เมื่อซื้อครบ 1,500 บาท ลดทันที 100 บาท', CAST(100.0000 AS Decimal(18, 4)), 0, CAST(1500.0000 AS Decimal(18, 4)), NULL, NULL, N'Admin', CAST(N'2025-12-08T22:18:42.887' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'DSC', N'DSCA000003', N'DCTA000003', N'ซื้อเยอะ ลดคุ้ม (Bulk 10k)', NULL, N'ยอดซื้อเกิน 10,000 บาท ลดเพิ่ม 10%', CAST(10.0000 AS Decimal(18, 4)), 1, CAST(10000.0000 AS Decimal(18, 4)), NULL, NULL, N'SalesMgr', CAST(N'2025-12-08T22:18:42.890' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'DSC', N'DSCA000004', N'DCTA000004', N'Gold Member Privilege', NULL, N'สิทธิพิเศษสมาชิก Gold ลด 15% ทุกรายการ', CAST(15.0000 AS Decimal(18, 4)), 1, CAST(0.0000 AS Decimal(18, 4)), NULL, NULL, N'Admin', CAST(N'2025-12-08T22:18:42.890' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'DSC', N'DSCA000005', N'DCTA000005', N'Big Book Fair 2025', NULL, N'โปรโมชั่นงานสัปดาห์หนังสือ ลด 20% ทั้งเดือน', CAST(20.0000 AS Decimal(18, 4)), 1, CAST(0.0000 AS Decimal(18, 4)), CAST(N'2025-03-01T00:00:00.000' AS DateTime), CAST(N'2025-03-31T00:00:00.000' AS DateTime), N'Marketing', CAST(N'2025-12-08T22:18:42.900' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'DSC', N'DSCA000006', N'DCTA000006', N'Welcome New User', N'HELLO2025', N'โค้ดส่วนลด 500 บาท สำหรับลูกค้าใหม่', CAST(500.0000 AS Decimal(18, 4)), 0, CAST(2000.0000 AS Decimal(18, 4)), NULL, NULL, N'Marketing', CAST(N'2025-12-08T22:18:42.903' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'DSC', N'DSCA000007', N'DCTA000007', N'Clearance Stock 2024', NULL, N'ล้างสต็อกสินค้าเก่าปี 2024 ลดสูงสุด 50%', CAST(50.0000 AS Decimal(18, 4)), 1, CAST(0.0000 AS Decimal(18, 4)), NULL, NULL, N'StoreMgr', CAST(N'2025-12-08T22:18:42.903' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'DSC', N'DSCA000008', N'DCTA000008', N'B2B Standard Rate', NULL, N'ราคาส่งสำหรับคู่ค้า (ลด 25% เมื่อสั่ง 50k+)', CAST(25.0000 AS Decimal(18, 4)), 1, CAST(50000.0000 AS Decimal(18, 4)), NULL, NULL, N'SalesDirector', CAST(N'2025-12-08T22:18:42.903' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount] ([autoID], [prefix], [discount_id], [discount_type_id], [discount_name], [discount_code], [description], [discount_value], [is_percent], [min_order_amount], [start_date], [end_date], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'DSC', N'DSCA000010', N'DCTA000001', N'New Year Sale', N'NY2025', N'20% off for orders over 1000', CAST(20.0000 AS Decimal(18, 4)), 1, CAST(1000.0000 AS Decimal(18, 4)), CAST(N'2025-01-01T00:00:00.000' AS DateTime), CAST(N'2025-01-31T00:00:00.000' AS DateTime), N'HACKER', CAST(N'2025-12-15T19:02:50.317' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_discount] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_discount_type] ON 

INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'DCT', N'DCTA000001', N'Percentage Discount (%)', N'ส่วนลดแบบคิดเป็นเปอร์เซ็นต์จากราคาขาย', N'PlayDevX', CAST(N'2025-12-08T22:20:29.733' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'DCT', N'DCTA000002', N'Fixed Amount (Baht)', N'ส่วนลดแบบระบุจำนวนเงินแน่นอน (บาท)', N'PlayDevX', CAST(N'2025-12-08T22:20:29.733' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'DCT', N'DCTA000003', N'Volume Discount', N'ส่วนลดตามปริมาณการสั่งซื้อ (ซื้อเยอะลดเยอะ)', N'PlayDevX', CAST(N'2025-12-08T22:20:29.733' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'DCT', N'DCTA000004', N'Member Privilege', N'ส่วนลดพิเศษสำหรับสมาชิกระดับต่างๆ', N'PlayDevX', CAST(N'2025-12-08T22:20:29.733' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'DCT', N'DCTA000005', N'Seasonal Promotion', N'โปรโมชั่นตามเทศกาล (ปีใหม่, งานหนังสือ)', N'PlayDevX', CAST(N'2025-12-08T22:20:29.733' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'DCT', N'DCTA000006', N'Coupon / Voucher', N'ส่วนลดจากการใช้คูปองหรือรหัสโปรโมชั่น', N'PlayDevX', CAST(N'2025-12-08T22:20:29.730' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'DCT', N'DCTA000007', N'End of Line / Clearance', N'ส่วนลดล้างสต็อกสินค้าเก่า', N'PlayDevX', CAST(N'2025-12-08T22:20:29.730' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'DCT', N'DCTA000008', N'Partner Discount', N'ส่วนลดคู่ค้าทางธุรกิจ (B2B)', N'PlayDevX', CAST(N'2025-12-08T22:20:29.730' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'DCT', N'DCTA000010', N'Employee Extra Discount', N'Exclusive discount for internal staff', N'VXRZ', CAST(N'2025-12-12T23:34:12.763' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'DCT', N'DCTA000011', N'DISCOUNT TYPE #01', N'DISCOUNT TYPE #01', N'root', CAST(N'2025-12-17T02:05:53.360' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'DCT', N'DCTA000012', N'DISCOUNT TYPE #02', N'DISCOUNT TYPE #02', N'root', CAST(N'2025-12-17T02:09:32.197' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_discount_type] ([autoID], [prefix], [discount_type_id], [discount_type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'DCT', N'DCTA000013', N'DISCOUNT TYPE #03', N'DISCOUNT TYPE #03', N'root', CAST(N'2025-12-17T02:09:50.410' AS DateTime), 0, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_discount_type] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_product] ON 

INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'PDT', N'PDTA000001', N'9786161849999', N'Harry Potter กับศิลาอาถรรพ์ (2024)', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000005', 0, CAST(325.0000 AS Decimal(18, 4)), CAST(495.0000 AS Decimal(18, 4)), N'9786161849990', CAST(0.00 AS Decimal(10, 2)), N'เล่ม 1', N'POSTMAN', CAST(N'2025-12-19T18:59:15.177' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'PDT', N'PDTA000002', N'9786161850001', N'Harry Potter กับห้องแห่งความลับ', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000005', 1, CAST(325.0000 AS Decimal(18, 4)), CAST(495.0000 AS Decimal(18, 4)), NULL, CAST(0.70 AS Decimal(10, 2)), N'เล่ม 2', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'PDT', N'PDTA000003', N'9786161850002', N'Atomic Habits', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000006', 1, CAST(185.0000 AS Decimal(18, 4)), CAST(285.0000 AS Decimal(18, 4)), NULL, CAST(0.45 AS Decimal(10, 2)), N'จิตวิทยา', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'PDT', N'PDTA000004', N'9786161850003', N'Rich Dad Poor Dad', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000004', 1, CAST(190.0000 AS Decimal(18, 4)), CAST(285.0000 AS Decimal(18, 4)), NULL, CAST(0.50 AS Decimal(10, 2)), N'การเงิน', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'PDT', N'PDTA000005', N'9786161850004', N'Sapiens: เซเปียนส์', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000004', 1, CAST(380.0000 AS Decimal(18, 4)), CAST(595.0000 AS Decimal(18, 4)), NULL, CAST(0.95 AS Decimal(10, 2)), N'ประวัติศาสตร์', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'PDT', N'PDTA000006', N'9786161850005', N'Think Again', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000006', 1, CAST(245.0000 AS Decimal(18, 4)), CAST(395.0000 AS Decimal(18, 4)), NULL, CAST(0.55 AS Decimal(10, 2)), N'พัฒนาตนเอง', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'PDT', N'PDTA000007', N'9786161850006', N'Psychology of Money', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000006', 1, CAST(195.0000 AS Decimal(18, 4)), CAST(290.0000 AS Decimal(18, 4)), NULL, CAST(0.40 AS Decimal(10, 2)), N'จิตวิทยาการเงิน', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'PDT', N'PDTA000008', N'9786161850007', N'One Piece เล่ม 105', N'PGTA000001', N'PFMA000001', N'UNTA000001', N'VENA000002', 1, CAST(45.0000 AS Decimal(18, 4)), CAST(75.0000 AS Decimal(18, 4)), NULL, CAST(0.20 AS Decimal(10, 2)), N'การ์ตูน', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'PDT', N'PDTA000009', N'IT-MS-OFFICE', N'Microsoft Office Home 2024', N'PGTA000017', N'PFMA000016', N'UNTA000005', N'VENA000016', 1, CAST(7200.0000 AS Decimal(18, 4)), CAST(8990.0000 AS Decimal(18, 4)), NULL, CAST(0.00 AS Decimal(10, 2)), N'License', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'PDT', N'PDTA000010', N'IT-WIN11-PRO', N'Windows 11 Pro FPP', N'PGTA000017', N'PFMA000016', N'UNTA000012', N'VENA000016', 1, CAST(6200.0000 AS Decimal(18, 4)), CAST(7990.0000 AS Decimal(18, 4)), NULL, CAST(0.15 AS Decimal(10, 2)), N'USB Drive', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'PDT', N'PDTA000011', N'IT-LOGI-M330', N'Logitech M330 Silent Mouse', N'PGTA000017', N'PFMA000016', N'UNTA000005', N'VENA000017', 1, CAST(420.0000 AS Decimal(18, 4)), CAST(699.0000 AS Decimal(18, 4)), NULL, CAST(0.25 AS Decimal(10, 2)), N'Wireless', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'PDT', N'PDTA000012', N'IT-K845', N'Logitech K845 Keyboard', N'PGTA000017', N'PFMA000016', N'UNTA000005', N'VENA000017', 1, CAST(1500.0000 AS Decimal(18, 4)), CAST(1990.0000 AS Decimal(18, 4)), NULL, CAST(1.20 AS Decimal(10, 2)), N'Mechanical', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'PDT', N'PDTA000013', N'IT-SANDISK-64', N'SanDisk Ultra USB 64GB', N'PGTA000017', N'PFMA000016', N'UNTA000005', N'VENA000017', 1, CAST(180.0000 AS Decimal(18, 4)), CAST(290.0000 AS Decimal(18, 4)), NULL, CAST(0.05 AS Decimal(10, 2)), N'Flash Drive', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'PDT', N'PDTA000014', N'BOX-00-A', N'กล่องพัสดุ เบอร์ A', N'PGTA000011', N'PFMA000013', N'UNTA000005', N'VENA000015', 1, CAST(2.8000 AS Decimal(18, 4)), CAST(5.0000 AS Decimal(18, 4)), NULL, CAST(0.10 AS Decimal(10, 2)), N'Size A', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'PDT', N'PDTA000015', N'BOX-00-B', N'กล่องพัสดุ เบอร์ B', N'PGTA000011', N'PFMA000013', N'UNTA000005', N'VENA000015', 1, CAST(3.5000 AS Decimal(18, 4)), CAST(7.0000 AS Decimal(18, 4)), NULL, CAST(0.15 AS Decimal(10, 2)), N'Size B', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'PDT', N'PDTA000016', N'BUBBLE-65', N'บับเบิ้ลกันกระแทก 65cm', N'PGTA000011', N'PFMA000013', N'UNTA000005', N'VENA000015', 1, CAST(220.0000 AS Decimal(18, 4)), CAST(350.0000 AS Decimal(18, 4)), NULL, CAST(3.50 AS Decimal(10, 2)), N'100 เมตร', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'PDT', N'PDTA000017', N'TAPE-OPP-CL', N'เทปใส 2 นิ้ว 45 หลา', N'PGTA000011', N'PFMA000013', N'UNTA000005', N'VENA000015', 1, CAST(85.0000 AS Decimal(18, 4)), CAST(150.0000 AS Decimal(18, 4)), NULL, CAST(1.20 AS Decimal(10, 2)), N'แพ็ค 6', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'PDT', N'PDTA000018', N'SRV-SHIPPING', N'ค่าจัดส่งสินค้า (EMS)', N'PGTA000015', N'PFMA000021', N'UNTA000005', N'VENA000015', 0, CAST(0.0000 AS Decimal(18, 4)), CAST(50.0000 AS Decimal(18, 4)), NULL, CAST(0.00 AS Decimal(10, 2)), N'เหมาจ่าย', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'PDT', N'PDTA000019', N'SRV-GIFT', N'บริการห่อของขวัญ', N'PGTA000015', N'PFMA000021', N'UNTA000005', NULL, 0, CAST(15.0000 AS Decimal(18, 4)), CAST(35.0000 AS Decimal(18, 4)), NULL, CAST(0.00 AS Decimal(10, 2)), N'Service', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'PDT', N'PDTA000020', N'SRV-MEMBER', N'ค่าสมัครสมาชิกรายปี', N'PGTA000015', N'PFMA000021', N'UNTA000005', NULL, 0, CAST(0.0000 AS Decimal(18, 4)), CAST(500.0000 AS Decimal(18, 4)), NULL, CAST(0.00 AS Decimal(10, 2)), N'Membership', N'System', CAST(N'2025-12-19T17:18:10.603' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product] ([autoID], [prefix], [product_id], [product_code], [product_name], [product_group_id], [product_format_type_id], [unit_type_id], [vendor_id], [count_stock], [cost_price], [sell_price], [barcode], [weight_kg], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'PDT', N'PDTA000021', N'', N'', N'', NULL, NULL, NULL, 0, CAST(0.0000 AS Decimal(18, 4)), CAST(0.0000 AS Decimal(18, 4)), N'885000010001', CAST(0.00 AS Decimal(10, 2)), N'Sample SKU Data', N'POSTMAN', CAST(N'2025-12-19T18:18:54.260' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_product] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_product_category] ON 

INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'PCT', N'PCTA000001', N'หนังสือและสิ่งพิมพ์ (Books & Publishing)', N'BOOK', N'ธุรกิจหลัก จำหน่ายหนังสือ นิตยสาร และสื่อสิ่งพิมพ์ทุกชนิด', N'System', CAST(N'2025-12-08T22:03:27.820' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'PCT', N'PCTA000002', N'ขนส่งและแพ็คกิ้ง (Logistics & Packing)', N'LOGISTICS', N'บริการขนส่งและจำหน่ายอุปกรณ์แพ็คกิ้ง (กล่อง/ซอง)', N'System', CAST(N'2025-12-08T22:03:27.820' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'PCT', N'PCTA000003', N'ไอทีและดิจิทัล (IT & Digital)', N'IT', N'สินค้าไอที ฮาร์ดแวร์ ซอฟต์แวร์ และสินค้าดิจิทัล', N'System', CAST(N'2025-12-08T22:03:27.820' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'PCT', N'PCTA000004', N'บริการและที่ปรึกษา (Service & Consult)', N'SERVICE', N'งานบริการ ที่ปรึกษา และค่าธรรมเนียมต่างๆ', N'System', CAST(N'2025-12-08T22:03:27.820' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'PCT', N'PCTA000005', N'สินค้าทั่วไปและพรีเมียม (Merchandise)', N'MERCH', N'สินค้าพรีเมียม ของที่ระลึก และสินค้าเบ็ดเตล็ดอื่นๆ', N'System', CAST(N'2025-12-08T22:03:27.820' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'PCT', N'PCTA000006', N'บัตรเติมเงิน (Redeem Card)', N'CARD', N'Redeem Card, game, mobile prepaid, eWallet', N'VXRZ', CAST(N'2025-12-11T11:56:09.567' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'PCT', N'PCTA000007', N'CRYPTO EXCHANGE', N'CRYPTO', N'BITCOIN, USDT, MEME COINS', N'VXRZ', CAST(N'2025-12-11T11:48:53.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'PCT', N'PCTA000008', N'HOBBY & TOYS', N'TOY', N'Games and toys', N'JACK', CAST(N'2025-12-10T11:13:00.753' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_category] ([autoID], [prefix], [product_category_id], [category_name], [category_code], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'PCT', N'PCTA000010', N'Test Product Categories #01', N'CAT01', N'Test Product Categories #01', N'admin', CAST(N'2025-12-16T22:58:48.570' AS DateTime), 0, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_product_category] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_product_format_type] ON 

INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'PFM', N'PFMA000001', N'ปกอ่อน (Paperback)', N'หนังสือเข้าเล่มไสกาว ปกกระดาษ', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'PFM', N'PFMA000002', N'ปกแข็ง (Hardcover)', N'หนังสือเข้าเล่มเย็บกี่ ปกแข็งจั่วปัง', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'PFM', N'PFMA000003', N'E-Book (PDF)', N'ไฟล์หนังสือดิจิทัล PDF (Fixed Layout)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'PFM', N'PFMA000004', N'E-Book (ePub)', N'ไฟล์หนังสือดิจิทัล ePub (Reflowable)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'PFM', N'PFMA000005', N'Audio Book (CD)', N'หนังสือเสียงรูปแบบแผ่น CD/MP3', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'PFM', N'PFMA000006', N'Audio Book (Digital Key)', N'รหัสเข้าฟังหนังสือเสียงผ่านระบบ Streaming', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'PFM', N'PFMA000007', N'นิตยสาร (Magazine)', N'เล่มนิตยสารรายคาบ เข้าเล่มมุงหลังคา/ไสกาว', N'PlayDevX', CAST(N'2025-12-08T22:00:04.617' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'PFM', N'PFMA000008', N'Boxset (กล่องสะสม)', N'ชุดหนังสือรวมเล่มพร้อมกล่องสะสม', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'PFM', N'PFMA000009', N'Limited Edition (Premium)', N'รุ่นพิเศษ ผลิตจำนวนจำกัด มีของแถม', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'PFM', N'PFMA000010', N'Zine (หนังสือทำมือ)', N'สิ่งพิมพ์ทำมือ อิสระ จำนวนจำกัด', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'PFM', N'PFMA000011', N'โปสเตอร์ (Poster)', N'ภาพพิมพ์ขนาดใหญ่ (ม้วนใส่กระบอก)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'PFM', N'PFMA000012', N'โปสการ์ด (Postcard)', N'ไปรษณียบัตรภาพพิมพ์ (แผ่น)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'PFM', N'PFMA000013', N'กล่องพัสดุ (Parcel Box)', N'อุปกรณ์แพ็คกิ้ง กล่องกระดาษลูกฟูก', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'PFM', N'PFMA000014', N'ซองเอกสาร/พลาสติก', N'ซองขยายข้าง หรือซองไปรษณีย์พลาสติก', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'PFM', N'PFMA000015', N'วัสดุกันกระแทก (Bubble)', N'ม้วนพลาสติกกันกระแทก', N'PlayDevX', CAST(N'2025-12-08T22:00:04.610' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'PFM', N'PFMA000016', N'Retail Box (กล่องสินค้า)', N'สินค้าไอทีบรรจุกล่องพร้อมขาย (Hardware)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.627' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'PFM', N'PFMA000017', N'Digital License (Key/Code)', N'รหัสลิขสิทธิ์ซอฟต์แวร์ (ส่งทางอีเมล/กระดาษ)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.627' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'PFM', N'PFMA000018', N'Subscription (รายเดือน/ปี)', N'สิทธิ์การใช้งานแบบเช่าใช้ (SaaS)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.627' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'PFM', N'PFMA000019', N'OEM / Bulk Pack', N'สินค้าไอทีไม่มีกล่องขายปลีก (สำหรับประกอบ)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.627' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'PFM', N'PFMA000020', N'Downloadable Content (DLC)', N'ส่วนเสริมของซอฟต์แวร์/เกม (Digital)', N'admin', CAST(N'2025-12-16T19:35:19.923' AS DateTime), 0, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'PFM', N'PFMA000021', N'Service (บริการรายครั้ง)', N'ค่าบริการซ่อม, ติดตั้ง, หรือดูแลระบบ', N'PlayDevX', CAST(N'2025-12-08T22:00:04.633' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'PFM', N'PFMA000022', N'Consultation (ที่ปรึกษา)', N'ค่าบริการที่ปรึกษา (คิดตาม Man-hour)', N'PlayDevX', CAST(N'2025-12-08T22:00:04.630' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (23, N'PFM', N'PFMA000023', N'Course / Training', N'หลักสูตรอบรมหรือสัมมนา', N'PlayDevX', CAST(N'2025-12-08T22:00:04.630' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (24, N'PFM', N'PFMA000024', N'Ticket / Voucher', N'ตั๋ว, บัตรกำนัล, หรือคูปองแทนเงินสด', N'PlayDevX', CAST(N'2025-12-08T22:00:04.630' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_format_type] ([autoID], [prefix], [product_format_type_id], [format_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (25, N'PFM', N'PFMA000025', N'Membership Fee', N'ค่าสมัครสมาชิก หรือค่าธรรมเนียมรายปี', N'PlayDevX', CAST(N'2025-12-08T22:00:04.630' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_product_format_type] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_product_group] ON 

INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'PGT', N'PGTA000001', N'PCTA000001', N'นิยายและวรรณกรรม (Fiction & Literature)', N'Novels, Thai literature, and translated works', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'PGT', N'PGTA000002', N'PCTA000001', N'การ์ตูนและมังงะ (Comics & Manga)', N'Graphic novels, Manga, and Comic books', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'PGT', N'PGTA000003', N'PCTA000001', N'หนังสือเรียนและวิชาการ (Textbooks & Academic)', N'School textbooks, Exam guides', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'PGT', N'PGTA000004', N'PCTA000001', N'จิตวิทยาและการพัฒนาตนเอง (Self-Development)', N'Psychology, Business', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'PGT', N'PGTA000005', N'PCTA000001', N'นิตยสารและวารสาร (Magazines & Journals)', N'Monthly magazines and Periodicals', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'PGT', N'PGTA000006', N'PCTA000001', N'หนังสือเด็กและเยาวชน (Children & Young Adult)', N'Kids books, Tales', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'PGT', N'PGTA000007', N'PCTA000001', N'ศาสนาและปรัชญา (Religion & Philosophy)', N'Religious texts, Dhamma', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'PGT', N'PGTA000008', N'PCTA000001', N'ประวัติศาสตร์และชีวประวัติ (History & Biography)', N'Historical accounts', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'PGT', N'PGTA000009', N'PCTA000001', N'อีบุ๊ก (E-books)', N'Digital downloadable books', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'PGT', N'PGTA000010', N'PCTA000001', N'หนังสือเสียง (Audiobooks)', N'Digital or physical audio books', N'System', CAST(N'2025-12-08T22:23:10.127' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'PGT', N'PGTA000011', N'PCTA000002', N'วัสดุแพ็คกิ้ง (Packing Materials)', N'Bubble wrap, Tape', N'System', CAST(N'2025-12-08T22:23:10.130' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'PGT', N'PGTA000012', N'PCTA000002', N'กล่องพัสดุ (Parcel Boxes)', N'Corrugated boxes and Envelopes', N'System', CAST(N'2025-12-08T22:23:10.130' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'PGT', N'PGTA000013', N'PCTA000002', N'ขนส่งในประเทศ (Domestic Shipping)', N'Standard delivery within Thailand', N'System', CAST(N'2025-12-08T22:23:10.130' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'PGT', N'PGTA000014', N'PCTA000002', N'ขนส่งต่างประเทศ (International Shipping)', N'Cross-border logistics', N'System', CAST(N'2025-12-08T22:23:10.130' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'PGT', N'PGTA000015', N'PCTA000002', N'บริการคลังสินค้า (Warehousing)', N'Storage rental and Fulfillment', N'System', CAST(N'2025-12-08T22:23:10.130' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'PGT', N'PGTA000016', N'PCTA000003', N'ลิขสิทธิ์ซอฟต์แวร์ (Software Licenses)', N'OS, Office suites, Adobe', N'System', CAST(N'2025-12-08T22:23:10.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'PGT', N'PGTA000017', N'PCTA000003', N'คอมพิวเตอร์และฮาร์ดแวร์ (Computer Hardware)', N'Laptops, Desktops', N'System', CAST(N'2025-12-08T22:23:10.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'PGT', N'PGTA000018', N'PCTA000003', N'อุปกรณ์ต่อพ่วง (Peripherals)', N'Keyboards, Mice, Headsets', N'System', CAST(N'2025-12-08T22:23:10.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'PGT', N'PGTA000019', N'PCTA000003', N'บริการคลาวด์และเซิร์ฟเวอร์ (Cloud Services)', N'VPS, Hosting', N'System', CAST(N'2025-12-08T22:23:10.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'PGT', N'PGTA000020', N'PCTA000003', N'คีย์เกมและบัตรเติมเงิน (Digital Game Keys)', N'Steam keys, Gift cards', N'System', CAST(N'2025-12-08T22:23:10.133' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'PGT', N'PGTA000021', N'PCTA000004', N'บริการที่ปรึกษา (Consulting Services)', N'Business and Technical consulting', N'System', CAST(N'2025-12-08T22:23:10.137' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'PGT', N'PGTA000022', N'PCTA000004', N'สมาชิกรายปี (Memberships)', N'Annual or Monthly subscription', N'System', CAST(N'2025-12-08T22:23:10.137' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (23, N'PGT', N'PGTA000023', N'PCTA000004', N'บริการออกแบบ (Design Services)', N'Graphic design, UI/UX', N'System', CAST(N'2025-12-08T22:23:10.137' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (24, N'PGT', N'PGTA000024', N'PCTA000004', N'สินค้าพรีเมียม (Merchandise)', N'Branded goods, Souvenirs', N'System', CAST(N'2025-12-08T22:23:10.137' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (25, N'PGT', N'PGTA000025', N'PCTA000004', N'บัตรกำนัล (Gift Vouchers)', N'Cash coupons', N'System', CAST(N'2025-12-08T22:23:10.137' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (27, N'PGT', N'PGTA000027', N'PCTA000001', N'Fiction & Literature', N'นิยายและวรรณกรรม แปลไทยและต่างประเทศ', N'Admin', CAST(N'2025-12-15T13:15:24.843' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_group] ([autoID], [prefix], [product_group_id], [product_category_id], [product_group_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (28, N'PGT', N'PGTA000028', N'PCTA000001', N'NINJA (Updated)', N'ปรับปรุงคำอธิบาย NINJA', N'admin', CAST(N'2025-12-22T23:15:21.697' AS DateTime), 0, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_product_group] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_product_sku] ON 

INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'SKU', N'SKUA000001', N'PDTA000001', N'9786161849999', NULL, NULL, NULL, NULL, N'พิมพ์ครั้งที่ 1', CAST(315.0000 AS Decimal(18, 4)), CAST(495.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'SKU', N'SKUA000002', N'PDTA000001', N'978616184999X', NULL, NULL, NULL, NULL, N'พิมพ์ครั้งที่ 2 (Reprint)', CAST(315.0000 AS Decimal(18, 4)), CAST(495.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'SKU', N'SKUA000003', N'PDTA000003', N'9786161850002', NULL, NULL, NULL, NULL, N'ปกมาตรฐาน', CAST(185.0000 AS Decimal(18, 4)), CAST(285.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'SKU', N'SKUA000004', N'PDTA000008', N'9786161850007', NULL, NULL, N'105', NULL, N'Standard', CAST(45.0000 AS Decimal(18, 4)), CAST(75.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'SKU', N'SKUA000005', N'PDTA000008', N'9786161850007-S', NULL, NULL, N'105', NULL, N'Special Cover', CAST(65.0000 AS Decimal(18, 4)), CAST(120.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'SKU', N'SKUA000006', N'PDTA000009', N'IT-MS-OFFICE', NULL, N'Key Card (Physical)', NULL, NULL, NULL, CAST(7200.0000 AS Decimal(18, 4)), CAST(8990.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'SKU', N'SKUA000007', N'PDTA000009', N'IT-MS-OFFICE-D', NULL, N'Digital Key (Email)', NULL, NULL, NULL, CAST(7200.0000 AS Decimal(18, 4)), CAST(8990.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'SKU', N'SKUA000008', N'PDTA000010', N'IT-WIN11-PRO', NULL, N'USB Box', NULL, NULL, NULL, CAST(6200.0000 AS Decimal(18, 4)), CAST(7990.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'SKU', N'SKUA000009', N'PDTA000011', N'IT-LOGI-M330-BK', NULL, N'สีดำ (Black)', NULL, NULL, NULL, CAST(420.0000 AS Decimal(18, 4)), CAST(699.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'SKU', N'SKUA000010', N'PDTA000011', N'IT-LOGI-M330-WH', NULL, N'สีขาว (White)', NULL, NULL, NULL, CAST(420.0000 AS Decimal(18, 4)), CAST(699.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'SKU', N'SKUA000011', N'PDTA000011', N'IT-LOGI-M330-BL', NULL, N'สีน้ำเงิน (Blue)', NULL, NULL, NULL, CAST(420.0000 AS Decimal(18, 4)), CAST(699.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'SKU', N'SKUA000012', N'PDTA000014', N'BOX-00-A', NULL, N'ชิ้นเดียว (Single)', NULL, NULL, NULL, CAST(2.8000 AS Decimal(18, 4)), CAST(5.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'SKU', N'SKUA000013', N'PDTA000014', N'BOX-00-A-20', NULL, N'แพ็ค 20 ใบ', NULL, NULL, NULL, CAST(50.0000 AS Decimal(18, 4)), CAST(90.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'SKU', N'SKUA000014', N'PDTA000014', N'BOX-00-A-50', NULL, N'แพ็ค 50 ใบ', NULL, NULL, NULL, CAST(120.0000 AS Decimal(18, 4)), CAST(200.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'SKU', N'SKUA000015', N'PDTA000018', N'SRV-SHIP-STD', NULL, N'Standard (3-5 วัน)', NULL, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), CAST(50.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'SKU', N'SKUA000016', N'PDTA000018', N'SRV-SHIP-EMS', NULL, N'EMS (1-2 วัน)', NULL, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), CAST(80.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.330' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'SKU', N'SKUA000017', N'PDTA000018', N'SRV-SHIP-SAME', NULL, N'Same Day (กทม.)', NULL, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), CAST(150.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.330' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'SKU', N'SKUA000018', N'PDTA000001', N'885000000001', NULL, NULL, N'200', NULL, NULL, CAST(80.0000 AS Decimal(18, 4)), CAST(100.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.327' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'SKU', N'SKUA000019', N'PDTA000001', N'885000000001', NULL, NULL, N'201', NULL, NULL, CAST(80.0000 AS Decimal(18, 4)), CAST(100.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.327' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'SKU', N'SKUA000020', N'PDTA000001', N'885000000005', NULL, NULL, N'205', NULL, N'Special Price', CAST(120.0000 AS Decimal(18, 4)), CAST(150.0000 AS Decimal(18, 4)), NULL, N'System', CAST(N'2025-12-18T23:00:37.327' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'SKU', N'SKUA000021', N'PDTA000001', N'9786161849999', NULL, NULL, NULL, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), CAST(0.0000 AS Decimal(18, 4)), N'25th Anniversary Edition', N'HACKER', CAST(N'2025-12-19T18:38:17.583' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_product_sku] ([autoID], [prefix], [sku_id], [ref_product_id], [barcode], [vendor_part_no], [variation_name], [issue_no], [volume_no], [edition_label], [cost_price], [sell_price], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'SKU', N'SKUA000022', N'PDTA000001', N'9786161849999', N'PART-001-A', N'X Edition', N'1', N'Vol. 1', N'Second Print', CAST(50.0000 AS Decimal(18, 4)), CAST(1500.0000 AS Decimal(18, 4)), N'Sample SKU Data', N'VXRZ', CAST(N'2025-12-19T19:01:43.553' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_product_sku] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_unit_type] ON 

INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (1, N'UNT', N'UNTA000001', N'เล่ม', N'หน่วยนับสำหรับหนังสือ นิตยสาร หรือสมุด', N'PlayDevX', CAST(N'2025-12-08T21:48:03.127' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (2, N'UNT', N'UNTA000002', N'ฉบับ', N'หน่วยนับสำหรับหนังสือพิมพ์ หรือเอกสารสำคัญ', N'PlayDevX', CAST(N'2025-12-08T21:48:03.127' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (3, N'UNT', N'UNTA000003', N'แผ่น', N'หน่วยนับสำหรับโปสเตอร์ หรือซีดี', N'PlayDevX', CAST(N'2025-12-08T21:48:03.127' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (4, N'UNT', N'UNTA000004', N'รีม', N'หน่วยนับสำหรับกระดาษ (1 รีม = 500 แผ่น)', N'PlayDevX', CAST(N'2025-12-08T21:48:03.127' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (5, N'UNT', N'UNTA000005', N'ชิ้น', N'หน่วยนับมาตรฐานสำหรับสินค้าทั่วไป', N'PlayDevX', CAST(N'2025-12-08T21:48:03.127' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (6, N'UNT', N'UNTA000006', N'อัน', N'หน่วยนับสำหรับอุปกรณ์ขนาดเล็ก', N'admin', CAST(N'2025-12-19T20:02:27.723' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (7, N'UNT', N'UNTA000007', N'ด้าม', N'หน่วยนับสำหรับปากกา ดินสอ', N'admin', CAST(N'2025-12-19T20:02:34.580' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (8, N'UNT', N'UNTA000008', N'ชุด', N'สินค้าที่ประกอบด้วยหลายชิ้นรวมกัน (Set)', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (9, N'UNT', N'UNTA000009', N'โหล', N'บรรจุภัณฑ์จำนวน 12 ชิ้น', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (10, N'UNT', N'UNTA000010', N'แพ็ค', N'หน่วยบรรจุรวมย่อย (เช่น แพ็ค 6 เล่ม)', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (11, N'UNT', N'UNTA000011', N'ห่อ', N'หน่วยบรรจุแบบห่อพลาสติก/กระดาษ.', N'root', CAST(N'2025-12-16T13:16:21.870' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (12, N'UNT', N'UNTA000012', N'กล่อง', N'หน่วยบรรจุภัณฑ์สำหรับการจัดส่ง', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (13, N'UNT', N'UNTA000013', N'ลัง', N'หน่วยบรรจุภัณฑ์ขนาดใหญ่ (Carton)', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (14, N'UNT', N'UNTA000014', N'พาเลท', N'หน่วยสำหรับการจัดเก็บในคลังสินค้า', N'PlayDevX', CAST(N'2025-12-08T21:48:03.150' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (16, N'UNT', N'UNTA000016', N'ถุงเล็ก', N'หน่วยบรรจุแบบถุงใส่น้ำชา', N'root', CAST(N'2025-12-15T20:42:57.543' AS DateTime), 0, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (21, N'UNT', N'UNTA000021', N'ทดสอบ unit_type_name 02', N'ทดสอบ unit_type_name 02 ทดสอบ unit_type_name 02 ทดสอบ unit_type_name 02 ทดสอบ unit_type_name 02 ', N'root', CAST(N'2025-12-16T13:04:26.017' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (25, N'UNT', N'UNTA000025', N'Unit Type Name 01', N'Unit Type Name 01', N'root', CAST(N'2025-12-19T20:01:53.887' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (26, N'UNT', N'UNTA000026', N'Unit Type Name 02', N'Unit Type Name 02', N'root', CAST(N'2025-12-19T20:02:06.320' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (27, N'UNT', N'UNTA000027', N'Unit Type Name 03', N'Unit Type Name 03', N'root', CAST(N'2025-12-19T20:02:10.720' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (28, N'UNT', N'UNTA000028', N'Unit Type Name 04', N'Unit Type Name 04', N'root', CAST(N'2025-12-19T20:02:02.727' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (29, N'UNT', N'UNTA000029', N'Unit Type Name 05', N'Unit Type Name 05', N'root', CAST(N'2025-12-19T20:01:57.610' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_unit_type] ([autoID], [prefix], [unit_type_id], [unit_type_name], [description], [update_by], [update_date], [is_delete], [is_active], [id_status]) VALUES (30, N'UNT', N'UNTA000030', N'Unit Type Name 06', N'Unit Type Name 06', N'root', CAST(N'2025-12-19T20:01:46.137' AS DateTime), 1, 1, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_unit_type] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_users] ON 

INSERT [dbo].[tb_users] ([autoID], [user_name], [user_password], [user_level], [update_date], [prefix], [user_id], [update_by], [is_active], [is_delete], [id_status]) VALUES (1, N'admin', N'$2a$10$XSYDYCCltBbxcCy8Ypkzb.0TooD8cwBY0u3uRqXd19hEoYjrkY.kq', N'ADMIN', CAST(N'2026-06-09T18:22:15.870' AS DateTime), N'USR', N'USRA000001', N'system', 1, 0, N'ACTIVE')
INSERT [dbo].[tb_users] ([autoID], [user_name], [user_password], [user_level], [update_date], [prefix], [user_id], [update_by], [is_active], [is_delete], [id_status]) VALUES (2, N'root', N'$2a$10$XSYDYCCltBbxcCy8Ypkzb.0TooD8cwBY0u3uRqXd19hEoYjrkY.kq', N'ADMIN', CAST(N'2026-06-09T18:22:23.463' AS DateTime), N'USR', N'USRA000002', N'system', 1, 0, N'ACTIVE')
INSERT [dbo].[tb_users] ([autoID], [user_name], [user_password], [user_level], [update_date], [prefix], [user_id], [update_by], [is_active], [is_delete], [id_status]) VALUES (3, N'jack', N'$2a$10$QeMq4cMVS0UaTM38no.HLuTdBsKI52Ka32Zkf4NDryAyETAzZsHoe', N'HACKER', CAST(N'2026-06-09T18:24:12.070' AS DateTime), N'USR', N'USRA000003', N'system', 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_users] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_vendor] ON 

INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'VEN', N'VENA000001', N'VETA000001', N'บริษัท แจ่มใส พับลิชชิ่ง จำกัด', N'0105545001234', N'สำนักงานใหญ่', N'คุณสมศรี ใจดี (ฝ่ายขาย)', N'02-840-4888', N'081-999-8888', N'sales@jamsai.com', N'www.jamsai.com', N'285/33 ซอยจรัญสนิทวงศ์ 31', N'บางขุนศรี', N'บางกอกน้อย', N'กรุงเทพมหานคร', N'10700', 60, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'VEN', N'VENA000002', N'VETA000001', N'บริษัท สยามอินเตอร์มัลติมีเดีย จำกัด (มหาชน)', N'0107548000456', N'สำนักงานใหญ่', N'คุณวิชัย (การตลาด)', N'02-694-3010', N'02-694-3011', N'marketing@siaminter.com', N'www.siaminter.com', N'459 ซอยลาดพร้าว 48', N'สามเสนนอก', N'ห้วยขวาง', N'กรุงเทพมหานคร', N'10310', 60, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'VEN', N'VENA000003', N'VETA000001', N'บริษัท มติชน จำกัด (มหาชน)', N'0107536001451', N'สำนักงานใหญ่', N'กองบรรณาธิการ', N'02-580-0021', NULL, N'info@matichon.co.th', N'www.matichon.co.th', N'12 ถนนเทศบาลนฤมาล', N'ลาดยาว', N'จตุจักร', N'กรุงเทพมหานคร', N'10900', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'VEN', N'VENA000004', N'VETA000001', N'บริษัท อมรินทร์พริ้นติ้ง แอนด์ พับลิชชิ่ง จำกัด (มหาชน)', N'0107536000412', N'สำนักงานใหญ่', N'คุณสุดา (Sales Key Account)', N'02-422-9999', N'02-422-9000', N'contact@amarin.co.th', N'www.amarin.com', N'378 ถนนชัยพฤกษ์', N'ตลิ่งชัน', N'ตลิ่งชัน', N'กรุงเทพมหานคร', N'10170', 60, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'VEN', N'VENA000005', N'VETA000001', N'บริษัท นานมีบุ๊คส์ จำกัด', N'0105534001111', N'สำนักงานใหญ่', N'ฝ่ายลิขสิทธิ์ต่างประเทศ', N'02-662-3000', NULL, N'rights@nanmeebooks.com', N'www.nanmeebooks.com', N'11 ซอยสุขุมวิท 31 (สวัสดี)', N'คลองเตยเหนือ', N'วัฒนา', N'กรุงเทพมหานคร', N'10110', 60, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'VEN', N'VENA000006', N'VETA000001', N'สำนักพิมพ์ วีเลิร์น (WeLearn)', N'0105550002222', N'อาคารพร้อมพันธุ์ 2', N'คุณนพดล (บรรณาธิการ)', N'02-938-5555', NULL, N'editor@welearnbook.com', N'www.welearnbook.com', N'1 ซอยลาดพร้าว 3', N'จอมพล', N'จตุจักร', N'กรุงเทพมหานคร', N'10900', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'VEN', N'VENA000007', N'VETA000001', N'บริษัท ฟีนิกซ์ (KADOKAWA Amarin)', N'0105559003333', N'สำนักงานใหญ่', N'ฝ่ายขายร้านค้า', N'02-422-9999', N'ต่อ 4123', N'sales@phoenixnext.com', N'www.phoenixnext.com', N'378 ถนนชัยพฤกษ์ (ตึกอมรินทร์)', N'ตลิ่งชัน', N'ตลิ่งชัน', N'กรุงเทพมหานคร', N'10170', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'VEN', N'VENA000008', N'VETA000001', N'บริษัท รักพิมพ์ พับลิชชิ่ง จำกัด', N'0105552004444', N'สำนักงานใหญ่', N'Sales Support', N'02-000-1111', NULL, N'luckpim_sales@hotmail.com', N'www.luckpim.com', N'55/5 หมู่บ้านกลางเมือง', N'ลาดพร้าว', N'ลาดพร้าว', N'กรุงเทพมหานคร', N'10230', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'VEN', N'VENA000009', N'VETA000001', N'สำนักพิมพ์ แซลมอน (Salmon Books)', N'0105540005555', N'สำนักงานใหญ่', N'คุณบก. (Minimore)', N'02-123-4567', NULL, N'salmon@bunbooks.com', N'www.salmonbooks.net', N'12/34 ซอยอารีย์สัมพันธ์ 5', N'สามเสนใน', N'พญาไท', N'กรุงเทพมหานคร', N'10400', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.337' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'VEN', N'VENA000010', N'VETA000002', N'บริษัท ซีเอ็ดยูเคชั่น จำกัด (มหาชน)', N'0107518000211', N'ศูนย์กระจายสินค้าบางนา', N'ฝ่ายจัดซื้อสินค้า', N'02-739-8000', N'02-739-8222', N'purchase@se-ed.com', N'www.se-ed.com', N'1858/87-90 อาคารทีซีไอเอฟ', N'บางนา', N'บางนา', N'กรุงเทพมหานคร', N'10260', 90, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.360' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'VEN', N'VENA000011', N'VETA000002', N'ศูนย์หนังสือจุฬาลงกรณ์มหาวิทยาลัย', N'0994000160081', N'สาขาสยามสแควร์', N'คุณมานะ รักเรียน', N'02-218-9888', N'02-255-4433', N'info@cubook.chula.ac.th', N'www.chulabook.com', N'อาคารวิทยกิตติ์ ซอยจุฬาฯ 64', N'ปทุมวัน', N'ปทุมวัน', N'กรุงเทพมหานคร', N'10330', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.360' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'VEN', N'VENA000012', N'VETA000009', N'บริษัท อมรินทร์ บุ๊ค เซ็นเตอร์ จำกัด (ร้านนายอินทร์)', N'0105536005555', N'ฝ่ายบัญชีเจ้าหนี้', N'จัดซื้อกลาง', N'02-423-9999', NULL, N'naiin@amarin.co.th', N'www.naiin.com', N'108 หมู่ 2 ถ.บางกรวย-จงถนอม', N'มหาสวัสดิ์', N'บางกรวย', N'นนทบุรี', N'11130', 60, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.360' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'VEN', N'VENA000013', N'VETA000006', N'บริษัท โรงพิมพ์ตะวันออก จำกัด (มหาชน)', N'0107537000111', N'โรงงานลาดกระบัง', N'ฝ่ายผลิต (คุณช่าง)', N'02-551-0541', N'081-555-6666', N'sales@epco.co.th', N'www.epco.co.th', N'51/29 หมู่ 3', N'ลำปลาทิว', N'ลาดกระบัง', N'กรุงเทพมหานคร', N'10520', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.360' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'VEN', N'VENA000014', N'VETA000001', N'บริษัท ไปรษณีย์ไทย จำกัด', N'0105546000000', N'สำนักงานใหญ่', N'แผนกลูกค้าธุรกิจ', N'1545', N'02-831-3131', N'postalcare@thailandpost.co.th', N'www.thailandpost.co.th', N'111 ถนนแจ้งวัฒนะ', N'ทุ่งสองห้อง', N'หลักสี่', N'กรุงเทพมหานคร', N'10210', 15, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.363' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'VEN', N'VENA000015', N'VETA000001', N'บริษัท เคอรี่ เอ็กซ์เพรส (ประเทศไทย) จำกัด (มหาชน)', N'0105557001111', N'สำนักงานใหญ่', N'Corporate Sales', N'1217', NULL, N'TH.EX.Sales@kerrylogistics.com', N'th.kerryexpress.com', N'89 อาคารเจ้าพระยา', N'บางรัก', N'บางรัก', N'กรุงเทพมหานคร', N'10500', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.363' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'VEN', N'VENA000016', N'VETA000007', N'บริษัท ไมโครซอฟท์ (ประเทศไทย) จำกัด', N'0105536008888', N'สำนักงานใหญ่', N'Enterprise Sales', N'02-263-6888', NULL, N'thailand@microsoft.com', N'www.microsoft.com/th-th', N'87/1 อาคารซีอาร์ซี ทาวเวอร์ ชั้น 37', N'ลุมพินี', N'ปทุมวัน', N'กรุงเทพมหานคร', N'10330', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'VEN', N'VENA000017', N'VETA000007', N'บริษัท ซินเน็ค (ประเทศไทย) จำกัด (มหาชน)', N'0107550000033', N'สำนักงานใหญ่', N'ฝ่ายขายดีลเลอร์', N'02-553-8888', NULL, N'sales@synnex.co.th', N'www.synnex.co.th', N'433 ถนนสุคนธสวัสดิ์', N'ลาดพร้าว', N'ลาดพร้าว', N'กรุงเทพมหานคร', N'10230', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'VEN', N'VENA000018', N'VETA000007', N'บริษัท เจ.ไอ.บี. คอมพิวเตอร์ กรุ๊ป จำกัด', N'0105542006666', N'สำนักงานใหญ่', N'แผนก B2B', N'02-017-4444', N'090-999-9999', N'corp_sales@jib.co.th', N'www.jib.co.th', N'21 ถ.พหลโยธิน', N'สนามบิน', N'ดอนเมือง', N'กรุงเทพมหานคร', N'10210', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'VEN', N'VENA000019', N'VETA000007', N'บริษัท แอดไวซ์ ไอที อินฟินิท จำกัด (มหาชน)', N'0125552007777', N'สำนักงานใหญ่', N'Corporate Sales', N'1491', N'02-547-0000', N'admin@advice.co.th', N'www.advice.co.th', N'74/1 หมู่ 1', N'ท่าอิฐ', N'ปากเกร็ด', N'นนทบุรี', N'11120', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'VEN', N'VENA000020', N'VETA000007', N'บริษัท อินเทอร์เน็ตประเทศไทย จำกัด (มหาชน) (INET)', N'0107544000099', N'สำนักงานใหญ่', N'Cloud Solution Sales', N'02-257-7000', NULL, N'sales@inet.co.th', N'www.inet.co.th', N'1768 อาคารไทยซัมมิท ทาวเวอร์', N'บางกะปิ', N'ห้วยขวาง', N'กรุงเทพมหานคร', N'10310', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'VEN', N'VENA000021', N'VETA000001', N'การไฟฟ้านครหลวง (MEA)', N'0994000361234', N'สำนักงานใหญ่ เพลินจิต', N'ศูนย์บริการข้อมูล', N'1130', N'02-254-9550', N'admin@mea.or.th', N'www.mea.or.th', N'30 ซอยชิดลม', N'ลุมพินี', N'ปทุมวัน', N'กรุงเทพมหานคร', N'10330', 0, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'VEN', N'VENA000022', N'VETA000001', N'การประปานครหลวง (MWA)', N'0994000365678', N'สำนักงานใหญ่', N'MWA Call Center', N'1125', N'02-504-0123', N'mwa1125@mwa.co.th', N'www.mwa.co.th', N'400 ถนนประชาชื่น', N'ทุ่งสองห้อง', N'หลักสี่', N'กรุงเทพมหานคร', N'10210', 0, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (23, N'VEN', N'VENA000023', N'VETA000001', N'บริษัท ทรู อินเทอร์เน็ต คอร์ปอเรชั่น จำกัด', N'0105548003333', N'สำนักงานใหญ่', N'Business Support', N'1242', NULL, N'business_success@truecorp.co.th', N'truebusiness.truecorp.co.th', N'18 อาคารทรู ทาวเวอร์', N'ห้วยขวาง', N'ห้วยขวาง', N'กรุงเทพมหานคร', N'10310', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (24, N'VEN', N'VENA000024', N'VETA000001', N'บริษัท ออฟฟิศเมท (ไทย) จำกัด', N'0105551006543', N'สำนักงานใหญ่', N'Contact Center', N'1281', N'02-739-5555', N'contact@officemate.co.th', N'www.officemate.co.th', N'919/555 อาคาร Jewelry Trade Center', N'สีลม', N'บางรัก', N'กรุงเทพมหานคร', N'10500', 45, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (25, N'VEN', N'VENA000025', N'VETA000001', N'บริษัท รักษาความปลอดภัย จีโฟร์เอส (ประเทศไทย) จำกัด', N'0105530009999', N'สำนักงานใหญ่', N'ฝ่ายสัญญาจ้าง', N'02-652-5000', NULL, N'sales@th.g4s.com', N'www.g4s.com/th-th', N'399 อาคารอินเตอร์เชนจ์ 21', N'คลองเตยเหนือ', N'วัฒนา', N'กรุงเทพมหานคร', N'10110', 30, N'THB', NULL, N'System', CAST(N'2025-12-08T22:29:03.370' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (27, N'VEN', N'VENA000027', N'VETA000001', N'ABC Publishing Co., Ltd.', N'1234567890123', N'Head Office', N'John Doe', N'02-123-4567', NULL, N'contact@abc.com', NULL, N'123 Silom Rd.', N'Silom', N'Bang Rak', N'Bangkok', N'10500', 30, N'THB', N'Reliable partner', N'UNKNOWN', CAST(N'2025-12-15T14:28:31.843' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor] ([autoID], [prefix], [vendor_id], [vendor_type_id], [vendor_name], [tax_id], [branch_name], [contact_person], [phone1], [phone2], [email], [website], [address], [sub_district], [district], [province], [zip_code], [credit_term_day], [currency], [note], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (28, N'VEN', N'VENA000028', N'VETA000009', N'BUGBUK', N'1234567890123', N'LAMPANG', N'PARKPOOM MANEEYOD', N'0987935595', N'', N'cookievirus@hotmail.com', N'cookievirus.com', N'98/6 Moo 9, Rasika Villa Garden 2, Banglen Soi 10/4 Bangkruai-Sainoi Road', N'', N'', N'นนทบุรี', N'11140', 30, N'THB', N'', N'root', CAST(N'2025-12-17T16:50:23.320' AS DateTime), 0, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_vendor] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_vendor_type] ON 

INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'VET', N'VETA000001', N'สำนักพิมพ์ (วรรณกรรม/นิยาย)', N'ผู้ผลิตงานวรรณกรรม นวนิยาย เรื่องสั้น', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'VET', N'VETA000002', N'สำนักพิมพ์ (วิชาการ/การศึกษา)', N'ผู้ผลิตตำราเรียน คู่มือสอบ และงานวิจัย', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'VET', N'VETA000003', N'สำนักพิมพ์ (การ์ตูน/มังงะ/Light Novel)', N'ผู้ผลิตสื่อสิ่งพิมพ์ประเภทการ์ตูนและนิยายภาพ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (4, N'VET', N'VETA000004', N'สำนักพิมพ์ (สารคดี/Non-fiction)', N'ผู้ผลิตหนังสือให้ความรู้ ประวัติศาสตร์ ฮาวทู', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'VET', N'VETA000005', N'สำนักพิมพ์ (เด็กและเยาวชน)', N'ผู้ผลิตนิทานและหนังสือเสริมพัฒนาการเด็ก', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'VET', N'VETA000006', N'โรงพิมพ์ (Offset Printing)', N'โรงงานพิมพ์ระบบออฟเซ็ทสำหรับงานจำนวนมาก', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (7, N'VET', N'VETA000007', N'โรงพิมพ์ (Digital/On-Demand)', N'โรงงานพิมพ์ระบบดิจิทัลสำหรับงานจำนวนน้อย/ด่วน', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (8, N'VET', N'VETA000008', N'ผู้จัดจำหน่ายหนังสือ (Distributor)', N'ตัวแทนกระจายสินค้าไปยังร้านค้าทั่วประเทศ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (9, N'VET', N'VETA000009', N'ร้านหนังสือ (Chain Store)', N'ร้านหนังสือที่มีสาขาจำนวนมากในห้างสรรพสินค้า', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (10, N'VET', N'VETA000010', N'ร้านหนังสืออิสระ (Indie Bookstore)', N'ร้านหนังสือขนาดเล็ก เน้นหนังสือเฉพาะกลุ่ม', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (11, N'VET', N'VETA000011', N'สายส่ง/โลจิสติกส์สิ่งพิมพ์', N'ผู้ให้บริการขนส่งหนังสือและนิตยสารโดยเฉพาะ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (12, N'VET', N'VETA000012', N'นักเขียนอิสระ (Freelance Writer)', N'บุคคลธรรมดาที่เป็นผู้ประพันธ์ต้นฉบับ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (13, N'VET', N'VETA000013', N'นักวาดภาพประกอบ (Illustrator)', N'ศิลปินผู้ออกแบบปกและภาพประกอบหนังสือ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (14, N'VET', N'VETA000014', N'บรรณาธิการอิสระ (Freelance Editor)', N'ผู้รับจ้างพิสูจน์อักษรและเรียบเรียงต้นฉบับ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (15, N'VET', N'VETA000015', N'ผู้ผลิต E-Book/Audiobook', N'ผู้ให้บริการแพลตฟอร์มหนังสือดิจิทัล', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (16, N'VET', N'VETA000016', N'ตัวแทนลิขสิทธิ์ (Rights Agency)', N'นายหน้าซื้อขายลิขสิทธิ์หนังสือต่างประเทศ', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (17, N'VET', N'VETA000017', N'ผู้จำหน่ายกระดาษ/เยื่อกระดาษ', N'Supplier วัตถุดิบกระดาษสำหรับโรงพิมพ์', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (18, N'VET', N'VETA000018', N'ผู้เข้าเล่ม/ทำปก (Bookbinder)', N'โรงงานรับจ้างเข้าเล่ม เย็บกี่ ไสกาว', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (19, N'VET', N'VETA000019', N'ผู้ผลิตสินค้าพรีเมียมหนังสือ', N'ผู้ผลิตที่คั่นหนังสือ กระเป๋าผ้า ของแถม', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (20, N'VET', N'VETA000020', N'ห้องสมุด/สถาบันการศึกษา', N'องค์กรที่สั่งซื้อหนังสือเพื่อการศึกษา', N'PlayDevX', CAST(N'2025-12-08T22:09:01.773' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (21, N'VET', N'VETA000021', N'Logistics Partner', N'Shipping and courier services', N'admin', CAST(N'2025-12-16T23:09:47.373' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (22, N'VET', N'VETA000022', N'Updated Vendor Type', N'This type includes updated information about the Vendor type.', N'UNKNOWN', CAST(N'2025-12-12T13:06:30.457' AS DateTime), 1, 1, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (23, N'VET', N'VETA000023', N'Vendor Type #01', N'Vendor Type #01', N'admin', CAST(N'2026-06-14T17:48:47.323' AS DateTime), 0, 0, N'ACTIVE')
INSERT [dbo].[tb_vendor_type] ([autoID], [prefix], [vendor_type_id], [type_name], [description], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (24, N'VET', N'VETA000024', N'ตัวแทนนักเขียนออนไลน์', N'ตัวแทนนักเขียนออนไลน์ และนายหน้าซื้อขายลิขสิทธิ์งานออนไลน์ในประเทศ', N'root', CAST(N'2025-12-16T23:28:24.113' AS DateTime), 0, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_vendor_type] OFF
GO
SET IDENTITY_INSERT [dbo].[tb_warehouse] ON 

INSERT [dbo].[tb_warehouse] ([autoID], [prefix], [warehouse_id], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (1, N'WHS', N'WHSA000001', N'DC', N'เพ็ญบุญจัดจำหน่าย (DC)', N'คลังสินค้าหลักสำหรับกระจายสินค้า รับของเข้าที่นี่เท่านั้น', 1, 0, N'System', CAST(N'2025-12-11T12:15:34.693' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_warehouse] ([autoID], [prefix], [warehouse_id], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (2, N'WHS', N'WHSA000002', N'BKK', N'เพ็ญบุญ สาขา กทม.', N'สาขากรุงเทพฯ (ตัดสต็อกเพื่อขาย Modern Trade)', 0, 0, N'System', CAST(N'2025-12-11T12:15:34.693' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_warehouse] ([autoID], [prefix], [warehouse_id], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (3, N'WHS', N'WHSA000003', N'DMG', N'คลังสินค้าเสียหาย (Defect)', N'สำหรับพักสินค้าเสียหายรอส่งคืน/ทำลาย', 0, 0, N'System', CAST(N'2025-12-11T12:15:34.693' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_warehouse] ([autoID], [prefix], [warehouse_id], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (5, N'WHS', N'WHSA000005', N'PRO', N'Province Distribution', N'Primary storage for outside BKK area', 0, 0, N'root', CAST(N'2025-12-17T02:19:40.467' AS DateTime), 1, 0, N'ACTIVE')
INSERT [dbo].[tb_warehouse] ([autoID], [prefix], [warehouse_id], [warehouse_code], [warehouse_name], [description], [is_main_dc], [allow_negative_stock], [update_by], [update_date], [is_active], [is_delete], [id_status]) VALUES (6, N'WHS', N'WHSA000006', N'INT', N'INTERNATIONAL', N'สาขาต่างประเทศ', 0, 1, N'root', CAST(N'2025-12-17T02:20:36.893' AS DateTime), 1, 0, N'ACTIVE')
SET IDENTITY_INSERT [dbo].[tb_warehouse] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__tb_users__7C9273C46A83CD18]    Script Date: 2026-06-17 2:45:07 PM ******/
ALTER TABLE [dbo].[tb_users] ADD UNIQUE NONCLUSTERED 
(
	[user_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_prefix]  DEFAULT ('BOK') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_update_by]  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_update_date]  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_is_delete]  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_book] ADD  CONSTRAINT [DF_tb_book_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_prefix]  DEFAULT ('BKT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_update_by]  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_update_date]  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_is_delete]  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_book_type] ADD  CONSTRAINT [DF_tb_book_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_company] ADD  CONSTRAINT [DF_tb_company_prefix]  DEFAULT ('CPN') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT ('00000') FOR [branch_code]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT ((7.00)) FOR [vat_rate]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_company] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_company] ADD  CONSTRAINT [DF_tb_company_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_customer] ADD  CONSTRAINT [DF_tb_customer_prefix]  DEFAULT ('CUS') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ((0)) FOR [credit_limit]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ((0)) FOR [credit_term_day]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_customer] ADD  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  CONSTRAINT [DF_tb_customer_type_prefix]  DEFAULT ('CUT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_customer_type] ADD  CONSTRAINT [DF_tb_customer_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_discount] ADD  CONSTRAINT [DF_tb_discount_prefix]  DEFAULT ('DSC') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ((0)) FOR [discount_value]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ((0)) FOR [is_percent]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ((0)) FOR [min_order_amount]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_discount] ADD  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  CONSTRAINT [DF_tb_discount_type_prefix]  DEFAULT ('DCT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_discount_type] ADD  CONSTRAINT [DF_tb_discount_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_product] ADD  CONSTRAINT [DF_tb_product_prefix]  DEFAULT ('PDT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((1)) FOR [count_stock]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((0)) FOR [cost_price]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((0)) FOR [sell_price]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((0)) FOR [weight_kg]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_product] ADD  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  CONSTRAINT [DF_tb_product_category_prefix]  DEFAULT ('PCT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_product_category] ADD  CONSTRAINT [DF_tb_product_category_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  CONSTRAINT [DF_tb_product_format_type_prefix]  DEFAULT ('PFM') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_product_format_type] ADD  CONSTRAINT [DF_tb_product_format_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  CONSTRAINT [DF_tb_product_group_prefix]  DEFAULT ('PGT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_product_group] ADD  CONSTRAINT [DF_tb_product_group_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  CONSTRAINT [DF_tb_product_sku_prefix]  DEFAULT ('SKU') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT ((0)) FOR [cost_price]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT ((0)) FOR [sell_price]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_product_sku] ADD  CONSTRAINT [DF_tb_product_sku_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_reference] ADD  DEFAULT ('REF') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_reference] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_reference] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_reference] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_reference] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_reference] ADD  CONSTRAINT [DF_tb_reference_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  DEFAULT ('UNT') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_unit_type] ADD  CONSTRAINT [DF_tb_unit_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_users] ADD  DEFAULT ('USR') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_users] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_users] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_users] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_users] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_users] ADD  CONSTRAINT [DF_tb_users_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  CONSTRAINT [DF_tb_vendor_prefix]  DEFAULT ('VEN') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ((30)) FOR [credit_term_day]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ('THB') FOR [currency]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_vendor] ADD  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  CONSTRAINT [DF_tb_vendor_type_prefix]  DEFAULT ('VET') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_vendor_type] ADD  CONSTRAINT [DF_tb_vendor_type_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  CONSTRAINT [DF_tb_warehouse_prefix]  DEFAULT ('WHS') FOR [prefix]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT ((0)) FOR [is_main_dc]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT ((0)) FOR [allow_negative_stock]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT ('System') FOR [update_by]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time'))) FOR [update_date]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  DEFAULT ((0)) FOR [is_delete]
GO
ALTER TABLE [dbo].[tb_warehouse] ADD  CONSTRAINT [DF_tb_warehouse_id_status]  DEFAULT ('ACTIVE') FOR [id_status]
GO
/****** Object:  StoredProcedure [dbo].[USP_CLEAN_CONSTRAINT]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 0. Helper to safely drop constraints and indexes
CREATE   PROCEDURE [dbo].[USP_CLEAN_CONSTRAINT] (@fkName NVARCHAR(128), @tableName NVARCHAR(128))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = @fkName AND parent_object_id = OBJECT_ID(@tableName))
    BEGIN
        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@tableName) + N' DROP CONSTRAINT ' + QUOTENAME(@fkName);
        EXEC(@sql);
    END
    IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = @fkName AND parent_object_id = OBJECT_ID(@tableName))
    BEGIN
        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@tableName) + N' DROP CONSTRAINT ' + QUOTENAME(@fkName);
        EXEC(@sql);
    END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_DROP_FK_IF_EXISTS]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Helper to drop constraints if they exist (from partial previous runs)
-- (We use this to ensure the final ADD CONSTRAINT doesn't fail on a naming conflict)
CREATE   PROCEDURE [dbo].[USP_DROP_FK_IF_EXISTS] (@fkName NVARCHAR(128), @tableName NVARCHAR(128))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = @fkName AND parent_object_id = OBJECT_ID(@tableName))
    BEGIN
        SET @sql = N'ALTER TABLE dbo.' + QUOTENAME(@tableName) + N' DROP CONSTRAINT ' + QUOTENAME(@fkName);
        EXEC(@sql);
    END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_DROP_INDEX_IF_EXISTS]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Helper to safely drop Index
CREATE   PROCEDURE [dbo].[USP_DROP_INDEX_IF_EXISTS] (@indexName NVARCHAR(128), @tableName NVARCHAR(128))
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = @indexName AND object_id = OBJECT_ID(@tableName))
    BEGIN
        SET @sql = N'DROP INDEX ' + QUOTENAME(@indexName) + N' ON dbo.' + QUOTENAME(@tableName);
        EXEC(@sql);
    END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_GENERATE_BUSINESS_ID]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* -------------------------------------------------------------------------
 * 1) USP_GENERATE_BUSINESS_ID (Canonical Generator) - Hardened & Guarded
 * ------------------------------------------------------------------------- */
CREATE   PROCEDURE [dbo].[USP_GENERATE_BUSINESS_ID]
    @TableName  NVARCHAR(100),          -- kept for signature compatibility (unused)
    @Prefix     NVARCHAR(10),
    @AutoID     INT,
    @OutputID   NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SeriesSize INT = 999999;   -- Max running number per series (6 digits)
    DECLARE @MaxAutoID  INT = 26 * 999999; -- 25,999,974 = last addressable id

    -- Guard: Prevent Silent Collision
    IF @AutoID IS NULL OR @AutoID < 1
        THROW 50001, N'USP_GENERATE_BUSINESS_ID: @AutoID must be >= 1.', 1;
    IF @AutoID > @MaxAutoID
        THROW 50002, N'USP_GENERATE_BUSINESS_ID: series space exhausted.', 1;

    -- Sanitize prefix: NULL-safe, trimmed, upper-cased, capped at 3 chars
    SET @Prefix = UPPER(LEFT(LTRIM(RTRIM(ISNULL(@Prefix, 'ERR'))), 3));

    DECLARE @SeriesIndex INT = ((@AutoID - 1) / @SeriesSize) % 26;  -- 0=A .. 25=Z
    DECLARE @SeriesChar  CHAR(1) = CHAR(65 + @SeriesIndex);        -- ASCII 65 = 'A'
    DECLARE @RunningNum  INT = ((@AutoID - 1) % @SeriesSize) + 1;  -- 1..999999

    SET @OutputID = @Prefix + @SeriesChar
                  + RIGHT('000000' + CAST(@RunningNum AS NVARCHAR(10)), 6);
END
GO
/****** Object:  StoredProcedure [dbo].[USP_GENERATE_ID]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* -------------------------------------------------------------------------
 * 2) USP_GENERATE_ID — FIXED: 1000000 -> 999999 (Wrapper logic)
 * ------------------------------------------------------------------------- */
CREATE   PROCEDURE [dbo].[USP_GENERATE_ID]
    @autoID  INT,
    @prefix  NVARCHAR(3),
    @new_id  NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @prefix = UPPER(LEFT(LTRIM(RTRIM(ISNULL(@prefix, 'ERR'))), 3));

    DECLARE @seriesIndex INT   = ((@autoID - 1) / 999999) % 26;   -- FIXED
    DECLARE @letter      NCHAR(1) = CHAR(65 + @seriesIndex);

    DECLARE @runningNum  INT   = ((@autoID - 1) % 999999) + 1;    -- FIXED
    DECLARE @digits      NVARCHAR(6) = RIGHT('000000' + CONVERT(NVARCHAR(6), @runningNum), 6);

    SET @new_id = @prefix + @letter + @digits;
END
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_COMPANY]    Script Date: 2026-06-17 2:45:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Auto Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_COMPANY]
ON [dbo].[tb_company]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_company t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_company] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_COMPANY]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_COMPANY_ID]    Script Date: 2026-06-17 2:45:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_COMPANY_ID]
ON [dbo].[tb_company]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE company_id IS NULL;

    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_company', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_company SET company_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;
    CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_company] ENABLE TRIGGER [TRIG_GENERATE_COMPANY_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER]    Script Date: 2026-06-17 2:45:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.1 Auto Update Date (UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER]
ON [dbo].[tb_customer]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE t
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_customer t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_customer] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_CUSTOMER]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_CUSTOMER_ID]    Script Date: 2026-06-17 2:45:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.2 Generate Business ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_CUSTOMER_ID]
ON [dbo].[tb_customer]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE customer_id IS NULL;

    OPEN cur;
    FETCH NEXT FROM cur INTO @autoID, @prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_customer',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;

        UPDATE tb_customer SET customer_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;

    CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_customer] ENABLE TRIGGER [TRIG_GENERATE_CUSTOMER_ID]
GO
/****** Object:  Trigger [dbo].[TRG_tb_customer_type_Insert]    Script Date: 2026-06-17 2:45:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   TRIGGER [dbo].[TRG_tb_customer_type_Insert]
ON [dbo].[tb_customer_type]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_code NVARCHAR(50);
    SELECT @autoID = autoID, @prefix = prefix FROM Inserted;

    EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
        @TableName = 'tb_customer_type', 
        @Prefix = @prefix, 
        @AutoID = @autoID, 
        @OutputID = @new_code OUTPUT;

    UPDATE dbo.tb_customer_type SET customer_type_id = @new_code WHERE autoID = @autoID;
END;
GO
ALTER TABLE [dbo].[tb_customer_type] ENABLE TRIGGER [TRG_tb_customer_type_Insert]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_tb_customer_type]    Script Date: 2026-07-03 (v5) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4.1 Auto Update Date (UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_tb_customer_type]
ON [dbo].[tb_customer_type]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE tb_customer_type
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_customer_type t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_customer_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_tb_customer_type]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_tb_customer_type_ID]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4.2 Generate Business ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_tb_customer_type_ID]
ON [dbo].[tb_customer_type]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @trig_autoID INT;
    DECLARE @trig_prefix NVARCHAR(3);
    DECLARE @generated_id NVARCHAR(50);

    DECLARE cur_gen_id CURSOR FOR 
    SELECT autoID, prefix FROM inserted WHERE customer_type_id IS NULL;

    OPEN cur_gen_id;
    FETCH NEXT FROM cur_gen_id INTO @trig_autoID, @trig_prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.USP_GENERATE_BUSINESS_ID 
            @TableName = 'tb_customer_type',
            @Prefix = @trig_prefix,
            @AutoID = @trig_autoID, 
            @OutputID = @generated_id OUTPUT;

        UPDATE tb_customer_type
        SET customer_type_id = @generated_id
        WHERE autoID = @trig_autoID;

        FETCH NEXT FROM cur_gen_id INTO @trig_autoID, @trig_prefix;
    END

    CLOSE cur_gen_id;
    DEALLOCATE cur_gen_id;
END;
GO
ALTER TABLE [dbo].[tb_customer_type] ENABLE TRIGGER [TRIG_GENERATE_tb_customer_type_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Auto Update Date (UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT]
ON [dbo].[tb_discount]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_discount t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_discount] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_DISCOUNT]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_DISCOUNT_ID]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_DISCOUNT_ID]
ON [dbo].[tb_discount]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE discount_id IS NULL;

    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_discount', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_discount SET discount_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;
    CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_discount] ENABLE TRIGGER [TRIG_GENERATE_DISCOUNT_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_tb_discount_type]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Update Date (UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_tb_discount_type] 
ON [dbo].[tb_discount_type] 
AFTER UPDATE 
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_discount_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_discount_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_tb_discount_type]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_tb_discount_type_ID]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID (Fixed Arguments)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_tb_discount_type_ID] 
ON [dbo].[tb_discount_type] 
AFTER INSERT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, 'DCT' FROM Inserted;
    
    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0 BEGIN
        -- Fixed: Added @TableName
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_discount_type',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;
        
        UPDATE t SET discount_type_id = @new_id, prefix = @prefix 
        FROM dbo.tb_discount_type t WHERE t.autoID = @autoID;
        
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END; CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_discount_type] ENABLE TRIGGER [TRIG_GENERATE_tb_discount_type_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT]    Script Date: 2026-06-17 2:45:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. TRIGGERS
-- 3.1 Auto Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT]
ON [dbo].[tb_product] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_product t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_product] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_PRODUCT]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_PRODUCT_ID]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_PRODUCT_ID]
ON [dbo].[tb_product] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE product_id IS NULL;
    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0 BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_product', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_product SET product_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END; CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_product] ENABLE TRIGGER [TRIG_GENERATE_PRODUCT_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_CATEGORY]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4.1 Auto Update Date (UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_CATEGORY]
ON [dbo].[tb_product_category]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE t
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_product_category t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_product_category] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_CATEGORY]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_PRODUCT_CATEGORY_ID]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4.2 Generate Business ID (Fixed Arguments)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_PRODUCT_CATEGORY_ID]
ON [dbo].[tb_product_category]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    
    DECLARE cur CURSOR FAST_FORWARD FOR 
        SELECT autoID, 'PCT' FROM inserted;

    OPEN cur;
    FETCH NEXT FROM cur INTO @autoID, @prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Fixed: Added @TableName
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_product_category',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;

        UPDATE tb_product_category
        SET product_category_id = @new_id, prefix = @prefix
        WHERE autoID = @autoID;

        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_product_category] ENABLE TRIGGER [TRIG_GENERATE_PRODUCT_CATEGORY_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_tb_product_format_type]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Update Date (Trigger on UPDATE Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_tb_product_format_type] 
ON [dbo].[tb_product_format_type] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_product_format_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_product_format_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_tb_product_format_type]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_tb_product_format_type_ID]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID (Fixed SP Arguments)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_tb_product_format_type_ID] 
ON [dbo].[tb_product_format_type] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, 'PFM' FROM Inserted; -- Force Prefix PFM
    
    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0 BEGIN
        -- FIXED: Added @TableName parameter
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_product_format_type',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;
        
        UPDATE t SET product_format_type_id = @new_id
        FROM dbo.tb_product_format_type t WHERE t.autoID = @autoID;
        
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END; CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_product_format_type] ENABLE TRIGGER [TRIG_GENERATE_tb_product_format_type_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_tb_product_group]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_tb_product_group] 
ON [dbo].[tb_product_group] 
AFTER UPDATE 
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_product_group t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_product_group] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_tb_product_group]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_tb_product_group_ID]    Script Date: 2026-06-17 2:45:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID (Fixed 4 Params)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_tb_product_group_ID] 
ON [dbo].[tb_product_group] 
AFTER INSERT 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, 'PGT' FROM Inserted;
    
    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0 BEGIN
        -- Fixed: Added @TableName
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_product_group',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;
        
        UPDATE t SET product_group_id = @new_id, prefix = @prefix 
        FROM dbo.tb_product_group t WHERE t.autoID = @autoID;
        
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END; CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_product_group] ENABLE TRIGGER [TRIG_GENERATE_tb_product_group_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_SKU]    Script Date: 2026-06-17 2:45:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. TRIGGERS
-- 3.1 Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_SKU]
ON [dbo].[tb_product_sku] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_product_sku t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_product_sku] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_PRODUCT_SKU]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_SKU_ID]    Script Date: 2026-06-17 2:45:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID
CREATE   TRIGGER [dbo].[TRIG_GENERATE_SKU_ID]
ON [dbo].[tb_product_sku] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE sku_id IS NULL;
    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0 BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_product_sku', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_product_sku SET sku_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END; CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_product_sku] ENABLE TRIGGER [TRIG_GENERATE_SKU_ID]
GO
/****** Object:  Trigger [dbo].[TRG_tb_reference_Insert]    Script Date: 2026-06-17 2:45:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   TRIGGER [dbo].[TRG_tb_reference_Insert]
ON [dbo].[tb_reference]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_code NVARCHAR(50);
    SELECT @autoID = autoID, @prefix = prefix FROM Inserted;

    EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
        @TableName = 'tb_reference', 
        @Prefix = @prefix, 
        @AutoID = @autoID, 
        @OutputID = @new_code OUTPUT;

    UPDATE dbo.tb_reference SET ref_id = @new_code WHERE autoID = @autoID;
END;
GO
ALTER TABLE [dbo].[tb_reference] ENABLE TRIGGER [TRG_tb_reference_Insert]
GO
/****** Object:  Trigger [dbo].[TRG_tb_reference_Update]    Script Date: 2026-06-17 2:45:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   TRIGGER [dbo].[TRG_tb_reference_Update]
ON [dbo].[tb_reference]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE t
       SET t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_reference t
      INNER JOIN inserted i ON t.ref_id = i.ref_id;
END;
GO
ALTER TABLE [dbo].[tb_reference] ENABLE TRIGGER [TRG_tb_reference_Update]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_tb_unit_type]    Script Date: 2026-07-03 (v5) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. [TRIGGER] 1: Auto Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_tb_unit_type]
ON [dbo].[tb_unit_type]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Prevent recursive trigger
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE tb_unit_type
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM tb_unit_type t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_unit_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_tb_unit_type]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_tb_unit_type_ID]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. [TRIGGER] 2: Generate Business ID (UNT...)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_tb_unit_type_ID]
ON [dbo].[tb_unit_type]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @trig_autoID INT;
    DECLARE @trig_prefix NVARCHAR(3);
    DECLARE @generated_id NVARCHAR(50);

    -- Cursor to handle Bulk Inserts safely
    DECLARE cur_gen_unit CURSOR FOR 
    SELECT autoID, prefix 
    FROM inserted 
    WHERE unit_type_id IS NULL;

    OPEN cur_gen_unit;
    FETCH NEXT FROM cur_gen_unit INTO @trig_autoID, @trig_prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Call Central Logic (Fixed: Added @TableName)
        EXEC dbo.USP_GENERATE_BUSINESS_ID 
            @TableName = 'tb_unit_type',
            @Prefix = @trig_prefix,
            @AutoID = @trig_autoID, 
            @OutputID = @generated_id OUTPUT;

        -- Update Business ID
        UPDATE tb_unit_type
        SET unit_type_id = @generated_id
        WHERE autoID = @trig_autoID;

        FETCH NEXT FROM cur_gen_unit INTO @trig_autoID, @trig_prefix;
    END

    CLOSE cur_gen_unit;
    DEALLOCATE cur_gen_unit;
END;
GO
ALTER TABLE [dbo].[tb_unit_type] ENABLE TRIGGER [TRIG_GENERATE_tb_unit_type_ID]
GO
/****** Object:  Trigger [dbo].[TRG_tb_users_Insert]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   TRIGGER [dbo].[TRG_tb_users_Insert]
ON [dbo].[tb_users]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_code NVARCHAR(50);
    SELECT @autoID = autoID, @prefix = prefix FROM Inserted;

    EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
        @TableName = 'tb_users', 
        @Prefix = @prefix, 
        @AutoID = @autoID, 
        @OutputID = @new_code OUTPUT;

    UPDATE dbo.tb_users SET user_id = @new_code WHERE autoID = @autoID;
END;
GO
ALTER TABLE [dbo].[tb_users] ENABLE TRIGGER [TRG_tb_users_Insert]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_USERS]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_USERS]
ON [dbo].[tb_users]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE tb_users
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    WHERE autoID IN (SELECT autoID FROM inserted);
END;

GO
ALTER TABLE [dbo].[tb_users] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_USERS]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.1 Auto Update Date
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR]
ON [dbo].[tb_vendor]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE t
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_vendor t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_vendor] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_VENDOR]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_VENDOR_ID]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.2 Generate Business ID (Standard v2.1.0)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_VENDOR_ID]
ON [dbo].[tb_vendor]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE vendor_id IS NULL;

    OPEN cur;
    FETCH NEXT FROM cur INTO @autoID, @prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calling Central SP (4 Params)
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_vendor',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;

        UPDATE tb_vendor SET vendor_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;

    CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_vendor] ENABLE TRIGGER [TRIG_GENERATE_VENDOR_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TYPE]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TYPE]
ON [dbo].[tb_vendor_type]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Prevent recursive trigger
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE t
    SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_vendor_type t
    INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_vendor_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_VENDOR_TYPE]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_VENDOR_TYPE_ID]    Script Date: 2026-06-17 2:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   TRIGGER [dbo].[TRIG_GENERATE_VENDOR_TYPE_ID]
ON [dbo].[tb_vendor_type]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    
    DECLARE insert_cursor CURSOR FAST_FORWARD FOR 
        SELECT autoID, 'VET' FROM inserted;

    OPEN insert_cursor;
    FETCH NEXT FROM insert_cursor INTO @autoID, @prefix;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- ✅ FIXED: Added @TableName parameter
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] 
            @TableName = 'tb_vendor_type',
            @Prefix = @prefix, 
            @AutoID = @autoID, 
            @OutputID = @new_id OUTPUT;

        UPDATE t
        SET vendor_type_id = @new_id, prefix = @prefix
        FROM dbo.tb_vendor_type t
        WHERE t.autoID = @autoID;

        FETCH NEXT FROM insert_cursor INTO @autoID, @prefix;
    END;

    CLOSE insert_cursor;
    DEALLOCATE insert_cursor;
END;
GO
ALTER TABLE [dbo].[tb_vendor_type] ENABLE TRIGGER [TRIG_GENERATE_VENDOR_TYPE_ID]
GO
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_WAREHOUSE]    Script Date: 2026-06-17 2:45:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.1 Auto Update Date (After Update Only)
CREATE   TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_WAREHOUSE]
ON [dbo].[tb_warehouse]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_warehouse t INNER JOIN inserted i ON t.autoID = i.autoID;
END;
GO
ALTER TABLE [dbo].[tb_warehouse] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_WAREHOUSE]
GO
/****** Object:  Trigger [dbo].[TRIG_GENERATE_WAREHOUSE_ID]    Script Date: 2026-06-17 2:45:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3.2 Generate ID (Call SP 4 Params)
CREATE   TRIGGER [dbo].[TRIG_GENERATE_WAREHOUSE_ID]
ON [dbo].[tb_warehouse]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE warehouse_id IS NULL;

    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_warehouse', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_warehouse SET warehouse_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;
    CLOSE cur; DEALLOCATE cur;
END;
GO
ALTER TABLE [dbo].[tb_warehouse] ENABLE TRIGGER [TRIG_GENERATE_WAREHOUSE_ID]
GO

-- =============================================================
-- v5 ADDED: tb_book Triggers
-- =============================================================
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK]
ON [dbo].[tb_book]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_book t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_book] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_BOOK]
GO

/****** Object:  Trigger [dbo].[TRIG_GENERATE_BOOK_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TRIG_GENERATE_BOOK_ID]
ON [dbo].[tb_book]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, prefix FROM inserted WHERE book_id IS NULL;

    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_book', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_book SET book_id = @new_id WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;
    CLOSE cur; DEALLOCATE cur;
END
GO
ALTER TABLE [dbo].[tb_book] ENABLE TRIGGER [TRIG_GENERATE_BOOK_ID]
GO

-- =============================================================
-- v5 ADDED: tb_book_type Triggers
-- =============================================================
/****** Object:  Trigger [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK_TYPE] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TRIG_AUTO_UPDATE_DATE_TB_BOOK_TYPE]
ON [dbo].[tb_book_type]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    UPDATE t SET update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    FROM dbo.tb_book_type t INNER JOIN inserted i ON t.autoID = i.autoID;
END
GO
ALTER TABLE [dbo].[tb_book_type] ENABLE TRIGGER [TRIG_AUTO_UPDATE_DATE_TB_BOOK_TYPE]
GO

/****** Object:  Trigger [dbo].[TRIG_GENERATE_BOOK_TYPE_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[TRIG_GENERATE_BOOK_TYPE_ID]
ON [dbo].[tb_book_type]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @autoID INT, @prefix NVARCHAR(3), @new_id NVARCHAR(50);
    DECLARE cur CURSOR FAST_FORWARD FOR SELECT autoID, 'BKT' FROM inserted WHERE book_type_id IS NULL;

    OPEN cur; FETCH NEXT FROM cur INTO @autoID, @prefix;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC [dbo].[USP_GENERATE_BUSINESS_ID] @TableName='tb_book_type', @Prefix=@prefix, @AutoID=@autoID, @OutputID=@new_id OUTPUT;
        UPDATE tb_book_type SET book_type_id = @new_id, prefix = @prefix WHERE autoID = @autoID;
        FETCH NEXT FROM cur INTO @autoID, @prefix;
    END;
    CLOSE cur; DEALLOCATE cur;
END
GO
ALTER TABLE [dbo].[tb_book_type] ENABLE TRIGGER [TRIG_GENERATE_BOOK_TYPE_ID]
GO

-- =============================================================
-- v5 ADDED: Business ID Unique Indexes (Section 6.1)
-- =============================================================
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_users_user_id] ON [dbo].[tb_users]([user_id]) WHERE [user_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_company_company_id] ON [dbo].[tb_company]([company_id]) WHERE [company_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_unit_type_unit_type_id] ON [dbo].[tb_unit_type]([unit_type_id]) WHERE [unit_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_format_type_id] ON [dbo].[tb_product_format_type]([product_format_type_id]) WHERE [product_format_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_category_id] ON [dbo].[tb_product_category]([product_category_id]) WHERE [product_category_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_type_id] ON [dbo].[tb_vendor_type]([vendor_type_id]) WHERE [vendor_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_type_id] ON [dbo].[tb_customer_type]([customer_type_id]) WHERE [customer_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_discount_type_id] ON [dbo].[tb_discount_type]([discount_type_id]) WHERE [discount_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_warehouse_id] ON [dbo].[tb_warehouse]([warehouse_id]) WHERE [warehouse_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_type_id] ON [dbo].[tb_book_type]([book_type_id]) WHERE [book_type_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_group_id] ON [dbo].[tb_product_group]([product_group_id]) WHERE [product_group_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_vendor_vendor_id] ON [dbo].[tb_vendor]([vendor_id]) WHERE [vendor_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_customer_customer_id] ON [dbo].[tb_customer]([customer_id]) WHERE [customer_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_discount_id] ON [dbo].[tb_discount]([discount_id]) WHERE [discount_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_product_id] ON [dbo].[tb_product]([product_id]) WHERE [product_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_product_sku_id] ON [dbo].[tb_product_sku]([sku_id]) WHERE [sku_id] IS NOT NULL;
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_tb_book_book_id] ON [dbo].[tb_book]([book_id]) WHERE [book_id] IS NOT NULL;
GO

-- =============================================================
-- v5 ADDED: Foreign Key Indexes (Section 6.1)
-- =============================================================
CREATE NONCLUSTERED INDEX [IX_tb_product_group_product_category_id] ON [dbo].[tb_product_group]([product_category_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_vendor_vendor_type_id] ON [dbo].[tb_vendor]([vendor_type_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_customer_customer_type_id] ON [dbo].[tb_customer]([customer_type_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_discount_discount_type_id] ON [dbo].[tb_discount]([discount_type_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_product_product_group_id] ON [dbo].[tb_product]([product_group_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_product_format_type_id] ON [dbo].[tb_product]([product_format_type_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_product_unit_type_id] ON [dbo].[tb_product]([unit_type_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_product_vendor_id] ON [dbo].[tb_product]([vendor_id]);
GO
CREATE NONCLUSTERED INDEX [IX_tb_product_sku_ref_product_id] ON [dbo].[tb_product_sku]([ref_product_id]);
GO
