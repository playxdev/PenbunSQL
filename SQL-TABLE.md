# 🏗️ PenbunSQL v5.0.0 — Execution Order & Development Roadmap

เอกสารนี้ระบุลำดับการรัน SQL Script เพื่อสร้างฐานข้อมูล PenbunSQL v5.0.0 และติดตามสถานะการพัฒนา (Roadmap) ปัจจุบัน
**คำเตือน:** ห้ามสลับลำดับ Execution Order เนื่องจากมีการผูกความสัมพันธ์ (Foreign Key) ระหว่างตาราง
**SQL Script:** [`docs/SQL-PENBUN-v5.sql`](./docs/SQL-PENBUN-v5.sql)

**Status Legend:** * ✅ **Done** = สร้างและปรับปรุงตามมาตรฐานแล้ว
* ⏳ **Pending** = รอการพัฒนา / อยู่ระหว่างดำเนินการ

---

## 🚨 Phase 0: Standardization & Cleanup (Prerequisites)
งานปรับปรุงมาตรฐานและเคลียร์ของเก่าที่ **ทำเสร็จสมบูรณ์แล้ว** ก่อนเริ่มรันโครงสร้างใหม่:
* ✅ **Schema Update:** ตัด `create_by`/`date` ทิ้ง ใช้ `update_by`/`date` เป็นหลัก
* ✅ **Dual Status Fields:** เพิ่ม `id_status` (NVARCHAR(20)) คู่กับ `is_active` (BIT) สำหรับ Extended Status
* ✅ **Legacy Cleanup:** ลบตารางขยะ (`product_type`, `pack_config`, ฯลฯ) ออกจาก DB
* ✅ **FK Cleanup:** เคลียร์ Constraint เก่าที่ค้างอยู่
* ✅ **ID Gen Fix:** ปรับ `USP_GENERATE_BUSINESS_ID` และ `USP_GENERATE_ID` รองรับ Series A-Z และ Running 1-999999

---

## 🟢 Layer 1: System Core (Foundation)
ส่วนประกอบพื้นฐานของระบบ ต้องสร้างก่อนเป็นลำดับแรกเพื่อให้กลไก ID และ Audit Log ทำงานได้

| Order | Status | Object Type | Table Name / Object | Prefix | Description |
| :--- | :---: | :--- | :--- | :---: | :--- |
| 1 | ✅ **Done** | Stored Proc | `USP_GENERATE_BUSINESS_ID` | - | (Critical) ตัวสร้าง ID กลางแบบ 4 Params (Series A-Z) |
| 2 | ✅ **Done** | Table | `tb_users` | USR | ตารางผู้ใช้งาน (อ้างอิง `update_by` แบบ Standardized) |
| 3 | ✅ **Done** | Table | `tb_reference` | REF | ตาราง Running Number ของระบบ |
| 4 | ✅ **Done** | Table | `tb_company` | CPN | **(New)** ข้อมูลนิติบุคคล (Company Profile) |

---

## 🟡 Layer 2: Master Data (Level 0 - Independent)
ตาราง Master พื้นฐานที่ไม่มี Foreign Key (สามารถสร้างพร้อมกันได้)

| Order | Status | Object Type | Table Name | Prefix | Description |
| :--- | :---: | :--- | :--- | :---: | :--- |
| 5 | ✅ **Done** | Table | `tb_unit_type` | UNT | หน่วยนับ (ชิ้น, เล่ม, กล่อง) |
| 6 | ✅ **Done** | Table | `tb_product_format_type` | PFM | รูปแบบสินค้า (Physical, Digital, Service) |
| 7 | ✅ **Done** | Table | `tb_product_category` | PCT | หมวดบัญชี (Material, Finished Goods, Asset) |
| 8 | ✅ **Done** | Table | `tb_vendor_type` | VET | ประเภทคู่ค้า (Supplier, Logistics, Outsourcer) |
| 9 | ✅ **Done** | Table | `tb_customer_type` | CUT | ประเภทลูกค้า (เพิ่ม `base_credit_day`) |
| 10 | ✅ **Done** | Table | `tb_discount_type` | DCT | ประเภทส่วนลด |
| 11 | ✅ **Done** | Table | `tb_warehouse` | WHS | คลังสินค้า (DC, Branch, Defect, Province, International) |
| 12 | ✅ **Done** | Table | `tb_book_type` | BKT | **(New)** ประเภทหนังสือ (Book Label) |

---

## 🟠 Layer 3: Master Data (Level 1 - Dependent)
ตาราง Master ที่ต้องอ้างอิงข้อมูล (Foreign Key) จาก Layer 2

| Order | Status | Table Name | Prefix | Dependencies (FK) |
| :--- | :---: | :--- | :---: | :--- |
| 13 | ✅ **Done** | `tb_product_group` | PGT | 🔗 `tb_product_category` |
| 14 | ✅ **Done** | `tb_vendor` | VEN | 🔗 `tb_vendor_type` |
| 15 | ✅ **Done** | `tb_customer` | CUS | 🔗 `tb_customer_type` |
| 16 | ✅ **Done** | `tb_discount` | DSC | 🔗 `tb_discount_type` |

