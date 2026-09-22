-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 01: FOUNDATION QUERYING
-- BÀI GIẢNG 02: BẢN CHẤT MỆNH ĐỀ WHERE, LOGIC 3 GIÁ TRỊ VÀ TÌM KIẾM MẪU
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Vai trò của mệnh đề WHERE trong Relational Algebra (Phép chọn - Selection $\sigma$).
--   2. Độ ưu tiên của các toán tử Logic (Operator Precedence) & Cạm bẫy AND / OR.
--   3. Toán tử tập hợp & khoảng: IN, NOT IN, BETWEEN.
--   4. Tìm kiếm chuỗi nâng cao: LIKE, ILIKE, và Biểu thức chính quy (POSIX Regex).
--   5. BẢN CHẤT LOGIC 3 GIÁ TRỊ (Three-Valued Logic) & Cạm bẫy chí tử với giá trị NULL.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Biết giữ lại đúng những dòng thỏa điều kiện mà không làm sai logic.
-- CÂU LỆNH CỐT LÕI: WHERE (lọc dòng), AND/OR/NOT (ghép điều kiện), IN/BETWEEN
-- (viết gọn nhiều điều kiện), LIKE (tìm mẫu), IS NULL (kiểm tra dữ liệu thiếu).
-- ⭐ MỨC ĐỘ DÙNG: WHERE, AND/OR, IN, IS NULL là RẤT THƯỜNG XUYÊN; Regex là nâng cao.
-- 🧠 CẦN NHỚ: WHERE chỉ giữ TRUE; FALSE và UNKNOWN đều bị bỏ. Luôn dùng ngoặc khi
-- trộn AND với OR và chỉ dùng `IS NULL`, không dùng `= NULL`.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢN CHẤT CỦA MỆNH ĐỀ WHERE (SELECTION OPERATOR $\sigma$)
-- ------------------------------------------------------------------------------
-- Trong Đại số Quan hệ, mệnh đề WHERE đóng vai trò là toán tử Chọn ($\sigma$).
-- Nó duyệt qua từng bộ dòng (Row/Tuple) từ bảng nguồn và đánh giá một Biểu thức Boolean (Predicate).
-- CHỈ NHỮNG DÒNG NÀO CÓ BIỂU THỨC TRẢ VỀ `TRUE` THÌ MỚI ĐƯỢC GIỮ LẠI TRONG TẬP KẾT QUẢ.
-- Những dòng trả về `FALSE` hoặc `UNKNOWN (NULL)` đều bị LOẠI BỎ.


-- ------------------------------------------------------------------------------
-- 2. ĐỘ ƯU TIÊN TOÁN TỬ LOGIC (OPERATOR PRECEDENCE) & CẠM BẪY AND / OR
-- ------------------------------------------------------------------------------
-- Thứ tự ưu tiên mặc định trong SQL:
--   1. Dấu ngoặc đơn `()` (Ưu tiên cao nhất)
--   2. Các phép so sánh: `=`, `<>`, `<`, `>`, `<=`, `>=`, `LIKE`, `IN`, `BETWEEN`
--   3. Toán tử phủ định `NOT`
--   4. Toán tử kết hợp `AND` (ƯU TIÊN CAO HƠN OR)
--   5. Toán tử lựa chọn `OR` (Ưu tiên thấp nhất)

-- 🎯 BÀI TOÁN NGHIỆP VỤ: 
-- "Tìm tất cả khách hàng ở Việt Nam mà đang sinh sống tại TP. Hồ Chí Minh hoặc Hà Nội."

-- ❌ CÁCH VIẾT SAI (Không dùng ngoặc đơn -> AND nuốt mất điều kiện đầu):
SELECT customer_id, first_name, city, country
FROM customers
WHERE country = 'Vietnam' AND city = 'Ho Chi Minh' OR city = 'Hanoi';
-- 💬 Mỗi phép `=` tạo ra TRUE/FALSE/UNKNOWN trên từng khách. Không có ngoặc nên
-- database ghép `country ... AND city ...` trước, rồi mới OR với điều kiện Hà Nội.

