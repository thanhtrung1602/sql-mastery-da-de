-- ==============================================================================
-- FOLDER 07: CAPSTONE EXERCISES & MOCK EXAMS
-- FILE: 02_de_pipeline_exam.sql
-- MỤC TIÊU:
--   Đề thi thử thực chiến vị trí Senior Data Engineer (Hệ thống, ETL/ELT, Concurrency, Performance)
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 LƯU Ý CHO NGƯỜI MỚI: Lời giải bên dưới có lệnh ghi dữ liệu và tạo index. Chỉ chạy
-- trên database thực hành đã khởi tạo. Đọc kỹ `ON CONFLICT` và `CREATE INDEX` trước khi
-- áp dụng vào môi trường thật, vì chúng thay đổi trạng thái database.
-- ==============================================================================

-- ==============================================================================
-- ĐỀ BÀI 1: XÂY DỰNG PIPELINE KHỬ TRÙNG LẶP & IDEMPOTENT LOADING
-- ==============================================================================
-- MÔ TẢ:
--   Giả sử bảng staging nhận được các bản ghi thanh toán từ bên thứ 3 bị trùng lặp.
--   Viết truy vấn lọc ra bản ghi thanh toán mới nhất cho mỗi transaction_ref và nạp vào bảng payments
--   sao cho không bị lỗi Unique Violation (Idempotent Upsert).
--
-- DỮ LIỆU STAGING ĐẦU VÀO:
--   CREATE TEMP TABLE staging_payments_raw (
--       raw_payment_id INT,
--       raw_order_id INT,
--       raw_payment_date TIMESTAMP,
--       raw_amount NUMERIC(12, 2),
--       raw_payment_status VARCHAR(20),
--       raw_transaction_ref VARCHAR(100)
--   );
--   INSERT INTO staging_payments_raw VALUES
--   (901, 1001, '2024-03-01 10:00:00', 37720500, 'Success', 'TXN-EXTERNAL-001'),
--   (902, 1001, '2024-03-01 10:05:00', 37720500, 'Success', 'TXN-EXTERNAL-001'), -- Trùng ref, bản ghi này mới hơn
--   (903, 1002, '2024-03-01 11:00:00', 48040000, 'Success', 'TXN-EXTERNAL-002');
--
-- KẾT QUẢ MONG ĐỢI SAU KHI NẠP (TRÊN BẢNG PAYMENTS):
--   - Bản ghi TXN-EXTERNAL-001 lấy payment_id = 902 (timestamp mới hơn).
--   - Bản ghi TXN-EXTERNAL-002 lấy payment_id = 903.
--   - Không gây ra lỗi trùng khoá chính/unique constraint khi chạy lại nhiều lần (Idempotent).

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI: ranked_payments vẫn là dữ liệu staging, chưa ghi gì. ROW_NUMBER = 1 giữ bản
-- ghi mới nhất theo mỗi transaction_ref; thêm raw_payment_id DESC để quyết định ổn định nếu
-- hai bản ghi cùng thời điểm. Sau đó INSERT ... ON CONFLICT biến thao tác thành idempotent.
WITH ranked_payments AS (
    SELECT
        raw_payment_id AS payment_id,
        raw_order_id AS order_id,
        raw_payment_date AS payment_date,
        raw_amount AS amount,
        raw_payment_status AS payment_status,
        raw_transaction_ref AS transaction_ref,
        ROW_NUMBER() OVER (
            PARTITION BY raw_transaction_ref
            ORDER BY raw_payment_date DESC, raw_payment_id DESC
        ) AS dedup_rank
    FROM staging_payments_raw
)
INSERT INTO payments (
    payment_id, order_id, payment_date, amount, payment_status, transaction_ref
)
SELECT
    payment_id, order_id, payment_date, amount, payment_status, transaction_ref
FROM ranked_payments
WHERE dedup_rank = 1
ON CONFLICT (transaction_ref) DO UPDATE SET
    payment_id = EXCLUDED.payment_id,
    order_id = EXCLUDED.order_id,
    payment_date = EXCLUDED.payment_date,
    amount = EXCLUDED.amount,
    payment_status = EXCLUDED.payment_status;
-- 💡 `EXCLUDED` là dòng mới định chèn nhưng đã đụng unique transaction_ref. Chạy lại cùng
-- staging sẽ cập nhật cùng giá trị thay vì tạo thêm payment, nên kết quả cuối không đổi.




-- ==============================================================================
-- ĐỀ BÀI 2: TỐI ƯU HÓA TRUY VẤN VỚI COVERING INDEX
-- ==============================================================================
-- MÔ TẢ:
--   Dashboard cần truy vấn thông tin khách hàng dựa trên email thường xuyên:
--   SELECT first_name, last_name, customer_segment FROM customers WHERE email = '...';
--   Hãy viết lệnh tạo Covering Index tối ưu nhất để câu lệnh trên đạt trạng thái "Index Only Scan" (Heap Fetch = 0).
--
-- KẾT QUẢ MONG ĐỢI:
--   Lệnh CREATE INDEX với INCLUDE mệnh đề phù hợp trong PostgreSQL.
--   Kiểm tra EXPLAIN ANALYZE hiển thị: Index Only Scan using idx_customers_email_covering on customers.

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI: email là cột tìm kiếm nên đặt trong ngoặc sau tên index. Ba cột SELECT chỉ để
-- đọc nên đặt INCLUDE: index chứa đủ dữ liệu để PostgreSQL có cơ hội không phải quay về bảng.
CREATE INDEX idx_customers_email_covering
ON customers (email)
INCLUDE (first_name, last_name, customer_segment);

EXPLAIN (ANALYZE, BUFFERS)
SELECT first_name, last_name, customer_segment
FROM customers
WHERE email = 'an.nguyen@example.com';
-- ⚠️ Index Only Scan không bảo đảm Heap Fetch = 0 ngay sau CREATE INDEX: PostgreSQL còn cần
-- visibility map sau VACUUM. Đừng tạo index chỉ vì một truy vấn; index làm INSERT/UPDATE chậm hơn
-- và tốn dung lượng. Với bảng thực hành nhỏ, Planner cũng có thể chọn Seq Scan hợp lý.
