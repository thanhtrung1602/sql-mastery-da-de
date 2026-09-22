-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- BÀI GIẢNG 04: PHÂN TÍCH COHORT RETENTION & PHỄU CHUYỂN ĐỔI (CONVERSION FUNNEL)
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Phương pháp luận Phân tích Nhóm thuần tập (Cohort Analysis Methodology).
--   2. Xây dựng Ma trận Giữ chân người dùng theo tháng (Monthly Cohort Retention Matrix M0 -> MN).
--   3. Phân tích Phễu hành vi người dùng (Web Conversion Funnel & Drop-off Rates).
--   4. Các chỉ số sức khỏe doanh nghiệp: Churn Rate, Repeat Purchase Rate, LTV.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Theo dõi nhóm người dùng cùng thời điểm bắt đầu và tỷ lệ đi qua các bước.
-- CÂU LỆNH: CTE (chia bước), DATE_TRUNC (tháng cohort), JOIN (nối hoạt động),
-- COUNT DISTINCT (đếm người duy nhất), CASE/FILTER (đếm từng bước funnel).
-- ⭐ MỨC ĐỘ DÙNG: CTE, DATE_TRUNC, COUNT DISTINCT thường xuyên; cohort/funnel là kỹ thuật DA.
-- 🧠 CẦN NHỚ: Phải xác định rõ mẫu số của retention/funnel. Một user xuất hiện nhiều event
-- chỉ được đếm một lần trong mỗi bước nếu KPI là "số người".
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. NGUYÊN LÝ MA TRẬN COHORT RETENTION THEO THÁNG
-- ------------------------------------------------------------------------------
-- 💡 MỤC TIÊU: Trả lời câu hỏi sống còn của mọi công ty Product/E-commerce/SaaS:
-- "Khách hàng đăng ký/mua hàng lần đầu vào tháng X, sau 1 tháng, 2 tháng, 3 tháng... còn bao nhiêu % quay lại?"
--
-- ┌────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
-- │ Cohort Month   │ Size (M0)   │ Month 0 (%) │ Month 1 (%) │ Month 2 (%) │
-- ├────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
-- │ 2023-09        │ 100 users   │ 100%        │ 40%         │ 25%         │
-- │ 2023-10        │ 150 users   │ 100%        │ 45%         │ ...         │
-- └────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
--
-- 🔄 4 BƯỚC XÂY DỰNG TRONG SQL:
--   Bước 1: Tìm tháng mua hàng đầu tiên của từng khách hàng (`cohort_month = MIN(order_date)`).
--   Bước 2: Tìm tất cả các tháng phát sinh đơn hàng tiếp theo (`activity_month`).
--   Bước 3: Tính chỉ số khoảng cách tháng: `month_index = (Year_diff * 12) + Month_diff`.
--   Bước 4: Đếm số lượng Active Users và chia cho quy mô ban đầu (Cohort Size tại Month 0).

-- 💬 CÁCH ĐỌC TOÀN BỘ QUERY COHORT: `first_purchase` tạo 1 dòng/khách với tháng đầu;
-- `user_activities` tạo 1 dòng/đơn completed và gắn tháng cohort; `cohort_summary` gộp
-- thành 1 dòng/cohort/tháng hoạt động; `cohort_sizes` chỉ lấy nhóm mốc 0 làm mẫu số.
-- Query cuối JOIN mẫu số vào từng mốc để tính %. Tách nhỏ như vậy dễ kiểm tra từng bước.

