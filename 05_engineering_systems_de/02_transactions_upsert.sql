-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- BÀI GIẢNG 02: QUẢN LÝ GIAO DỊCH (ACID), KHÓA CONCURRENCY VÀ IDEMPOTENT UPSERT
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Bốn trụ cột ACID trong Hệ thống Cơ sở dữ liệu phân tán.
--   2. Bốn cấp độ cô lập giao dịch (Transaction Isolation Levels) & Các hiện tượng bất thường.
--   3. Khóa dữ liệu dòng (Row-level Locking) & Kỹ thuật xử lý hàng đợi song song với `FOR UPDATE SKIP LOCKED`.
--   4. Kỹ thuật nạp dữ liệu Idempotent (Chạy lại nhiều lần không lỗi): ON CONFLICT (UPSERT) vs MERGE.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Ghi dữ liệu an toàn khi có lỗi hoặc nhiều người/tiến trình cùng làm việc.
-- CÂU LỆNH: BEGIN/COMMIT/ROLLBACK (giao dịch), SAVEPOINT (mốc quay lại), FOR UPDATE
-- (khóa dòng), ON CONFLICT/MERGE (upsert: chèn hoặc cập nhật).
-- ⭐ MỨC ĐỘ DÙNG: transaction và ON CONFLICT rất thường xuyên với DE; isolation/locking nâng cao.
-- 🔒 AN TOÀN: Các lệnh INSERT/UPDATE/DELETE thay đổi dữ liệu. Luôn thử trong transaction.
-- 🧠 CẦN NHỚ: COMMIT mới ghi vĩnh viễn; ROLLBACK hủy các thay đổi chưa commit.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BỐN TRỤ CỘT ACID & ĐIỀU KHIỂN GIAO DỊCH
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬────────────────────────────────────────────────────────────────────────┐
-- │ Thuộc tính ACID │ Ý nghĩa sống còn trong Hệ thống Tài chính & Kỹ thuật                   │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 1. Atomicity    │ "Tất cả hoặc không gì cả" - Toàn bộ các bước phải thành công, nếu 1    │
-- │    (Nguyên tử)  │ bước lỗi thì ROLLBACK hoàn tác toàn bộ về trạng thái ban đầu.          │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 2. Consistency  │ Dữ liệu luôn tuân thủ 100% các ràng buộc Schema (PK, FK, CHECK).       │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 3. Isolation    │ Các giao dịch chạy đồng thời không được nhìn thấy dữ liệu dở dang của  │
-- │    (Cô lập)     │ nhau trước khi Commit.                                                 │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 4. Durability   │ Khi đã COMMIT thành công, dữ liệu được ghi vào WAL Disk vĩnh viễn,     │
-- │    (Bền vững)   │ kể cả khi server bị sập nguồn ngay sau đó.                             │
-- └─────────────────┴────────────────────────────────────────────────────────────────────────┘

BEGIN; -- Bắt đầu Transaction

-- Bước 1: Trừ kho
UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 101 AND stock_quantity >= 1;

-- Bước 2: Tạo bản ghi thanh toán
INSERT INTO payments (payment_id, order_id, payment_date, amount, payment_status, transaction_ref)
VALUES (999, 1001, CURRENT_TIMESTAMP, 32000000, 'Success', 'TXN-DEMO-LOCK-999');

-- Bước 3: Đánh dấu Savepoint
SAVEPOINT order_saved;

-- Bước 4: Lưu vĩnh viễn
COMMIT;


-- ------------------------------------------------------------------------------
-- 2. KHÓA DÒNG SONG SONG CHO DATA PIPELINES (FOR UPDATE SKIP LOCKED)
-- ------------------------------------------------------------------------------
-- 🎯 BÀI TOÁN DATA PIPELINE / QUEUE WORKER:
-- Có 10 Worker chạy song song cùng đọc bảng sự kiện `web_events` để xử lý.
-- Yêu cầu: Không Worker nào được xử lý trùng sự kiện của Worker khác và KHÔNG BỊ TREO CHỜ (No Lock Wait).

SELECT 
    event_id, 
    session_id, 
    event_type, 
    event_time
FROM web_events
WHERE customer_id IS NOT NULL
ORDER BY event_time ASC
LIMIT 5
FOR UPDATE SKIP LOCKED; 
-- 🔍 GIẢI THÍCH:
-- - `FOR UPDATE`: Khóa độc quyền 5 dòng này (Chặn các transaction khác sửa đổi).
-- - `SKIP LOCKED`: Các worker khác khi chạy câu lệnh này sẽ TỰ ĐỘNG BỎ QUA 5 dòng đang bị khóa
--   và lập tức lấy ngay 5 dòng kế tiếp mà không phải chờ đợi 1 mili-giây nào!


-- ------------------------------------------------------------------------------
-- 3. IDEMPOTENT UPSERT TRONG DATA PIPELINES (ETL/ELT RELIABILITY)
-- ------------------------------------------------------------------------------
-- 💡 KHÁI NIỆM IDEMPOTENCY:
-- Một pipeline được gọi là Idempotent nếu bạn chạy nó 1 lần hay 1000 lần trên cùng 1 tập dữ liệu,
-- trạng thái cuối cùng của CSDL vẫn hoàn toàn như nhau, không sinh ra bản ghi rác trùng lặp!

-- 3.1 Cú pháp PostgreSQL ON CONFLICT DO UPDATE (UPSERT):
INSERT INTO products (product_id, product_name, category_id, cost_price, unit_price, stock_quantity, is_discontinued)
VALUES (101, 'iPhone 15 Pro Max 256GB - 2024 V2', 2, 25500000, 31500000, 50, FALSE)
ON CONFLICT (product_id) -- Bắt xung đột khóa chính
DO UPDATE SET
    product_name = EXCLUDED.product_name,
    cost_price = EXCLUDED.cost_price,
    unit_price = EXCLUDED.unit_price,
    stock_quantity = products.stock_quantity + EXCLUDED.stock_quantity; -- Cộng dồn thêm tồn kho

-- 3.2 Chuẩn ANSI SQL MERGE Statement (PostgreSQL 15+, Snowflake, BigQuery):
CREATE TEMP TABLE staging_updates (
    product_id INT,
    product_name VARCHAR(150),
    new_price NUMERIC(12, 2)
);

INSERT INTO staging_updates VALUES 
(102, 'Samsung Galaxy S24 Ultra (Khuyến Mãi)', 27990000),
(999, 'Bàn phím cơ cao cấp', 1800000);

MERGE INTO products AS target
USING staging_updates AS source
ON (target.product_id = source.product_id)
WHEN MATCHED THEN
    UPDATE SET 
        product_name = source.product_name,
        unit_price = source.new_price
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, category_id, cost_price, unit_price, stock_quantity)
    VALUES (source.product_id, source.product_name, 4, 1200000, source.new_price, 20);
