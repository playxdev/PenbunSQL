
# 📘 PenbunSQL Standard Specification v4.0

**Project:** Penbun System (Distribution Center Database)
**Version:** 4.0.0 (Stable)
**Status:** Stable / Standard Compliant
**Effective Date:** 2026-06-17
**Architect:** PlayDevX

-----

## 1\. 🏁 Core Philosophy
1. **Business Unit First:** เน้นการจัดกลุ่มตามหน่วยธุรกิจ (BOOK, IT, SERVICE)
2. **Hybrid Inventory Logic:** ตาราง `tb_product` รองรับทั้งสินค้าและบริการผ่าน flag `count_stock`
3. **Creation is First Update:** ใช้ `update_date` เป็นตัวบอกเวลาสร้างและแก้ไขล่าสุด
4. **Strict Consistency:** บังคับใช้ Common Fields (8 รายการ) ในตารางหลัก

-----

## 2\. 🔠 Naming Conventions (มาตรฐานการตั้งชื่อ)

เพื่อให้โค้ด Clean และง่ายต่อการ Maintenance ในอนาคต

| Object Type | Naming Pattern | Example |
| :--- | :--- | :--- |
| **Table** | `tb_` + `snake_case` | `tb_product`, `tb_receive_note` |
| **Primary Key** | `autoID` | `autoID` (INT Identity Only) |
| **Business ID** | `[table_name_no_tb]_id` | `product_id`, `order_id` |
| **Foreign Key** | `[ref_table_no_tb]_id` | `customer_id`, `unit_type_id` |
| **Boolean/Flag** | `is_` + `verb/adjective` | `is_active`, `is_delete`, `is_vat` |
| **Trigger** | `TRIG_[ACTION]_[TABLE]` | `TRIG_AUTO_UPDATE_DATE_tb_product` |
| **Index** | `IX_[Table]_[Column]` | `IX_tb_product_product_code` |

-----

## 3\. 🧱 Standard Table Structure (โครงสร้างตารางมาตรฐาน)

### 3.1 Master & Header Tables (ตารางหลัก)

ตารางที่มี Prefix และ Business ID ต้องมีโครงสร้างดังนี้ (Strict v4.0+):

| Field Group | Field Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PK** | `autoID` | `INT IDENTITY(1,1)` | NO | - | Surrogate Key สำหรับ System |
| **ID System** | `prefix` | `NVARCHAR(3)` | NO | - | รหัสย่อตาราง (เช่น 'PDT') |
| | `[table]_id` | `NVARCHAR(50)` | NO | - | Business Key (Gen by Trigger) |
| **Audit** | `update_by` | `NVARCHAR(50)` | NO | 'System' | ผู้ทำรายการล่าสุด (ทั้งสร้างและแก้) |
| | `update_date` | `DATETIME` | NO | GETDATE() | เวลาทำรายการ (SE Asia Time) |
| **Status** | `is_active` | `BIT` | NO | 1 | 1=Active, 0=Inactive (กรอง Query ทั่วไป) |
| | `is_delete` | `BIT` | NO | 0 | 1=Deleted (Soft Delete) |
| | `id_status` | `NVARCHAR(20)` | NO | 'ACTIVE' | **Extended Status:** ACTIVE, INACTIVE, SUSPENDED |

> **💡 Note:** 
> * ใช้ Concept **"Creation is First Update"** โดยตัด `create_by` และ `create_date` ออก
> * `id_status` เก็บข้อความสถานะแบบขยาย (เช่น `ACTIVE`, `INACTIVE`, `SUSPENDED`) ในขณะที่ `is_active` ใช้สำหรับกรอง Boolean ในการ Query ทั่วไป

### 3.2 Detail / Transaction Item Tables (ตารางลูก)

ตารางรายการย่อย (เช่น `tb_order_item`) **ไม่ต้องมี Prefix และ Business ID**

| Field Group | Field Name | Data Type | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| **PK** | `autoID` | `INT IDENTITY(1,1)` | NO | Primary Key |
| **FK (Header)** | `[header]_id` | `NVARCHAR(50)` | NO | Link ไปตารางแม่ (เช่น `order_id`) |
| **FK (Item)** | `[product]_id` | `NVARCHAR(50)` | NO | Link ไปสินค้า (เช่น `product_id`) |
| **Data** | `qty` | `DECIMAL(18,4)` | NO | จำนวน (รองรับทศนิยม) |
| **Audit** | `update_date` | `DATETIME` | YES | วันที่ปรับปรุงล่าสุด |
| **Status** | `is_delete` | `BIT` | NO | 0=Normal, 1=Line Cancelled |

-----

## 4\. ⚙️ Core Engine & Logic

### 4.1 ID Generation Logic (Series A-Z)

ใช้ Stored Procedure: **`USP_GENERATE_BUSINESS_ID`** (รับ 4 Parameters)

  * **Pattern:** `[PREFIX 3 chars]` + `[SERIES A-Z]` + `[RUN 6 digits]`
  * **Example:** `PDTA999999` -\> `PDTB000001`

