-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 01: FOUNDATION QUERYING (NỀN TẢNG TRUY VẤN DỮ LIỆU)
-- BÀI GIẢNG 01: BẢN CHẤT CÂU LỆNH SELECT, FROM, PHÉP CHIẾU VÀ DISTINCT
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Bối cảnh & Cơ chế hoạt động của Database Engine (Parser, Planner, Executor).
--   2. Phép chiếu (Projection) & Tại sao không bao giờ dùng "SELECT *" trong Production.
--   3. Bí danh (Aliases) & Chuẩn đặt tên Clean Code SQL.
--   4. Biểu thức số học, xử lý chuỗi và hàm biến đổi dữ liệu trực tiếp.
--   5. Khử trùng lặp: Phân biệt DISTINCT (ANSI) và DISTINCT ON (Đặc sản PostgreSQL).
--   6. Cạm bẫy thường gặp & Quy tắc tối ưu hiệu năng (Best Practices).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Sau bài này, bạn phải đọc được một câu "lấy cột A, B từ bảng X".
-- CÂU LỆNH CỐT LÕI: SELECT (chọn thứ cần hiển thị), FROM (chọn bảng nguồn),
-- AS (đặt tên hiển thị), DISTINCT (bỏ dòng trùng). Đây là nhóm lệnh RẤT THƯỜNG
-- XUYÊN: bạn sẽ gặp trong gần như mọi truy vấn đọc dữ liệu.
-- 🧠 CẦN NHỚ: Mỗi dòng kết quả vẫn là một dòng nguồn, trừ khi dùng DISTINCT,
-- GROUP BY hoặc JOIN. `AS` chỉ đổi nhãn trong kết quả, không đổi tên cột trong bảng.
-- 💬 CÁCH ĐỌC: `SELECT cot FROM bang;` = "hiển thị cot lấy từ bang".
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BỐI CẢNH & CƠ CHẾ HOẠT ĐỘNG BÊN DƯỚI CỦA CƠ SỞ DỮ LIỆU
-- ------------------------------------------------------------------------------
-- Trong mô hình Dữ liệu Quan hệ (Relational Model), một bảng là một tập hợp các bộ (Tuples/Rows)
-- và các thuộc tính (Attributes/Columns).
-- 
-- Khi bạn gửi một câu lệnh SQL đến Database Engine (như PostgreSQL), quy trình xử lý diễn ra như sau:
--   ┌───────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
--   │ 1. Parser     │ ──> │ 2. Rewriter      │ ──> │ 3. Query Planner │ ──> │ 4. Executor      │
--   │ Kiểm tra cú   │     │ Áp dụng View,    │     │ Tìm đường dẫn tối│     │ Quét Disk / RAM  │
--   │ pháp & từ khóa│     │ RLS, Rule engine │     │ ưu (Cost-based)  │     │ trả về Recordset │
--   └───────────────┘     └──────────────────┘     └──────────────────┘     └──────────────────┘
--
-- ⚠️ THỨ TỰ THỰC THI LOGICAL (Logical Execution Order):
-- Dù bạn viết `SELECT` đầu tiên, Database Engine thực tế sẽ chạy `FROM` trước để xác định nguồn bảng,
-- sau đó mới đến các bước lọc, gom nhóm, và cuối cùng mới tới `SELECT` để chiếu (Project) các cột ra ngoài.


-- ------------------------------------------------------------------------------
-- 2. PHÉP CHIẾU (PROJECTION) & TẠI SAO PHẢI NÓI "KHÔNG" VỚI "SELECT *"
-- ------------------------------------------------------------------------------
-- Phép chiếu là hành động chọn ra một tập hợp con các cột từ bảng.

-- ❌ 2.1 TRUY VẤN KHÔNG KHUYẾN NGHỊ (Chỉ dùng khi khám phá nhanh trên Console):
SELECT * 
FROM customers;
-- 💬 `*` nghĩa là "tất cả cột"; `customers` là tên bảng. Dấu `;` kết thúc câu lệnh.
-- 📌 Chỉ dùng khi xem nhanh cấu trúc/dữ liệu; báo cáo thật phải liệt kê cột cần thiết.

