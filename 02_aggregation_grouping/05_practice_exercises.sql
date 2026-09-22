-- ==============================================================================
-- FOLDER 02: AGGREGATION & GROUPING
-- FILE: 05_practice_exercises.sql
-- MỤC TIÊU:
--   Luyện tập các kỹ năng gom nhóm: COUNT/SUM/AVG, FILTER (WHERE ...),
--   HAVING vs WHERE, ROLLUP/CUBE, và gom nhóm chuỗi thời gian (DATE_TRUNC).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH LÀM: Trước khi gõ, xác định "một dòng kết quả là gì". Nếu là thành phố,
-- tháng hay danh mục thì đưa cột đó vào GROUP BY; số liệu là COUNT/SUM/AVG. Dùng WHERE
-- để bỏ dòng không liên quan trước khi tính, HAVING để bỏ cả nhóm sau khi tính.
-- 🧠 CẦN NHỚ: `COUNT(*)` đếm dòng; `COUNT(DISTINCT x)` đếm giá trị x không trùng.
-- ==============================================================================

-- ==============================================================================
-- BÀI TẬP 1 (CƠ BẢN): THỐNG KÊ DOANH THU & SỐ LƯỢNG ĐƠN HÀNG THEO THÀNH PHỐ
-- ==============================================================================
-- YÊU CẦU:
--   Thống kê số lượng đơn hàng, tổng phí vận chuyển (total_shipping_fee) và phí vận chuyển trung bình (avg_shipping_fee)
--   theo từng thành phố giao hàng (shipping_city). Làm tròn avg_shipping_fee đến 2 chữ số thập phân.
--   Chỉ lấy các thành phố có tổng số đơn hàng >= 2. Sắp xếp theo số đơn hàng giảm dần.

-- GỢI Ý: Dùng GROUP BY shipping_city, COUNT(order_id), SUM(shipping_fee), ROUND(AVG(shipping_fee), 2), HAVING COUNT(order_id) >= 2.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +---------------+--------------+--------------------+------------------+
-- | shipping_city | total_orders | total_shipping_fee | avg_shipping_fee |
-- +---------------+--------------+--------------------+------------------+
-- | Ho Chi Minh   |            7 |          120000.00 |         17142.86 |
-- | Hanoi         |            5 |          110000.00 |         22000.00 |
-- | Da Nang       |            3 |          105000.00 |         35000.00 |
-- | Can Tho       |            2 |           50000.00 |         25000.00 |
-- | Singapore     |            2 |          300000.00 |        150000.00 |
-- +---------------+--------------+--------------------+------------------+
-- (5 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 2 (TRUNG BÌNH): TỶ LỆ HOÀN TẤT ĐƠN HÀNG VỚI FILTER (WHERE ...)
-- ==============================================================================
-- YÊU CẦU:
--   Với từng phương thức thanh toán (payment_method), tính:
--   1. Tổng số đơn hàng.
--   2. Số đơn hàng thành công (order_status = 'Completed').
--   3. Số đơn hàng bị hủy (order_status = 'Cancelled').
--   4. Tỷ lệ hoàn tất đơn hàng theo % (làm tròn 2 chữ số thập phân).
--   Sắp xếp theo total_orders giảm dần.
--
-- GỢI Ý: Dùng COUNT(*) FILTER (WHERE ...) hoặc CASE WHEN kết hợp NULLIF để tránh chia cho 0.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +----------------+--------------+------------------+------------------+---------------------+
-- | payment_method | total_orders | completed_orders | cancelled_orders | completion_rate_pct |
-- +----------------+--------------+------------------+------------------+---------------------+
-- | Credit Card    |            9 |                9 |                0 |              100.00 |
-- | Bank Transfer  |            5 |                4 |                0 |               80.00 |
-- | E-Wallet       |            4 |                4 |                0 |              100.00 |
-- | COD            |            2 |                0 |                1 |                0.00 |
-- +----------------+--------------+------------------+------------------+---------------------+
-- (4 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 3 (NÂNG CAO): DOANH THU THEO THÁNG VÀ DANH SÁCH SẢN PHẨM BÁN ĐƯỢC
-- ==============================================================================
-- YÊU CẦU:
--   Thống kê theo từng tháng cho các đơn hàng đã hoàn tất (order_status = 'Completed'):
--   - Tháng phát sinh đơn hàng (định dạng YYYY-MM).
--   - Tổng doanh thu thuần (quantity * unit_price * (1 - discount_pct)).
--   - Danh sách các ID sản phẩm phân biệt bán được trong tháng đó, nối thành chuỗi phân cách bởi dấu phẩy.
--   Sắp xếp theo sales_month tăng dần.
--
-- GỢI Ý: Dùng DATE_TRUNC('month', order_date), TO_CHAR() hoặc STROFDATE, STRING_AGG(DISTINCT product_id::TEXT, ', ').
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+---------------------+---------------------------+
-- | sales_month | monthly_net_revenue | distinct_product_ids_sold |
-- +-------------+---------------------+---------------------------+
-- | 2023-09     |        114136500.00 | 101, 103, 105, 106, 108   |
-- | 2023-10     |        104025500.00 | 102, 103, 105, 106        |
-- | 2023-11     |         79475500.00 | 101, 104, 107             |
-- | 2023-12     |         63128000.00 | 101, 105, 108, 109        |
-- | 2024-01     |         36280000.00 | 102, 107                  |
-- | 2024-02     |         66790000.00 | 101, 106                  |
-- +-------------+---------------------+---------------------------+
-- (6 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 4 (OLAP BI): BÁO CÁO PHÂN TÍCH QUỸ LƯƠNG ĐA TẦNG VỚI ROLLUP
-- ==============================================================================
-- YÊU CẦU:
--   Tạo báo cáo tổng quỹ lương (SUM salary) và số lượng nhân sự theo:
--   - Cấp 1: Phòng ban (department).
--   - Cấp 2: Quản lý trực tiếp (manager_id).
--   - Dòng tổng kết toàn công ty (Grand Total).
--   Sắp xếp theo department_name, manager_id.
--
-- GỢI Ý: Dùng GROUP BY ROLLUP(department, manager_id), COALESCE(department, '== TOÀN CÔNG TY ==').
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +--------------------+------------+-----------------+---------------+
-- | department_name    | manager_id | total_headcount | total_payroll |
-- +--------------------+------------+-----------------+---------------+
-- | == TOÀN CÔNG TY == |       NULL |               8 |  428000000.00 |
-- | Engineering        |          1 |               1 |   75000000.00 |
-- | Engineering        |          2 |               2 |   83000000.00 |
-- | Engineering        |          4 |               1 |   22000000.00 |
-- | Engineering        |       NULL |               4 |  180000000.00 |
-- | Executive          |       NULL |               1 |  120000000.00 |
-- | Executive          |       NULL |               1 |  120000000.00 |
-- | Sales & Marketing  |          1 |               1 |   70000000.00 |
-- | Sales & Marketing  |          3 |               2 |   58000000.00 |
-- | Sales & Marketing  |       NULL |               3 |  128000000.00 |
-- +--------------------+------------+-----------------+---------------+
-- (10 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
