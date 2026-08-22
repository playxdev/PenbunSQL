
# 📘 PenbunSQL Standard Specification v7.0

**Project:** Penbun System (Distribution Center Database)
**Version:** 7.0.0
**Status:** Stable / Standard Compliant
**Effective Date:** 2026-08-21
**Architect:** PlayDevX
**Reference Script:** [`docs/SQL-PENBUN-v7.sql`](./docs/SQL-PENBUN-v7.sql)

-----

## 1. 🏁 Core Philosophy

1. **Business Unit First:** จัดกลุ่มตามหน่วยธุรกิจ (BOOK, MAGZ, SERVICE, IT, PACK, STATION)
2. **Hybrid Inventory Logic:** `tb_product` รองรับทั้งสินค้าและบริการผ่าน flag `count_stock`
3. **Creation is First Update:** ใช้ `update_date` เป็นตัวบอกทั้งเวลาสร้างและแก้ไขล่าสุด
4. **Strict Consistency:** บังคับใช้ Common Fields (8 รายการ) ในทุกตาราง
5. **🆕 Integrity at the Database:** กฎธุรกิจที่บังคับได้ ต้องบังคับที่ DB ไม่ใช่ที่ Application
   → Foreign Key, CHECK Constraint, Status Invariant Trigger, Block-Delete Trigger
6. **🆕 Ledger is Truth, Balance is Cache:** ยอดคงเหลือทุกชนิดต้องสร้างใหม่ได้จาก Ledger เสมอ

> **หลักตัดสินใจ:** ถ้ากฎหนึ่งบังคับที่ DB ได้ ห้ามปล่อยให้เป็นแค่ข้อตกลงในเอกสาร
> v5 เขียนว่า *"ห้ามใช้ DELETE"* แต่ไม่มีอะไรบังคับ — v7 บังคับด้วย Trigger + FK

-----

## 2. 🔠 Naming Conventions

| Object Type | Naming Pattern | Example |
| :--- | :--- | :--- |
| **Table** | `tb_` + `snake_case` | `tb_product`, `tb_receive_note` |
| **Primary Key** | `autoID` | `INT IDENTITY` เท่านั้น |
| **Business ID** | `[table_no_tb]_id` | `product_id`, `order_id` |
| **🆕 Foreign Key Column** | `ref_[parent_no_tb]_auto` | `ref_customer_auto`, `ref_sku_auto` |
| **Boolean / Flag** | `is_` + `verb/adjective` | `is_active`, `is_delete`, `is_vat` |
| **View** | `vw_` + `snake_case` | `vw_order_header`, `vw_stock_onhand` |
| **Stored Procedure** | `USP_[VERB]_[OBJECT]` | `USP_POST_ORDER`, `USP_REBUILD_STOCK_CACHE` |
| **Trigger** | `TRIG_[ACTION]_[TABLE_UPPER]` | `TRIG_GENERATE_TB_ORDER_ID` |
| **PK Constraint** | `PK_[table]` | `PK_tb_product` |
| **FK Constraint** | `FK_[table]_[column]` | `FK_tb_order_ref_customer_auto` |
| **CHECK Constraint** | `CK_[table]_[topic]` | `CK_tb_order_status` |
| **Default Constraint** | `DF_[table]_[column]` | `DF_tb_product_is_active` |
| **Unique Index** | `UQ_[table]_[topic]` | `UQ_tb_order_doc_no` |
| **Normal Index** | `IX_[table]_[column]` | `IX_tb_order_ref_customer_auto` |

> **⚠️ เปลี่ยนจาก v4/v5:**
> FK Column เดิมใช้ Business ID (`customer_id NVARCHAR(50)`) — **ยกเลิกแล้ว**
> ใช้ `ref_customer_auto INT` แทน เหตุผลอยู่ในหัวข้อ 4.3
>
> Trigger เดิมมี 3 รูปแบบปนกัน (`TRIG_GENERATE_BOOK_ID`, `TRIG_GENERATE_tb_customer_type_ID`, `TRG_tb_reference_Update`) — v7 ใช้รูปแบบเดียวทั้งระบบ

-----

## 3. 🧱 Standard Table Structure

### 3.1 Common Fields (บังคับทุกตาราง — 8 รายการ)

| Field Group | Field Name | Data Type | Nullable | Default | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PK** | `autoID` | `INT IDENTITY(1,1)` | NO | — | Surrogate Key + **เป้าหมายของ FK ทั้งระบบ** |
| **ID System** | `prefix` | `NVARCHAR(3)` | NO | ค่าคงที่ต่อตาราง | รหัสย่อตาราง (เช่น `'PDT'`) |
| | `[table]_id` | `NVARCHAR(50)` | YES* | — | Business Key (Gen by Trigger) |
| **Audit** | `update_by` | `NVARCHAR(50)` | NO | `'System'` | ผู้ทำรายการล่าสุด (ทั้งสร้างและแก้) |
| | `update_date` | `DATETIME` | NO | SE Asia now | เวลาทำรายการ |
| **Status** | `is_active` | `BIT` | NO | `1` | 1=Active, 0=Inactive |
| | `is_delete` | `BIT` | NO | `0` | 1=Deleted (Soft Delete) |
| | `id_status` | `NVARCHAR(20)` | NO | `'ACTIVE'` | Extended Status |

