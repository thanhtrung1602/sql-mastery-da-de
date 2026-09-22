-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 03: TABLE JOINS
-- BÀI GIẢNG 03: CÁC PHÉP TOÁN TẬP HỢP: UNION, UNION ALL, INTERSECT VÀ EXCEPT
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Bản chất toán học của Phép toán tập hợp (Set Operations theo chiều dọc - Vertical Append).
--   2. Phân tích chi phí hiệu năng: UNION (Sort Unique Overhead) vs UNION ALL ($O(N)$ Streams).
--   3. Phép Giao (INTERSECT) và Phép Hiệu (EXCEPT / MINUS).
--   4. Các quy tắc vàng về khớp kiểu dữ liệu và thứ tự cột.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Ghép dọc các tập kết quả, thay vì ghép ngang cột như JOIN.
-- CÂU LỆNH: UNION (gộp và bỏ trùng), UNION ALL (gộp, giữ trùng), INTERSECT (phần chung),
-- EXCEPT (phần chỉ ở truy vấn đầu).
-- ⭐ MỨC ĐỘ DÙNG: UNION ALL thường xuyên trong ETL; UNION/INTERSECT/EXCEPT thỉnh thoảng.
-- 🧠 CẦN NHỚ: Mỗi SELECT phải có cùng số cột theo cùng thứ tự và các kiểu tương thích.
-- ORDER BY/LIMIT cho toàn bộ kết quả phải đặt ở cuối, không đặt vào từng nhánh.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢN CHẤT CỦA SET OPERATIONS: NỐI DỌC VS NỐI NGANG (JOIN)
-- ------------------------------------------------------------------------------
-- - JOIN : Kết hợp các bảng theo CHIỀU NGANG (Mở rộng thêm các cột thuộc tính).
-- - SET  : Kết hợp các bảng theo CHIỀU DỌC (Chồng thêm các dòng dữ liệu vào cùng cấu trúc cột).
--
--   ┌─────────────────┐       ┌─────────────────┐
--   │ Bảng A (3 dòng) │   +   │ Bảng B (2 dòng) │  ───(UNION ALL)───> Kết quả: 5 dòng
--   └─────────────────┘       └─────────────────┘


-- ------------------------------------------------------------------------------
-- 2. SO SÁNH HIỆU NĂNG: UNION VS UNION ALL
-- ------------------------------------------------------------------------------
-- ┌───────────────┬──────────────────────────────────┬─────────────────────────────────┐
-- │ Tiêu chí      │ UNION ALL                        │ UNION                           │
-- ├───────────────┼──────────────────────────────────┼─────────────────────────────────┤
-- │ Khử trùng lặp │ KHÔNG lọc trùng (Giữ nguyên vẹn)  │ CÓ lọc trùng (Chỉ giữ dòng duy nhất)│
-- │ Cơ chế        │ Ghép luồng trực tiếp (Streaming) │ Thực hiện Unique Sort / Hash in RAM │
-- │ Tốc độ        │ CỰC NHANH $O(N)$                 │ CHẬM $O(N \log N)$              │
-- │ Bộ nhớ        │ Tiêu tốn cực ít RAM              │ Dễ bị tràn `work_mem` ra đĩa    │
-- └───────────────┴──────────────────────────────────┴─────────────────────────────────┘

-- 2.1 UNION ALL (Luôn là lựa chọn ưu tiên mặc định trong Data Pipeline):
SELECT city AS location_name, 'Khách hàng sinh sống' AS source_type
FROM customers
UNION ALL
SELECT shipping_city AS location_name, 'Thành phố giao hàng' AS source_type
FROM orders;

-- 2.2 UNION (Chỉ dùng khi nghiệp vụ THỰC SỰ YÊU CẦU loại bỏ hoàn toàn các dòng trùng):
SELECT city FROM customers
UNION
SELECT shipping_city FROM orders;


-- ------------------------------------------------------------------------------
-- 3. PHÉP GIAO (INTERSECT) VÀ PHÉP HIỆU (EXCEPT)
-- ------------------------------------------------------------------------------

-- 3.1 INTERSECT: Tìm các thành phố VỪA có khách hàng sinh sống, VỪA có đơn hàng giao tới (Tập giao $A \cap B$)
SELECT city FROM customers
INTERSECT
SELECT shipping_city FROM orders;

-- 3.2 EXCEPT: Tìm các thành phố CÓ khách hàng sinh sống NHƯNG CHƯA TỪNG có đơn hàng nào giao tới ($A \setminus B$)
SELECT city FROM customers
EXCEPT
SELECT shipping_city FROM orders;


-- ------------------------------------------------------------------------------
-- 4. BỐN QUY TẮC BẤT DI BẤT DỊCH KHI VIẾT SET OPERATIONS
-- ------------------------------------------------------------------------------
-- 1. Số lượng cột ở tất cả các câu lệnh SELECT con PHẢI HOÀN TOÀN BẰNG NHAU.
-- 2. Kiểu dữ liệu của các cột ở từng vị trí tương ứng PHẢI TƯƠNG THÍCH VỚI NHAU.
-- 3. Tên cột ở tập kết quả cuối cùng LUÔN LẤY THEO TÊN CỘT CỦA CÂU LỆNH SELECT ĐẦU TIÊN.
-- 4. Mệnh đề `ORDER BY` chỉ được phép viết duy nhất 1 lần ở DÒNG CUỐI CÙNG của toàn bộ câu lệnh.

SELECT 
    customer_id AS entity_id, 
    first_name || ' ' || last_name AS entity_name, 
    'Customer' AS entity_role 
FROM customers
UNION ALL
SELECT 
    employee_id AS entity_id, 
    first_name || ' ' || last_name AS entity_name, 
    'Employee' AS entity_role 
FROM employees
ORDER BY entity_id ASC;
