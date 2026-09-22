-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- BÀI GIẢNG 04: TỐI ƯU HÓA HIỆU NĂNG, ĐỌC EXPLAIN ANALYZE & CHIẾN LƯỢC ĐÁNH INDEX
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Giải phẫu chi tiết cây thực thi: `EXPLAIN (ANALYZE, BUFFERS, COSTS)`.
--   2. Phân biệt 4 phương thức quét dữ liệu: Seq Scan, Index Scan, Index Only Scan, Bitmap Scan.
--   3. Chiến lược các loại Index: B-Tree, GIN (Inverted), BRIN (Block Range Index).
--   4. Tối ưu cực đại với Partial Index và Covering Index (Mệnh đề INCLUDE).
--   5. Quy tắc SARGable: Nhận diện và sửa chữa các lỗi viết SQL làm vô hiệu hóa Index.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Đoán ít hơn, đo bằng kế hoạch thực thi rồi mới tối ưu.
-- CÂU LỆNH: EXPLAIN ANALYZE (chạy và báo chi phí thực), CREATE INDEX (tạo chỉ mục),
-- B-tree/GIN/BRIN/partial/covering index, DROP INDEX.
-- ⭐ MỨC ĐỘ DÙNG: EXPLAIN ANALYZE và B-tree index thường xuyên; GIN/BRIN tùy kiểu dữ liệu.
-- 🔒 AN TOÀN: CREATE/DROP INDEX thay đổi schema và dùng tài nguyên; kiểm tra môi trường trước.
-- 🧠 CẦN NHỚ: Index không tự động làm mọi query nhanh; nó cũng làm ghi dữ liệu tốn hơn.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ĐỌC & PHÂN TÍCH EXPLAIN ANALYZE
-- ------------------------------------------------------------------------------
-- - `EXPLAIN`: Kế hoạch ước tính (Cost estimation) của Optimizer dựa trên bảng thống kê `pg_statistic`.
-- - `EXPLAIN ANALYZE`: THỰC SỰ CHẠY QUERY trên hệ thống, đo lường thời gian thực thi (Actual Time) và I/O Blocks.

EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT order_id, customer_id, order_date
FROM orders
WHERE customer_id = 1;

-- 📊 GIẢI PHẪU CÁC THÔNG SỐ TRONG KẾ HOẠCH THỰC THI:
--   - `cost=0.00..12.50`: Chi phí ước tính (Startup Cost .. Total Cost) tính theo đơn vị I/O page fetches.
--   - `actual time=0.012..0.015`: Thời gian thực thi đo bằng mili-giây (ms).
--   - `rows=1`: Số lượng dòng ước tính vs Số dòng thực tế trả về (`actual rows=1`).
--   - `Buffers: shared hit=3 read=0`: Đọc 3 block từ RAM Shared Buffers, 0 block từ ổ cứng Disk -> Hiệu năng tuyệt hảo!


-- ------------------------------------------------------------------------------
-- 2. BẢN ĐỒ CÁC LOẠI INDEX TRONG POSTGRESQL
-- ------------------------------------------------------------------------------
-- ┌────────────┬─────────────────────────────┬─────────────────────────────────────────────────┐
-- │ Loại Index │ Cấu trúc dữ liệu            │ Trường hợp sử dụng tối ưu                       │
-- ├────────────┼─────────────────────────────┼─────────────────────────────────────────────────┤
-- │ 1. B-Tree  │ Cây nhị phân cân bằng (B+)  │ Mặc định: So sánh bằng `=`, `<`, `>`, `BETWEEN` │
-- │ 2. GIN     │ Generalized Inverted Index  │ Tìm kiếm phần tử trong mảng Array, JSONB, FTS   │
-- │ 3. BRIN    │ Block Range Index           │ Bảng lớn hàng trăm triệu dòng time-series tăng dần│
-- └────────────┴─────────────────────────────┴─────────────────────────────────────────────────┘

-- 2.1 B-Tree Index mặc định:
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- 2.2 Composite Index (Chỉ mục kết hợp nhiều cột) & Quy tắc Tiền tố bên trái (Leftmost Prefix):
-- Tối ưu cho query: WHERE customer_id = ? AND order_date >= ?
CREATE INDEX IF NOT EXISTS idx_orders_cust_date ON orders(customer_id, order_date DESC);

-- 2.3 Partial Index (Chỉ mục một phần - Tiết kiệm 90% dung lượng RAM/Disk):
-- Chỉ đánh chỉ mục cho các đơn hàng chưa xử lý xong (Pending/Processing):
CREATE INDEX IF NOT EXISTS idx_orders_active_pipeline 
ON orders(order_id, order_date) 
WHERE order_status IN ('Pending', 'Processing');

-- 2.4 Covering Index với mệnh đề INCLUDE (Tạo trạng thái Index Only Scan thần tốc):
-- Giúp query không bao giờ phải chạm vào Table Heap (Heap Fetch = 0):
CREATE INDEX IF NOT EXISTS idx_customers_lookup_covering 
ON customers(email) 
INCLUDE (first_name, last_name, customer_segment);

-- 2.5 BRIN Index (Kích thước siêu nhỏ, tối ưu cho bảng Log/Web Events hàng chục triệu dòng):
CREATE INDEX IF NOT EXISTS idx_web_events_brin_time 
ON web_events USING BRIN (event_time);


-- ------------------------------------------------------------------------------
-- 3. QUY TẮC SARGABLE: TRÁNH CÁC ANTI-PATTERNS LÀM HỎNG INDEX
-- ------------------------------------------------------------------------------
-- SARGable = Search Argument Able (Khả năng tận dụng được Index của mệnh đề điều kiện).

-- ❌ ANTI-PATTERN 1: Bọc hàm (Function) xung quanh cột có Index
-- SELECT * FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2023; -- Gây Seq Scan toàn bảng!

-- ✅ CÁCH SỬA SARGABLE ĐÚNG:
SELECT * FROM orders 
WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01';

-- ❌ ANTI-PATTERN 2: Ép kiểu ngầm định (Implicit Type Casting)
-- So sánh cột VARCHAR với số nguyên INT: `WHERE phone_number = 123456`
-- Database buộc phải convert toàn bộ cột chuỗi sang số -> Vô hiệu hóa Index!

-- ✅ CÁCH SỬA ĐÚNG:
-- `WHERE phone_number = '123456'`