---

## 🔴 Layer 4: Business Core (Product, Book, SKU)
หัวใจสำคัญของระบบ (ตารางสินค้า บริการ และหนังสือ)

| Order | Status | Table Name | Prefix | Dependencies (FK) | Description & Logic |
| :--- | :---: | :--- | :---: | :--- | :--- |
| 17 | ✅ **Done** | `tb_product` | PDT | 🔗 `tb_product_group`<br>🔗 `tb_unit_type`<br>🔗 `tb_product_format_type` | **Hybrid Core:** ใช้ Flag `count_stock` (1=Stock, 0=Service) |
| 18 | ✅ **Done** | `tb_product_sku` | SKU | 🔗 `tb_product` | **(New)** SKU Variations (แยกตามเล่ม/ฉบับ/รูปแบบ) |
| 19 | ✅ **Done** | `tb_book` | BOK | — | **(New)** ข้อมูลหนังสือ (Book Master) |

---

## 🟣 Layer 5: Inbound Transactions (Receive — Coming in v4.1)
โมดูลการรับสินค้าเข้าสต็อก *(อยู่ในระหว่างออกแบบ)*

| Order | Status | Table Name | Prefix | Type | Dependencies (FK) |
| :--- | :---: | :--- | :---: | :--- | :--- |
| 20 | ⏳ **Pending** | `tb_receive_note` | RCV | Header | 🔗 `tb_vendor` 🔗 `tb_warehouse` 🔗 `tb_users` |
| 21 | ⏳ **Pending** | `tb_receive_item` | — | Detail | 🔗 `tb_receive_note` 🔗 `tb_product` |

---

## 🔵 Layer 6: Outbound Transactions (Order/Sale — Coming in v4.1)
โมดูลการขายและตัดสต็อก *(อยู่ในระหว่างออกแบบ)*

| Order | Status | Table Name | Prefix | Type | Dependencies (FK) |
| :--- | :---: | :--- | :---: | :--- | :--- |
| 22 | ⏳ **Pending** | `tb_order` | ORD | Header | 🔗 `tb_customer` 🔗 `tb_warehouse` 🔗 `tb_users` |
| 23 | ⏳ **Pending** | `tb_order_item` | — | Detail | 🔗 `tb_order` 🔗 `tb_product` 🔗 `tb_discount` |

---

## 🏗️ Future Phase: Inventory & Distribution (v4.2+)
ระบบบริหารจัดการคลังสินค้าเต็มรูปแบบ (หลังจากเสร็จสิ้น Layer 5-6)

* ⏳ **Create Table:** `tb_product_stock` (Balance Table per Warehouse)
  * PK: `product_id` + `warehouse_id`
* ⏳ **Create Module:** Internal Transfer (`tb_transfer_note`)
* ⏳ **Logic:** ระบบคำนวณต้นทุน (Moving Average Cost)

---

## 🗺️ Dependency Map (Updated v4.0.0)
แผนผังแสดง Dependency ของตารางในระบบปัจจุบัน

```
Layer 1 (Core)
  ├── tb_users (USR)          ─── อ้างอิง update_by
  ├── tb_reference (REF)      ─── Running Number
  └── tb_company (CPN)        ─── ข้อมูลนิติบุคคล

Layer 2 (Master Independent)
  ├── tb_unit_type (UNT)
  ├── tb_product_format_type (PFM)
  ├── tb_product_category (PCT)
  ├── tb_vendor_type (VET)
  ├── tb_customer_type (CUT)
  ├── tb_discount_type (DCT)
  ├── tb_warehouse (WHS)
  └── tb_book_type (BKT)

Layer 3 (Master Dependent)
  ├── tb_product_group (PGT)  ─── 🔗 PCT
  ├── tb_vendor (VEN)         ─── 🔗 VET
  ├── tb_customer (CUS)       ─── 🔗 CUT
  └── tb_discount (DSC)       ─── 🔗 DCT

Layer 4 (Business Core)
  ├── tb_product (PDT)        ─── 🔗 PGT, UNT, PFM
  ├── tb_product_sku (SKU)    ─── 🔗 PDT
  └── tb_book (BOK)

Layer 5-6 (Transactions — Pending)
  ├── tb_receive_note (RCV)   ─── 🔗 VEN, WHS, USR
  └── tb_order (ORD)          ─── 🔗 CUS, WHS, USR
```
---
> 📝 **Note for Developer:**
> Database ปัจจุบัน (Layer 1-4) สะอาดและพร้อมใช้งานแล้ว มีตารางใหม่ 4 ตาราง (`tb_company`, `tb_book_type`, `tb_product_sku`, `tb_book`) เทียบกับ v3.0.1
> ลำดับต่อไปคือเริ่มออกแบบ Transaction Layer (v4.1) และ Inventory System (v4.2)