> **\* ทำไม Business ID เป็น `NULL` ได้:**
> Trigger `AFTER INSERT` เป็นตัวเติมค่า จึงต้องยอมให้เป็น `NULL` ชั่วขณะ
> ป้องกันการซ้ำด้วย **Filtered Unique Index** (`WHERE ... IS NOT NULL`) — ดูหัวข้อ 4.6

### 3.2 Detail / Item Tables

> **⚠️ เปลี่ยนจาก v4/v5:** เดิมกำหนดว่าตารางลูก *"ไม่ต้องมี Prefix และ Business ID"*
> **v7 ยกเลิกข้อยกเว้นนี้** — ตารางลูกต้องมี Common Fields ครบ 8 รายการเหมือนตารางแม่

**เหตุผล:**
* ทำให้ Soft Delete รายบรรทัดตรวจสอบย้อนหลังได้ (ใครลบบรรทัดไหน เมื่อไหร่)
* Trigger แบบ Set-Based ทำให้ต้นทุนการ gen ID ต่ำมาก (ใบละ 1 ครั้ง ไม่ว่ากี่บรรทัด — ดูหัวข้อ 4.5)
* ลดจำนวนกฎที่ต้องจำจาก 2 ชุด เหลือ 1 ชุด

ตารางลูกต้องมีเพิ่มจาก Common Fields:

| Field | Data Type | Description |
| :--- | :--- | :--- |
| `ref_[header]_auto` | `INT NOT NULL` | FK ไปตารางแม่ |
| `line_no` | `INT NOT NULL` | ลำดับบรรทัด (unique ร่วมกับ header) |
| `ref_sku_auto` | `INT NOT NULL` | FK ไปสินค้า |

พร้อม Unique Index: `UQ_[table]_line ON (ref_[header]_auto, line_no) WHERE is_delete = 0`

### 3.3 Computed Columns

ค่าที่คำนวณจากคอลัมน์อื่นในแถวเดียวกัน **ต้องใช้ Computed Column** ห้ามให้ Application คำนวณแล้วเก็บ

```sql
[amount]         AS ([qty_delivered]*[unit_price]) PERSISTED,
[qty_available]  AS ([qty_onhand]-[qty_reserved])  PERSISTED,
[qty_outstanding] AS ([qty_delivered]-[qty_returned]) PERSISTED,
```

ใช้ `PERSISTED` เสมอ เพื่อให้สร้าง Index บนคอลัมน์นั้นได้

-----

## 4. ⚙️ Core Engine & Logic

### 4.1 ID Generation (Series A-Z)

* **Pattern:** `[PREFIX 3 chars]` + `[SERIES A-Z]` + `[RUN 6 digits]`
* **Example:** `PDTA999999` → `PDTB000001`
* **Source of truth:** `tb_reference` (`ref_id` = ชื่อตาราง, `ref_int` = เลขล่าสุด, `ref_text` = Series)

| Procedure | ใช้เมื่อไหร่ |
| :--- | :--- |
| `USP_ALLOCATE_BUSINESS_ID_BLOCK` | **ตัวหลัก** — จองเลขเป็นบล็อก เรียกโดย Trigger เท่านั้น |
| `USP_GENERATE_BUSINESS_ID` | Wrapper แบบทีละแถว เก็บไว้เพื่อความเข้ากันได้ |

> **ห้ามแก้ `tb_reference` ด้วยมือหรือจาก Application เด็ดขาด** — ทุกการเปลี่ยนแปลงต้องผ่าน
> `USP_ALLOCATE_BUSINESS_ID_BLOCK` เท่านั้น การ `UPDATE ref_int` เองจะทำลายกลไกกันชนทั้งระบบ

### 4.2 🆕 Concurrency Contract ของ Auto-ID

กลไกทั้งหมดพึ่งสองบรรทัดนี้ **ห้ามแก้ hint ออกไม่ว่ากรณีใด**

```sql
SELECT @cur = ref_int, @Series = ISNULL(ref_text, N'A')
  FROM dbo.tb_reference WITH (UPDLOCK, HOLDLOCK)   -- <<< ห้ามถอด
 WHERE ref_id = @TableName;
```

| Hint | หน้าที่ | ถ้าถอดออก |
| :--- | :--- | :--- |
| `UPDLOCK` | จับ **U lock ตั้งแต่ตอนอ่าน** (U ไม่เข้ากับ U) | สอง session อ่าน `ref_int` ค่าเดียวกัน → **ID ซ้ำ** |
| `HOLDLOCK` | ถือ lock จนจบ transaction ไม่ใช่จบ statement | lock ปล่อยก่อน `UPDATE` → **ID ซ้ำ** |
| `WHERE ref_id = ...` | `ref_id` เป็น clustered PK → ล็อกแค่ **1 แถว** | ล็อกกว้างเกินจำเป็น ทุกตารางบล็อกกันหมด |

**พฤติกรรมเมื่อมี 10 session ยิงพร้อมกันที่ตารางเดียวกัน:**

| ลำดับ | Session | ผล |
| :---: | :--- | :--- |
| 1 | A | จับ U lock อ่าน `ref_int = 100` เขียน 110 → ได้ช่วง **101–110** |
| 2 | B–J | รอที่ `SELECT ... UPDLOCK` (blocked) |
| 3 | A commit | ปล่อย lock |
| 4 | B | อ่าน `ref_int = 110` → ได้ช่วง **111–120** |

⇒ ไม่มีทางที่สอง session อ่านค่าเดิมซ้ำ **การันตีว่า ID ไม่ซ้ำ**

**ตาข่ายนิรภัยชั้นสอง:** `UQ_<table>_id` (filtered unique index) จะโยน error 2601 ถ้าเกิดซ้ำจริง ⇒ transaction rollback ไม่ใช่ข้อมูลเสียเงียบ ๆ

#### 4.2.1 Gapless — คุณสมบัติที่ตั้งใจ ไม่ใช่ผลข้างเคียง

`UPDATE tb_reference` อยู่ใน transaction เดียวกับ `INSERT` ⇒ **rollback แล้วเลขคืนให้** ไม่เกิดเลขกระโดด
เป็นข้อกำหนดทางบัญชีสำหรับเลขที่เอกสาร และเป็นเหตุผลที่ **ห้ามเปลี่ยนไปใช้ `SEQUENCE`** กับตารางเอกสาร

| กลุ่มตาราง | ต้อง Gapless? | กลไกที่อนุญาต |
| :--- | :---: | :--- |
| เอกสาร (`RCV` `ORD` `RTN` `VRN`) + Master ทุกตัว | ✅ | `USP_ALLOCATE_BUSINESS_ID_BLOCK` เท่านั้น |
| Ledger / Item / Cache (`STM` `STK` `CSB` `RCI` `ODI` `RTI` `VRI` `AHS`) | ❌ | อนุญาตให้ใช้ `SEQUENCE` ได้ถ้าต้องการ throughput |

#### 4.2.2 ต้อง Pre-Seed `tb_reference` ตอนติดตั้ง

Proc มี fallback `IF NOT EXISTS (...) INSERT ...` ซึ่งทำงานเฉพาะ **แถวแรกสุดของตารางนั้นตลอดกาล**
ตอนที่แถวยังไม่มี SQL Server ต้องใช้ **range lock (RangeS-U)** แทน row lock ธรรมดา — ยัง serialize ถูกต้อง
แต่เป็นจุดเดียวในระบบที่ความถูกต้องขึ้นกับพฤติกรรม range lock

**กฎ:** Deploy script ต้อง pre-seed `tb_reference` ให้ครบทุกตารางที่มี Business ID เพื่อให้ path นั้นไม่มีวันทำงาน

```sql
INSERT INTO dbo.tb_reference (ref_id, ref_int, ref_text, prefix, update_by)
SELECT v.t, 0, N'A', N'REF', N'System'
  FROM (VALUES ('tb_order'),('tb_order_item'),('tb_stock_movement') /* ...ครบทุกตาราง */ ) AS v(t)
 WHERE NOT EXISTS (SELECT 1 FROM dbo.tb_reference r WHERE r.ref_id = v.t);
```

### 4.3 🆕 Canonical Lock Order (กันตายด้วย Deadlock)

`HOLDLOCK` ถือ lock จนจบ **outer transaction** ⇒ Stored Procedure ที่ครอบด้วย `BEGIN TRAN`
จะสะสม lock บน `tb_reference` หลายแถวพร้อมกัน

**ถ้า proc สองตัวจับ lock คนละลำดับ = Deadlock ทันที**

**ลำดับบังคับ — proc ใหม่ทุกตัวต้องแตะตารางตามลำดับนี้เท่านั้น:**

```
1. tb_stock_movement      (STM)   ← Ledger มาก่อนเสมอ
2. tb_product_stock       (STK)
3. tb_consign_balance     (CSB)
4. tb_allocation_history  (AHS)
5. ตารางเอกสาร (ORD / RCV / RTN / VRN) — UPDATE สถานะเป็นขั้นสุดท้าย
```

| Procedure | ลำดับที่ใช้จริง | สอดคล้อง? |
| :--- | :--- | :---: |
| `USP_POST_RECEIVE` | STM → STK → RCV | ✅ |
| `USP_POST_ORDER` | STM → STK → CSB → AHS → ORD | ✅ |
| `USP_POST_RETURN` | STM → STK → CSB → AHS → RTN | ✅ |
| `USP_POST_VENDOR_RETURN` | STM → STK → VRN | ✅ |

