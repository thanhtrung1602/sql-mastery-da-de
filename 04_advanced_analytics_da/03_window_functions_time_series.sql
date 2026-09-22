-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- BÀI GIẢNG 03: HÀM CỬA SỔ CHUỖI THỜI GIAN, ĐIỀU HƯỚNG GIÁ TRỊ VÀ WINDOW FRAMING
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Hàm điều hướng giá trị: LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE().
--   2. Tính toán tốc độ tăng trưởng chu kỳ: MoM (Month-over-Month), YoY (Year-over-Year).
--   3. Tổng lũy kế tích lũy (Running Total / Cumulative Sum).
--   4. MỆNH ĐỀ ĐỊNH NGHĨA KHUNG CỬA SỔ (WINDOW FRAME SPECIFICATION): ROWS vs RANGE.
--   5. Tính toán Trung bình trượt (Moving Averages: 7-Day / 30-Day Moving Avg).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: So sánh hiện tại với quá khứ/tương lai và tính số liệu lũy kế theo thời gian.
-- CÂU LỆNH: LAG (dòng trước), LEAD (dòng sau), SUM OVER (lũy kế), ROWS/RANGE (khung cửa sổ),
-- AVG OVER (trung bình trượt).
-- ⭐ MỨC ĐỘ DÙNG: LAG, SUM OVER và AVG OVER rất thường xuyên trong báo cáo chuỗi thời gian.
-- 🧠 CẦN NHỚ: Luôn có ORDER BY ổn định trong OVER. "7 dòng trước" (ROWS) khác "7 ngày
-- trước" (RANGE); hãy chọn đúng theo ý nghĩa nghiệp vụ.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. HÀM ĐIỀU HƯỚNG GIÁ TRỊ: LAG() VÀ LEAD()
-- ------------------------------------------------------------------------------
-- - `LAG(cột, N, default_val)`  : Lấy giá trị của $N$ dòng ĐỨNG TRƯỚC dòng hiện tại.
-- - `LEAD(cột, N, default_val)` : Lấy giá trị của $N$ dòng ĐỨNG SAU dòng hiện tại.

-- 🎯 BÀI TOÁN KINH DOANH: TÍNH TĂNG TRƯỞNG DOANH THU THEO THÁNG (MOM GROWTH %):
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS current_rev
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)::DATE
)
SELECT 
    sales_month,
    current_rev AS doanh_thu_thang_nay,
    
    -- Lấy doanh thu của tháng liền trước:
    LAG(current_rev, 1) OVER (ORDER BY sales_month ASC) AS doanh_thu_thang_truoc,
    
    -- Tăng trưởng tuyệt đối:
    current_rev - LAG(current_rev, 1) OVER (ORDER BY sales_month ASC) AS tang_truong_tuyet_doi,
    
    -- Tỷ lệ tăng trưởng % (MoM Growth Rate %):
    ROUND(
        (current_rev - LAG(current_rev, 1) OVER (ORDER BY sales_month ASC)) * 100.0 / 
        NULLIF(LAG(current_rev, 1) OVER (ORDER BY sales_month ASC), 0), 
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY sales_month ASC;


-- ------------------------------------------------------------------------------
-- 2. RUNNING TOTAL (TỔNG LŨY KẾ THEO THỜI GIAN)
-- ------------------------------------------------------------------------------
-- 💡 CƠ CHẾ: Cộng dồn giá trị của tất cả các dòng từ điểm bắt đầu cho tới dòng hiện tại.

WITH daily_sales AS (
    SELECT 
        CAST(o.order_date AS DATE) AS sale_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS daily_rev
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY CAST(o.order_date AS DATE)
)
SELECT 
    sale_date,
    daily_rev,
    -- Mặc định khi có ORDER BY, khung cửa sổ là RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW:
    SUM(daily_rev) OVER (ORDER BY sale_date ASC) AS running_total_revenue
FROM daily_sales
ORDER BY sale_date ASC;


-- ------------------------------------------------------------------------------
-- 3. MỆNH ĐỀ WINDOW FRAME (KHUNG CỬA SỔ CHI TIẾT)
-- ------------------------------------------------------------------------------
-- ┌───────────────────────────┬────────────────────────────────────────────────────────┐
-- │ Thành phần Frame          │ Ý nghĩa                                                │
-- ├───────────────────────────┼────────────────────────────────────────────────────────┤
-- │ UNBOUNDED PRECEDING       │ Bắt đầu từ dòng ĐẦU TIÊN của Partition                 │
-- │ N PRECEDING               │ Bắt đầu từ $N$ dòng phía trước dòng hiện tại           │
-- │ CURRENT ROW               │ Dòng hiện tại đang được tính toán                      │
-- │ N FOLLOWING               │ Đến $N$ dòng phía sau dòng hiện tại                    │
-- │ UNBOUNDED FOLLOWING       │ Đến tận dòng CUỐI CÙNG của Partition                   │
-- └───────────────────────────┴────────────────────────────────────────────────────────┘

-- 🎯 BÀI TOÁN: TÍNH TRUNG BÌNH TRƯỢT 3 NGÀY (3-DAY MOVING AVERAGE)
-- Khung cửa sổ sẽ gồm: [Dòng hôm kia, Dòng hôm qua, Dòng hôm nay] = 3 dòng.

WITH daily_sales AS (
    SELECT 
        CAST(o.order_date AS DATE) AS sale_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS daily_rev
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY CAST(o.order_date AS DATE)
)
SELECT 
    sale_date,
    daily_rev,
    ROUND(
        AVG(daily_rev) OVER (
            ORDER BY sale_date ASC 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW -- Cửa sổ trượt 3 dòng
        ), 
        2
    ) AS moving_avg_3_days
FROM daily_sales
ORDER BY sale_date ASC;