-- 🔍 PHÂN TÍCH LỖI SAI:
-- Do AND ưu tiên hơn OR, Database hiểu câu lệnh thành:
-- `(country = 'Vietnam' AND city = 'Ho Chi Minh') OR (city = 'Hanoi')`
-- Hậu quả: Nếu có một người ở 'Hanoi' thuộc quốc gia 'Mỹ' hay bất kỳ đâu, họ vẫn bị lấy ra!

-- ✅ CÁCH VIẾT ĐÚNG (Dùng ngoặc đơn kiểm soát logic):
SELECT customer_id, first_name, city, country
FROM customers
WHERE country = 'Vietnam' 
  AND (city = 'Ho Chi Minh' OR city = 'Hanoi');
-- 💡 TẠI SAO đúng: ngoặc tạo một "nhóm lựa chọn thành phố". Chỉ người vừa ở Việt Nam
-- vừa thuộc một trong hai thành phố mới qua được WHERE.


-- ------------------------------------------------------------------------------
-- 3. TOÁN TỬ DANH SÁCH (IN / NOT IN) VÀ KHOẢNG GIÁ TRỊ (BETWEEN)
-- ------------------------------------------------------------------------------

-- 3.1 Toán tử IN: Tương đương với chuỗi nhiều phép so sánh `OR`
SELECT product_id, product_name, category_id, unit_price
FROM products
WHERE category_id IN (2, 3, 4); -- Lấy sản phẩm thuộc danh mục Điện thoại, Laptop, Phụ kiện
-- 💬 IN (2, 3, 4) đọc là "category_id bằng 2 HOẶC 3 HOẶC 4". Dùng IN giúp ít lặp hơn OR.

-- 3.2 Toán tử BETWEEN ... AND ... (BAO GỒM CẢ 2 ĐẦU MÚT [Inclusive])
SELECT product_id, product_name, unit_price
FROM products
WHERE unit_price BETWEEN 5000000 AND 30000000;
-- Tương đương: unit_price >= 5000000 AND unit_price <= 30000000
-- ⚠️ BETWEEN CÓ gồm cả hai đầu mút. Với thời điểm, ưu tiên khoảng nửa mở
-- `>= '2024-01-01' AND < '2024-02-01'` để không bỏ sót phần giờ trong ngày cuối.


-- ------------------------------------------------------------------------------
-- 4. TÌM KIẾM MẪU CHUỖI: LIKE, ILIKE VÀ POSIX REGEX
-- ------------------------------------------------------------------------------

-- 4.1 LIKE (Case-sensitive - Phân biệt hoa thường)
--   `%` : Đại diện cho 0 hoặc nhiều ký tự bất kỳ.
--   `_` : Đại diện cho đúng 1 ký tự bất kỳ.
SELECT product_id, product_name
FROM products
WHERE product_name LIKE 'iPhone%'; -- Bắt đầu bằng 'iPhone'
-- 💬 `%` là "bất kỳ chuỗi ký tự nào, kể cả rỗng". LIKE không hiểu đó là tìm gần đúng;
-- nó chỉ so khớp mẫu theo vị trí. `iPhone%` không tìm "iPhone" nằm giữa tên.

-- 4.2 ILIKE (Case-insensitive - Không phân biệt hoa thường, chuẩn PostgreSQL)
SELECT product_id, product_name
FROM products
WHERE product_name ILIKE '%pro%'; -- Chứa 'pro', 'Pro', 'PRO'

-- 4.3 POSIX REGULAR EXPRESSIONS (Toán tử Regex cực mạnh trong PostgreSQL)
--   `~`   : Khớp Regex (Phân biệt hoa thường)
--   `~*`  : Khớp Regex (Không phân biệt hoa thường)
--   `!~`  : Không khớp Regex
SELECT customer_id, first_name, email
FROM customers
WHERE email ~* '^[a-z0-9._%+-]+@(example|global)\.com$'; -- Validate định dạng email thuộc domain chỉ định
-- 📌 Regex hữu ích cho kiểm tra mẫu phức tạp; trước hết hãy thành thạo =, IN và LIKE.


