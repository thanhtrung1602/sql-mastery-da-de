-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 03: TABLE JOINS
-- BÀI GIẢNG 04: CÁC MẪU THIẾT KẾ JOIN NÂNG CAO: NON-EQUI JOINS VÀ LATERAL JOINS
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Non-Equi Joins: Kỹ thuật kết nối không dùng dấu bằng `=` (Dải giá, Binned Tier, Khoảng thời gian).
--   2. Time-Window Joins: Khớp các sự kiện hành vi xảy ra trong khoảng thời gian nhất định.
--   3. LATERAL JOIN: "Vòng lặp For-Each" nguyên bản bên trong SQL Engine.
--   4. Ứng dụng đỉnh cao của Lateral Join: Lấy Top-N bản ghi cho mỗi nhóm trực tiếp trong FROM.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Ghép theo khoảng giá trị hoặc chạy một truy vấn phụ cho từng dòng bên trái.
-- CÂU LỆNH: non-equi JOIN (ON dùng <, >, BETWEEN), LATERAL (truy vấn phải nhìn được dòng trái),
-- generate_series (tạo dãy), LEFT JOIN LATERAL (vẫn giữ dòng không có kết quả con).
-- ⭐ MỨC ĐỘ DÙNG: JOIN theo `=` rất thường xuyên; LATERAL và non-equi JOIN là nâng cao.
-- 🧠 CẦN NHỚ: LATERAL có thể chạy lại cho từng dòng nên phải LIMIT và index hợp lý khi dữ liệu lớn.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. NON-EQUI JOINS (KẾT NỐI THEO KHOẢNG ĐIỀU KIỆN)
-- ------------------------------------------------------------------------------
-- Hầu hết các phép Join thông thường đều dùng toán tử bằng (`tableA.id = tableB.id`).
-- Tuy nhiên, trong phân tích dữ liệu thực tế, ta thường xuyên phải kết nối theo khoảng: `>`, `<`, `BETWEEN`.

-- 🎯 BÀI TOÁN 1: KHỚP SẢN PHẨM VÀO BẢNG CHÍNH SÁCH CHIẾT KHẤU THEO DẢI GIÁ
WITH discount_matrix AS (
    SELECT 'Tier Bronze' AS tier_name, 0.00 AS min_price, 10000000.00 AS max_price, 0.00 AS discount_rate
    UNION ALL
    SELECT 'Tier Silver', 10000000.01, 30000000.00, 0.05
    UNION ALL
    SELECT 'Tier Gold', 30000000.01, 999999999.00, 0.10
)
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    dm.tier_name,
    dm.discount_rate,
    ROUND(p.unit_price * (1 - dm.discount_rate), 0) AS gia_sau_chiet_khau
FROM products p
JOIN discount_matrix dm 
  ON p.unit_price BETWEEN dm.min_price AND dm.max_price;


-- ------------------------------------------------------------------------------
-- 2. TIME-WINDOW JOINS (KẾT NỐI THEO CỬA SỔ THỜI GIAN SỰ KIỆN)
-- ------------------------------------------------------------------------------
-- 🎯 BÀI TOÁN ATTRIBUTION MARKETING:
-- "Tìm các sự kiện xem trang web (page_view) xảy ra trong vòng 15 PHÚT TRƯỚC KHI đơn hàng được tạo."

SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    we.event_id,
    we.event_time,
    we.page_url,
    ROUND(EXTRACT(EPOCH FROM (o.order_date - we.event_time)) / 60, 1) AS minutes_before_order
FROM orders o
JOIN web_events we 
  ON o.customer_id = we.customer_id
 AND we.event_time BETWEEN (o.order_date - INTERVAL '15 minutes') AND o.order_date;


-- ------------------------------------------------------------------------------
-- 3. LATERAL JOIN (VÒNG LẶP FOR-EACH BÊN TRONG SQL)
-- ------------------------------------------------------------------------------
-- 💡 NGUYÊN LÝ HOẠT ĐỘNG:
-- Thông thường, một Subquery bên trong mệnh đề `FROM` là độc lập hoàn toàn, không thể "nhìn thấy"
-- các cột của bảng đứng trước nó.
--
-- Từ khóa `LATERAL` phá vỡ giới hạn này! Nó cho phép Subquery bên trong tham chiếu trực tiếp
-- đến các cột của dòng hiện tại từ bảng đứng trước, hoạt động giống như một vòng lặp `for-each row`.

-- 🎯 BÀI TOÁN ĐỈNH CAO: "Với MỖI khách hàng, lấy đúng 2 đơn hàng có giá trị cao nhất của riêng họ":
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    top_orders.order_id,
    top_orders.order_date,
    top_orders.total_order_value
FROM customers c
CROSS JOIN LATERAL (
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS total_order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = c.customer_id -- Tham chiếu ngược lại cột `c.customer_id` từ bảng bên ngoài!
    GROUP BY o.order_id, o.order_date
    ORDER BY total_order_value DESC
    LIMIT 2                             -- Lấy đúng Top 2 cho từng khách hàng
) top_orders;

-- 3.2 LEFT JOIN LATERAL (Bảo toàn khách hàng chưa mua hàng):
SELECT 
    c.customer_id,
    c.first_name,
    latest.order_id,
    latest.order_date
FROM customers c
LEFT JOIN LATERAL (
    SELECT o.order_id, o.order_date
    FROM orders o
    WHERE o.customer_id = c.customer_id
    ORDER BY o.order_date DESC
    LIMIT 1
) latest ON TRUE;
