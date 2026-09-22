-- ==============================================================================
-- FOLDER 01: FOUNDATION QUERYING
-- FILE: 05_practice_exercises.sql
-- MỤC TIÊU:
--   Luyện tập các kỹ năng nền tảng: SELECT, ALIAS, WHERE, ORDER BY, LIMIT/OFFSET,
--   DISTINCT, DISTINCT ON, ép kiểu và xử lý ngày tháng.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH LÀM BÀI TẬP CHO NGƯỜI MỚI
-- Mỗi lời giải bên dưới được giữ lại để bạn đối chiếu. Trước khi nhìn lời giải, hãy viết
-- khung `SELECT ... FROM ...`, rồi lần lượt thêm WHERE, ORDER BY. Sau khi chạy, tự hỏi:
-- (1) một dòng kết quả đại diện cho gì? (2) điều kiện nào loại dòng? (3) vì sao cần alias?
-- 🧠 CẦN NHỚ: SQL không phân biệt hoa/thường ở từ khóa và tên không có dấu nháy, nhưng viết
-- SELECT/FROM/WHERE hoa giúp dễ đọc. Giá trị văn bản như 'Vietnam' phải dùng nháy đơn.
-- ==============================================================================

-- ==============================================================================
-- BÀI TẬP 1 (CƠ BẢN): DANH SÁCH KHÁCH HÀNG VIỆT NAM
-- ==============================================================================
-- YÊU CẦU:
--   Lấy ra danh sách các khách hàng thuộc quốc gia 'Vietnam'.
--   Hiển thị các cột: customer_id (đổi tên thành ma_khach_hang), họ và tên ghép lại (ho_va_ten),
--   email và thành phố (city). Sắp xếp theo ma_khach_hang tăng dần.