-- ------------------------------------------------------------------------------
-- 5. BẢN CHẤT LOGIC 3 GIÁ TRỊ (THREE-VALUED LOGIC) & CẠM BẪY VỚI NULL
-- ------------------------------------------------------------------------------
-- Trong SQL, một biểu thức điều kiện không chỉ trả về TRUE hoặc FALSE, mà có 3 trạng thái:
--   1. TRUE (Đúng)
--   2. FALSE (Sai)
--   3. UNKNOWN (Chưa xác định / NULL)
--
-- 📊 BẢNG CHÂN TRỊ LOGIC 3 GIÁ TRỊ (TRUTH TABLE):
-- ┌─────────┬─────────┬─────────┬─────────┬─────────┐
-- │ A       │ B       │ A AND B │ A OR B  │ NOT A   │
-- ├─────────┼─────────┼─────────┼─────────┼─────────┤
-- │ TRUE    │ UNKNOWN │ UNKNOWN │ TRUE    │ FALSE   │
-- │ FALSE   │ UNKNOWN │ FALSE   │ UNKNOWN │ TRUE    │
-- │ UNKNOWN │ UNKNOWN │ UNKNOWN │ UNKNOWN │ UNKNOWN │
-- └─────────┴─────────┴─────────┴─────────┴─────────┘
--
-- ⚠️ NGUYÊN TẮC BẤT DI BẤT DỊCH:
-- `NULL` KHÔNG PHẢI LÀ MỘT GIÁ TRỊ, NÓ LÀ TRẠNG THÁI THIẾU THÔNG TIN (Missing Information).
-- Do đó: Không bao giờ được dùng `col = NULL` hoặc `col <> NULL` (kết quả luôn là UNKNOWN -> 0 dòng)!

-- 5.1 Cú pháp chuẩn kiểm tra NULL:
SELECT employee_id, first_name, manager_id
FROM employees
WHERE manager_id IS NULL; -- Lấy nhân viên cấp cao nhất (Không có Sếp quản lý)
-- 💬 `IS NULL` hỏi "ô này có đang thiếu thông tin không?" chứ không so sánh với một giá trị.

-- 5.2 [CẠM BẪY KINH ĐIỂN] NOT IN VỚI DANH SÁCH CHỨA NULL:
-- Giả sử ta muốn tìm khách hàng chưa từng đặt đơn hàng:
-- ❌ NẾU VIẾT:
-- SELECT * FROM customers WHERE customer_id NOT IN (SELECT customer_id FROM orders);
-- NẾU TRONG BẢNG ORDERS CÓ DÙ CHỈ 1 DÒNG customer_id LÀ NULL:
-- Biểu thức trở thành: `customer_id NOT IN (1, 2, NULL)`
-- Mở rộng logic: `customer_id <> 1 AND customer_id <> 2 AND customer_id <> NULL`
-- Vì `customer_id <> NULL` luôn ra UNKNOWN, toàn bộ câu lệnh AND sẽ ra UNKNOWN
-- => KẾT QUẢ: TRẢ VỀ 0 DÒNG (RỖNG TOÀN BỘ) DÙ CÓ RẤT NHIỀU KHÁCH HÀNG THỎA MÃN!

-- ✅ GIẢI PHÁP THAY THẾ AN TOÀN: Dùng `NOT EXISTS` hoặc `LEFT JOIN ... WHERE right.key IS NULL`.
SELECT c.customer_id, c.first_name, c.email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);
-- 💬 Với mỗi khách `c`, truy vấn con tìm xem có ít nhất một đơn `o` cùng customer_id không.
-- NOT EXISTS chỉ giữ khách mà truy vấn con KHÔNG tìm thấy dòng nào. Đây là cách rất thường
-- dùng để tìm "có A nhưng chưa có B" và an toàn khi cột ở bảng B có NULL.
