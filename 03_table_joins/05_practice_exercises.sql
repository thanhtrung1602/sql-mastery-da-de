-- ==============================================================================
-- FOLDER 03: TABLE JOINS
-- FILE: 05_practice_exercises.sql
-- MỤC TIÊU:
--   Luyện tập kết nối bảng: INNER/LEFT/FULL JOIN, Anti-join (NOT EXISTS / LEFT JOIN IS NULL),
--   Self-join, Lateral Join, và Set Operations (UNION/INTERSECT/EXCEPT).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH LÀM: Viết số dòng dự đoán trước khi JOIN. Một customer có thể có nhiều order,
-- một order có thể có nhiều order_item; JOIN theo các quan hệ 1-này-nhiều sẽ nhân dòng.
-- 🧠 CẦN NHỚ: Muốn giữ hết bảng trái dùng LEFT JOIN; muốn chỉ hỏi "có tồn tại không" ưu tiên
-- EXISTS/NOT EXISTS thay vì JOIN rồi DISTINCT.
-- ==============================================================================

-- ==============================================================================
-- BÀI TẬP 1 (CƠ BẢN): BÁO CÁO DOANH THU THEO DANH MỤC SẢN PHẨM
-- ==============================================================================
-- YÊU CẦU:
--   Lấy ra tên danh mục (category_name) và tổng doanh thu thuần thu được từ danh mục đó (chỉ tính đơn hàng 'Completed').
--   Bao gồm cả những danh mục chưa bán được sản phẩm nào (hiển thị doanh thu là 0).
--   Sắp xếp theo total_revenue giảm dần.

-- GỢI Ý: Dùng categories c LEFT JOIN products p ON ... LEFT JOIN order_items oi ON ... LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'Completed'.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-----------------------+---------------+
-- | category_name         | total_revenue |
-- +-----------------------+---------------+
-- | Smartphones & Tablets |  216780000.00 |
-- | Laptops & Computers   |  137500000.00 |
-- | Audio & Accessories   |   62337000.00 |
-- | Kitchen Appliances    |   59508500.00 |
-- | Fashion & Apparel     |    7470000.00 |
-- | Electronics           |          0.00 |
-- | Home & Living         |          0.00 |
-- | Books & Media         |          0.00 |
-- +-----------------------+---------------+
-- (8 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 2 (ANTI-JOIN): TÌM SẢN PHẨM "Ế" (CHƯA TỪNG ĐƯỢC BÁN)
-- ==============================================================================
-- YÊU CẦU:
--   Tìm danh sách tất cả các sản phẩm có trong kho (bảng products) nhưng CHƯA TỪNG
--   xuất hiện trong bất kỳ đơn hàng nào (bảng order_items).
--
-- GỢI Ý: Dùng NOT EXISTS hoặc LEFT JOIN ... WHERE oi.order_item_id IS NULL.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------+-------------------------------+------------+----------------+
-- | product_id | product_name                  | unit_price | stock_quantity |
-- +------------+-------------------------------+------------+----------------+
-- | 110        | Outdated Android Tablet Gen 1 | 2500000.00 |              0 |
-- +------------+-------------------------------+------------+----------------+
-- (1 row)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 3 (SELF-JOIN): DANH SÁCH NHÂN VIÊN VÀ MỨC LƯƠNG CỦA QUẢN LÝ
-- ==============================================================================
-- YÊU CẦU:
--   Tìm các nhân viên có mức lương cao hơn hoặc bằng 50% mức lương của Người quản lý trực tiếp của họ.
--   Hiển thị tên nhân viên, lương nhân viên, tên quản lý, lương quản lý, và tỷ lệ %.
--   Sắp xếp theo salary_ratio_pct giảm dần.
--
-- GỢI Ý: Dùng employees e JOIN employees m ON e.manager_id = m.employee_id.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------------+-----------------+------------------+----------------+------------------+
-- | employee_name    | employee_salary | manager_name     | manager_salary | salary_ratio_pct |
-- +------------------+-----------------+------------------+----------------+------------------+
-- | Nguyen Hoang Nam |     75000000.00 | Tran Tung Lam    |   120000000.00 |            62.50 |
-- | Pham Duc Thang   |     45000000.00 | Nguyen Hoang Nam |    75000000.00 |            60.00 |
-- | Le Thu Thao      |     70000000.00 | Tran Tung Lam    |   120000000.00 |            58.33 |
-- | Vu Quang Huy     |     38000000.00 | Nguyen Hoang Nam |    75000000.00 |            50.67 |
-- +------------------+-----------------+------------------+----------------+------------------+
-- (4 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 4 (LATERAL JOIN): ĐƠN HÀNG ĐẮT GIÁ NHẤT CỦA TỪNG KHÁCH HÀNG
-- ==============================================================================
-- YÊU CẦU:
--   Với mỗi khách hàng trong bảng customers, sử dụng LATERAL JOIN để tìm đúng 1 đơn hàng
--   có giá trị thanh toán lớn nhất (tính từ bảng payments với status = 'Success').
--   Sắp xếp theo max_payment_amount giảm dần (các khách chưa có thanh toán xếp sau cùng).
--
-- GỢI Ý: Dùng customers c LEFT JOIN LATERAL (...) ON TRUE.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+-----------------+----------+--------------------+
-- | customer_id | customer_name   | order_id | max_payment_amount |
-- +-------------+-----------------+----------+--------------------+
-- | 7           | David Smith     | 1009     |        54140000.00 |
-- | 2           | Tran Thi Bich   | 1002     |        48040000.00 |
-- | 5           | Hoang Minh Em   | 1006     |        38105500.00 |
-- | 1           | Nguyen Van An   | 1001     |        37720500.00 |
-- | 3           | Le Quoc Cuong   | 1003     |         7676000.00 |
-- | 4           | Pham Thanh Dung | NULL     |               NULL |
-- | 6           | Vu Thi Giang    | NULL     |               NULL |
-- | 8           | Do Hoang Hai    | NULL     |               NULL |
-- | 9           | Ngo Ngoc Khanh  | NULL     |               NULL |
-- | 10          | Bui Van Lam     | NULL     |               NULL |
-- +-------------+-----------------+----------+--------------------+
-- (10 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
