-- ==============================================================================
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- FILE: 07_practice_exercises.sql
-- MỤC TIÊU:
--   Luyện tập các kỹ năng nâng cao của Data Analyst: Window Functions (Ranking, Offset, Framing),
--   CTE đệ quy, Cohort Retention, Phễu chuyển đổi (Funnel), và Phân khúc RFM.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH LÀM: Hãy chia bài dài thành CTE có tên. Ghi chú cạnh từng CTE "một dòng là gì";
-- sau đó kiểm tra từng CTE bằng `SELECT * FROM ten_cte` trước khi ghép bước tiếp theo.
-- 🧠 CẦN NHỚ: Window function giữ số dòng, GROUP BY làm gộp dòng. Đừng dùng nhầm hai cách.
-- ==============================================================================

-- ==============================================================================
-- BÀI TẬP 1 (WINDOW RANKING): TOP 1 SẢN PHẨM MANG LẠI DOANH THU CAO NHẤT MỖI THÁNG
-- ==============================================================================
-- YÊU CẦU:
--   Với mỗi tháng trong năm 2023, tìm đúng 1 sản phẩm (product_name) mang lại tổng doanh thu cao nhất trong tháng đó.
--   Hiển thị tháng, tên sản phẩm, và tổng doanh thu tháng của sản phẩm đó.

-- GỢI Ý: Dùng CTE gom nhóm theo tháng + product, sau đó dùng ROW_NUMBER() hoặc DENSE_RANK() OVER (PARTITION BY sales_month ORDER BY rev DESC).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+--------------------------+---------------------+
-- | sales_month | product_name             | top_product_revenue |
-- +-------------+--------------------------+---------------------+
-- | 2023-09-01  | MacBook Pro 14 M3 Pro    |         48000000.00 |
-- | 2023-10-01  | MacBook Pro 14 M3 Pro    |         48000000.00 |
-- | 2023-11-01  | Dell XPS 15 9530         |         41500000.00 |
-- | 2023-12-01  | iPhone 15 Pro Max 256GB  |         32000000.00 |
-- | 2024-01-01  | Samsung Galaxy S24 Ultra |         29990000.00 |
-- | 2024-02-01  | iPhone 15 Pro Max 256GB  |         60800000.00 |
-- +-------------+--------------------------+---------------------+
-- (6 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 2 (TIME-SERIES WINDOW): KHOẢNG CÁCH NGÀY GIỮA 2 LẦN MUA HÀNG LIÊN TIẾP
-- ==============================================================================
-- YÊU CẦU:
--   Với mỗi khách hàng phát sinh đơn hàng, tính số ngày đã trôi qua kể từ đơn hàng liền trước của chính khách hàng đó.
--   Nếu là đơn hàng đầu tiên của họ, hiển thị là NULL.
--   Sắp xếp theo customer_id, order_date ASC.
--
-- GỢI Ý: Dùng LAG(order_date, 1) OVER (PARTITION BY customer_id ORDER BY order_date ASC).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +----------+-------------+---------------------+---------------------+---------------------------+
-- | order_id | customer_id | order_date          | prev_order_date     | days_since_previous_order |
-- +----------+-------------+---------------------+---------------------+---------------------------+
-- | 1001     | 1           | 2023-09-01 10:15:00 | NULL                |                      NULL |
-- | 1004     | 1           | 2023-09-12 16:45:00 | 2023-09-01 10:15:00 |                      11.3 |
-- | 1011     | 1           | 2023-11-15 12:15:00 | 2023-09-12 16:45:00 |                      63.8 |
-- | 1016     | 1           | 2024-01-05 09:30:00 | 2023-11-15 12:15:00 |                      50.9 |
-- | 1002     | 2           | 2023-09-02 14:20:00 | NULL                |                      NULL |
-- | 1007     | 2           | 2023-10-10 17:10:00 | 2023-09-02 14:20:00 |                      38.1 |
-- | 1015     | 2           | 2023-12-24 20:10:00 | 2023-10-10 17:10:00 |                      75.1 |
-- | 1003     | 3           | 2023-09-05 09:00:00 | NULL                |                      NULL |
-- | 1010     | 3           | 2023-11-01 10:00:00 | 2023-09-05 09:00:00 |                      57.0 |
-- | 1020     | 3           | 2024-02-14 15:00:00 | 2023-11-01 10:00:00 |                     105.2 |
-- | ...      | ...         | ...                 | ...                 |                       ... |
-- +----------+-------------+---------------------+---------------------+---------------------------+
-- (20 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 3 (WINDOW FRAMING): TÍNH TỔNG DOANH THU LŨY KẾ THEO DANH MỤC
-- ==============================================================================
-- YÊU CẦU:
--   Tính doanh thu tích lũy tăng dần (Running Total) theo thời gian cho TỪNG DANH MỤC SẢN PHẨM RIÊNG BIỆT.
--   Hiển thị order_id, order_date, category_name, product_name, line_amount, category_running_total.
--   Sắp xếp theo category_name, order_date ASC.
--
-- GỢI Ý: Dùng SUM(line_amount) OVER (PARTITION BY category_name ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +----------+---------------------+---------------------+---------------------------+-------------+------------------------+
-- | order_id | order_date          | category_name       | product_name              | line_amount | category_running_total |
-- +----------+---------------------+---------------------+---------------------------+-------------+------------------------+
-- | 1001     | 2023-09-01 10:15:00 | Audio & Accessories | AirPods Pro 2 USB-C       |  5690500.00 |             5690500.00 |
-- | 1003     | 2023-09-05 09:00:00 | Audio & Accessories | Sony WH-1000XM5 Headphone |  7641000.00 |            13331500.00 |
-- | 1006     | 2023-10-01 08:20:00 | Audio & Accessories | Sony WH-1000XM5 Headphone |  8065500.00 |            21397000.00 |
-- | 1007     | 2023-10-10 17:10:00 | Audio & Accessories | AirPods Pro 2 USB-C       | 11980000.00 |            33377000.00 |
-- | 1009     | 2023-10-20 19:40:00 | Audio & Accessories | AirPods Pro 2 USB-C       |  5990000.00 |            39367000.00 |
-- | 1015     | 2023-12-24 20:10:00 | Audio & Accessories | Sony WH-1000XM5 Headphone |  8490000.00 |            47857000.00 |
-- | ...      | ...                 | ...                 | ...                       |         ... |                    ... |
-- +----------+---------------------+---------------------+---------------------------+-------------+------------------------+

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:




-- ==============================================================================
-- BÀI TẬP 4 (DA METRICS): TỶ LỆ KHÁCH HÀNG MUA HÀNG LẶP LẠI (REPEAT PURCHASE RATE)
-- ==============================================================================
-- YÊU CẦU:
--   Tính tỷ lệ khách hàng mua hàng lặp lại (Repeat Purchase Rate %):
--   Công thức: (Số lượng khách hàng có >= 2 đơn Completed / Tổng số khách hàng có ít nhất 1 đơn Completed) * 100%.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------------------+---------------+--------------------------+
-- | total_buying_customers | repeat_buyers | repeat_purchase_rate_pct |
-- +------------------------+---------------+--------------------------+
-- |                      8 |             5 |                    62.50 |
-- +------------------------+---------------+--------------------------+
-- (1 row)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:
