-- ==============================================================================
-- FOLDER 07: CAPSTONE EXERCISES & MOCK EXAMS
-- FILE: 01_da_analytics_exam.sql
-- MỤC TIÊU:
--   Đề thi thử thực chiến vị trí Senior Data Analyst (Tổng hợp 5 bài toán kinh doanh lớn)
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 LƯU Ý CHO NGƯỜI MỚI: Đây là đề tự luyện có lời giải chú thích. Hãy tự viết trước,
-- rồi mới chạy lời giải. Với mọi chỉ số %, hãy nói rõ tử số là gì, mẫu số là gì và một dòng
-- đầu ra đại diện cho thiết bị/khách hàng/quý nào.
-- ==============================================================================

-- ==============================================================================
-- ĐỀ BÀI 1: PHÂN TÍCH TỶ LỆ CHUYỂN ĐỔI PHỄU THEO THIẾT BỊ (DEVICE FUNNEL CONVERSION)
-- ==============================================================================
-- MÔ TẢ:
--   Bộ phận Marketing muốn biết người dùng trên Desktop hay Mobile có tỷ lệ hoàn tất đơn hàng cao hơn.
--   Hãy tính toán số lượng session và tỷ lệ % chuyển đổi từ bước 'page_view' đến 'purchase' theo từng loại 'device_type'.
--   Sắp xếp theo session_conversion_rate_pct giảm dần.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+----------------+---------------------+------------------------------+
-- | device_type | total_sessions | purchasing_sessions | session_conversion_rate_pct  |
-- +-------------+----------------+---------------------+------------------------------+
-- | Desktop     |              2 |                   2 |                       100.00 |
-- | Mobile      |              2 |                   0 |                         0.00 |
-- +-------------+----------------+---------------------+------------------------------+
-- (2 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI: session_steps biến nhiều event trong cùng session thành đúng một dòng/session.
WITH session_steps AS (
    SELECT
        device_type,
        session_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS has_page_view,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM web_events
    GROUP BY device_type, session_id
)
SELECT
    device_type,
    COUNT(*) FILTER (WHERE has_page_view = 1) AS total_sessions,
    COUNT(*) FILTER (WHERE has_page_view = 1 AND has_purchase = 1) AS purchasing_sessions,
    ROUND(
        COUNT(*) FILTER (WHERE has_page_view = 1 AND has_purchase = 1) * 100.0
        / NULLIF(COUNT(*) FILTER (WHERE has_page_view = 1), 0),
        2
    ) AS session_conversion_rate_pct
FROM session_steps
GROUP BY device_type
ORDER BY session_conversion_rate_pct DESC NULLS LAST;
-- 💡 MAX của các giá trị 0/1 hoạt động như "có ít nhất một event loại này". COUNT FILTER
-- đếm session, không đếm event, nên một user xem nhiều trang không làm phồng tỷ lệ.




-- ==============================================================================
-- ĐỀ BÀI 2: ĐO LƯỜNG GIÁ TRỊ VÒNG ĐỜI KHÁCH HÀNG (CUSTOMER LIFETIME VALUE - CLV)
-- ==============================================================================
-- MÔ TẢ:
--   Xác định Top 5 khách hàng có tổng giá trị đóng góp (CLV) cao nhất cho công ty (tính từ các đơn hàng 'Completed').
--   Bao gồm: customer_id, tên đầy đủ (full_name), ngày đăng ký (signup_date), tổng số đơn hàng đã hoàn tất (completed_orders),
--   tổng chi tiêu thực tế (customer_lifetime_value), và giá trị trung bình trên mỗi đơn hàng (personal_aov).
--   Sắp xếp theo customer_lifetime_value giảm dần.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+---------------+-------------+------------------+-------------------------+--------------+
-- | customer_id | full_name     | signup_date | completed_orders | customer_lifetime_value | personal_aov |
-- +-------------+---------------+-------------+------------------+-------------------------+--------------+
-- | 1           | Nguyen Van An | 2023-01-10  |                4 |            129985500.00 |     32496375 |
-- | 7           | David Smith   | 2023-05-25  |                2 |            114790000.00 |     57395000 |
-- | 2           | Tran Thi Bich | 2023-02-15  |                3 |            100470000.00 |     33490000 |
-- | 5           | Hoang Minh Em | 2023-04-05  |                2 |             58203500.00 |     29101750 |
-- | 8           | Do Hoang Hai  | 2023-06-18  |                1 |             32000000.00 |     32000000 |
-- +-------------+---------------+-------------+------------------+-------------------------+--------------+
-- (5 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI: order_values làm đúng một dòng/đơn hàng trước. Đây là bước quan trọng vì
-- order_items có thể có nhiều dòng; đếm order_id ngay sau JOIN sẽ dễ đếm trùng đơn.
WITH order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS order_net_value
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, o.customer_id
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.signup_date,
    COUNT(ov.order_id) AS completed_orders,
    SUM(ov.order_net_value) AS customer_lifetime_value,
    ROUND(SUM(ov.order_net_value) / NULLIF(COUNT(ov.order_id), 0), 0) AS personal_aov
FROM customers AS c
JOIN order_values AS ov ON ov.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.signup_date
ORDER BY customer_lifetime_value DESC
LIMIT 5;
-- 🧠 CẦN NHỚ: CTE đầu là "một dòng = một đơn"; truy vấn cuối là "một dòng = một khách".




-- ==============================================================================
-- ĐỀ BÀI 3: PHÂN TÍCH TỐC ĐỘ TĂNG TRƯỞNG DOANH THU THEO QUÝ (QOQ REVENUE GROWTH)
-- ==============================================================================
-- MÔ TẢ:
--   Tính tổng doanh thu thuần theo từng Quý trong năm (từ các đơn hàng 'Completed'), doanh thu của Quý liền trước,
--   và tốc độ tăng trưởng phần trăm theo quý (QoQ Growth %).
--   Sắp xếp theo sales_quarter tăng dần.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +---------------+-------------------+----------------------+----------------+
-- | sales_quarter | quarterly_revenue | prev_quarter_revenue | qoq_growth_pct |
-- +---------------+-------------------+----------------------+----------------+
-- | 2023-07-01    |      114136500.00 |                 NULL |           NULL |
-- | 2023-10-01    |      246629000.00 |         114136500.00 |         116.08 |
-- | 2024-01-01    |      103070000.00 |         246629000.00 |         -58.21 |
-- +---------------+-------------------+----------------------+----------------+
-- (3 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI: quarterly_revenue là một dòng/quý. LAG đọc doanh thu của dòng quý ngay trước
-- theo thời gian; vì vậy phải tạo doanh thu theo quý trước rồi mới dùng window function.
WITH quarterly_revenue AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date)::DATE AS sales_quarter,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS quarterly_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('quarter', o.order_date)::DATE
),
with_previous_quarter AS (
    SELECT
        sales_quarter,
        quarterly_revenue,
        LAG(quarterly_revenue) OVER (ORDER BY sales_quarter) AS prev_quarter_revenue
    FROM quarterly_revenue
)
SELECT
    sales_quarter,
    quarterly_revenue,
    prev_quarter_revenue,
    ROUND(
        (quarterly_revenue - prev_quarter_revenue) * 100.0
        / NULLIF(prev_quarter_revenue, 0),
        2
    ) AS qoq_growth_pct
FROM with_previous_quarter
ORDER BY sales_quarter;
-- ⚠️ Quý đầu không có quý trước nên LAG trả NULL; tăng trưởng NULL là trung thực, không phải 0%.
