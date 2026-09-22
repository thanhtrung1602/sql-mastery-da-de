-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- BÀI GIẢNG 05: PHÂN VÙNG BẢNG (PARTITIONING), BẢO TRÌ CSDL & MATERIALIZED VIEWS
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Phân vùng Bảng khai báo (Declarative Partitioning: Range, List, Hash).
--   2. Kiểm chứng cơ chế Partition Pruning (Bỏ qua các phân vùng không cần thiết).
--   3. Kiến trúc MVCC (Multi-Version Concurrency Control), Dead Tuples và VACUUM / ANALYZE.
--   4. Materialized Views và kỹ thuật làm mới ngầm `REFRESH CONCURRENTLY`.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Quản lý bảng rất lớn bằng cách chia phần và bảo dưỡng vật lý đúng cách.
-- CÂU LỆNH: PARTITION BY/CREATE TABLE ... PARTITION OF (chia bảng), VACUUM/ANALYZE,
-- REINDEX, CREATE MATERIALIZED VIEW/REFRESH.
-- ⭐ MỨC ĐỘ DÙNG: ANALYZE/VACUUM thường xuyên ở vận hành; partition/MV dùng khi có nhu cầu rõ.
-- 🔒 AN TOÀN: REINDEX, REFRESH và thao tác partition có thể tốn tài nguyên/khóa; đừng chạy mù quáng.
-- 🧠 CẦN NHỚ: Partition chỉ giúp khi điều kiện query cho phép database bỏ qua các partition không liên quan.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PHÂN VÙNG BẢNG THEO KHOẢNG THỜI GIAN (RANGE PARTITIONING)
-- ------------------------------------------------------------------------------
-- Khi bảng dữ liệu đạt quy mô hàng trăm triệu dòng (ví dụ bảng Log sự kiện),
-- việc truy vấn và xóa dữ liệu cũ (Data Retention / Purging) sẽ làm tê liệt hệ thống.
--
-- 💡 GIẢI PHÁP PHÂN VÙNG (PARTITIONING):
-- Chia nhỏ bảng cha thành nhiều bảng con vật lý độc lập theo từng Quý / Năm.
-- Khi cần xóa dữ liệu của một quý cũ, chỉ cần `DROP TABLE partition_old` trong 1 mili-giây
-- mà không cần chạy lệnh `DELETE` tốn kém!

DROP TABLE IF EXISTS partitioned_web_logs CASCADE;

-- 1.1 Tạo Bảng Cha (Master Partitioned Table)
CREATE TABLE partitioned_web_logs (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY,
    user_id INT,
    action_type VARCHAR(50),
    log_timestamp TIMESTAMP NOT NULL,
    payload JSONB,
    PRIMARY KEY (log_id, log_timestamp) -- Cột phân vùng bắt buộc phải nằm trong Primary Key
) PARTITION BY RANGE (log_timestamp);

-- 1.2 Tạo các Bảng Con (Partitions) theo từng Quý
CREATE TABLE web_logs_2024_q1 PARTITION OF partitioned_web_logs
    FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2024-04-01 00:00:00');

CREATE TABLE web_logs_2024_q2 PARTITION OF partitioned_web_logs
    FOR VALUES FROM ('2024-04-01 00:00:00') TO ('2024-07-01 00:00:00');

-- 1.3 Nạp dữ liệu kiểm thử
INSERT INTO partitioned_web_logs (user_id, action_type, log_timestamp) VALUES
(101, 'login', '2024-02-14 10:00:00'),   -- Tự động điều hướng vào web_logs_2024_q1
(102, 'checkout', '2024-05-20 15:30:00'); -- Tự động điều hướng vào web_logs_2024_q2

-- 1.4 Kiểm tra PARTITION PRUNING trong EXPLAIN:
-- Optimizer sẽ tự động BỎ QUA HOÀN TOÀN partition Q2 và chỉ quét đúng partition Q1!
EXPLAIN ANALYZE
SELECT * FROM partitioned_web_logs
WHERE log_timestamp BETWEEN '2024-02-01' AND '2024-02-28';


-- ------------------------------------------------------------------------------
-- 2. BẢO TRÌ VÀ DỌN DẸP BỘ NHỚ (VACUUM & ANALYZE)
-- ------------------------------------------------------------------------------
-- 💡 BẢN CHẤT KIẾN TRÚC MVCC CỦA POSTGRESQL:
-- Khi bạn chạy lệnh `UPDATE` hoặc `DELETE`:
-- - Dòng dữ liệu cũ KHÔNG BỊ XÓA NGAY LẬP TỨC trên ổ cứng, mà chỉ bị đánh dấu là "Dòng chết" (Dead Tuple).
-- - Một dòng mới (New Tuple) được tạo ra.
-- - Theo thời gian, Dead Tuples tích tụ làm bảng bị phình to (Table Bloat) -> Tốn dung lượng Disk và làm chậm truy vấn.

-- 2.1 VACUUM: Dọn dẹp Dead Tuples để giải phóng và tái sử dụng không gian trống
VACUUM (VERBOSE, ANALYZE) orders;

-- 2.2 REINDEX: Xây dựng lại cây chỉ mục B-Tree khi bị phân mảnh sau nhiều thao tác INSERT/UPDATE
REINDEX TABLE orders;


-- ------------------------------------------------------------------------------
-- 3. MATERIALIZED VIEWS (BẢNG TỔNG HỢP VẬT LÝ CHO BI DASHBOARD)
-- ------------------------------------------------------------------------------
-- View thông thường: Chỉ là một câu truy vấn lưu tên, mỗi lần gọi View là Database phải tính lại từ đầu.
-- Materialized View: TÍNH TOÁN VÀ LƯU KẾT QUẢ VẬT LÝ XUỐNG Ổ CỨNG -> Dashboard đọc dữ liệu trong micro-seconds!

DROP MATERIALIZED VIEW IF EXISTS mv_monthly_sales_summary;

CREATE MATERIALIZED VIEW mv_monthly_sales_summary AS
SELECT 
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    c.category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)::DATE, c.category_name
WITH DATA;

-- Tạo Unique Index để kích hoạt tính năng làm mới không khóa bảng (Concurrent Refresh):
CREATE UNIQUE INDEX idx_mv_sales_month_cat ON mv_monthly_sales_summary(sales_month, category_name);

-- Làm mới dữ liệu ngầm mà KHÔNG CHẶN các truy vấn đọc của người dùng:
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_sales_summary;
