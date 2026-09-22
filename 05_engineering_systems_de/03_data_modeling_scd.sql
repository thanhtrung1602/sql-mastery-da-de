-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- BÀI GIẢNG 03: THIẾT KẾ DATA WAREHOUSE & SLOWLY CHANGING DIMENSIONS (SCD TYPE 2)
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Kiến trúc Mô hình hóa Chiều (Kimball Dimensional Modeling: Star Schema vs Snowflake Schema).
--   2. Phân loại Fact Tables (Transactional, Periodic Snapshot, Accumulating Snapshot).
--   3. Phân loại các dạng Slowly Changing Dimensions (SCD Type 0, 1, 2, 3, 4, 6).
--   4. Cài đặt chi tiết mô hình SCD Type 2 thực chiến (Surrogate Keys & Validity Ranges).
--   5. Viết truy vấn Trạng thái quá khứ (Point-in-Time Historical Querying).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Lưu dữ liệu kho theo cách trả lời được câu hỏi lịch sử, không chỉ trạng thái hiện tại.
-- CÂU LỆNH: CREATE TABLE (tạo fact/dimension), UPDATE/INSERT (SCD), transaction,
-- effective_date/expiry_date/is_current (dấu mốc SCD Type 2).
-- ⭐ MỨC ĐỘ DÙNG: mô hình fact/dimension và SCD2 thường gặp ở Data Warehouse; các Type 3/4 ít hơn.
-- 🧠 CẦN NHỚ: SCD1 ghi đè quá khứ; SCD2 đóng bản ghi cũ và chèn bản ghi mới để giữ lịch sử.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢNG SO SÁNH CÁC LOẠI SCD (SLOWLY CHANGING DIMENSIONS)
-- ------------------------------------------------------------------------------
-- ┌──────────┬─────────────────────────────┬─────────────────────────────────────────────────┐
-- │ Loại SCD │ Cơ chế xử lý khi đổi thông tin │ Đánh giá & Ứng dụng                             │
-- ├──────────┼─────────────────────────────┼─────────────────────────────────────────────────┤
-- │ Type 0   │ Giữ nguyên (Retain Original)│ Không bao giờ đổi (VD: Ngày sinh, Nơi sinh).    │
-- │ Type 1   │ Ghi đè (Overwrite)          │ MẤT TOÀN BỘ LỊCH SỬ (Chỉ giữ trạng thái mới nhất│
-- │ Type 2   │ Thêm dòng mới (Add Row)     │ CHUẨN VÀNG: Lưu vết toàn bộ lịch sử biến động.   │
-- │ Type 3   │ Thêm cột mới (Add Column)   │ Chỉ lưu được 1 trạng thái trước đó (Previous).  │
-- │ Type 4   │ Bảng lịch sử riêng (History)│ Bảng chính giữ Type 1, bảng phụ lưu lịch sử.    │
-- └──────────┴─────────────────────────────┴─────────────────────────────────────────────────┘


-- ------------------------------------------------------------------------------
-- 2. CÀI ĐẶT SCD TYPE 2 TRONG DATA WAREHOUSE
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS dim_customers_scd2 CASCADE;

CREATE TABLE dim_customers_scd2 (
    customer_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Khóa đại diện duy nhất (Surrogate Key)
    customer_id INT NOT NULL,                                     -- Khóa nghiệp vụ tự nhiên (Natural Key)
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    customer_segment VARCHAR(20),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP,                                           -- NULL có nghĩa là phiên bản hiện tại
    is_current BOOLEAN DEFAULT TRUE                               -- Cờ báo hiệu trạng thái mới nhất
);

-- 2.1 Khởi tạo dữ liệu ban đầu (Initial Load - Tháng 1/2023):
INSERT INTO dim_customers_scd2 (customer_id, first_name, last_name, email, city, customer_segment, valid_from, valid_to, is_current)
VALUES 
(1, 'Nguyen', 'Van An', 'an.nguyen@example.com', 'Ho Chi Minh', 'Standard', '2023-01-10 00:00:00', NULL, TRUE);

-- 2.2 Kịch bản biến động 1: Ngày 01/06/2023, khách hàng chuyển nhà đến 'Da Nang' và được nâng hạng 'Gold'
-- Bước A: Đóng phiên bản cũ
UPDATE dim_customers_scd2
SET valid_to = '2023-06-01 00:00:00',
    is_current = FALSE
WHERE customer_id = 1 AND is_current = TRUE;

-- Bước B: Chèn phiên bản mới (Version 2)
INSERT INTO dim_customers_scd2 (customer_id, first_name, last_name, email, city, customer_segment, valid_from, valid_to, is_current)
VALUES 
(1, 'Nguyen', 'Van An', 'an.nguyen@example.com', 'Da Nang', 'Gold', '2023-06-01 00:00:00', NULL, TRUE);

-- 2.3 Kịch bản biến động 2: Ngày 01/01/2024, khách hàng được nâng hạng 'VIP'
UPDATE dim_customers_scd2
SET valid_to = '2024-01-01 00:00:00',
    is_current = FALSE
WHERE customer_id = 1 AND is_current = TRUE;

INSERT INTO dim_customers_scd2 (customer_id, first_name, last_name, email, city, customer_segment, valid_from, valid_to, is_current)
VALUES 
(1, 'Nguyen', 'Van An', 'an.nguyen@example.com', 'Da Nang', 'VIP', '2024-01-01 00:00:00', NULL, TRUE);


-- ------------------------------------------------------------------------------
-- 3. TRUY VẤN POINT-IN-TIME (TRUY VẤN TRẠNG THÁI LỊCH SỬ CHÍNH XÁC)
-- ------------------------------------------------------------------------------

-- 3.1 Truy vấn trạng thái HIỆN TẠI (Current State):
SELECT customer_id, first_name, city, customer_segment 
FROM dim_customers_scd2 
WHERE is_current = TRUE;

-- 3.2 Point-in-Time Query: "Tại ngày '2023-08-15', khách hàng này ở thành phố nào và hạng gì?"
-- Kết quả chính xác: 'Da Nang' và hạng 'Gold' (Khớp điều kiện: valid_from <= T < valid_to)
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    city,
    customer_segment,
    valid_from,
    valid_to
FROM dim_customers_scd2
WHERE customer_id = 1
  AND valid_from <= '2023-08-15 00:00:00'
  AND (valid_to > '2023-08-15 00:00:00' OR valid_to IS NULL);
