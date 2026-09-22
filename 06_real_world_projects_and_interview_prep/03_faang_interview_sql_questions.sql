-- ==============================================================================
-- FOLDER 06: REAL-WORLD PROJECTS & INTERVIEW PREPARATION
-- FILE: 03_faang_interview_sql_questions.sql
-- MỤC TIÊU:
--   Tuyển tập 5 câu hỏi phỏng vấn SQL kinh điển chuẩn FAANG / Top Tech Companies
--   (Meta, Google, Amazon, Uber, Netflix) với lời giải chi tiết và phân tích độ phức tạp.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH DÙNG FILE NÀY: Mỗi câu có lời giải ngay dưới đề. Hãy che phần "LỜI GIẢI"
-- để tự làm trước. Khi đối chiếu, đọc phần "một dòng kết quả đại diện cho gì" và các
-- chú thích theo thứ tự FROM → WHERE → GROUP BY/OVER → SELECT. Đây là bài luyện tổng hợp,
-- không phải danh sách cú pháp cần học thuộc lòng.
-- ==============================================================================

-- ==============================================================================
-- CÂU HỎI 1: TÌM MỨC LƯƠNG CAO THỨ N (NTH HIGHEST SALARY) - Chuẩn Google / Meta
-- ==============================================================================
-- Đề bài: Viết truy vấn tìm mức lương cao thứ 2 trong công ty từ bảng employees.
-- Yêu cầu: Nếu không có mức lương thứ 2, trả về NULL. Phải xử lý trường hợp có nhiều người trùng lương.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------------------+
-- | second_highest_salary  |
-- +------------------------+
-- |            75000000.00 |
-- +------------------------+
-- (1 row)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI VÀ CÁCH ĐỌC:
-- Một dòng của ranked_salaries vẫn là một nhân viên. DENSE_RANK gán cùng hạng cho các mức
-- lương bằng nhau, vì bài hỏi mức lương cao thứ 2 chứ không hỏi nhân viên đứng thứ 2.
WITH ranked_salaries AS (
    SELECT
        salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS salary_rank
    FROM employees
)
SELECT
    MAX(salary) FILTER (WHERE salary_rank = 2) AS second_highest_salary
FROM ranked_salaries;
-- 💡 Nếu không có hạng 2, FILTER không có giá trị nào để MAX tính và trả về NULL đúng yêu cầu.
-- 🧠 CẦN NHỚ: ROW_NUMBER sẽ coi hai nhân viên trùng lương là hai vị trí; DENSE_RANK thì không.




-- ==============================================================================
-- CÂU HỎI 2: CHUỖI NGÀY HOẠT ĐỘNG LIÊN TIẾP (CONSECUTIVE ACTIVE DAYS) - Chuẩn Spotify / Duolingo
-- ==============================================================================
-- Đề bài: Tìm tất cả khách hàng đã phát sinh sự kiện trong ít nhất 3 ngày LIÊN TIẾP từ bảng web_events.
-- Kỹ thuật gợi ý: Kỹ thuật Gaps and Islands (Hòn đảo và Khoảng trống) với ROW_NUMBER().
-- Hiển thị: customer_id, streak_start_date, streak_end_date, consecutive_days_count.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI FORMAT (EXPECTED OUTPUT):
-- +-------------+-------------------+-----------------+------------------------+
-- | customer_id | streak_start_date | streak_end_date | consecutive_days_count |
-- +-------------+-------------------+-----------------+------------------------+
-- | ...         | ...               | ...             | ...                    |
-- +-------------+-------------------+-----------------+------------------------+

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI VÀ CÁCH ĐỌC:
-- active_days bỏ các event trùng ngày: một khách có 10 click trong ngày vẫn chỉ là 1 ngày hoạt động.
WITH active_days AS (
    SELECT DISTINCT
        customer_id,
        event_time::DATE AS active_day
    FROM web_events
    WHERE customer_id IS NOT NULL
),
numbered_days AS (
    SELECT
        customer_id,
        active_day,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY active_day) AS day_number
    FROM active_days
),
islands AS (
    SELECT
        customer_id,
        active_day,
        active_day - day_number::INT AS island_key
    FROM numbered_days
)
SELECT
    customer_id,
    MIN(active_day) AS streak_start_date,
    MAX(active_day) AS streak_end_date,
    COUNT(*) AS consecutive_days_count
FROM islands
GROUP BY customer_id, island_key
HAVING COUNT(*) >= 3
ORDER BY customer_id, streak_start_date;
-- 💡 TẠI SAO trừ ROW_NUMBER: với các ngày liên tiếp, cả ngày và số thứ tự cùng tăng 1,
-- nên hiệu luôn giống nhau. Hiệu đó trở thành nhãn của một "hòn đảo" ngày liên tiếp.