> **ตัวอย่างที่ห้ามเขียน:** proc ที่ `INSERT tb_allocation_history` ก่อนแล้วค่อย `INSERT tb_stock_movement`
> จะจับ AHS → STM สวนทางกับ `USP_POST_ORDER` ที่จับ STM → AHS ⇒ วิ่งพร้อมกันเมื่อไหร่ deadlock ทันที

### 4.4 🆕 Throughput Impact ที่ต้องยอมรับ

เพราะทุก `USP_POST_*` แตะ `tb_stock_movement` เหมือนกันหมด **การ POST เอกสารจึงถูก serialize ทั้งระบบ**

| สถานการณ์ | ผล | ประเมิน |
| :--- | :--- | :--- |
| INSERT Master ธรรมดา (autocommit) | lock สั้นมาก | ✅ ไม่มีปัญหา |
| 10 คน POST พร้อมกัน @ 100 ms/ใบ | เข้าคิว รอสูงสุด ~1 วินาที | ✅ ยอมรับได้ |
| ปิดงวด POST 500 ใบรวด | ~50 วินาทีต่อคนที่รอ | ⚠️ ต้องแยกคิว/ทำนอกเวลา |

**ข้อดีที่ออกแบบไว้:** แต่ละตารางใช้คนละแถวใน `tb_reference` ⇒ คนที่กำลังเพิ่มลูกค้า **ไม่บล็อก** คนที่กำลัง POST ใบส่ง

**กฎ:** `USP_POST_*` ต้องทำงานให้สั้นที่สุด — **ห้ามมี `WAITFOR`, การเรียก external, หรือ query รายงานหนัก ๆ อยู่ใน transaction**

### 4.5 🆕 Trigger ต้องเป็น Set-Based ห้ามใช้ CURSOR

v5 ใช้ `CURSOR` + `EXEC` ทีละแถว ⇒ ใบส่ง 500 บรรทัด = แตะ `tb_reference` **500 ครั้ง**
v7 จองเลขครั้งเดียวแล้วแจกด้วย `ROW_NUMBER()` ⇒ **1 ครั้ง**

**Template มาตรฐาน:**

```sql
CREATE TRIGGER [dbo].[TRIG_GENERATE_TB_ORDER_ID] ON [dbo].[tb_order] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    -- ไม่ใส่ NESTLEVEL guard โดยตั้งใจ : INSERT จาก proc ก็ต้องได้ Business ID
    DECLARE @cnt INT = (SELECT COUNT(*) FROM inserted WHERE [order_id] IS NULL);
    IF @cnt = 0 RETURN;

    DECLARE @startNo INT, @series NVARCHAR(1);
    EXEC [dbo].[USP_ALLOCATE_BUSINESS_ID_BLOCK]
         @TableName = N'tb_order', @BlockSize = @cnt,
         @StartNo = @startNo OUTPUT, @Series = @series OUTPUT;

    ;WITH src AS (SELECT autoID, prefix, ROW_NUMBER() OVER (ORDER BY autoID) - 1 AS rn
                    FROM inserted WHERE [order_id] IS NULL)
    UPDATE t SET t.[order_id] = src.prefix + @series
                + RIGHT(N'000000' + CAST(@startNo + src.rn AS NVARCHAR(10)), 6)
      FROM dbo.tb_order t INNER JOIN src ON t.autoID = src.autoID;
END
```

**กฎการใส่ NESTLEVEL guard:**

| Trigger | Guard? | เหตุผล |
| :--- | :---: | :--- |
| `TRIG_GENERATE_*_ID` | ❌ ไม่ใส่ | INSERT จาก Stored Procedure ก็ต้องได้ ID |
| `TRIG_AUTO_UPDATE_DATE_*` | ✅ ใส่ | กัน recursion จาก UPDATE ของ trigger ตัวอื่น |
| `TRIG_SYNC_STATUS_*` | ✅ ใส่ | เหตุผลเดียวกัน |
| `TRIG_BLOCK_DELETE_*` | ❌ ไม่ใส่ | เป็น `INSTEAD OF` ไม่เกิด recursion |

### 4.6 🆕 Foreign Key Strategy — ทำไมต้องอ้าง `autoID`

**ปัญหา:** Business ID เป็น `NULL` ตอน `INSERT` (Trigger เติมทีหลัง) จึงต้องใช้ **Filtered Unique Index** และ SQL Server **ไม่ยอมให้ Filtered Index รองรับ `FOREIGN KEY`**

จะเปลี่ยนเป็น Unique Index ธรรมดาก็ไม่ได้ เพราะ **multi-row INSERT จะมีหลายแถวที่ Business ID เป็น `NULL` พร้อมกัน** ก่อน Trigger ทำงาน ⇒ ชน unique ทันที

**ทางออก:** ให้ FK อ้าง `autoID` (PK, `INT`, `NOT NULL` เสมอ)

