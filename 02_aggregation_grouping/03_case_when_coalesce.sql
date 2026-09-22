-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 02: AGGREGATION & GROUPING
-- BÀI GIẢNG 03: LOGIC ĐIỀU KIỆN CASE WHEN, CONDITIONAL AGGREGATION VÀ MỆNH ĐỀ FILTER
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Cơ chế hoạt động của CASE WHEN (Short-circuit Evaluation & Type Consistency).
--   2. Conditional Aggregation (Kỹ thuật tính tổng có điều kiện để xoay dữ liệu).
--   3. Mệnh đề FILTER (WHERE ...) trong chuẩn ANSI SQL & PostgreSQL hiện đại.
--   4. Bộ tứ xử lý NULL & Giới hạn: COALESCE, NULLIF, GREATEST, LEAST.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Đặt nhãn/giá trị thay thế theo điều kiện mà không phải sửa dữ liệu gốc.
-- CÂU LỆNH: CASE WHEN (nếu/thì), COALESCE (lấy giá trị khác NULL đầu tiên), NULLIF
-- (đổi giá trị đặc biệt thành NULL), FILTER (lọc riêng cho một hàm tổng hợp), GREATEST/LEAST.
-- ⭐ MỨC ĐỘ DÙNG: CASE, COALESCE rất thường xuyên; FILTER là PostgreSQL nâng cao.
-- 🧠 CẦN NHỚ: CASE đọc từ trên xuống, gặp WHEN đúng đầu tiên thì dừng. COALESCE không
-- phân biệt "0" với NULL: chỉ thay thế khi giá trị thật sự NULL.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BIỂU THỨC ĐIỀU KIỆN CASE WHEN (IF-ELSE TRONG SQL)
-- ------------------------------------------------------------------------------
-- CƠ CHẾ ĐÁNH GIÁ (SHORT-CIRCUIT EVALUATION):
-- Database duyệt qua các nhánh `WHEN` từ trên xuống dưới.
-- Ngay khi gặp nhánh đầu tiên thỏa mãn `TRUE`, nó sẽ trả về kết quả tương ứng và DỪNG LẠI,
-- KHÔNG ĐÁNH GIÁ các nhánh `WHEN` còn lại phía dưới.
-- Nếu không có nhánh nào thỏa mãn, nó sẽ trả về giá trị ở nhánh `ELSE` (nếu thiếu ELSE -> trả về NULL).

-- 1.1 Phân loại dải giá sản phẩm (Binned Price Tiers):
SELECT 
    product_id,
    product_name,
    unit_price,
    CASE 
        WHEN unit_price >= 30000000 THEN 'Premium Flagship'
        WHEN unit_price >= 10000000 THEN 'Mid-High Tier'
        WHEN unit_price >= 5000000  THEN 'Budget-Mid Tier'
        ELSE 'Entry Level'
    END AS price_tier
FROM products;

-- 💡 LƯU Ý VỀ TÍNH NHẤT QUÁN KIỂU DỮ LIỆU (TYPE CONSISTENCY):
-- Tất cả các giá trị trả về sau `THEN` và `ELSE` BẮT BUỘC phải cùng một kiểu dữ liệu
-- (hoặc có thể tự động ép kiểu về cùng một kiểu chung).


-- ------------------------------------------------------------------------------
-- 2. CONDITIONAL AGGREGATION (TỔNG HỢP CÓ ĐIỀU KIỆN)
-- ------------------------------------------------------------------------------
-- Đây là kỹ thuật cốt lõi để tính toán các tỷ lệ chuyển đổi, tỷ lệ hoàn tất đơn hàng
-- mà chỉ cần quét qua bảng đúng 1 lần duy nhất (Single Table Scan)!

-- 2.1 Kỹ thuật truyền thống: Kết hợp SUM/COUNT với CASE WHEN
SELECT 
    shipping_city,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) AS completed_orders,
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) AS cancelled_orders,
    ROUND(
        COUNT(CASE WHEN order_status = 'Completed' THEN 1 END) * 100.0 / NULLIF(COUNT(order_id), 0), 
        2
    ) AS completion_rate_pct
FROM orders
GROUP BY shipping_city;


-- ------------------------------------------------------------------------------
-- 3. MỆNH ĐỀ FILTER (WHERE ...) - CHUẨN ANSI SQL HIỆN ĐẠI
-- ------------------------------------------------------------------------------
-- 🌟 TẠI SAO FILTER (WHERE ...) VƯỢT TRỘI HƠN CASE WHEN?
--   1. Cú pháp trong sáng, trực quan, đúng bản chất lọc dữ liệu cho hàm tổng hợp.
--   2. Query Planner của PostgreSQL tối ưu hiệu năng tốt hơn đáng kể trên bảng dữ liệu lớn.

SELECT 
    shipping_city,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_status = 'Completed') AS completed_orders,
    COUNT(*) FILTER (WHERE order_status = 'Cancelled') AS cancelled_orders,
    SUM(shipping_fee) FILTER (WHERE payment_method = 'Credit Card') AS credit_card_shipping_total
FROM orders
GROUP BY shipping_city;


-- ------------------------------------------------------------------------------
-- 4. BỘ TỨ XỬ LÝ NULL VÀ GIÁ TRỊ GIỚI HẠN
-- ------------------------------------------------------------------------------

-- 4.1 COALESCE(val1, val2, ...): Trả về giá trị đầu tiên KHÁC NULL trong danh sách
SELECT 
    employee_id,
    first_name,
    COALESCE(manager_id, 0) AS manager_or_zero,
    COALESCE(department, 'Chưa phân bổ') AS safe_department
FROM employees;

-- 4.2 NULLIF(val1, val2): Trả về NULL nếu val1 = val2, ngược lại trả về val1
-- 🛡️ VŨ KHÍ CHỐNG LỖI CHIA CHO 0 (DIVISION BY ZERO):
-- Trong mọi công thức tính phần trăm, luôn bọc mẫu số vào `NULLIF(mau_so, 0)`:
SELECT 
    100 / NULLIF(0, 0) AS safe_division_result; -- Trả về NULL thay vì làm sập (Crash) toàn bộ truy vấn!

-- 4.3 GREATEST & LEAST: Lấy giá trị lớn nhất / nhỏ nhất theo từng dòng (Row-level Comparison)
SELECT 
    product_id,
    product_name,
    cost_price,
    unit_price,
    GREATEST(cost_price, unit_price) AS gia_cao_hon,
    LEAST(cost_price, unit_price) AS gia_thap_hon
FROM products;