-- ==============================================================================
-- CÂU HỎI 3: PHÂN LOẠI NÚT TRONG CÂY CẤP BẬC (TREE NODE CLASSIFICATION) - Chuẩn Amazon / Uber
-- ==============================================================================
-- Đề bài: Cho bảng cây quan hệ employees (employee_id, manager_id). Phân loại từng nhân viên thành một trong 3 loại:
--   - 'Root (C-Level Executive)': Nhân viên cấp cao nhất (Không có Quản lý).
--   - 'Inner (People Manager)': Quản lý trung gian (Vừa có Quản lý, vừa quản lý nhân viên khác).
--   - 'Leaf (Individual Contributor)': Nhân viên cấp dưới cùng (Không quản lý bất kỳ ai).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------+------------------+---------------------------------+
-- | employee_id | employee_name    | employee_org_node_type          |
-- +-------------+------------------+---------------------------------+
-- | 1           | Tran Tung Lam    | Root (C-Level Executive)        |
-- | 2           | Nguyen Hoang Nam | Inner (People Manager)          |
-- | 3           | Le Thu Thao      | Inner (People Manager)          |
-- | 4           | Pham Duc Thang   | Inner (People Manager)          |
-- | 5           | Vu Quang Huy     | Leaf (Individual Contributor)   |
-- | 6           | Doan My Linh     | Leaf (Individual Contributor)   |
-- | 7           | Ho Bao Ngoc      | Leaf (Individual Contributor)   |
-- | 8           | Dang Minh Tri    | Leaf (Individual Contributor)   |
-- +-------------+------------------+---------------------------------+
-- (8 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI VÀ CÁCH ĐỌC: mỗi dòng e là một nhân viên. Truy vấn con EXISTS chỉ kiểm tra
-- có cấp dưới hay không, không ghép thêm dòng nên không làm nhân bản nhân viên quản lý.
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    CASE
        WHEN e.manager_id IS NULL THEN 'Root (C-Level Executive)'
        WHEN EXISTS (
            SELECT 1
            FROM employees AS report
            WHERE report.manager_id = e.employee_id
        ) THEN 'Inner (People Manager)'
        ELSE 'Leaf (Individual Contributor)'
    END AS employee_org_node_type
FROM employees AS e
ORDER BY e.employee_id;
-- 🧠 CẦN NHỚ: Đặt nhánh Root trước vì cấp cao nhất có thể cũng quản lý người khác.




-- ==============================================================================
-- CÂU HỎI 4: TỶ LỆ HỦY ĐƠN HÀNG HÀNG NGÀY CỦA NGƯỜI DÙNG HỢP LỆ (TRIPS & USERS) - Chuẩn Uber
-- ==============================================================================
-- Đề bài: Tính tỷ lệ hủy đơn (Cancellation Rate) theo từng ngày của các đơn hàng
-- phát sinh từ những khách hàng KHÔNG BỊ KHÓA (customer_segment <> 'Banned').
-- Làm tròn kết quả đến 2 chữ số thập phân.
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +------------+----------------+--------------------+-------------------+
-- | order_day  | total_requests | cancelled_requests | cancellation_rate |
-- +------------+----------------+--------------------+-------------------+
-- | 2023-09-01 |              1 |                  0 |              0.00 |
-- | 2023-09-02 |              1 |                  0 |              0.00 |
-- | 2023-09-05 |              1 |                  0 |              0.00 |
-- | 2023-09-12 |              1 |                  0 |              0.00 |
-- | 2023-09-15 |              1 |                  1 |              1.00 |
-- | ...        |            ... |                ... |               ... |
-- +------------+----------------+--------------------+-------------------+

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI VÀ CÁCH ĐỌC: một dòng kết quả là một ngày. WHERE loại khách bị khóa trước
-- khi đếm; FILTER chỉ đếm các đơn Cancelled trong cùng nhóm ngày, không loại các đơn hợp lệ khác.
SELECT
    o.order_date::DATE AS order_day,
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE o.order_status = 'Cancelled') AS cancelled_requests,
    ROUND(
        COUNT(*) FILTER (WHERE o.order_status = 'Cancelled') * 1.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE c.customer_segment IS DISTINCT FROM 'Banned'
GROUP BY o.order_date::DATE
ORDER BY order_day;
-- 💡 `IS DISTINCT FROM` coi NULL là "khác Banned", nên không vô tình bỏ khách chưa có segment.




-- ==============================================================================
-- CÂU HỎI 5: TÍNH TRUNG VỊ MỨC LƯƠNG CỦA TỪNG PHÒNG BAN KHÔNG DÙNG HÀM BUILT-IN - Chuẩn LinkedIn
-- ==============================================================================
-- Đề bài: Tính mức lương Median cho mỗi phòng ban bằng thuần túy Window Functions và toán học (không dùng PERCENTILE_CONT).
--
-- KẾT QUẢ ĐẦU RA MONG ĐỢI (EXPECTED OUTPUT):
-- +-------------------+--------------------+
-- | department        | dept_median_salary |
-- +-------------------+--------------------+
-- | Engineering       |        41500000.00 |
-- | Executive         |       120000000.00 |
-- | Sales & Marketing |        30000000.00 |
-- +-------------------+--------------------+
-- (3 rows)

-- VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:

-- LỜI GIẢI VÀ CÁCH ĐỌC: ranked_employees vẫn giữ một dòng cho mỗi nhân viên. Hai cửa sổ
-- tính thứ tự và tổng số người TRONG TỪNG phòng; truy vấn ngoài chỉ lấy vị trí giữa rồi AVG.
WITH ranked_employees AS (
    SELECT
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary) AS salary_position,
        COUNT(*) OVER (PARTITION BY department) AS department_size
    FROM employees
    WHERE department IS NOT NULL
)
SELECT
    department,
    AVG(salary) FILTER (
        WHERE salary_position IN ((department_size + 1) / 2, (department_size + 2) / 2)
    ) AS dept_median_salary
FROM ranked_employees
GROUP BY department
ORDER BY department;
-- 💡 Phòng có số người lẻ: hai công thức cùng chỉ một vị trí giữa. Số người chẵn: chúng chỉ
-- hai vị trí giữa và AVG lấy trung bình của chúng. Không dùng PERCENTILE_CONT.