-- GỢI Ý: Dùng SELECT, toán tử nối chuỗi `||`, bí danh `AS`, WHERE country = 'Vietnam', ORDER BY.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +---------------+-----------------+------------------------+-------------+
-- | ma_khach_hang | ho_va_ten       | email                  | city        |
-- +---------------+-----------------+------------------------+-------------+
-- | 1             | Nguyen Van An   | an.nguyen@example.com  | Ho Chi Minh |
-- | 2             | Tran Thi Bich   | bich.tran@example.com  | Hanoi       |
-- | 3             | Le Quoc Cuong   | cuong.le@example.com   | Da Nang     |
-- | 4             | Pham Thanh Dung | dung.pham@example.com  | Ho Chi Minh |
-- | 5             | Hoang Minh Em   | em.hoang@example.com   | Can Tho     |
-- | 6             | Vu Thi Giang    | giang.vu@example.com   | Hanoi       |
-- | 8             | Do Hoang Hai    | hai.do@example.com     | Hai Phong   |
-- | 9             | Ngo Ngoc Khanh  | khanh.ngo@example.com  | Ho Chi Minh |
-- | 10            | Bui Van Lam     | lam.bui@example.com    | Hanoi       |
-- +---------------+-----------------+------------------------+-------------+
-- (9 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
select 
    customer_id as ma_khach_hang,          -- lấy id, chỉ đổi tiêu đề cột kết quả
    first_name || ' ' || last_name as ho_va_ten, -- nối họ + khoảng trắng + tên
    email,                                 -- giữ nguyên tên cột vì không cần đổi nhãn
    city
from customers                             -- nguồn: một dòng là một khách hàng
where country = 'Vietnam'                  -- chỉ giữ khách có quốc gia đúng bằng chuỗi này
order by customer_id asc;                  -- sắp xếp id nhỏ đến lớn trước khi hiển thị




-- ==============================================================================
-- BÀI TẬP 2 (CƠ BẢN): LỌC SẢN PHẨM CÔNG NGHỆ CAO CẤP
-- ==============================================================================
-- YÊU CẦU:
--   Tìm tất cả các sản phẩm có giá niêm yết (unit_price) từ 10,000,000 đến 40,000,000 VNĐ
--   thuộc danh mục có category_id là 2 (Smartphones & Tablets) hoặc 3 (Laptops & Computers).
--   Hiển thị product_id, product_name, category_id, unit_price và số lượng tồn kho (stock_quantity).
--   Sắp xếp theo unit_price giảm dần.
--
-- GỢI Ý: Dùng BETWEEN ... AND ..., toán tử IN (...).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------+--------------------------+-------------+-------------+----------------+
-- | product_id | product_name             | category_id | unit_price  | stock_quantity |
-- +------------+--------------------------+-------------+-------------+----------------+
-- | 101        | iPhone 15 Pro Max 256GB  | 2           | 32000000.00 | 45             |
-- | 102        | Samsung Galaxy S24 Ultra | 2           | 29990000.00 | 30             |
-- +------------+--------------------------+-------------+-------------+----------------+
-- (2 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
select 
    product_id,
    product_name,
    category_id,
    unit_price,
    stock_quantity
from products
where 
    unit_price between 10000000 and 40000000 -- BETWEEN gồm cả 10tr và 40tr
    and category_id in (2, 3)                 -- đồng thời thuộc một trong hai danh mục
order by unit_price desc;                     -- giá lớn nhất đứng đầu



-- ==============================================================================
-- BÀI TẬP 3 (TRUNG BÌNH): TÍNH TOÁN LỢI NHUẬN VÀ TỶ LỆ ĐỘI GIÁ (GROSS MARKUP)
-- ==============================================================================
-- YÊU CẦU:
--   Tính lợi nhuận tuyệt đối (unit_price - cost_price) và tỷ suất lợi nhuận trên giá vốn / tỷ lệ đội giá (gross_markup_pct)
--   cho từng sản phẩm đang kinh doanh (is_discontinued = FALSE).
--   Làm tròn tỷ suất phần trăm đến 2 chữ số thập phân và lọc ra các sản phẩm có tỷ suất lợi nhuận >= 25%.
--   Sắp xếp theo gross_markup_pct giảm dần.
--
-- GỢI Ý: 
--   - Công thức Gross Markup %: ((unit_price - cost_price) / cost_price) * 100
--   - Dùng ROUND(), phép toán số học, mệnh đề WHERE.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------+-------------------------------+-------------+-------------+--------------+------------------+
-- | product_id | product_name                  | cost_price  | unit_price  | gross_profit | gross_markup_pct |
-- +------------+-------------------------------+-------------+-------------+--------------+------------------+
-- | 109        | Vintage Leather Jacket        |  1200000.00 |  2490000.00 |   1290000.00 |           107.50 |
-- | 107        | Air Fryer Philips XXL HD9650  |  4200000.00 |  6290000.00 |   2090000.00 |            49.76 |
-- | 105        | Sony WH-1000XM5 Headphone     |  6000000.00 |  8490000.00 |   2490000.00 |            41.50 |
-- | 108        | Robot Vacuum Dreame L20 Ultra | 16000000.00 | 21900000.00 |   5900000.00 |            36.88 |
-- | 106        | AirPods Pro 2 USB-C           |  4500000.00 |  5990000.00 |   1490000.00 |            33.11 |
-- | 104        | Dell XPS 15 9530              | 32000000.00 | 41500000.00 |   9500000.00 |            29.69 |
-- | 103        | MacBook Pro 14 M3 Pro         | 38000000.00 | 48000000.00 |  10000000.00 |            26.32 |
-- +------------+-------------------------------+-------------+-------------+--------------+------------------+
-- (7 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
select 
	product_id,
	product_name,
	cost_price,
	unit_price,
	(unit_price - cost_price) as gross_profit, -- phép tính thực hiện trên từng sản phẩm
	ROUND(((unit_price - cost_price) / NULLIF(cost_price, 0)) * 100, 2) as gross_markup_pct
from products
where 
	is_discontinued = false                    -- chỉ sản phẩm còn kinh doanh
	and ((unit_price - cost_price) / NULLIF(cost_price, 0)) * 100 >= 25
-- NULLIF(cost_price, 0) đổi mẫu số 0 thành NULL để tránh lỗi chia 0; WHERE sẽ bỏ dòng đó.
order by gross_markup_pct desc;             -- có thể dùng alias trong ORDER BY



-- ==============================================================================
-- BÀI TẬP 4 (NÂNG CAO - POSTGRESQL): ĐƠN HÀNG GẦN NHẤT MỖI KHÁCH HÀNG VỚI DISTINCT ON
-- ==============================================================================
-- YÊU CẦU:
--   Với mỗi khách hàng, tìm đúng 1 đơn hàng mới nhất (theo order_date) mà họ đã đặt.
--   Hiển thị customer_id, order_id, order_date và order_status.
--   Sắp xếp theo customer_id ASC, order_date DESC.
--
-- GỢI Ý: Dùng `DISTINCT ON (customer_id)` kết hợp `ORDER BY customer_id ASC, order_date DESC`.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+----------+---------------------+--------------+
-- | customer_id | order_id | order_date          | order_status |
-- +-------------+----------+---------------------+--------------+
-- | 1           | 1016     | 2024-01-05 09:30:00 | Completed    |
-- | 2           | 1015     | 2023-12-24 20:10:00 | Completed    |
-- | 3           | 1020     | 2024-02-14 15:00:00 | Completed    |
-- | 4           | 1017     | 2024-01-18 14:00:00 | Completed    |
-- | 5           | 1014     | 2023-12-12 18:25:00 | Completed    |
-- | 6           | 1008     | 2023-10-15 13:00:00 | Processing   |
-- | 7           | 1019     | 2024-02-10 11:15:00 | Completed    |
-- | 8           | 1012     | 2023-11-20 15:50:00 | Completed    |
-- | 9           | 1013     | 2023-12-05 11:00:00 | Completed    |
-- | 10          | 1018     | 2024-01-25 16:30:00 | Refunded     |
-- +-------------+----------+---------------------+--------------+
-- (10 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
select distinct on (customer_id)
	customer_id,
	order_id,
	order_date,
	order_status
from orders
order by 
	customer_id asc, -- bắt buộc đứng đầu và tạo nhóm khách hàng
	order_date desc; -- trong mỗi nhóm, đơn mới nhất đứng đầu nên DISTINCT ON giữ nó



-- ==============================================================================
-- BÀI TẬP 5 (THỜI GIAN & INTERVAL): TÍNH TUỔI VÀ THỜI GIAN ĐỒNG HÀNH
-- ==============================================================================
-- YÊU CẦU:
--   Tính độ tuổi chính xác (theo năm) của từng khách hàng tính đến thời điểm hiện tại.
--   Đồng thời lọc ra các khách hàng có độ tuổi >= 28 tuổi.
--   Sắp xếp theo age_years giảm dần.
--
-- GỢI Ý: Dùng hàm `AGE()`, `EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))`.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT FORMAT):
-- +-------------+-----------------+------------+-----------+
-- | customer_id | customer_name   | birth_date | age_years |
-- +-------------+-----------------+------------+-----------+
-- | 7           | David Smith     | 1985-04-18 | 41        |
-- | 3           | Le Quoc Cuong   | 1988-03-08 | 38        |
-- | 10          | Bui Van Lam     | 1989-10-10 | 36        |
-- | 5           | Hoang Minh Em   | 1990-12-30 | 35        |
-- | 1           | Nguyen Van An   | 1992-05-14 | 34        |
-- | 8           | Do Hoang Hai    | 1994-01-03 | 32        |
-- | 2           | Tran Thi Bich   | 1995-11-20 | 30        |
-- | 9           | Ngo Ngoc Khanh  | 1997-08-19 | 29        |
-- | 4           | Pham Thanh Dung | 1998-07-25 | 28        |
-- +-------------+-----------------+------------+-----------+
-- *(Lưu ý: Giá trị `age_years` phụ thuộc vào ngày chạy thực tế `CURRENT_DATE`)*

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
select 
	customer_id,
	first_name || ' ' || last_name as customer_name,
	birth_date,
	Extract(YEAR FROM AGE(CURRENT_DATE, birth_date)) as age_years
from customers
where Extract(YEAR FROM AGE(CURRENT_DATE, birth_date)) >= 28 -- lọc trước khi SELECT xuất ra
order by age_years desc; -- alias dùng được tại ORDER BY, nhưng chưa dùng được ở WHERE
-- 💡 TẠI SAO lặp công thức trong WHERE: thứ tự logic chạy WHERE trước SELECT, nên alias
-- age_years chưa tồn tại ở thời điểm WHERE chạy. Bài CTE sẽ cho cách tránh lặp công thức.