-- 💡 TẠI SAO SELECT * LÀ ANTI-PATTERN TRONG PRODUCTION?
--   1. Lãng phí Băng thông Mạng & I/O: Đọc tất cả các cột từ ổ đĩa vào Shared Buffers và gửi qua mạng,
--      ngay cả những cột chứa dữ liệu cực lớn như TEXT, JSONB, BYTEA mà ứng dụng không hề dùng tới.
--   2. Vô hiệu hóa "Index Only Scan": Database buộc phải quét Table Heap thay vì chỉ đọc trực tiếp từ Index.
--   3. Dễ vỡ ứng dụng (Fragile Code): Nếu Data Engineer thêm/xóa/đổi thứ tự cột trong Schema, các câu lệnh
--      INSERT INTO ... SELECT hoặc các ORM ánh xạ theo vị trí cột sẽ bị crash hoặc ghi sai dữ liệu.

-- ✅ 2.2 TRUY VẤN CHUẨN MỰC (Chỉ chọn đúng những cột nghiệp vụ cần dùng):
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    city
FROM customers;
-- 💬 Mỗi tên cột sau SELECT tạo thành một cột trong kết quả. Dấu phẩy ngăn các cột;
-- không có dấu phẩy sau cột cuối cùng. FROM chưa lọc dòng nào nên lấy mọi khách hàng.

-- BẢNG KẾT QUẢ KỲ VỌNG:
-- customer_id | first_name | last_name | email                 | city
-- ------------+------------+-----------+-----------------------+------------
-- 1           | Nguyen     | Van An    | an.nguyen@example.com | Ho Chi Minh
-- 2           | Tran       | Thi Bich  | bich.tran@example.com | Hanoi
-- ...


-- ------------------------------------------------------------------------------
-- 3. BÍ DANH (COLUMN & TABLE ALIASES) VÀ CLEAN CODE SQL
-- ------------------------------------------------------------------------------
-- Bí danh giúp đổi tên hiển thị của cột ở tập kết quả đầu ra và rút gọn tên bảng khi truy vấn.

SELECT 
    c.customer_id AS ma_dinh_danh,
    c.first_name || ' ' || c.last_name AS ho_va_ten_day_du, -- Nối chuỗi bằng toán tử chuẩn ANSI ||
    c.email AS dia_chi_email,
    c.customer_segment AS phan_khuc_khach_hang
FROM customers AS c;
-- 💬 `c` là bí danh bảng. Sau dòng này, `c.email` nghĩa chính xác là customers.email.
-- 💡 TẠI SAO: khi JOIN nhiều bảng cùng có cột `customer_id`, tiền tố `c.` tránh mơ hồ.

-- 💡 QUY TẮC CLEAN CODE CHO DATA TEAM:
-- - Luôn giữ từ khóa `AS` khi đặt alias cho cột để tăng tính rõ ràng.
-- - Đặt tên Alias bằng `snake_case`, mang ý nghĩa kinh doanh rõ ràng, tránh viết tắt tối nghĩa (như a, b, c1).


-- ------------------------------------------------------------------------------
-- 4. BIỂU THỨC SỐ HỌC, XỬ LÝ CHUỖI & BIẾN ĐỔI DỮ LIỆU TRỰC TIẾP
-- ------------------------------------------------------------------------------
-- Bạn có thể thực hiện mọi phép tính toán toán học (+, -, *, /, %) và hàm chuỗi ngay trong mệnh đề SELECT.

SELECT 
    product_name,
    unit_price AS gia_ban_le,
    cost_price AS gia_von,
    
    -- 1. Tính lợi nhuận gộp trên từng đơn vị sản phẩm
    (unit_price - cost_price) AS loi_nhuan_tuyet_doi,
    
    -- 2. Tính tỷ suất lợi nhuận phần trăm (Gross Profit Margin %)
    ROUND(((unit_price - cost_price) / cost_price) * 100, 2) AS ty_suat_loi_nhuan_pct,
    
    -- 3. Tính giá bán sau thuế VAT 10%
    ROUND(unit_price * 1.10, 0) AS gia_sau_thue_vat,
    
    -- 4. Xử lý chuỗi: In hoa tên sản phẩm và đo độ dài ký tự
    UPPER(product_name) AS ten_in_hoa,
    LENGTH(product_name) AS so_ky_tu
