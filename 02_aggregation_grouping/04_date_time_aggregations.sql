-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 02: AGGREGATION & GROUPING
-- BÀI GIẢNG 04: TỔNG HỢP THEO CHUỖI THỜI GIAN, TIME BUCKETING VÀ XỬ LÝ KHOẢNG TRỐNG
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Cơ chế làm tròn thời gian với DATE_TRUNC() (Hour, Day, Week, Month, Quarter, Year).
--   2. Trích xuất thành phần chu kỳ với EXTRACT() và TO_CHAR().
--   3. Gom nhóm theo khoảng thời gian tùy biến (Time Bucketing & Trend Analysis).
--   4. Kỹ thuật lấp đầy khoảng trống ngày tháng (Continuous Date Spine & GENERATE_SERIES).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Gom dữ liệu thời gian thành ngày/tháng và tránh tính sai do múi giờ.
-- CÂU LỆNH: DATE_TRUNC (cắt về đầu đơn vị), EXTRACT (lấy phần năm/tháng...),
-- INTERVAL (khoảng thời gian), FILTER/CASE (tạo chỉ số theo điều kiện).
-- ⭐ MỨC ĐỘ DÙNG: DATE_TRUNC, EXTRACT, INTERVAL rất thường xuyên trong báo cáo.
-- 🧠 CẦN NHỚ: Muốn nhóm theo tháng, SELECT và GROUP BY phải dùng cùng biểu thức tháng.
-- `DATE_TRUNC('month', ts)` là đầu tháng, không phải một chuỗi nhãn hiển thị.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CẮT GỌT THỜI GIAN VỚI DATE_TRUNC (VŨ KHÍ SỐ 1 CỦA DATA ANALYST)
-- ------------------------------------------------------------------------------
-- `DATE_TRUNC(unit, timestamp)` sẽ làm tròn mốc thời gian về ĐẦU của chu kỳ chỉ định:
--
--   Timestamp gốc: '2023-09-15 14:35:22'
--   ├── DATE_TRUNC('hour')    ──> '2023-09-15 14:00:00' (Đầu giờ)
--   ├── DATE_TRUNC('day')     ──> '2023-09-15 00:00:00' (Đầu ngày)
--   ├── DATE_TRUNC('week')    ──> '2023-09-11 00:00:00' (Đầu tuần - Thứ 2)
--   ├── DATE_TRUNC('month')   ──> '2023-09-01 00:00:00' (Đầu tháng)
--   ├── DATE_TRUNC('quarter') ──> '2023-07-01 00:00:00' (Đầu quý 3)
--   └── DATE_TRUNC('year')    ──> '2023-01-01 00:00:00' (Đầu năm)

-- 🎯 BÁO CÁO DOANH SỐ THỰC TẾ THEO TỪNG THÁNG:
SELECT 
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_completed_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers_bought,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS net_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)::DATE
ORDER BY sales_month ASC;


-- ------------------------------------------------------------------------------
-- 2. TRÍCH XUẤT THÀNH PHẦN VỚI EXTRACT & DATE_PART
-- ------------------------------------------------------------------------------
-- Dùng khi muốn phân tích tính mùa vụ, thói quen theo khung giờ hoặc ngày trong tuần.

-- 🎯 PHÂN TÍCH KHUNG GIỜ VÀ THỨ TRONG TUẦN CÓ LƯỢNG ĐẶT HÀNG CAO NHẤT (PEAK HOURS):
SELECT 
    EXTRACT(DOW FROM order_date) AS day_of_week_num, -- 0 = Chủ Nhật, 1 = Thứ 2, ..., 6 = Thứ 7
    TO_CHAR(order_date, 'Day') AS day_of_week_name,
    EXTRACT(HOUR FROM order_date) AS order_hour,     -- Khung giờ từ 0 đến 23
    COUNT(order_id) AS total_orders_placed
FROM orders
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day'), EXTRACT(HOUR FROM order_date)
ORDER BY day_of_week_num, order_hour;


-- ------------------------------------------------------------------------------
-- 3. LẤP ĐẦY KHOẢNG TRỐNG THỜI GIAN (CONTINUOUS DATE SPINE GENERATION)
-- ------------------------------------------------------------------------------
-- ⚠️ VẤN ĐỀ NGHIỆP VỤ THỰC TẾ:
-- Nếu cửa hàng của bạn không có đơn hàng nào vào ngày '2023-09-03', phép `GROUP BY order_date`
-- thông thường sẽ BỎ QUA HOÀN TOÀN ngày đó -> Làm đứt gãy biểu đồ đường (Line Chart) trên Dashboard BI!
--
-- 💡 GIẢI PHÁP: 
-- Tạo một "Xương sống ngày liên tục" (Date Spine) bằng hàm `generate_series()` và `LEFT JOIN` với bảng đơn hàng.

WITH date_spine AS (
    -- Sinh ra danh sách tất cả các ngày từ 01/09/2023 đến 30/09/2023 không thiếu ngày nào:
    SELECT generate_series(
        '2023-09-01'::DATE, 
        '2023-09-30'::DATE, 
        INTERVAL '1 day'
    )::DATE AS calendar_date
)
SELECT 
    ds.calendar_date,
    COUNT(o.order_id) AS total_orders_placed,
    COALESCE(SUM(o.shipping_fee), 0) AS total_shipping_fees
FROM date_spine ds
LEFT JOIN orders o ON ds.calendar_date = CAST(o.order_date AS DATE)
GROUP BY ds.calendar_date
ORDER BY ds.calendar_date ASC;
