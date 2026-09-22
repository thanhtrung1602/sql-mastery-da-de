-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST (PHÂN TÍCH NÂNG CAO)
-- BÀI GIẢNG 01: TRUY VẤN CON (SUBQUERIES), CTE (MỆNH ĐỀ WITH) VÀ CTE ĐỆ QUY (RECURSIVE)
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Phân loại 3 dạng Subquery: Scalar Subquery, Multi-row Subquery, Correlated Subquery.
--   2. Common Table Expressions (CTE với mệnh đề WITH): Clean Code & Modularity.
--   3. Cơ chế tối ưu của CTE trong PostgreSQL 12+ (Inlining vs Materialization).
--   4. CTE ĐỆ QUY (WITH RECURSIVE): Xử lý dữ liệu phân cấp hình cây (Org Chart, Bảng quan hệ cha con).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Chia một câu hỏi lớn thành các bước có tên, dễ kiểm tra và tái sử dụng.
-- CÂU LỆNH: subquery (truy vấn trong truy vấn), WITH ... AS (...) / CTE (bảng tạm trong
-- một câu SQL), WITH RECURSIVE (lặp theo cây), EXISTS (kiểm tra có dòng liên quan).
-- ⭐ MỨC ĐỘ DÙNG: CTE và subquery rất thường xuyên; recursive CTE là nâng cao.
-- 🧠 CẦN NHỚ: CTE chỉ tồn tại trong đúng câu lệnh sau WITH; không tạo bảng thật. Hãy đặt
-- tên CTE theo ý nghĩa của dữ liệu nó tạo ra, và chạy từng CTE riêng để kiểm tra.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PHÂN LOẠI CÁC DẠNG TRUY VẤN CON (SUBQUERIES)
-- ------------------------------------------------------------------------------

-- 1.1 Scalar Subquery (Truy vấn con vô hướng): Trả về ĐÚNG 1 DÒNG VÀ 1 CỘT duy nhất.
-- Có thể đặt ở bất kỳ nơi nào chấp nhận một giá trị đơn (SELECT, WHERE, HAVING).
SELECT 
    product_id,
    product_name,
    unit_price,
    ROUND((SELECT AVG(unit_price) FROM products), 2) AS overall_avg_price,
    ROUND(unit_price - (SELECT AVG(unit_price) FROM products), 2) AS diff_from_market_avg
FROM products;

-- 1.2 Correlated Subquery (Truy vấn con tương quan):
-- Subquery phụ thuộc vào từng dòng của truy vấn cha bên ngoài (Chạy lặp $N$ lần).
-- 🎯 BÀI TOÁN: Tìm các sản phẩm có giá CAO HƠN GIÁ TRUNG BÌNH CỦA CHÍNH DANH MỤC ĐÓ:
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    p.unit_price
FROM products p
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id -- Tham chiếu ngược về bảng p bên ngoài
);


-- ------------------------------------------------------------------------------
-- 2. COMMON TABLE EXPRESSIONS (CTE VỚI MỆNH ĐỀ WITH)
-- ------------------------------------------------------------------------------
-- CTE cho phép bạn định nghĩa các bảng tạm logic đặt tên được, giúp chia nhỏ bài toán phức tạp
-- thành các bước tư duy tuần tự, dễ đọc và dễ gỡ lỗi (Debugging).

-- 🎯 BÀI TOÁN KINH DOANH:
-- "Tìm Top 3 khách hàng chi tiêu nhiều nhất và tính tỷ lệ % đóng góp của họ trên tổng doanh thu toàn công ty."

WITH customer_spending AS (
    -- Bước 1: Tính tổng chi tiêu của từng khách hàng
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.customer_id
),
revenue_summary AS (
    -- Bước 2: Tính tổng doanh thu toàn bộ hệ thống
    SELECT SUM(total_spent) AS grand_total_revenue 
    FROM customer_spending
)
-- Bước 3: Ghép nối và tính tỷ lệ phần trăm đóng góp
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    cs.total_spent,
    rs.grand_total_revenue,
    ROUND((cs.total_spent * 100.0 / rs.grand_total_revenue), 2) AS contribution_pct
FROM customer_spending cs
CROSS JOIN revenue_summary rs
JOIN customers c ON cs.customer_id = c.customer_id
ORDER BY cs.total_spent DESC
LIMIT 3;


-- ------------------------------------------------------------------------------
-- 3. CTE ĐỆ QUY (WITH RECURSIVE) - DUYỆT CÂY PHÂN CẤP TỔ CHỨC
-- ------------------------------------------------------------------------------
-- 💡 CƠ CHẾ HOẠT ĐỘNG CỦA WITH RECURSIVE:
--   ┌──────────────────────────────────────────────────────────┐
--   │ Bước 1: Anchor Member (Phần neo)                         │ ──> Lấy phần tử gốc (CEO: Level 1)
--   ├──────────────────────────────────────────────────────────┤
--   │ Bước 2: UNION ALL                                        │
--   ├──────────────────────────────────────────────────────────┤
--   │ Bước 3: Recursive Member (Phần đệ quy)                   │ ──> Tìm nhân viên cấp dưới của dòng vừa lấy
--   │        Lặp lại cho đến khi tập kết quả trả về RỖNG!      │
--   └──────────────────────────────────────────────────────────┘

WITH RECURSIVE employee_hierarchy AS (
    -- 1. ANCHOR MEMBER: Cấp cao nhất (CEO / Lãnh đạo có manager_id IS NULL)
    SELECT 
        employee_id,
        first_name || ' ' || last_name AS full_name,
        manager_id,
        department,
        1 AS org_level,
        CAST(first_name || ' ' || last_name AS TEXT) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 2. RECURSIVE MEMBER: Tìm tất cả nhân viên báo cáo trực tiếp cho cấp trên ở bước trước
    SELECT 
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.manager_id,
        e.department,
        eh.org_level + 1,
        eh.reporting_path || ' -> ' || (e.first_name || ' ' || e.last_name)
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    REPEAT('   ', org_level - 1) || full_name AS indented_tree, -- Thụt đầu dòng trực quan theo cấp bậc
    department,
    org_level,
    reporting_path
FROM employee_hierarchy
ORDER BY reporting_path;
