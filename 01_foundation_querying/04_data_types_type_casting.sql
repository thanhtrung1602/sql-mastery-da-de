-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 01: FOUNDATION QUERYING
-- BÀI GIẢNG 04: HỆ THỐNG KIỂU DỮ LIỆU, ÉP KIỂU VÀ XỬ LÝ THỜI GIAN/MÚI GIỜ
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Tổng quan các hệ kiểu dữ liệu trong SQL (Numeric, Text, Temporal, Boolean, Semi-structured).
--   2. Phép ép kiểu tường minh (Explicit Casting): CAST() vs Toán tử `::`.
--   3. Xử lý thời gian chuyên sâu: TIMESTAMP WITHOUT TIME ZONE vs TIMESTAMPTZ.
--   4. Toán học thời gian với INTERVAL và hàm AGE().
--   5. Chuyển đổi múi giờ (Timezone Conversion) trong hệ thống toàn cầu.
--   6. Thao tác với kiểu Mảng (Arrays) cơ bản.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Nhận ra dữ liệu là số, chữ, ngày giờ hay dữ liệu có cấu trúc; đổi kiểu đúng lúc.
-- CÂU LỆNH: CAST(... AS type) và `::type` (ép kiểu), INTERVAL (khoảng thời gian),
-- AGE/EXTRACT (tính và lấy thành phần thời gian), AT TIME ZONE (đổi múi giờ), ARRAY.
-- ⭐ MỨC ĐỘ DÙNG: DATE, TIMESTAMP, CAST rất thường xuyên; array và timezone nâng cao.
-- 🧠 CẦN NHỚ: Tiền dùng NUMERIC, không dùng FLOAT; dữ liệu thời điểm toàn cầu nên lưu UTC.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢN ĐỒ CÁC KIỂU DỮ LIỆU CỐT LÕI TRONG CƠ SỞ DỮ LIỆU
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬──────────────────┬──────────────┬──────────────────────────────────────────┐
-- │ Nhóm Kiểu       │ Tên Kiểu         │ Dung lượng   │ Phạm vi / Ứng dụng                       │
-- ├─────────────────┼──────────────────┼──────────────┼──────────────────────────────────────────┤
-- │ Số nguyên       │ SMALLINT         │ 2 bytes      │ -32,768 đến +32,767                      │
-- │                 │ INT / INTEGER    │ 4 bytes      │ -2.1 tỷ đến +2.1 tỷ (Khóa chính mặc định)│
-- │                 │ BIGINT           │ 8 bytes      │ -9 tỷ tỷ đến +9 tỷ tỷ (Log/Events lớn)   │
-- ├─────────────────┼──────────────────┼──────────────┼──────────────────────────────────────────┤
-- │ Số thực/Chính xác│ NUMERIC(p, s)   │ Biến đổi     │ Tiền tệ, Tài chính (Không bị sai số float│
-- │                 │ REAL / DOUBLE    │ 4/8 bytes    │ Tính toán khoa học, ML (Chấp nhận sai số)│
-- ├─────────────────┼──────────────────┼──────────────┼──────────────────────────────────────────┤
-- │ Chuỗi           │ VARCHAR(N)       │ N bytes + len│ Chuỗi có giới hạn độ dài                 │
-- │                 │ TEXT             │ Biến đổi     │ Chuỗi văn bản độ dài bất kỳ              │
-- ├─────────────────┼──────────────────┼──────────────┼──────────────────────────────────────────┤
-- │ Thời gian       │ DATE             │ 4 bytes      │ Chỉ lưu Ngày (YYYY-MM-DD)                │
-- │                 │ TIMESTAMP (TZ)   │ 8 bytes      │ Ngày + Giờ (Kèm hoặc không kèm Múi giờ)  │
-- │                 │ INTERVAL         │ 16 bytes     │ Khoảng thời gian (Ví dụ: '7 days')       │
-- └─────────────────┴──────────────────┴──────────────┴──────────────────────────────────────────┘


-- ------------------------------------------------------------------------------
-- 2. ÉP KIỂU DỮ LIỆU (TYPE CASTING)
-- ------------------------------------------------------------------------------

-- 2.1 Cú pháp chuẩn ANSI SQL: CAST(biểu_thức AS kiểu_đích)
SELECT 
    order_id,
    order_date,
    CAST(order_date AS DATE) AS order_date_only,
    CAST(shipping_fee AS INT) AS shipping_fee_rounded,
    CAST(customer_id AS VARCHAR(10)) AS customer_id_str
FROM orders;
-- 💬 CAST không làm thay đổi kiểu của cột gốc trong bảng orders; nó chỉ đổi kiểu của giá trị
-- trong kết quả truy vấn này. `AS order_date_only` là tên cột kết quả, không phải tên kiểu.

-- 2.2 Cú pháp ngắn gọn của PostgreSQL: biểu_thức::kiểu_đích
SELECT 
    product_id,
    unit_price,
    unit_price::NUMERIC(10, 0) AS price_clean,
    '2024-01-15'::DATE AS parsed_date,
    '{"status": "active"}'::JSONB AS json_data
FROM products;
-- 💬 `expr::TYPE` là cách rút gọn của PostgreSQL. Với mã cần dễ chuyển sang database khác,
-- `CAST(expr AS TYPE)` dễ đọc và tương thích hơn.


-- ------------------------------------------------------------------------------
-- 3. TOÁN HỌC THỜI GIAN VỚI INTERVAL VÀ HÀM AGE()
-- ------------------------------------------------------------------------------
-- `INTERVAL` cho phép bạn cộng trừ các đơn vị thời gian (năm, tháng, ngày, giờ, phút, giây)
-- một cách tự nhiên mà không cần phải đổi ra Unix Epoch timestamp.

SELECT 
    order_id,
    order_date,
    -- Cộng 7 ngày để ước tính ngày giao hàng:
    order_date + INTERVAL '7 days' AS estimated_delivery_date,
    
    -- Lùi về đúng 1 tháng trước:
    order_date - INTERVAL '1 month' AS one_month_prior,
    
    -- Cộng hỗn hợp: 2 ngày 4 giờ 30 phút:
    order_date + INTERVAL '2 days 4 hours 30 minutes' AS exact_future_moment
FROM orders;
-- 💬 `INTERVAL '7 days'` là một khoảng, không phải một ngày cụ thể. Cộng nó vào timestamp
-- tạo timestamp mới; lệnh SELECT chỉ xem thử, không cập nhật order_date trong bảng.

-- 3.2 Tính tuổi và khoảng cách thời gian chính xác với AGE():
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    birth_date,
    AGE(CURRENT_DATE, birth_date) AS exact_age_interval, -- Trả về dạng: '32 years 3 mons 4 days'
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS age_in_years -- Trích xuất số năm nguyên vẹn
FROM customers;
-- 💬 CURRENT_DATE lấy ngày hiện tại theo phiên database. AGE trả về khoảng lịch (năm/tháng/ngày),
-- còn EXTRACT(YEAR FROM ...) lấy riêng phần năm. Hai khái niệm khác với chia số ngày cho 365.


-- ------------------------------------------------------------------------------
-- 4. XỬ LÝ MÚI GIỜ (TIMEZONE CONVERSIONS - TIMESTAMPTZ)
-- ------------------------------------------------------------------------------
-- 💡 NGUYÊN TẮC VÀNG TRONG DATA ENGINEERING:
-- Trong Data Warehouse toàn cầu, TOÀN BỘ timestamp nên được lưu ở chuẩn UTC (Coordinated Universal Time).
-- Khi trình diễn lên Dashboard cho người dùng ở từng quốc gia, ta mới convert sang Local Timezone tương ứng.

SELECT 
    event_id,
    event_time,
    -- Chuyển sang múi giờ UTC:
    event_time AT TIME ZONE 'UTC' AS time_utc,
    
    -- Chuyển sang múi giờ Việt Nam (GMT+7):
    event_time AT TIME ZONE 'Asia/Ho_Chi_Minh' AS time_vietnam,
    
    -- Chuyển sang múi giờ New York (Eastern Time):
    event_time AT TIME ZONE 'America/New_York' AS time_us_east
FROM web_events;
-- ⚠️ AT TIME ZONE phụ thuộc kiểu đầu vào (TIMESTAMP hay TIMESTAMPTZ). Trước khi dùng cho báo
-- cáo thật, hãy kiểm tra event_time đang được lưu ở múi giờ nào để tránh hiển thị lệch 7 tiếng.


-- ------------------------------------------------------------------------------
-- 5. KIỂU DỮ LIỆU MẢNG (ARRAYS)
-- ------------------------------------------------------------------------------
-- PostgreSQL hỗ trợ kiểu dữ liệu mảng nguyên bản (Native Arrays).
-- Lưu ý: Chỉ mục (Index) của mảng trong SQL bắt đầu từ 1 (1-based Index), KHÔNG PHẢI 0!

SELECT 
    ARRAY['Hanoi', 'Ho Chi Minh', 'Da Nang'] AS vietnam_cities,
    (ARRAY['Hanoi', 'Ho Chi Minh', 'Da Nang'])[1] AS first_city_hanoi, -- Lấy phần tử thứ 1
    (ARRAY['Hanoi', 'Ho Chi Minh', 'Da Nang'])[2] AS second_city_hcm,  -- Lấy phần tử thứ 2
    ARRAY_LENGTH(ARRAY['Hanoi', 'Ho Chi Minh', 'Da Nang'], 1) AS total_elements;
-- 💬 `ARRAY[...]` tạo mảng. Chỉ số `[1]` lấy phần tử đầu vì PostgreSQL đếm từ 1. Mảng phù hợp
-- cho thuộc tính nhỏ, cố định; dữ liệu quan hệ lớn nên tách thành bảng và JOIN.
