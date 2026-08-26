# โครงสร้างส่วนลด — legacy สู่ Penbun v4

ปิดช่องว่างที่ [`PENBUN-TODO.md`](./PENBUN-TODO.md) §1 ข้อ 6 และ §8.2 ระบุไว้ :
ไม่มีตารางไหนบอกว่าร้านหนึ่งจ่ายเท่าไหร่สำหรับหนังสือเล่มหนึ่ง `tb_order_item.discount_percent`
จึงเป็นเลขที่คนคีย์พิมพ์เอง และผิดเมื่อไหร่รู้ตอนร้านทักมา

เขียน 26 สิงหาคม 2026 · PenbunSQL v9 (add-on) · PenbunAPI v4.0.0 · PenbunWeb beta 1.3.0

---

## 1. legacy เก็บส่วนลดไว้ 4 ที่

| ตารางเดิม | ผูกกับ | ค่า | ช่วงเวลา | ความหมาย |
|---|---|---|---|---|
| `tb_DiscountGroups` | `tb_Stores.DiscountGroupId` | `ProfileDiscount` float | ไม่มี | ส่วนลดพื้นฐานตามกลุ่มร้าน |
| `tb_OnTopDiscounts` | `StoreBranchId` | `OnTopDiscount` float | มี | ส่วนลดซ้อนระดับสาขา ตามแคมเปญ |
| `tb_SpecialProductDiscounts` | `BookId` | `SpecialProductDiscount` float | มี | ส่วนลดเฉพาะหนังสือ |
| `tb_Books.Amount1/2/3` | ตัวหนังสือเอง | int | ไม่มี | ขั้นบันไดตามจำนวน |

ราคาที่ร้านจ่ายจริงเกิดจากหลายชั้นซ้อนกัน ไม่ใช่แถวเดียว และชื่อตารางคือที่เก็บ
"ขอบเขต" ของแต่ละชั้น

## 2. v4 ก่อนแก้

`tb_discount` เป็นแคมเปญแบน ๆ : `discount_value`, `is_percent`, `min_order_amount`,
ช่วงวันที่ และ FK ไป `tb_discount_type` เท่านั้น **ไม่มีคอลัมน์ปลายทางสักช่อง**
`tb_customer.discount_group` เป็น `nvarchar(20)` อิสระที่ไม่มีอะไร resolve ให้

ของที่ v4 มีแต่ legacy ไม่มี : ลดเป็นบาทได้ (`is_percent`) และขั้นบันไดตามยอดเงิน
(`min_order_amount`) ซึ่งดีกว่า `Amount1/2/3` ที่ฝังอยู่ในตัวหนังสือ

---

## 3. โครงสร้างที่สร้างจริง

```
tb_discount_group ──< tb_customer.ref_discount_group_auto
        │
        └──< tb_price_rule (rule_scope = GROUP, GROUP_SKU)
tb_customer ──────────< tb_price_rule (CUSTOMER, CUSTOMER_SKU)
tb_route ─────────────< tb_price_rule (ROUTE)
tb_product_sku ───────< tb_price_rule (SKU, *_SKU)

UFN_RESOLVE_DISCOUNT(customer, sku, qty, doc_date) -> ตัวเลขเดียว + ที่มา
```

`tb_discount` เดิมยังอยู่และยังเป็นแคมเปญเหมือนเดิม — ไม่ได้ถูกแทนที่ คนละหน้าที่กัน

### 3.1 ทำไมตารางเดียว ไม่ใช่สองตารางตาม Roadmap

Roadmap v9 ข้อ 4 เสนอ `tb_discount_group_price` (SKU × กลุ่ม) กับ
`tb_customer_sku_discount` (SKU × ลูกค้า) สองตารางนั้นครอบ legacy ได้ 2 มิติจาก 4 :
ไม่มีที่ให้ "ส่วนลดทั้งสาย" และไม่มีที่ให้ on-top ระดับร้านที่ไม่ผูกกับ SKU
(`tb_OnTopDiscounts`) เติมทีหลังจะกลายเป็นสี่ตารางที่มีคอลัมน์เหมือนกัน
และมีตัว resolve สี่ชุดที่ต้องแก้พร้อมกันทุกครั้ง

`tb_price_rule` แยกมิติด้วย `rule_scope` + คอลัมน์ปลายทาง โดยมี
`CK_tb_price_rule_target` บังคับว่าปลายทางต้องตรงกับ scope ที่ประกาศ
เพิ่มมิติใหม่ = เพิ่มค่า enum หนึ่งค่า ไม่ใช่ตารางใหม่หนึ่งตาราง

### 3.2 คอลัมน์ที่ทำงานจริง

| คอลัมน์ | หน้าที่ | แทนของ legacy |
|---|---|---|
| `rule_scope` + `ref_*_auto` | ขอบเขตและปลายทาง | ชื่อตารางทั้งสามของ legacy |
| `discount_percent` \| `net_price` | มูลค่า ใส่ได้อย่างเดียว | ส่วนลด % · ราคาสุทธิของ ส่วนลดตามกลุ่ม |
| `min_qty` / `max_qty` | ขั้นบันได หนึ่งขั้นหนึ่งแถว | `tb_Books.Amount1/2/3` |
| `is_on_top` | 1 = บวกทับผู้ชนะ · 0 = แข่งกัน | `tb_OnTopDiscounts` |
| `priority` | ตัดสินเมื่อ scope เท่ากัน | ไม่มี |
| `start_date` / `end_date` | ช่วงเวลา | `StartDate` / `EndDate` |

---

## 4. ลำดับการคิดส่วนลด

ตอบคำถามค้างข้อ 3 ใน `PenbunSQL/SQL-TABLE.md` (*ส่วนลด 4 แบบ ซ้อนกันหรือทับกัน*) ว่า **ทั้งคู่**

1. **แข่งกัน (ทับ)** — กฎที่ `is_on_top = 0` เจาะจงกว่าชนะ ชนะแล้วชนะเดี่ยว

   `CUSTOMER_SKU (60) > CUSTOMER (50) > ROUTE (40) > GROUP_SKU (30) > GROUP (20) > SKU (10)`

   เสมอกัน → `priority` มากชนะ → `min_qty` สูงชนะ → แถวใหม่ชนะ

2. **ซ้อน** — กฎที่ `is_on_top = 1` ทุกแถวที่เข้าเกณฑ์บวกกัน แล้วบวกทับผู้ชนะจากข้อ 1
   ตรงกับ `tb_OnTopDiscounts` ของ legacy

3. **ชั้นสุดท้าย** — ไม่มีกฎไหนเข้าเกณฑ์เลย → `tb_book.customer_discount_percent` → ไม่มีอีก → 0

เกณฑ์เข้าใช้ของทุกแถว : `is_active = 1`, วันที่เอกสารอยู่ในช่วง, จำนวนอยู่ในช่วง `min_qty`–`max_qty`

> **ยังต้องให้ศูนย์กระจายสินค้ายืนยัน** ว่าลำดับความเจาะจงนี้ตรงกับที่ใช้จริง
> เอกสาร legacy ไม่ได้เขียนไว้ และ §8.4 บันทึกไว้ว่าหน้าจอ ส่วนลดตามกลุ่ม ของ legacy
> เองก็แสดง %ส่วนลด ไม่ได้มาแต่ไหนแต่ไร ลำดับที่เขียนไว้ข้างบนคือข้อสันนิษฐานที่ดีที่สุด
> ที่พิสูจน์ได้ด้วยเทสต์ ไม่ใช่ข้อเท็จจริงที่ยืนยันแล้ว

`source_scope` ที่ฟังก์ชันคืนมาบอกว่าตัวเลขมาจากชั้นไหน หน้าจอใบสั่งขายต้องแสดงค่านี้
ควบไปกับตัวเลขเสมอ ไม่ใช่ช่องกรอกเปล่าที่ไม่มีที่มา

### 4.1 ช่วงเวลาทับซ้อน

CHECK constraint มองได้ทีละแถวจึงกันไม่ได้ `TRIG_BLOCK_OVERLAP_TB_PRICE_RULE` เป็นตัวกัน :
แถวใหม่ที่ scope + ปลายทาง + ขั้นบันได + `is_on_top` เดียวกัน ห้ามมีช่วงวันคาบเกี่ยวกับแถวเดิม
ที่ยัง active ทริกเกอร์ใช้ `THROW 50000` ไม่ใช่ `RAISERROR` + `ROLLBACK` เพราะ ROLLBACK
ในทริกเกอร์ทำให้ client ได้ error 3609 แล้ว PenbunAPI แปลเป็น `INTERNAL` — ด้วย `THROW`
ผู้ใช้ได้ `BUSINESS_RULE` พร้อมข้อความไทยตามสัญญาใน `httpx/sqlerr.go`

---

## 5. ไฟล์ที่แก้

### PenbunSQL

* `SQL/SQL-PENBUN-v9.sql` — **ใหม่** full build 34 ตาราง · 32 วิว · 11 proc · 1 function
  ใช้กับฐานเปล่าหรือฐานที่ยอมให้ลบทั้งก้อน (SECTION 1 ลบทุกอย่างก่อนสร้าง)
* `TEST/TEST-discount-resolve.sql` — **ใหม่** 10 เคส ทุกเคสพิมพ์ PASS/FAIL เอง

### PenbunAPI