| ผลที่ได้ | |
| :--- | :--- |
| ✅ ผูก FK ได้ 100% | v5 = 0 ตัว → v7 = 53 ตัว |
| ⚡ Index เล็กลง ~25 เท่า | `INT` 4 byte แทน `NVARCHAR(50)` 100 byte |
| 🔒 บังคับ Soft Delete | `ON DELETE NO ACTION` ทำให้ลบตารางแม่ที่มีลูกอ้างอยู่ไม่ได้ |

**Business ID ยังใช้เป็น Public Key** สำหรับผู้ใช้และ API — อ่านผ่าน **View** (หัวข้อ 5)

```sql
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [FK_tb_order_ref_customer_auto]
    FOREIGN KEY([ref_customer_auto]) REFERENCES [dbo].[tb_customer] ([autoID]);
```

### 4.7 Timezone Logic

ห้ามใช้ `GETDATE()` ทุกกรณี ใช้ `SE Asia Standard Time` เท่านั้น

```sql
-- Default Constraint
DEFAULT (CONVERT([datetime],(sysdatetimeoffset() AT TIME ZONE 'SE Asia Standard Time')))

-- ใน Trigger / Procedure
CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
```

### 4.8 🆕 Status Invariant

3 คอลัมน์สถานะต้องสอดคล้องกันเสมอ **บังคับด้วย Trigger** ไม่ใช่หวังพึ่ง Application

| `is_delete` | `is_active` | `id_status` | ถูกต้อง? |
| :---: | :---: | :--- | :---: |
| 0 | 1 | `ACTIVE` | ✅ |
| 0 | 0 | `INACTIVE` | ✅ |
| 1 | 0 | `DELETED` | ✅ |
| 1 | **1** | `ACTIVE` | ❌ **เกิดขึ้นจริงใน v5** |

```sql
CREATE TRIGGER [dbo].[TRIG_SYNC_STATUS_TB_ORDER] ON [dbo].[tb_order] AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL() > 1 RETURN;
    IF NOT UPDATE([is_delete]) RETURN;
    UPDATE t SET t.is_active = 0, t.id_status = N'DELETED'
      FROM dbo.tb_order t INNER JOIN inserted i ON t.autoID = i.autoID
     WHERE i.is_delete = 1 AND (t.is_active = 1 OR t.id_status <> N'DELETED');
END
```

### 4.9 🆕 Block Hard Delete

ทุกตารางต้องมี `INSTEAD OF DELETE` trigger แปลง `DELETE` เป็น Soft Delete

```sql
CREATE TRIGGER [dbo].[TRIG_BLOCK_DELETE_TB_ORDER] ON [dbo].[tb_order] INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.is_delete = 1, t.is_active = 0, t.id_status = N'DELETED',
                 t.update_date = CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time' AS DATETIME)
      FROM dbo.tb_order t INNER JOIN deleted d ON t.autoID = d.autoID;
END
```

> **⚠️ ผลข้างเคียงที่ต้องรู้:** ตารางที่มี `INSTEAD OF` trigger จะใช้ `OUTPUT` clause แบบไม่มี `INTO` ไม่ได้
> ถ้า Application ต้องการค่าที่เพิ่ง insert ให้ `SELECT` ตามหลังแทน

-----

## 5. 🔍 🆕 Read / Write Model Separation

| ทิศทาง | ช่องทางที่อนุญาต | ห้าม |
| :--- | :--- | :--- |
| **อ่าน** | `vw_*` (View) | `SELECT` ตารางดิบแล้วเขียน JOIN เอง |
| **เขียน (Master)** | `INSERT` / `UPDATE` ตารางตรง ๆ | — |
| **เขียน (Transaction)** | `USP_POST_*` | อัปเดตสต็อก/ยอดคงค้างเอง |
| **สต็อก** | `USP_APPLY_STOCK_MOVEMENT` เท่านั้น | `UPDATE tb_product_stock` ตรง ๆ |

**เหตุผล:** View แปลง `ref_*_auto` → Business ID ให้แล้ว ทำให้ API ไม่ต้องรู้เรื่อง `autoID` และเปลี่ยน schema ภายในได้โดยไม่กระทบ API

### 5.1 🆕 Ledger vs Cache

| ตาราง | ประเภท | Rebuild ด้วย |
| :--- | :--- | :--- |
| `tb_stock_movement` | **Ledger** (append-only) | — คือความจริง |
| `tb_product_stock` | Cache | `USP_REBUILD_STOCK_CACHE` |
| `tb_consign_balance` | Cache | `USP_REBUILD_CONSIGN_BALANCE` |

**กฎ:** ตาราง Cache ทุกตัวต้องมี Procedure สร้างใหม่จาก Ledger ได้ 100% ถ้าเขียน Cache ใหม่โดยไม่มี Rebuild Procedure ถือว่าผิดมาตรฐาน

Ledger ต้องเก็บที่มาของทุกความเคลื่อนไหว: `doc_table` + `doc_auto` + `doc_no`

-----

## 6. 🔒 Safety & Constraints

### 6.1 Indexing Standard

ทุกตารางต้องมีครบ 4 ชั้น:

```sql
-- 1. Business ID (filtered — เพราะ Trigger เติมค่าหลัง INSERT)
CREATE UNIQUE NONCLUSTERED INDEX UQ_tb_order_id
    ON dbo.tb_order(order_id) WHERE order_id IS NOT NULL;

-- 2. Natural Key (filtered ด้วย is_delete เพื่อให้ Soft Delete แล้วสร้างซ้ำได้)
CREATE UNIQUE NONCLUSTERED INDEX UQ_tb_order_doc_no
    ON dbo.tb_order(doc_no) WHERE is_delete = 0;

-- 3. Foreign Key (SQL Server ไม่สร้างให้อัตโนมัติ)
CREATE NONCLUSTERED INDEX IX_tb_order_ref_customer_auto
    ON dbo.tb_order(ref_customer_auto);

-- 4. Query-specific (เท่าที่จำเป็น)
CREATE NONCLUSTERED INDEX IX_tb_order_period
    ON dbo.tb_order(period_key, ref_route_auto) INCLUDE (ref_customer_auto, doc_status);
```

### 6.2 🆕 CHECK Constraint Standard

ทุกคอลัมน์ที่เป็น **enum แบบปิด** ต้องมี `CHECK` ห้ามปล่อยเป็น free text

```sql
ALTER TABLE [dbo].[tb_order] WITH CHECK ADD CONSTRAINT [CK_tb_order_status]
    CHECK ([doc_status] IN (N'DRAFT', N'CONFIRMED', N'DELIVERED', N'INVOICED', N'CANCELLED'));
```

**เกณฑ์เลือกระหว่าง CHECK กับตาราง Type:**

| ใช้ CHECK | ใช้ตาราง Type |
| :--- | :--- |
| ค่าคงที่ เปลี่ยนพร้อมโค้ดเท่านั้น | ผู้ใช้เพิ่ม/แก้เองได้ |
| ไม่มี attribute เพิ่มเติม | ต้องเก็บ description / config |
| เช่น `doc_status`, `route_type`, `trade_type` | เช่น `tb_vendor_type` (24 แถว), `tb_customer_type` |

### 6.3 Data Type Standards

| ประเภทข้อมูล | Type | หมายเหตุ |
| :--- | :--- | :--- |
| **Money / Price / Cost** | `DECIMAL(18, 4)` | รองรับเศษสตางค์ละเอียด |
| **🆕 Quantity** | `DECIMAL(18, 2)` | เดิม v4 กำหนด `(18,4)` — ธุรกิจนี้นับเป็นเล่ม/มัด ไม่ต้องการ 4 ตำแหน่ง |
| **Percent** | `DECIMAL(5, 2)` | 0.00 – 999.99 |
| **Status / Flags** | `BIT` | 0 หรือ 1 |
| **Business ID** | `NVARCHAR(50)` | |
| **FK Column** | `INT` | อ้าง `autoID` |
| **Document No.** | `NVARCHAR(30)` | |
| **Code** | `NVARCHAR(20)` | `warehouse_code`, `route_code` |
| **Description / Remark** | `NVARCHAR(255)` หรือ `NVARCHAR(MAX)` | |
| **Date only** | `DATE` | `publication_date`, `effective_date` |
| **Date + Time** | `DATETIME` | |

### 6.4 🆕 Script Standard

* Script ต้อง **Idempotent** — รันซ้ำได้โดยไม่พัง (`IF NOT EXISTS` / `IF OBJECT_ID(...) IS NULL`)
* Full rebuild script ต้องมี **SECTION VERIFY** ตอนท้ายเพื่อยืนยันจำนวน object
* Encoding: **UTF-8 with BOM**, line ending: **CRLF**
* ลำดับใน script = Dependency Order (ดู `SQL-TABLE.md`)

### 6.5 🆕 Audit Rule

`update_by` **ต้องมาจาก JWT claim ของผู้ใช้จริง** ห้ามรับจาก query string

> ในข้อมูล v5 จริงพบค่า `'UNKNOWN'` หลุดเข้าฐาน (มาจาก `c.Query("user", "UNKNOWN")` ฝั่ง Go)
> และพบค่าที่ไม่ใช่ user จริงปนอยู่ (`'PlayDevX'`, `'System'`, `'root'`) ⇒ ตรวจสอบย้อนหลังไม่ได้

-----

## 7. 🆔 Prefix Registry (v7.0 — 32 รายการ)

