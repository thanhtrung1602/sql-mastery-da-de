-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 03: TABLE JOINS (KẾT HỢP BẢNG & QUAN HỆ DỮ LIỆU)
-- BÀI GIẢNG 01: BẢN CHẤT ĐẠI SỐ QUAN HỆ CỦA JOINS VÀ CẠM BẪY LỌC TRONG ON VS WHERE
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Bản chất toán học của phép Join (Tích Descartes $\times$ $\rightarrow$ Phép chọn $\sigma$).
--   2. Cơ chế thực thi của 3 giải thuật Join cốt lõi: Nested Loop, Hash Join, Merge Join.
--   3. Chi tiết: INNER JOIN, LEFT OUTER JOIN, RIGHT OUTER JOIN.
--   4. CẠM BẪY CHÍ TỬ KHI LỌC DỮ LIỆU: Đặt điều kiện trong mệnh đề `ON` vs mệnh đề `WHERE`.
--   5. Kỹ thuật kết hợp đa bảng (Multi-table Joins) trong mô hình E-commerce chuẩn.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Ghép thông tin ở nhiều bảng mà không mất hoặc nhân sai số dòng.
-- CÂU LỆNH: INNER JOIN (chỉ dòng khớp), LEFT JOIN (giữ hết bảng trái), RIGHT JOIN,
-- ON (quy tắc ghép), WHERE (lọc sau ghép).
-- ⭐ MỨC ĐỘ DÙNG: INNER JOIN và LEFT JOIN là RẤT THƯỜNG XUYÊN; RIGHT JOIN ít dùng.
-- 🧠 CẦN NHỚ: `ON` trả lời "hai dòng nào là một cặp"; `WHERE` trả lời "sau khi ghép,
-- cặp nào được giữ". Trước JOIN, phải biết một khóa có thể khớp bao nhiêu dòng.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CƠ CHẾ BÊN DƯỚI CỦA 3 GIẢI THUẬT JOIN TRONG DATABASE ENGINE
-- ------------------------------------------------------------------------------
-- Khi bạn viết lệnh JOIN, Query Planner sẽ phân tích chi phí và chọn 1 trong 3 thuật toán:
--
-- ┌────────────────┬────────────────────────────────────────────────────────────────────────┐
-- │ Thuật toán Join│ Cơ chế hoạt động & Trường hợp tối ưu                                   │
-- ├────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 1. Nested Loop │ Duyệt 2 vòng lặp lồng nhau $O(M \times N)$. Cực nhanh khi 1 bảng rất nhỏ│
-- │                │ và bảng kia có B-Tree Index trên khóa join.                            │
-- │ 2. Hash Join   │ Băm bảng nhỏ vào bộ nhớ RAM (Hash Table in Work_Mem), sau đó quét bảng │
-- │                │ lớn để tra cứu $O(M + N)$. Tối ưu cho bảng lớn với điều kiện bằng `=`.  │
-- │ 3. Merge Join  │ Sắp xếp 2 bảng theo khóa join rồi duyệt song song như 2 con trỏ.        │
-- │                │ Tối ưu khi dữ liệu đã được sort sẵn qua Index.                         │
-- └────────────────┴────────────────────────────────────────────────────────────────────────┘


-- ------------------------------------------------------------------------------
-- 2. INNER JOIN (GIAO NHAU GIỮA 2 BẢNG)
-- ------------------------------------------------------------------------------
-- Chỉ giữ lại các dòng có khóa khớp ở CẢ HAI BẢNG. Dòng nào không có cặp tương ứng sẽ bị loại bỏ hoàn toàn.

SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.unit_price
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id;


-- ------------------------------------------------------------------------------
-- 3. LEFT JOIN & RIGHT JOIN (BẢO TOÀN DỮ LIỆU BẢNG CHÍNH)
-- ------------------------------------------------------------------------------

-- 3.1 LEFT JOIN: Bảo toàn 100% dòng của bảng bên trái (customers).
-- Nếu khách hàng chưa có đơn hàng nào bên bảng phải (orders), toàn bộ cột của orders sẽ tự động điền `NULL`.
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city,
    o.order_id,
    o.order_date,
    o.order_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;

-- 3.2 RIGHT JOIN: Bảo toàn 100% dòng của bảng bên phải.
-- 💡 Best Practice trong ngành: 99% các kỹ sư ưu tiên viết lại RIGHT JOIN thành LEFT JOIN
-- để luồng tư duy và cấu trúc code luôn nhất quán từ trái sang phải (Left-to-Right reading flow).


-- ------------------------------------------------------------------------------
-- 4. CẠM BẪY CHÍ TỬ: ĐIỀU KIỆN TRONG "ON" VS ĐIỀU KIỆN TRONG "WHERE" TRONG LEFT JOIN
-- ------------------------------------------------------------------------------
-- Đây là lỗi sai phổ biến nhất của các Data Analyst khiến kết quả bị lệch hoàn toàn!

-- 🎯 BÀI TOÁN NGHIỆP VỤ:
-- "Lấy danh sách TẤT CẢ khách hàng kèm thông tin các đơn hàng đã hoàn tất (Completed) của họ.
-- Nếu khách hàng chưa từng mua hoặc chưa có đơn Completed, VẪN PHẢI HIỂN THỊ TÊN HỌ VÀ ĐIỀN NULL."

-- ❌ CÁCH VIẾT SAI (Đặt điều kiện lọc vào mệnh đề WHERE):
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id,
    o.order_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'; 
-- 🔍 TẠI SAO SAI?
-- Mệnh đề WHERE được thực thi SAU KHI LEFT JOIN hoàn tất (Bước 2 vs Bước 1).
-- Khi khách hàng chưa có đơn hàng, `o.order_status` sẽ là `NULL`.
-- Điều kiện `WHERE NULL = 'Completed'` trả về UNKNOWN -> TOÀN BỘ KHÁCH CHƯA CÓ ĐƠN BỊ XÓA SẠCH!
-- => Câu lệnh LEFT JOIN bị vô tình biến thành INNER JOIN mà bạn không hề hay biết!

-- ✅ CÁCH VIẾT ĐÚNG (Đặt điều kiện lọc vào mệnh đề ON):
SELECT 
    c.customer_id,
    c.first_name,
    o.order_id,
    o.order_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
                  AND o.order_status = 'Completed';
-- 🔍 TẠI SAO ĐÚNG?
-- Điều kiện trong `ON` được đánh giá TRONG QUÁ TRÌNH KẾT NỐI (Join-time Filter).
-- Nó chỉ lọc các đơn hàng của bảng `orders`, sau đó vẫn bảo toàn 100% dòng của bảng `customers` bên trái!


-- ------------------------------------------------------------------------------
-- 5. KẾT HỢP ĐA BẢNG (MULTI-TABLE JOINS)
-- ------------------------------------------------------------------------------
-- Báo cáo chi tiết luồng giá trị: Khách hàng -> Đơn hàng -> Chi tiết sản phẩm -> Danh mục

SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.city AS customer_city,
    cat.category_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS line_net_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE o.order_status = 'Completed'
ORDER BY o.order_id, oi.order_item_id;