* `internal/resources/discount.go` — **ใหม่** descriptor `discount-group` และ `price-rule`
* `internal/resources/registry.go` — ต่อท้ายทั้งสองตัว
* `internal/resources/master.go` — `customer.discount_group` (ข้อความ) กลายเป็น
  ref `discount_group_id` และฟิลเตอร์เปลี่ยนตาม
* `internal/repository/resolver.go` — `tb_discount_group` เข้า allow-list และ cache
  (ตารางเล็ก แทบไม่เปลี่ยน เหมือน lookup ตัวอื่น)

### PenbunWeb

* `src/ts/master/resources.ts` — `DISCOUNT_GROUP`, `PRICE_RULE`, `CUSTOMER` ผูกกลุ่มด้วย ref
* `src/ts/core/nav.ts` — กฎส่วนลด เข้าเมนู คู่ค้า · กลุ่มส่วนลด อยู่ที่หน้า ข้อมูลพื้นฐาน
* `public/discount-groups.html` · `public/price-rules.html` — สร้างด้วย `npm run gen:master`
* registry จาก 18 เป็น 20 resource เอกสารทุกที่ที่นับเลขนี้ปรับตาม

---

## 6. ที่พิสูจน์แล้ว

รันบน SQL Server จริง (ฐาน `PENBUN_V9TEST` : v8 เต็ม + add-on v9)

| สิ่งที่ตรวจ | ผล |
|---|---|
| `SQL-PENBUN-v9.sql` บนฐานเปล่า | ผ่าน 0 error — 34 ตาราง · 32 วิว · 11 proc · 1 function · 136 ทริกเกอร์ · 55 FK · untrusted FK = 0 |
| v9 full รันทับตัวเอง | ผ่าน 0 error |
| รันซ้ำสามรอบ | ผ่าน — ลูกค้าที่ผูกกลุ่มไว้ยังผูกอยู่หลังสร้างตารางใหม่ |
| `TEST-discount-resolve.sql` | 10/10 PASS |
| `go build ./...` · `go test ./...` | ผ่านทั้งหมด |
| `npm test` | 1358 passed, 0 failed |
| `GET /discount-group` | คืน 5 กลุ่มพร้อม `customer_count` |
| `POST /price-rule` (GROUP) | สร้างได้ คืน `target_name` |
| `POST` ปลายทางไม่ตรง scope | ปฏิเสธ — CHECK ทำงาน |
| `POST` scope ที่ไม่มีในรายการ | ปฏิเสธพร้อมชื่อฟิลด์ — descriptor ดักก่อนถึง DB |
| `POST` ซ้ำช่วงวัน | `BUSINESS_RULE` + ข้อความไทยจากทริกเกอร์ |
| `GET /meta/enums` | มี `price_rule_rule_scope` ครบหกค่า |

---

## 7. ที่ยังเหลือ

1. **ผูกตัวคิดส่วนลดเข้ากับใบสั่งขาย** — วันนี้ `UFN_RESOLVE_DISCOUNT` มีแล้วแต่ยังไม่มีใครเรียก
   `tb_order_item.discount_percent` ยังเป็นเลขที่คนพิมพ์ ต้องให้ document engine เรียกตอนเพิ่มบรรทัด
   และให้หน้าจอแสดง `source_scope` ควบไปด้วย
2. **ยืนยันลำดับความเจาะจงกับศูนย์** (§4)
3. **`Amount1/2/3` ย้ายไม่ได้** — เป็น int สามตัวบน `tb_Books` ไม่มีคอลัมน์เปอร์เซ็นต์คู่กัน
   อ่านไม่ออกว่า "ซื้อครบ N ลด x%" หรือ "แถม N เล่ม" ต้องดูโค้ดคำนวณของ legacy ก่อน
   ที่เหลือของ legacy ย้ายได้ตามตารางใน §8.2 ของ PENBUN-TODO
4. ~~พับ add-on เข้า full build~~ — ทำแล้ว `SQL-PENBUN-v9.sql` เป็น full build เต็ม
   (tb_discount_group อยู่ Layer 1 · tb_price_rule เป็น Layer 10 ใหม่) ฐานที่มีข้อมูลจริง
   อยู่แล้วต้องสำรองก่อนรัน เพราะ SECTION 1 ลบทุก object
5. **ฟอร์มยังไม่ซ่อนช่องปลายทางตาม scope** — ฟอร์ม master วันนี้แสดงทุกช่องเสมอ
   ผู้ใช้จึงเห็นช่องกลุ่ม ลูกค้า สาย SKU พร้อมกันทั้งสี่ และรู้ว่าต้องกรอกช่องไหนจาก hint
   ฐานข้อมูลปฏิเสธค่าที่ผิดรูปอยู่แล้ว แต่ประสบการณ์ยังไม่ดี — ต้องมี conditional field
   ใน `master/form.ts` ก่อนถึงจะเรียกว่าจบ
