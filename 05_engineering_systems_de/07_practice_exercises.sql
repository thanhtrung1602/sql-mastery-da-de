-- ==============================================================================
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- FILE: 07_practice_exercises.sql
-- MỤC TIÊU:
--   Luyện tập các kỹ năng hệ thống cốt lõi của Data Engineer:
--   SCD Type 2 Pipelines, Idempotent Upsert, Row Locking, JSONB ETL Transformations,
--   Indexing, và Partitioning.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH LÀM AN TOÀN: Đọc kỹ các lệnh INSERT/UPDATE/DELETE/CREATE trước khi chạy. Với
-- bài ghi dữ liệu, bọc thử nghiệm trong BEGIN ... ROLLBACK để xem kết quả mà không lưu vĩnh viễn.
-- 🧠 CẦN NHỚ: Khóa unique/primary key quyết định dòng nào là "cùng một thực thể" khi UPSERT.
-- ==============================================================================

-- ==============================================================================
-- BÀI TẬP 1 (IDEMPOTENT UPSERT): ĐỒNG BỘ DỮ LIỆU TỒN KHO TỪ BẢNG ĐỆM
-- ==============================================================================
-- YÊU CẦU:
--   Cho bảng đệm `temp_inventory_sync` chứa thông tin cập nhật tồn kho mới.
--   Viết câu lệnh `INSERT INTO ... ON CONFLICT (product_id) DO UPDATE` để:
--   - Nếu sản phẩm đã có: Cập nhật `stock_quantity` mới và `unit_price` mới.
--   - Nếu sản phẩm chưa có: Chèn mới vào bảng `products`.
--
-- DỮ LIỆU ĐỆM BAN ĐẦU:
--   CREATE TEMP TABLE temp_inventory_sync (
--       product_id INT PRIMARY KEY,
--       product_name VARCHAR(150),
--       category_id INT,
--       cost_price NUMERIC(12, 2),
--       unit_price NUMERIC(12, 2),
--       stock_quantity INT
--   );
--   INSERT INTO temp_inventory_sync VALUES 
--   (101, 'iPhone 15 Pro Max 256GB', 2, 26000000, 32000000, 100),
--   (199, 'Mechanical Keyboard Keychron K2', 4, 1500000, 2200000, 50);
--
-- KẾT QUẢ MONG ĐỢI SAU KHI UPSERT (KIỂM TRA TRÊN BẢNG PRODUCTS):
--   Product 101 có stock_quantity được cập nhật thành 100.
--   Product 199 được chèn mới thành công vào bảng products với stock_quantity = 50.

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 2 (JSONB ETL TRANSFORMATION): TRÍCH XUẤT THUỘC TÍNH JSON THÀNH DẠNG QUAN HỆ
-- ==============================================================================
-- YÊU CẦU:
--   Bảng `products` có cột `specs` lưu JSONB. Viết truy vấn trích xuất:
--   - product_id, product_name.
--   - Dung lượng RAM (`ram_spec` dạng text).
--   - Dung lượng bộ nhớ (`storage_spec` dạng text).
--   - Trọng lượng gram (`weight_in_grams` ép kiểu INT).
--   - Chỉ lọc các sản phẩm có thuộc tính RAM tồn tại trong JSONB.
--
-- GỢI Ý: Dùng toán tử `->>` và toán tử kiểm tra key tồn tại `?`.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------+--------------------------+----------+--------------+-----------------+
-- | product_id | product_name             | ram_spec | storage_spec | weight_in_grams |
-- +------------+--------------------------+----------+--------------+-----------------+
-- | 101        | iPhone 15 Pro Max 256GB  | 8GB      | 256GB        |             221 |
-- | 102        | Samsung Galaxy S24 Ultra | 12GB     | 512GB        |            NULL |
-- | 103        | MacBook Pro 14 M3 Pro    | 18GB     | 512GB        |            NULL |
-- | 104        | Dell XPS 15 9530         | 32GB     | 1TB          |            NULL |
-- +------------+--------------------------+----------+--------------+-----------------+
-- (4 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 3 (CONCURRENCY ROW LOCKING): XÂY DỰNG HÀNG ĐỢI XỬ LÝ SỰ KIỆN WEB
-- ==============================================================================
-- YÊU CẦU:
--   Viết câu lệnh khóa an toàn 3 sự kiện web chưa xử lý (trong transaction) mà không làm
--   treo các tiến trình worker khác đang chạy song song (SKIP LOCKED).
--   Hiển thị event_id, session_id, event_type, event_time.
--
-- GỢI Ý: Dùng `SELECT ... FOR UPDATE SKIP LOCKED LIMIT 3`.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +----------+------------+------------+---------------------+
-- | event_id | session_id | event_type | event_time          |
-- +----------+------------+------------+---------------------+
-- | 1        | sess_001   | page_view  | 2023-09-01 10:00:00 |
-- | 2        | sess_001   | search     | 2023-09-01 10:05:00 |
-- | 3        | sess_001   | add_to_cart| 2023-09-01 10:08:00 |
-- +----------+------------+------------+---------------------+
-- (3 rows - locked)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 4 (SCD TYPE 2 LOGIC): CẬP NHẬT ĐỊA CHỈ KHÁCH HÀNG
-- ==============================================================================
-- YÊU CẦU:
--   Viết block lệnh chuẩn cập nhật địa chỉ khách hàng (customer_id = 2) từ 'Hanoi' sang 'Ho Chi Minh'
--   trong bảng `dim_customers_scd2` theo chuẩn SCD Type 2:
--   1. Bước 1: Cập nhật bản ghi hiện tại thành `is_current = FALSE`, `valid_to = CURRENT_TIMESTAMP`.
--   2. Bước 2: Chèn bản ghi mới với `city = 'Ho Chi Minh'`, `is_current = TRUE`, `valid_from = CURRENT_TIMESTAMP`, `valid_to = NULL`.
--
-- KẾT QUẢ MONG ĐỢI TRÊN BẢNG DIM_CUSTOMERS_SCD2:
-- +-------------+---------------+-------------+---------------------+---------------------+------------+
-- | customer_id | first_name    | city        | valid_from          | valid_to            | is_current |
-- +-------------+---------------+-------------+---------------------+---------------------+------------+
-- | 2           | Tran Thi Bich | Hanoi       | 2023-02-15 09:45:00 | <CURRENT_TIMESTAMP> | FALSE      |
-- | 2           | Tran Thi Bich | Ho Chi Minh | <CURRENT_TIMESTAMP> | NULL                | TRUE       |
-- +-------------+---------------+-------------+---------------------+---------------------+------------+

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