FROM products;
-- 💬 Những phép tính trong SELECT được tính lại cho từng sản phẩm; chúng chưa ghi lại
-- vào bảng products. `ROUND(x, 2)` làm tròn x đến 2 chữ số sau dấu thập phân.
-- ⚠️ Nếu cost_price có thể bằng 0, công thức tỷ suất phải dùng
-- `... / NULLIF(cost_price, 0)` để tránh lỗi chia cho 0.


-- ------------------------------------------------------------------------------
-- 5. KHỬ TRÙNG LẶP: DISTINCT (ANSI) VS DISTINCT ON (POSTGRESQL SPECIAL)
-- ------------------------------------------------------------------------------

-- 5.1 DISTINCT ANSI SQL: Khử toàn bộ các dòng có giá trị trùng lặp hoàn toàn
-- Cơ chế: Database sẽ thực hiện phép Gom nhóm (Hash Aggregate) hoặc Sắp xếp (Unique Sort) để lọc bỏ bản ghi trùng.
SELECT DISTINCT 
    city,
    country
FROM customers
ORDER BY city ASC;
-- 💬 DISTINCT xét cả cặp (city, country), không chỉ city. ORDER BY đặt sau DISTINCT
-- để sắp xếp danh sách đã khử trùng; `ASC` là tăng dần và có thể bỏ vì là mặc định.

-- 5.2 [NÂNG CAO] DISTINCT ON (Biểu thức): Đặc sản tối thượng của PostgreSQL
--
-- 🎯 BÀI TOÁN NGHIỆP VỤ: 
-- "Với mỗi khách hàng, hãy lấy thông tin của ĐƠN HÀNG MỚI NHẤT mà họ đã đặt."
--
-- Trong MySQL/Oracle: Bạn phải dùng Window Function `ROW_NUMBER()` hoặc Self-Join phức tạp.
-- Trong PostgreSQL: Chỉ cần 1 câu lệnh `DISTINCT ON` siêu ngắn gọn và tốc độ vượt trội!

SELECT DISTINCT ON (customer_id)
    customer_id,
    order_id,
    order_date,
    order_status,
    shipping_city
FROM orders
ORDER BY 
    customer_id ASC,     -- Cột trong DISTINCT ON BẮT BUỘC phải là cột đầu tiên trong ORDER BY!
    order_date DESC;    -- Sắp xếp giảm dần để dòng đầu tiên chính là đơn hàng mới nhất

-- ⭐ MỨC ĐỘ DÙNG: DISTINCT rất thường xuyên khi khám phá danh sách giá trị; DISTINCT ON
-- là cú pháp PostgreSQL nâng cao, không có trong nhiều hệ quản trị khác.
-- 🧠 CẦN NHỚ: với `DISTINCT ON (customer_id)`, ORDER BY phải bắt đầu bằng customer_id;
-- cột sắp xếp sau đó quyết định "dòng đầu tiên" nào được giữ lại.

-- 🔍 GIẢI THÍCH NGUYÊN LÝ HOẠT ĐỘNG CỦA DISTINCT ON:
--   Bước 1: Sắp xếp bảng orders theo customer_id tăng dần, và order_date giảm dần.
--   Bước 2: Quét qua tập kết quả, khi gặp customer_id mới, nó giữ lại dòng đầu tiên (chính là order_date mới nhất)
--           và bỏ qua toàn bộ các dòng có cùng customer_id phía sau.

-- ------------------------------------------------------------------------------
-- 6. TÓM TẮT & BEST PRACTICES
-- ------------------------------------------------------------------------------
-- ✅ Luôn chỉ định cụ thể danh sách cột trong SELECT.
-- ✅ Sử dụng toán tử `||` thay vì hàm concat phi tiêu chuẩn khi nối chuỗi.
-- ✅ Luôn nhớ: Cột trong `DISTINCT ON (col_A)` BẮT BUỘC phải đứng đầu tiên trong `ORDER BY col_A, col_B`.
-- ✅ Lưu ý chi phí: `DISTINCT` trên tập dữ liệu hàng chục triệu dòng có thể gây tốn RAM (Work_mem) do thao tác Sort/Hash.