### 4.2 Timezone Logic & Audit Strategy

1.  **INSERT (Creation):** `update_date` ถูกเติมค่าโดยอัตโนมัติจาก **Default Constraint**
    ```sql
    DEFAULT CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
    ```
2.  **UPDATE (Modification):** `update_date` ถูกอัปเดตค่าใหม่จาก **Trigger** (`AFTER UPDATE`)

-----

## 5\. 🆔 Prefix Registry (Updated v4.0)

ทะเบียน Prefix ล่าสุดที่ใช้ในระบบ (อ้างอิงตาม Layer การสร้าง)

| Layer | Category | Table Name | Prefix | Note |
| :--- | :--- | :--- | :--- | :--- |
| **L1** | System | `tb_users` | **USR** | ผู้ใช้ระบบ |
| **L1** | System | `tb_reference` | **REF** | Running Number |
| **L1** | System | `tb_company` | **CPN** | **(New)** ข้อมูลนิติบุคคล |
| **L2** | Config | `tb_unit_type` | **UNT** | หน่วยนับ |
| **L2** | Config | `tb_product_format_type` | **PFM** | รูปแบบสินค้า |
| **L2** | Config | `tb_product_category` | **PCT** | หมวดบัญชี (Asset/Expense) |
| **L2** | Partner | `tb_vendor_type` | **VET** | ประเภทคู่ค้า |
| **L2** | Client | `tb_customer_type` | **CUT** | ประเภทลูกค้า |
| **L2** | Sales | `tb_discount_type` | **DCT** | ประเภทส่วนลด |
| **L2** | Stock | `tb_warehouse` | **WHS** | คลังสินค้า (DC/Branch/Defect/Province/International) |
| **L2** | Book | `tb_book_type` | **BKT** | **(New)** ประเภทหนังสือ |
| **L3** | Product | `tb_product_group` | **PGT** | กลุ่มสินค้า (Business Unit) |
| **L3** | Partner | `tb_vendor` | **VEN** | คู่ค้า |
| **L3** | Client | `tb_customer` | **CUS** | ลูกค้า |
| **L3** | Sales | `tb_discount` | **DSC** | แคมเปญส่วนลด |
| **L4** | Product | `tb_product` | **PDT** | สินค้า (Hybrid Core) |
| **L4** | Product | `tb_product_sku` | **SKU** | **(New)** SKU Variations |
| **L4** | Book | `tb_book` | **BOK** | **(New)** ข้อมูลหนังสือ |
| **L5** | Inbound | `tb_receive_note` | **RCV** | ใบรับสินค้า *(v4.1)* |
| **L6** | Outbound | `tb_order` | **ORD** | ใบสั่งซื้อ/ใบขาย *(v4.1)* |

-----

## 6\. 🔒 Safety & Constraints

### 6.1 Indexing Standard

เพื่อประสิทธิภาพสูงสุดในการ Query ด้วย Business ID

```sql
-- 1. Unique Index on Business ID (Prevent Duplicate ID)
CREATE UNIQUE NONCLUSTERED INDEX UQ_tablename_id ON dbo.tb_tablename(table_id) WHERE table_id IS NOT NULL;

-- 2. Index on Foreign Keys (Performance)
CREATE NONCLUSTERED INDEX IX_tablename_ref_id ON dbo.tb_tablename(ref_id);
```

### 6.2 Data Type Standards

  * **Money / Cost / Price:** `DECIMAL(18, 4)` (รองรับเศษสตางค์ละเอียด)
  * **Quantity:** `DECIMAL(18, 4)` (เผื่อตัดแบ่งหน่วยย่อย)
  * **Status / Flags:** `BIT` (0 or 1)
  * **Description / Remark:** `NVARCHAR(MAX)` หรือ `NVARCHAR(1000)`

-----

## 📝 Change Log

### v4.0.0 (17/06/2026)
  * **Added:** เพิ่ม `id_status` (NVARCHAR(20)) เป็น Common Field ลำดับที่ 8 — Dual Status กับ `is_active`
  * **Added:** Prefix ใหม่ 4 รายการ: **`CPN`** (`tb_company`), **`BKT`** (`tb_book_type`), **`SKU`** (`tb_product_sku`), **`BOK`** (`tb_book`)
  * **Fixed:** ปรับ `USP_GENERATE_BUSINESS_ID` และ `USP_GENERATE_ID` ให้ใช้ Series Letter (A-Z) และ Running 6 หลัก (1-999999)
  * **Updated:** เปลี่ยน Common Fields จาก 6 → 8 รายการ

### v2.3.0 (10/12/2025)
  * **Added:** เพิ่ม Prefix **`WHS`** (`tb_warehouse`) สำหรับรองรับโมเดล Multi-Location
  * **Verified:** ยืนยันมาตรฐาน Audit "Creation is First Update" ใช้ได้จริงในทุกตาราง