| Layer | Table | Prefix | Note |
| :--- | :--- | :---: | :--- |
| **L0** | `tb_reference` | **REF** | Running Number (PK = `ref_id`) |
| **L0** | `tb_users` | **USR** | ผู้ใช้ระบบ |
| **L1** | `tb_company` | **CPN** | นิติบุคคล |
| **L1** | `tb_customer_type` | **CUT** | ประเภทลูกค้า |
| **L1** | `tb_vendor_type` | **VET** | ประเภทคู่ค้า |
| **L1** | `tb_discount_type` | **DCT** | ประเภทส่วนลด |
| **L1** | `tb_product_category` | **PCT** | หมวดสินค้า |
| **L1** | `tb_product_format_type` | **PFM** | รูปแบบสินค้า |
| **L1** | `tb_unit_type` | **UNT** | หน่วยนับ |
| **L1** | `tb_book_type` | **BKT** | ประเภทหนังสือ |
| **L2** | `tb_product_group` | **PGT** | กลุ่มสินค้า |
| **L2** | `tb_warehouse` | **WHS** | คลังสินค้า |
| **L3** | `tb_vendor` | **VEN** | คู่ค้า |
| **L3** | `tb_customer` | **CUS** | ลูกค้า |
| **L3** | `tb_discount` | **DSC** | แคมเปญส่วนลด |
| **L4** | `tb_product` | **PDT** | Hybrid Core |
| **L5** | `tb_product_sku` | **SKU** | SKU / ฉบับ |
| **L5** | `tb_book` | **BOK** | Extension 1:1 ของ `tb_product` |
| **L6** | `tb_route` | **RTE** | 🆕 สายจัดจำหน่าย |
| **L6** | `tb_customer_route` | **CRT** | 🆕 ลูกค้า × สาย |
| **L7** | `tb_stock_movement` | **STM** | 🆕 Ledger |
| **L7** | `tb_product_stock` | **STK** | 🆕 Cache ยอดคงเหลือ |
| **L7** | `tb_consign_balance` | **CSB** | 🆕 Cache ยอดฝากขาย |
| **L8** | `tb_receive_note` | **RCV** | 🆕 ใบรับ (Header) |
| **L8** | `tb_receive_item` | **RCI** | 🆕 ใบรับ (Item) |
| **L8** | `tb_order` | **ORD** | 🆕 ใบส่ง (Header) |
| **L8** | `tb_order_item` | **ODI** | 🆕 ใบส่ง (Item) |
| **L8** | `tb_return_note` | **RTN** | 🆕 ใบรับคืนจากร้าน (Header) |
| **L8** | `tb_return_item` | **RTI** | 🆕 ใบรับคืนจากร้าน (Item) |
| **L8** | `tb_vendor_return_note` | **VRN** | 🆕 ใบส่งคืนเจ้าของ (Header) |
| **L8** | `tb_vendor_return_item` | **VRI** | 🆕 ใบส่งคืนเจ้าของ (Item) |
| **L9** | `tb_allocation_history` | **AHS** | 🆕 ประวัติยอดส่ง/คืน |

> **กฎการจอง Prefix:** ต้องไม่ซ้ำกับที่มีอยู่ และต้องจดในตารางนี้ก่อนสร้างตาราง

-----

## 8. ✅ Compliance Checklist

ก่อน merge schema ใหม่ ต้องผ่านครบทุกข้อ:

- [ ] Common Fields ครบ 8 รายการ
- [ ] `prefix` จดในทะเบียนแล้ว และไม่ซ้ำ
- [ ] FK ทุกตัวอ้าง `ref_*_auto` → `autoID` และมี `FOREIGN KEY` constraint จริง
- [ ] FK ทุกคอลัมน์มี `IX_` index รองรับ
- [ ] Business ID มี Filtered Unique Index
- [ ] Natural Key มี Unique Index (`WHERE is_delete = 0`)
- [ ] คอลัมน์ enum แบบปิดมี `CHECK` constraint
- [ ] Trigger ครบ 4 ตัว: `GENERATE_ID`, `AUTO_UPDATE_DATE`, `SYNC_STATUS`, `BLOCK_DELETE`
- [ ] Trigger เป็น Set-Based ไม่มี `CURSOR`
- [ ] ไม่มี `GETDATE()` — ใช้ SE Asia Standard Time
- [ ] ตาราง Cache ทุกตัวมี Rebuild Procedure
- [ ] มี View สำหรับอ่าน ที่แปลง `autoID` → Business ID แล้ว
- [ ] Script รันซ้ำได้ (Idempotent)

### 🔐 เฉพาะงานที่แตะ Concurrency / Transaction

- [ ] ไม่ถอด `WITH (UPDLOCK, HOLDLOCK)` ออกจากตัวจอง ID (หัวข้อ 4.2)
- [ ] ตารางใหม่ถูก pre-seed ลง `tb_reference` ใน deploy script (หัวข้อ 4.2.2)
- [ ] ไม่มีโค้ดใดนอก `USP_ALLOCATE_BUSINESS_ID_BLOCK` ที่ `UPDATE tb_reference`
- [ ] Procedure ใหม่แตะตารางตาม **Canonical Lock Order** (หัวข้อ 4.3)
- [ ] ไม่มี `WAITFOR` / external call / query รายงานหนัก อยู่ใน `BEGIN TRAN` (หัวข้อ 4.4)
- [ ] ผ่าน `TEST-concurrency-id.sql` แล้ว — V1 = PASS, V2/V3 = 0 แถว, V4 = IN SYNC

-----

## 📝 Change Log

### v7.0.1 (22/08/2026) — Concurrency Specification

