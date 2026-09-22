-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- BÀI GIẢNG 02: HÀM CỬA SỔ XẾP HẠNG (WINDOW RANKING FUNCTIONS) & TOP-N PER GROUP
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Bản chất của Window Function: Khác biệt cốt tử so với GROUP BY thông thường.
--   2. Cấu trúc ngữ pháp tổng quát: `HÀM() OVER (PARTITION BY ... ORDER BY ...)`.
--   3. So sánh chi tiết 3 hàm xếp hạng: ROW_NUMBER(), RANK(), DENSE_RANK().
--   4. Phân chia tập dữ liệu thành N nhóm đều nhau với NTILE(N).
--   5. Bài toán kinh điển số 1 trong mọi buổi phỏng vấn DA: "Top-N bản ghi cho mỗi nhóm" (Top-N per Group).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: So sánh mỗi dòng với các dòng liên quan nhưng không gộp chúng thành một dòng.
-- CÂU LỆNH: `... OVER (...)` (biến hàm thành window function), PARTITION BY (chia nhóm
-- để tính riêng), ORDER BY trong OVER (thứ tự tính), ROW_NUMBER/RANK/DENSE_RANK/NTILE.
-- ⭐ MỨC ĐỘ DÙNG: ROW_NUMBER và RANK rất thường xuyên trong phân tích; NTILE thỉnh thoảng.
-- 🧠 CẦN NHỚ: GROUP BY làm nhiều dòng thành một; window function vẫn giữ nguyên số dòng.
-- `ORDER BY` trong OVER dùng để tính, còn ORDER BY cuối câu dùng để hiển thị.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢN CHẤT CỦA WINDOW FUNCTION (HÀM CỬA SỔ)
-- ------------------------------------------------------------------------------
-- ┌──────────────────────┬────────────────────────────────────────────────────────────┐
-- │ Tính năng            │ GROUP BY vs WINDOW FUNCTION                                │
-- ├──────────────────────┼────────────────────────────────────────────────────────────┤
-- │ GROUP BY             │ Nén nhiều dòng thành 1 DÒNG DUY NHẤT (Mất thông tin chi tiết).│
-- │ WINDOW FUNCTION      │ TÍNH TOÁN TRÊN TẬP DÒNG NHƯNG BẢO TOÀN 100% CÁC DÒNG RIÊNG LẺ.│
-- └──────────────────────┴────────────────────────────────────────────────────────────┘
--
--   Bảng ban đầu: 5 dòng ──(GROUP BY)──────> Còn 2 dòng tổng
--   Bảng ban đầu: 5 dòng ──(OVER PARTITION)─> VẪN ĐỦ 5 DÒNG (Kèm cột giá trị tính toán!)


-- ------------------------------------------------------------------------------
-- 2. SO SÁNH TRỰC QUAN: ROW_NUMBER(), RANK(), DENSE_RANK()
-- ------------------------------------------------------------------------------
-- Giả sử có danh sách nhân viên với mức lương: [100tr, 75tr, 75tr, 45tr]
-- ┌─────────┬──────────────┬────────────┬──────────────────┐
-- │ Lương   │ ROW_NUMBER() │ RANK()     │ DENSE_RANK()     │
-- ├─────────┼──────────────┼────────────┼──────────────────┤
-- │ 100tr   │ 1            │ 1          │ 1                │
-- │ 75tr    │ 2            │ 2 (Trùng)  │ 2 (Trùng)        │
-- │ 75tr    │ 3            │ 2 (Trùng)  │ 2 (Trùng)        │
-- │ 45tr    │ 4            │ 4 (NHẢY SỐ)│ 3 (LIÊN TỤC)     │
-- └─────────┴──────────────┴────────────┴──────────────────┘

SELECT 
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS row_num,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_num,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dense_rank_num
FROM employees;


-- ------------------------------------------------------------------------------
-- 3. PHÂN VỊ TẬP DỮ LIỆU VỚI NTILE(N)
-- ------------------------------------------------------------------------------
-- Chia tập dữ liệu thành $N$ phần bằng nhau.
-- Thường dùng để chia nhóm khách hàng theo phân vị (Quartiles: 4 nhóm, Deciles: 10 nhóm).

SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    signup_date,
    NTILE(4) OVER (ORDER BY signup_date ASC) AS customer_vintage_quartile -- Nhóm 1: Lâu năm nhất -> Nhóm 4: Mới nhất
FROM customers;


-- ------------------------------------------------------------------------------
-- 4. BÀI TOÁN TOP-N PER GROUP (TOP N SẢN PHẨM BÁN CHẠY NHẤT MỖI DANH MỤC)
-- ------------------------------------------------------------------------------
-- 🎯 YÊU CẦU: Tìm đúng 2 sản phẩm có doanh thu cao nhất cho TỪNG DANH MỤC SẢN PHẨM.

WITH product_sales AS (
    -- Bước 1: Tính tổng doanh thu theo từng sản phẩm và danh mục
    SELECT 
        c.category_name,
        p.product_name,
        p.product_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_name, p.product_name, p.product_id
),
ranked_products AS (
    -- Bước 2: Đánh số thứ tự xếp hạng doanh thu trong từng danh mục
    SELECT 
        category_name,
        product_name,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name 
            ORDER BY total_revenue DESC
        ) AS category_sales_rank
    FROM product_sales
)
-- Bước 3: Lọc lấy Top 2
SELECT 
    category_name,
    category_sales_rank,
    product_name,
    total_revenue
FROM ranked_products
WHERE category_sales_rank <= 2
ORDER BY category_name, category_sales_rank;
