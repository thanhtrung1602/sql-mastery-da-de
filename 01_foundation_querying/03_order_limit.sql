-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 01: FOUNDATION QUERYING
-- BÀI GIẢNG 03: SẮP XẾP ĐA TẦNG, XỬ LÝ NULL KHI SORT VÀ PHÂN TRANG HIỆU NĂNG CAO
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Cơ chế hoạt động của ORDER BY trong bộ nhớ (QuickSort, Top-N HeapSort, External Disk Merge Sort).
--   2. Sắp xếp đa tầng (Multi-column Sorting) & Hướng sắp xếp (ASC, DESC).
--   3. Kiểm soát vị trí giá trị NULL tuyệt đối với NULLS FIRST và NULLS LAST.
--   4. Phân trang truyền thống (LIMIT & OFFSET) và "Cơn ác mộng hiệu năng" (Performance Pitfall).
--   5. Phân trang con trỏ (Keyset / Cursor-based Pagination) - Kỹ thuật chuẩn Data Engineering.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Sắp xếp kết quả ổn định và chỉ lấy đúng số dòng cần xem.
-- CÂU LỆNH: ORDER BY (sắp xếp), ASC/DESC (chiều), NULLS FIRST/LAST (vị trí dữ liệu
-- thiếu), LIMIT (số dòng lấy), OFFSET (số dòng bỏ qua), WHERE + cursor (trang tiếp).
-- ⭐ MỨC ĐỘ DÙNG: ORDER BY/LIMIT rất thường xuyên; OFFSET chỉ phù hợp trang nông;
-- keyset pagination là kiến thức nâng cao cho API/dữ liệu lớn.
-- 🧠 CẦN NHỚ: Không có ORDER BY thì "5 dòng đầu" không có thứ tự bảo đảm.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CƠ CHẾ BÊN DƯỚI CỦA ORDER BY (DATABASE ENGINE INTERNALS)
-- ------------------------------------------------------------------------------
-- Khi thực thi ORDER BY, Database Engine sẽ chọn một trong các thuật toán sắp xếp:
--   1. Top-N HeapSort: Dùng khi có `ORDER BY ... LIMIT N` với N nhỏ. Database chỉ duy trì 1 vùng nhớ Heap
--      kích thước N phần tử -> Rất nhanh, không cần sắp xếp toàn bộ bảng!
--   2. QuickSort (Trong RAM / Work_Mem): Khi toàn bộ tập dữ liệu cần sắp xếp vừa vặn trong vùng nhớ `work_mem`.
--   3. External Merge Sort (Tràn ra Ổ đĩa - Disk Spill): Khi dữ liệu quá lớn không vừa `work_mem`.
--      Database phải ghi các file tạm xuống ổ đĩa (Temporary Files) rồi merge lại -> Gây chậm hệ thống nghiêm trọng!


-- ------------------------------------------------------------------------------
-- 2. SẮP XẾP ĐA TẦNG (MULTI-COLUMN SORTING)
-- ------------------------------------------------------------------------------
-- Khi sắp xếp theo nhiều cột, Database sẽ ưu tiên cột đứng trước. Nếu giá trị ở cột trước trùng nhau,
-- nó mới xét tiếp đến cột đứng sau.

SELECT 
    customer_id, 
    first_name, 
    city, 
    customer_segment, 
    signup_date
FROM customers
ORDER BY 
    city ASC,                 -- Ưu tiên 1: Thành phố theo bảng chữ cái A -> Z
    customer_segment DESC,    -- Ưu tiên 2: Cùng thành phố thì VIP xếp trước Standard (Z -> A)
    signup_date ASC;          -- Ưu tiên 3: Cùng phân khúc thì người đăng ký sớm hơn xếp trước

-- 💬 Database xét city trước. CHỈ khi hai người cùng city mới xét customer_segment,
-- rồi mới xét signup_date. Mỗi cột ORDER BY có thể có chiều ASC/DESC riêng.


-- ------------------------------------------------------------------------------
-- 3. XỬ LÝ VỊ TRÍ NULL VỚI NULLS FIRST / NULLS LAST
-- ------------------------------------------------------------------------------
-- 💡 MẶC ĐỊNH TRONG POSTGRESQL:
--   - Khi sắp xếp ASC  : NULL được xem là "Vô cùng lớn" -> Xếp ở CUỐI CÙNG (NULLS LAST).
--   - Khi sắp xếp DESC : NULL được xem là "Vô cùng lớn" -> Xếp ở ĐẦU TIÊN (NULLS FIRST).
--
-- Tuy nhiên, trong phân tích dữ liệu, bạn hoàn toàn có thể kiểm soát vị trí của NULL theo ý muốn:

-- 3.1 Ép NULL luôn ở cuối cùng ngay cả khi sắp xếp DESC (Tránh trường hợp dữ liệu rác nổi lên đầu):
SELECT 
    employee_id, 
    first_name, 
    manager_id, 
    salary
FROM employees
ORDER BY 
    manager_id DESC NULLS LAST; -- Người có manager_id lớn nhất lên đầu, CEO (manager_id là NULL) ở cuối cùng
-- 💬 NULLS LAST ghi rõ quy tắc thay vì dựa vào mặc định của PostgreSQL. Cách viết này
-- dễ đọc hơn và ít gây ngạc nhiên khi chuyển sang hệ quản trị khác.

-- 3.2 Ép NULL lên đầu tiên khi sắp xếp ASC:
SELECT 
    event_id, 
    session_id, 
    customer_id, 
    event_type
FROM web_events
ORDER BY 
    customer_id ASC NULLS FIRST;


-- ------------------------------------------------------------------------------
-- 4. PHÂN TRANG TRUYỀN THỐNG: LIMIT & OFFSET VÀ CẠM BẪY HIỆU NĂNG
-- ------------------------------------------------------------------------------

-- 4.1 Cú pháp cơ bản:
SELECT product_id, product_name, unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 3 OFFSET 0; -- Trang 1: Lấy 3 sản phẩm đầu tiên
-- 💬 LIMIT 3 = trả tối đa 3 dòng. OFFSET 0 = không bỏ dòng nào; trang 2 cỡ 3 sẽ là OFFSET 3.
-- ⚠️ LIMIT không thay thế ORDER BY: không có ORDER BY, các trang có thể đổi thứ tự giữa lần chạy.

-- ⚠️ TẠI SAO OFFSET LÀ CƠN ÁC MỘNG HIỆU NĂNG (O(N) Complexity)?
-- Giả sử bạn truy vấn Trang thứ 10,000 của một bảng có 10 triệu dòng:
-- `SELECT * FROM orders ORDER BY order_id LIMIT 10 OFFSET 100000;`
--
-- 🔄 CƠ CHẾ THỰC THI BÊN DƯỚI CỦA DATABASE:
--   1. Database phải đọc và sắp xếp toàn bộ 100,010 dòng từ ổ đĩa vào RAM.
--   2. Quét qua 100,000 dòng đầu tiên và VỨT BỎ (Discard) toàn bộ 100,000 dòng này.
--   3. Chỉ giữ lại đúng 10 dòng cuối cùng để trả về client.
-- => Hậu quả: Càng sang các trang sau, câu lệnh chạy càng chậm cấp số nhân, làm nghẽn CPU và I/O!


-- ------------------------------------------------------------------------------
-- 5. PHÂN TRANG HIỆU NĂNG CAO: KEYSET (CURSOR-BASED) PAGINATION
-- ------------------------------------------------------------------------------
-- 💡 NGUYÊN LÝ HOẠT ĐỘNG (O(log N) Complexity):
-- Thay vì dùng OFFSET để đếm số dòng bỏ qua, ta dùng mệnh đề WHERE dựa trên Khóa chính / Cột đã đánh Index
-- của bản ghi cuối cùng ở trang trước đó (gọi là Con trỏ - Cursor).
--
-- ┌──────────────────────┐
-- │ Trang 1: (ID 1 -> 5) │ ──> Nhận được bản ghi cuối có order_id = 5
-- └──────────────────────┘
--           │
--           ▼
-- ┌────────────────────────────────────────────────────────┐
-- │ Trang 2: WHERE order_id > 5 ORDER BY order_id LIMIT 5  │ ──> Tận dụng B-Tree Index đi thẳng tới ID 6!
-- └────────────────────────────────────────────────────────┘

-- Truy vấn Trang 2 sử dụng Keyset Pagination (Siêu nhanh kể cả khi bảng có 100 triệu dòng):
SELECT order_id, customer_id, order_date, shipping_city
FROM orders
WHERE order_id > 1005 -- Cursor từ trang trước
ORDER BY order_id ASC
LIMIT 5;
-- 💬 `order_id > 1005` là "dấu trang" do ứng dụng lưu từ dòng cuối trang trước, không phải
-- số trang. Khóa nên có index và phải cùng chiều với ORDER BY để truy vấn nhanh, ổn định.

-- Phân trang theo nhiều cột (Ví dụ: order_date và order_id):
SELECT order_id, customer_id, order_date
FROM orders
WHERE (order_date, order_id) > ('2023-10-01 08:20:00', 1006)
ORDER BY order_date ASC, order_id ASC
LIMIT 5;
-- 💬 So sánh cặp `(order_date, order_id)` giúp xử lý nhiều đơn có cùng thời điểm. order_id
-- là khóa phụ để không lặp hoặc bỏ sót dòng khi chuyển trang.
