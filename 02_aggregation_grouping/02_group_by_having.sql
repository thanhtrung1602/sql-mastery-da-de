-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 02: AGGREGATION & GROUPING
-- BÀI GIẢNG 02: BẢN CHẤT GOM NHÓM (GROUP BY), LỌC NHÓM (HAVING) VÀ KHỐI ĐA CHIỀU OLAP
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Thứ tự thực thi Logical 7 bước của một câu lệnh SQL chuẩn mực.
--   2. Cơ chế băm gom nhóm (Hash Aggregate) vs Sắp xếp gom nhóm (Group Aggregate).
--   3. Phân biệt bản chất: Lọc tiền gom nhóm (WHERE) vs Lọc hậu gom nhóm (HAVING).
--   4. Khối đa chiều OLAP cho Business Intelligence: ROLLUP, CUBE và GROUPING SETS.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Tạo báo cáo "một dòng cho mỗi nhóm", ví dụ doanh thu theo thành phố.
-- CÂU LỆNH: GROUP BY (chia nhóm), HAVING (lọc nhóm), WHERE (lọc dòng trước nhóm),
-- GROUPING SETS/ROLLUP/CUBE (tạo nhiều cấp tổng hợp).
-- ⭐ MỨC ĐỘ DÙNG: GROUP BY, HAVING rất thường xuyên; ROLLUP/CUBE dùng cho báo cáo nâng cao.
-- 🧠 CẦN NHỚ: Sau GROUP BY, SELECT chỉ được chứa cột dùng để nhóm hoặc một hàm tổng hợp.
-- WHERE trước GROUP BY; HAVING sau GROUP BY.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. THỨ TỰ THỰC THI LOGICAL 7 BƯỚC CỦA SQL ENGINE
-- ------------------------------------------------------------------------------
-- Hiểu rõ thứ tự này là chìa khóa để không bao giờ mắc lỗi cú pháp trong SQL:
--
--   ┌────────────────────────────────────────────────────────────────────────┐
--   │ BƯỚC 1: FROM & JOIN     ──> Xác định tập dữ liệu nguồn & kết nối bảng   │
--   │ BƯỚC 2: WHERE           ──> Lọc từng dòng đơn lẻ trước khi gom nhóm     │
--   │ BƯỚC 3: GROUP BY        ──> Phân chia dữ liệu thành các nhóm độc lập    │
--   │ BƯỚC 4: HAVING          ──> Lọc các nhóm dựa trên kết quả tính tổng hợp │
--   │ BƯỚC 5: SELECT          ──> Chiếu các cột, tính toán biểu thức & alias  │
--   │ BƯỚC 6: ORDER BY        ──> Sắp xếp tập kết quả cuối cùng              │
--   │ BƯỚC 7: LIMIT / OFFSET  ──> Cắt lấy số lượng dòng chỉ định              │
--   └────────────────────────────────────────────────────────────────────────┘
--
-- 💡 HỆ QUẢ LOGIC QUAN TRỌNG:
-- - Không thể dùng Alias đặt trong SELECT ở mệnh đề WHERE hoặc GROUP BY (Vì SELECT chạy sau).
-- - Không thể dùng Hàm tổng hợp (như SUM, COUNT) trong mệnh đề WHERE (Vì WHERE chạy trước GROUP BY).


-- ------------------------------------------------------------------------------
-- 2. GOM NHÓM ĐƠN CỘT VÀ ĐA CỘT VỚI GROUP BY
-- ------------------------------------------------------------------------------

-- 2.1 Gom nhóm đơn cột: Đếm số khách hàng và số khách VIP theo Thành phố
SELECT 
    city,
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN customer_segment = 'VIP' THEN 1 END) AS total_vip_customers
FROM customers
GROUP BY city
ORDER BY total_customers DESC;

-- 2.2 Gom nhóm đa cột: Phân tích số lượng đơn theo (Thành phố giao hàng + Phương thức thanh toán)
SELECT 
    shipping_city,
    payment_method,
    COUNT(order_id) AS order_count,
    ROUND(AVG(shipping_fee), 2) AS avg_shipping_fee
FROM orders
GROUP BY shipping_city, payment_method
ORDER BY shipping_city, order_count DESC;


-- ------------------------------------------------------------------------------
-- 3. PHÂN BIỆT RẠCH RÒI: WHERE VS HAVING
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬──────────────────────────────────┬─────────────────────────────────┐
-- │ Tiêu chí        │ WHERE                            │ HAVING                          │
-- ├─────────────────┼──────────────────────────────────┼─────────────────────────────────┤
-- │ Thời điểm chạy  │ TRƯỚC khi gom nhóm (Bước 2)       │ SAU khi đã gom nhóm (Bước 4)    │
-- │ Đối tượng lọc   │ Từng dòng dữ liệu riêng lẻ        │ Cả một nhóm dữ liệu             │
-- │ Hàm tổng hợp    │ TUYỆT ĐỐI KHÔNG ĐƯỢC CHỨA        │ ĐƯỢC CHỨA (COUNT, SUM, AVG...)  │
-- │ Hiệu năng       │ Rất nhanh (Giảm bớt dòng gom)    │ Chậm hơn (Phải gom xong mới lọc)│
-- └─────────────────┴──────────────────────────────────┴─────────────────────────────────┘

-- 🎯 BÀI TOÁN: Tìm các thành phố tại Việt Nam có từ 2 khách hàng trở lên:
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
WHERE country = 'Vietnam' -- Lọc trước: Loại bỏ khách nước ngoài ngay từ đầu để giảm tải gom nhóm
GROUP BY city
HAVING COUNT(*) >= 2      -- Lọc sau: Chỉ giữ lại các nhóm thành phố có từ 2 người trở lên
ORDER BY customer_count DESC;


-- ------------------------------------------------------------------------------
-- 4. KHỐI ĐA CHIỀU OLAP CHO DATA ANALYST / BI (ROLLUP, CUBE, GROUPING SETS)
-- ------------------------------------------------------------------------------

-- 4.1 ROLLUP: Tạo báo cáo phân cấp cha-con (Subtotals & Grand Total)
-- Ứng dụng: Báo cáo quỹ lương theo (Phòng ban -> Quản lý) và dòng Tổng kết công ty
SELECT 
    department,
    manager_id,
    SUM(salary) AS total_payroll,
    COUNT(employee_id) AS headcount,
    GROUPING(department) AS is_dept_subtotal, -- Trả về 1 nếu là dòng tổng gộp của department
    GROUPING(manager_id) AS is_mgr_subtotal
FROM employees
GROUP BY ROLLUP(department, manager_id)
ORDER BY department, manager_id;

-- 4.2 CUBE: Tạo TẤT CẢ các tổ hợp gom nhóm có thể có ($2^N$ góc nhìn đa chiều)
SELECT 
    customer_segment,
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY CUBE(customer_segment, city)
ORDER BY customer_segment, city;

-- 4.3 GROUPING SETS: Chỉ định chính xác các tập gom nhóm tùy biến
SELECT 
    customer_segment,
    city,
    COUNT(*) AS total_users
FROM customers
GROUP BY GROUPING SETS (
    (customer_segment), -- Tổng theo Phân khúc
    (city),             -- Tổng theo Thành phố
    ()                  -- Grand Total toàn bộ
)
ORDER BY customer_segment, city;
