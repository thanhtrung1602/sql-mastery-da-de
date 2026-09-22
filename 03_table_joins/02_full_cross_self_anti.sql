-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 03: TABLE JOINS
-- BÀI GIẢNG 02: FULL OUTER, CROSS JOIN, SELF JOIN, SEMI-JOIN VÀ ANTI-JOIN
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. FULL OUTER JOIN: Hợp nhất và đối soát dữ liệu 2 chiều.
--   2. CROSS JOIN (Tích Descartes): Sinh tổ hợp ma trận phân tích & Rủi ro bùng nổ dữ liệu.
--   3. SELF JOIN (Tự kết nối): Mô hình hóa cây cấp bậc phân cấp (Hierarchical Tree).
--   4. SEMI-JOIN (Bán kết nối với EXISTS): Kiểm tra sự tồn tại không làm nhân bản số dòng.
--   5. ANTI-JOIN (Phản kết nối): Kỹ thuật tìm kiếm các bản ghi KHÔNG TỒN TẠI chuẩn mực.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Nhận biết các kiểu ghép ít gặp hơn và chọn đúng theo câu hỏi nghiệp vụ.
-- CÂU LỆNH: FULL OUTER JOIN (giữ cả hai bên), CROSS JOIN (mọi tổ hợp), SELF JOIN
-- (bảng ghép chính nó), EXISTS/NOT EXISTS (có/chưa có dòng liên quan).
-- ⭐ MỨC ĐỘ DÙNG: EXISTS thường xuyên; FULL/SELF JOIN thỉnh thoảng; CROSS JOIN cần cẩn trọng.
-- 🧠 CẦN NHỚ: CROSS JOIN có số dòng = số dòng A × số dòng B. Chỉ dùng khi thật sự muốn
-- tạo mọi tổ hợp, ví dụ lịch ngày × danh sách sản phẩm.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. FULL OUTER JOIN (ĐỐI SOÁT DỮ LIỆU 2 CHIỀU)
-- ------------------------------------------------------------------------------
-- Giữ lại TẤT CẢ các dòng từ CẢ HAI BẢNG.
--   - Dòng nào khớp -> Ghép nối bình thường.
--   - Dòng nào chỉ có ở bảng Trái -> Điền NULL cho cột bảng Phải.
--   - Dòng nào chỉ có ở bảng Phải -> Điền NULL cho cột bảng Trái.

-- 🎯 BÀI TOÁN ĐỐI SOÁT: Tìm tất cả danh mục và sản phẩm (Bao gồm danh mục chưa có SP, và SP chưa gắn danh mục)
SELECT 
    c.category_id,
    c.category_name,
    p.product_id,
    p.product_name
FROM categories c
FULL OUTER JOIN products p ON c.category_id = p.category_id;


-- ------------------------------------------------------------------------------
-- 2. CROSS JOIN (TÍCH DESCARTES - CARTESIAN PRODUCT)
-- ------------------------------------------------------------------------------
-- Ghép MỖI dòng của bảng A với TẤT CẢ các dòng của bảng B -> Kết quả trả về $M \times N$ dòng.
-- ⚠️ CẢNH BÁO CHO DATA ENGINEER: Nếu bảng A có 10,000 dòng và bảng B có 10,000 dòng,
-- CROSS JOIN sẽ sinh ra 100,000,000 dòng -> Có thể làm tràn bộ nhớ và sập CSDL nếu không có LIMIT!

-- 🎯 ỨNG DỤNG HỢP LỆ: Tạo khung ma trận phân tích đầy đủ theo (Thành phố $\times$ Danh mục sản phẩm)
SELECT 
    cities.city,
    cats.category_name
FROM (SELECT DISTINCT city FROM customers) cities
CROSS JOIN (SELECT DISTINCT category_name FROM categories WHERE is_active = TRUE) cats
ORDER BY cities.city, cats.category_name;


-- ------------------------------------------------------------------------------
-- 3. SELF JOIN (TỰ KẾT NỐI VỚI CHÍNH NÓ)
-- ------------------------------------------------------------------------------
-- Dùng khi một bảng có quan hệ đệ quy (Recursive Relationship) trỏ tới chính nó.
-- Ví dụ: Bảng nhân viên `employees` có cột `manager_id` trỏ tới `employee_id` của cấp trên.

SELECT 
    emp.employee_id,
    emp.first_name || ' ' || emp.last_name AS ten_nhan_vien,
    emp.department AS phong_ban,
    COALESCE(mgr.first_name || ' ' || mgr.last_name, '== LÃNH ĐẠO CẤP CAO / KHÔNG CÓ SẾP ==') AS ten_quan_ly_truc_tiep
FROM employees emp
LEFT JOIN employees mgr ON emp.manager_id = mgr.employee_id
ORDER BY emp.employee_id;


-- ------------------------------------------------------------------------------
-- 4. SEMI-JOIN (BÁN KẾT NỐI VỚI EXISTS)
-- ------------------------------------------------------------------------------
-- 🎯 BÀI TOÁN: Tìm các khách hàng ĐÃ TỪNG đặt ít nhất 1 đơn hàng thành công.
-- ⚠️ NẾU DÙNG INNER JOIN: Khách hàng mua 10 đơn sẽ bị lặp lại 10 lần (Duplication). Phải tốn công dùng DISTINCT để khử trùng.
-- 💡 GIẢI PHÁP VƯỢT TRỘI: Dùng SEMI-JOIN với mệnh đề `EXISTS`.
-- Cơ chế: Database kiểm tra bảng phụ, ngay khi tìm thấy 1 dòng khớp đầu tiên, nó lập tức DỪNG LẠI (Early Termination)
-- và trả về dòng của bảng chính -> Không bao giờ làm nhân bản số dòng!

SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id 
      AND o.order_status = 'Completed'
);


-- ------------------------------------------------------------------------------
-- 5. ANTI-JOIN (PHẢN KẾT NỐI - TÌM NHỮNG GÌ KHÔNG TỒN TẠI)
-- ------------------------------------------------------------------------------
-- 🎯 BÀI TOÁN: Tìm những khách hàng ĐÃ ĐĂNG KÝ nhưng CHƯA TỪNG mua bất kỳ đơn hàng nào.

-- ✅ CÁCH 1 (KHUYÊN DÙNG NHẤT): Dùng NOT EXISTS (Hiệu năng cực cao và miễn nhiễm với NULL)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.signup_date
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- ✅ CÁCH 2: Dùng LEFT JOIN ... WHERE right_table.key IS NULL
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.signup_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