จากการทบทวนพฤติกรรมของ Auto-ID Allocator ภายใต้การใช้งานพร้อมกันหลาย session

* **Added — 4.2 Concurrency Contract:** ระบุชัดว่า `WITH (UPDLOCK, HOLDLOCK)` เป็นสิ่งที่**ห้ามถอด** พร้อมตารางอธิบายว่าถอดตัวไหนแล้วพังยังไง และ trace การทำงานเมื่อมี 10 session ยิงพร้อมกัน
* **Added — 4.2.1 Gapless Property:** ระบุว่า "เลขไม่กระโดด" เป็นข้อกำหนดที่ตั้งใจ (rollback แล้วเลขคืน) และแบ่งกลุ่มตารางว่ากลุ่มไหนห้ามเปลี่ยนไปใช้ `SEQUENCE`
* **Added — 4.2.2 Pre-Seed Requirement:** บังคับ pre-seed `tb_reference` ทุกตารางตอน deploy เพื่อปิด path ที่ต้องพึ่ง range lock
* **Added — 4.3 Canonical Lock Order:** กำหนดลำดับบังคับ `STM → STK → CSB → AHS → เอกสาร` สำหรับ Procedure ทุกตัว พร้อมตารางยืนยันว่า `USP_POST_*` ทั้ง 4 ตัวปัจจุบันสอดคล้องแล้ว
* **Added — 4.4 Throughput Impact:** บันทึกว่า POST ถูก serialize ทั้งระบบเพราะทุกตัวแตะ `tb_stock_movement` พร้อมตัวเลขประเมินผลกระทบ 3 สถานการณ์
* **Added:** ข้อห้าม `UPDATE tb_reference` จากภายนอก Procedure
* **Added:** Compliance Checklist หมวด Concurrency 6 ข้อ
* **Renumbered:** หัวข้อเดิม 4.2–4.6 เลื่อนเป็น 4.5–4.9

### v7.0.0 (21/08/2026)
* **🔴 Breaking — FK Strategy:** เปลี่ยน FK Column จาก Business ID (`NVARCHAR(50)`) เป็น `ref_*_auto` (`INT` → `autoID`) ทำให้ผูก `FOREIGN KEY` ได้จริง **0 → 53 ตัว**
* **🔴 Breaking — Item Tables:** ยกเลิกข้อยกเว้น *"ตารางลูกไม่ต้องมี Prefix/Business ID"* — ตารางลูกต้องมี Common Fields ครบเหมือนตารางแม่
* **Added:** Trigger มาตรฐาน 4 ตัวต่อตาราง (เดิม 2) — เพิ่ม `SYNC_STATUS` และ `BLOCK_DELETE`
* **Added:** `CHECK` Constraint Standard สำหรับคอลัมน์ enum แบบปิด + เกณฑ์เลือกระหว่าง CHECK กับตาราง Type
* **Added:** Read/Write Model Separation — อ่านผ่าน View, เขียนธุรกรรมผ่าน Procedure
* **Added:** Ledger vs Cache Principle + กฎว่า Cache ทุกตัวต้องมี Rebuild Procedure
* **Added:** Status Invariant บังคับด้วย Trigger (v5 มีข้อมูลจริงที่ `is_delete=1` แต่ `is_active=1`)
* **Added:** Naming ของ View / Procedure / CHECK / FK Constraint
* **Added:** Compliance Checklist
* **Changed:** Trigger ต้องเป็น Set-Based **ห้ามใช้ `CURSOR`**
* **Changed:** Quantity เปลี่ยนจาก `DECIMAL(18,4)` → `DECIMAL(18,2)`
* **Changed:** Trigger Naming เป็นรูปแบบเดียว `TRIG_[ACTION]_[TABLE_UPPER]` (v5 มี 3 รูปแบบปนกัน)
* **Fixed:** Prefix Registry อัปเดตครบ 32 รายการ (v4 มี 20 และบางตัวยังเป็น *Pending*)
* **Fixed:** เอกสารเดิมของ PenbunAPI ระบุ `prefix NVARCHAR(5)` — ยืนยันว่าค่าที่ถูกต้องคือ **`NVARCHAR(3)`**

### v4.0.0 (17/06/2026)
* **Added:** `id_status` (NVARCHAR(20)) เป็น Common Field ลำดับที่ 8 — Dual Status กับ `is_active`
* **Added:** Prefix ใหม่ 4 รายการ: `CPN`, `BKT`, `SKU`, `BOK`
* **Fixed:** ปรับ `USP_GENERATE_BUSINESS_ID` ให้ใช้ Series Letter (A-Z) และ Running 6 หลัก
* **Updated:** Common Fields จาก 6 → 8 รายการ

### v2.3.0 (10/12/2025)
* **Added:** Prefix `WHS` (`tb_warehouse`) รองรับโมเดล Multi-Location
* **Verified:** ยืนยันมาตรฐาน Audit "Creation is First Update" ใช้ได้จริงในทุกตาราง
