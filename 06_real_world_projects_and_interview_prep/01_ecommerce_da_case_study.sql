-- ==============================================================================
-- FOLDER 06: REAL-WORLD PROJECTS & INTERVIEW PREPARATION
-- FILE: 01_ecommerce_da_case_study.sql
-- MỤC TIÊU:
--   Dự án phân tích kinh doanh thực chiến tổng hợp dành cho Senior Data Analyst.
--   Giải quyết 7 bài toán kinh doanh chiến lược thực tế trên dữ liệu E-commerce.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH ĐỌC CASE STUDY: Mỗi phần trả lời một câu hỏi kinh doanh khác nhau. Trước khi
-- chạy, hãy xác định "một dòng kết quả là tháng/cặp sản phẩm/sản phẩm/khách hàng". Sau đó
-- mới đọc JOIN, WHERE, GROUP BY, Window Function và công thức KPI theo thứ tự đó.
-- ⭐ KỸ NĂNG DÙNG RẤT NHIỀU: JOIN, GROUP BY, COUNT DISTINCT, SUM, CTE, CASE, WINDOW.
-- 🧠 CẦN NHỚ: order_items là một dòng hàng, không phải một đơn. Muốn đếm đơn phải
-- COUNT(DISTINCT o.order_id) hoặc gom về một dòng/đơn trước.
-- ==============================================================================

-- ==============================================================================
-- BÀI TOÁN 1: DOANH THU THUẦN, SỐ ĐƠN VÀ GIÁ TRỊ ĐƠN HÀNG TRUNG BÌNH (AOV) THEO THÁNG
-- ==============================================================================
-- Insight mong muốn: Đo lường tốc độ tăng trưởng quy mô doanh thu và sự thay đổi trong thói quen chi tiêu của người dùng.

-- 💬 CÁCH ĐỌC: JOIN biến một đơn thành nhiều dòng hàng (order_items). Vì vậy COUNT phải dùng
-- DISTINCT o.order_id để mỗi đơn chỉ tính một lần. SUM công thức dòng hàng tạo doanh thu thuần;
-- DATE_TRUNC + GROUP BY biến kết quả thành một dòng/tháng. NULLIF bảo vệ phép tính AOV.

SELECT 
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_completed_orders,
    COUNT(DISTINCT o.customer_id) AS unique_purchasers,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS net_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) / NULLIF(COUNT(DISTINCT o.order_id), 0), 
        0
    ) AS average_order_value_aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)::DATE
ORDER BY sales_month ASC;

-- ==============================================================================
-- BÀI TOÁN 2: PHÂN TÍCH GIỎ HÀNG (MARKET BASKET ANALYSIS - CROSS-SELLING)
-- ==============================================================================
-- Yêu cầu: Tìm các cặp sản phẩm thường xuyên được mua cùng nhau trong cùng một đơn hàng.
-- Ứng dụng: Gợi ý sản phẩm kèm theo (Frequently Bought Together) trên trang checkout.

-- 💬 CÁCH ĐỌC: oi1 và oi2 là hai "vai" khác nhau của cùng bảng order_items. Điều kiện cùng
-- order_id giữ cặp trong một giỏ; `oi1.product_id < oi2.product_id` vừa loại cặp chính nó,
-- vừa chỉ giữ một cách viết A–B thay vì tính cả A–B và B–A. Một dòng kết quả là một cặp sản phẩm.

SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 
  ON oi1.order_id = oi2.order_id 
 AND oi1.product_id < oi2.product_id -- Tránh cặp trùng lặp (A, B) và (B, A) và tự kết nối (A, A)
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN orders o ON oi1.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 5;

-- ==============================================================================
-- BÀI TOÁN 3: PHÂN LOẠI HÀNG TỒN KHO THEO NGUYÊN LÝ ABC (PARETO 80/20)
-- ==============================================================================
-- Quy tắc ABC Inventory:
--   - Hạng A: Nhóm sản phẩm chiếm 70% - 80% tổng doanh thu (Cần kiểm soát tồn kho chặt chẽ nhất).
--   - Hạng B: Nhóm sản phẩm chiếm 15% - 20% doanh thu kế tiếp.
--   - Hạng C: Nhóm sản phẩm chiếm 5% - 10% doanh thu còn lại (Ít quan trọng nhất).

-- 💬 CÁCH ĐỌC: product_revenue là 1 dòng/sản phẩm. cumulative_revenue vẫn là 1 dòng/sản phẩm
-- nhưng SUM OVER tính tổng lũy kế theo doanh thu giảm dần, không làm gộp dòng. SELECT cuối so
-- tỷ lệ lũy kế với ngưỡng 70/90 để gán nhãn. Các ngưỡng này là quy ước business, có thể đổi.

WITH product_revenue AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_rev
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name
),
cumulative_revenue AS (
    SELECT 
        product_id,
        product_name,
        total_rev,
        SUM(total_rev) OVER (ORDER BY total_rev DESC) AS running_total_revenue,
        SUM(total_rev) OVER () AS grand_total_revenue
    FROM product_revenue
)
SELECT 
    product_id,
    product_name,
    total_rev,
    ROUND((running_total_revenue * 100.0 / grand_total_revenue), 2) AS cumulative_revenue_pct,
    CASE 
        WHEN (running_total_revenue * 100.0 / grand_total_revenue) <= 70 THEN 'Class A (Critical SKU)'
        WHEN (running_total_revenue * 100.0 / grand_total_revenue) <= 90 THEN 'Class B (Moderate SKU)'
        ELSE 'Class C (Low Impact SKU)'
    END AS abc_inventory_class
FROM cumulative_revenue
ORDER BY total_rev DESC;

-- ==============================================================================
-- BÀI TOÁN 4: XÁC ĐỊNH KHÁCH HÀNG CÓ NGUY CƠ RỜI BỎ (CHURN RISK IDENTIFICATION)
-- ==============================================================================
-- Tiêu chí: Khách hàng từng mua hàng ít nhất 2 lần nhưng đã hơn 60 ngày không phát sinh đơn mới.

-- 💬 CÁCH ĐỌC: customer_order_summary là 1 dòng/khách đã có đơn Completed. COUNT và MAX
-- được tính trước trong CTE; WHERE ngoài CTE mới lọc theo hai số liệu tổng hợp. Không thể viết
-- `WHERE COUNT(...) >= 2` ngay trong truy vấn trong vì WHERE chạy trước bước GROUP BY.

WITH customer_order_summary AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        COUNT(o.order_id) AS total_orders,
        MAX(o.order_date) AS last_order_date,
        ('2024-03-01'::DATE - MAX(o.order_date)::DATE) AS days_since_last_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
)
SELECT 
    customer_id,
    customer_name,
    email,
    total_orders,
    last_order_date,
    days_since_last_order,
    'High Risk of Churn - Send Reactivation Promo Code' AS marketing_action
FROM customer_order_summary
WHERE total_orders >= 2 
  AND days_since_last_order > 60
ORDER BY days_since_last_order DESC;