WITH first_purchase AS (
    -- Bước 1: Xác định Cohort Month cho từng khách hàng
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
user_activities AS (
    -- Bước 2 & 3: Tính chỉ số khoảng cách tháng (month_index: 0, 1, 2, 3...)
    SELECT 
        o.customer_id,
        fp.cohort_month,
        DATE_TRUNC('month', o.order_date)::DATE AS activity_month,
        (EXTRACT(YEAR FROM o.order_date) - EXTRACT(YEAR FROM fp.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM fp.cohort_month)) AS month_index
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.order_status = 'Completed'
),
cohort_summary AS (
    -- Bước 4: Đếm số khách hàng hoạt động ở từng mốc
    SELECT 
        cohort_month,
        month_index,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM user_activities
    GROUP BY cohort_month, month_index
),
cohort_sizes AS (
    -- Lấy quy mô ban đầu tại Month 0
    SELECT 
        cohort_month, 
        active_customers AS cohort_initial_size
    FROM cohort_summary 
    WHERE month_index = 0
)
-- Kết quả cuối cùng: Ma trận Tỷ lệ giữ chân (Retention Rate %)
SELECT 
    cs.cohort_month,
    csz.cohort_initial_size,
    cs.month_index,
    cs.active_customers,
    ROUND((cs.active_customers * 100.0 / csz.cohort_initial_size), 2) AS retention_rate_pct
FROM cohort_summary cs
JOIN cohort_sizes csz ON cs.cohort_month = csz.cohort_month
ORDER BY cs.cohort_month, cs.month_index;


-- ------------------------------------------------------------------------------
-- 2. PHÂN TÍCH PHỄU CHUYỂN ĐỔI (SALES CONVERSION FUNNEL & DROP-OFF RATE)
-- ------------------------------------------------------------------------------
-- 💡 MỤC TIÊU: Xác định điểm rơi rớt người dùng nhiều nhất trên Website:
-- Luồng chuẩn: [Xem trang] ──> [Tìm kiếm] ──> [Thêm vào giỏ] ──> [Bắt đầu thanh toán] ──> [Mua hàng thành công]

-- 💬 CÁCH ĐỌC QUERY FUNNEL: `session_funnel` gộp nhiều event thành 1 dòng/session bằng cờ
-- 0/1; `aggregated_steps` cộng các cờ để có một dòng tổng; các SELECT UNION ALL chỉ trình bày
-- dòng tổng đó thành 5 nhãn. Mẫu số ở đây luôn là step1_views (chuyển đổi từ đầu phễu),
-- không phải tỷ lệ chuyển đổi giữa hai bước liên tiếp.

WITH session_funnel AS (
    SELECT 
        session_id,
        MAX(CASE WHEN event_type = 'page_view' THEN 1 ELSE 0 END) AS has_page_view,
        MAX(CASE WHEN event_type = 'search' THEN 1 ELSE 0 END) AS has_search,
        MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS has_add_to_cart,
        MAX(CASE WHEN event_type = 'checkout_start' THEN 1 ELSE 0 END) AS has_checkout,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM web_events
    GROUP BY session_id
),
aggregated_steps AS (
    SELECT 
        COUNT(*) AS total_sessions,
        SUM(has_page_view) AS step1_views,
        SUM(has_search) AS step2_searches,
        SUM(has_add_to_cart) AS step3_carts,
        SUM(has_checkout) AS step4_checkouts,
        SUM(has_purchase) AS step5_purchases
    FROM session_funnel
)
SELECT 
    '1. Xem Trang Chủ (Page View)' AS funnel_stage, step1_views AS user_sessions, 100.0 AS conversion_from_top_pct FROM aggregated_steps
UNION ALL
SELECT 
    '2. Tìm Kiếm Sản Phẩm (Search)', step2_searches, ROUND((step2_searches * 100.0 / NULLIF(step1_views, 0)), 2) FROM aggregated_steps
UNION ALL
SELECT 
    '3. Thêm Vào Giỏ (Add to Cart)', step3_carts, ROUND((step3_carts * 100.0 / NULLIF(step1_views, 0)), 2) FROM aggregated_steps
UNION ALL
SELECT 
    '4. Bắt Đầu Thanh Toán (Checkout)', step4_checkouts, ROUND((step4_checkouts * 100.0 / NULLIF(step1_views, 0)), 2) FROM aggregated_steps
UNION ALL
SELECT 
    '5. Đặt Hàng Thành Công (Purchase)', step5_purchases, ROUND((step5_purchases * 100.0 / NULLIF(step1_views, 0)), 2) FROM aggregated_steps;
