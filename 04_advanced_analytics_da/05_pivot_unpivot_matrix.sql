-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- BÀI GIẢNG 05: XOAY DỮ LIỆU DÒNG-CỘT (PIVOT) VÀ CỘT-DÒNG (UNPIVOT)
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Khái niệm Wide Format (Dạng rộng) vs Long Format (Dạng dài).
--   2. Kỹ thuật PIVOT (Dòng thành Cột) bằng Conditional Aggregation & Mệnh đề FILTER.
--   3. Kỹ thuật UNPIVOT (Cột thành Dòng) hiện đại nhất bằng CROSS JOIN LATERAL (VALUES ...).
--   4. Xây dựng Báo cáo Ma trận Đối chiếu Doanh thu 2 chiều.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Đổi dữ liệu "dài" (nhiều dòng) thành bảng ma trận để đọc báo cáo dễ hơn, rồi đổi lại.
-- CÂU LỆNH: CASE + aggregate hoặc FILTER (pivot tĩnh), crosstab (pivot PostgreSQL),
-- UNION ALL / CROSS JOIN LATERAL + VALUES (unpivot).
-- ⭐ MỨC ĐỘ DÙNG: CASE + aggregate thường xuyên; crosstab/LATERAL nâng cao và đặc thù PostgreSQL.
-- 🧠 CẦN NHỚ: Pivot thay đổi hình thức hiển thị, không thay đổi số liệu. Cột pivot phải được
-- biết trước ở pivot tĩnh; dữ liệu linh hoạt thường nên giữ dạng dài trong kho dữ liệu.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. SO SÁNH WIDE FORMAT VS LONG FORMAT TRONG PHÂN TÍCH DỮ LIỆU
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬────────────────────────────────────────────────────────┐
-- │ Định dạng       │ Đặc điểm & Ứng dụng                                    │
-- ├─────────────────┼────────────────────────────────────────────────────────┤
-- │ Long Format     │ Mỗi dòng là một quan sát riêng lẻ (Mô hình CSDL quan hệ│
-- │ (Dạng Dài)      │ chuẩn chuẩn hóa 3NF). Cực kỳ tối ưu cho tính toán SQL. │
-- ├─────────────────┼────────────────────────────────────────────────────────┤
-- │ Wide Format     │ Các danh mục được dàn thành các cột riêng biệt.        │
-- │ (Dạng Rộng)     │ Tối ưu cho Trình diễn Báo cáo Dashboard và Bảng tính.  │
-- └─────────────────┴────────────────────────────────────────────────────────┘


-- ------------------------------------------------------------------------------
-- 2. PIVOT (XOAY DÒNG THÀNH CỘT - LONG TO WIDE)
-- ------------------------------------------------------------------------------

-- 🎯 BÀI TOÁN: Xây dựng bảng ma trận doanh thu theo Từng Thành Phố (Dòng) x Phương thức thanh toán (Cột)

-- 2.1 Phương pháp chuẩn 100% ANSI SQL (Dùng CASE WHEN):
SELECT 
    shipping_city,
    SUM(CASE WHEN payment_method = 'Credit Card' THEN shipping_fee ELSE 0 END) AS fee_credit_card,
    SUM(CASE WHEN payment_method = 'Bank Transfer' THEN shipping_fee ELSE 0 END) AS fee_bank_transfer,
    SUM(CASE WHEN payment_method = 'E-Wallet' THEN shipping_fee ELSE 0 END) AS fee_e_wallet,
    SUM(CASE WHEN payment_method = 'COD' THEN shipping_fee ELSE 0 END) AS fee_cod,
    SUM(shipping_fee) AS total_shipping_fee
FROM orders
GROUP BY shipping_city
ORDER BY total_shipping_fee DESC;

-- 2.2 Phương pháp hiện đại trong PostgreSQL (Dùng FILTER):
SELECT 
    shipping_city,
    COALESCE(SUM(shipping_fee) FILTER (WHERE payment_method = 'Credit Card'), 0) AS fee_credit_card,
    COALESCE(SUM(shipping_fee) FILTER (WHERE payment_method = 'Bank Transfer'), 0) AS fee_bank_transfer,
    COALESCE(SUM(shipping_fee) FILTER (WHERE payment_method = 'E-Wallet'), 0) AS fee_e_wallet,
    COALESCE(SUM(shipping_fee) FILTER (WHERE payment_method = 'COD'), 0) AS fee_cod
FROM orders
GROUP BY shipping_city;


-- ------------------------------------------------------------------------------
-- 3. UNPIVOT (XOAY CỘT THÀNH DÒNG - WIDE TO LONG)
-- ------------------------------------------------------------------------------
-- 🎯 BÀI TOÁN: Bảng dữ liệu đầu vào đang ở dạng bảng tính Excel rộng (Wide format với các cột Q1, Q2, Q3, Q4).
-- Ta cần chuẩn hóa ngược lại thành từng dòng (Long format) để lưu vào Data Warehouse.

WITH wide_sales_report AS (
    SELECT 
        101 AS product_id, 'iPhone 15 Pro' AS product_name, 
        150000000 AS q1_sales, 180000000 AS q2_sales, 210000000 AS q3_sales, 250000000 AS q4_sales
    UNION ALL
    SELECT 
        103, 'MacBook Pro 14', 
        90000000, 110000000, 140000000, 190000000
)
-- 🌟 KỸ THUẬT UNPIVOT TỐI ƯU NHẤT: CROSS JOIN LATERAL (VALUES ...)
SELECT 
    w.product_id,
    w.product_name,
    v.quarter_name,
    v.revenue_amount
FROM wide_sales_report w
CROSS JOIN LATERAL (
    VALUES 
        ('Q1', w.q1_sales),
        ('Q2', w.q2_sales),
        ('Q3', w.q3_sales),
        ('Q4', w.q4_sales)
) AS v(quarter_name, revenue_amount)
ORDER BY w.product_id, v.quarter_name;
