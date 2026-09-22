-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER (KỸ THUẬT HỆ THỐNG CSDL)
-- BÀI GIẢNG 01: DATA DEFINITION LANGUAGE (DDL), RÀNG BUỘC TOÀN VẸN VÀ GENERATED COLUMNS
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Vai trò của Ràng buộc toàn vẹn (Integrity Constraints) trong việc bảo vệ dữ liệu.
--   2. Giải phẫu chi tiết: PRIMARY KEY, UNIQUE, NOT NULL, CHECK CONSTRAINTS.
--   3. Các chiến lược xóa khóa ngoại (Foreign Key Referential Actions: CASCADE, RESTRICT, SET NULL).
--   4. Cột tự động tính toán lưu trữ vật lý (Generated Stored Columns).
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Tạo cấu trúc bảng và để database tự chặn dữ liệu không hợp lệ.
-- CÂU LỆNH: CREATE TABLE (tạo bảng), PRIMARY KEY/UNIQUE/NOT NULL/CHECK (ràng buộc),
-- FOREIGN KEY (khóa ngoại), DEFAULT (giá trị mặc định), GENERATED (cột tự tính), DROP TABLE.
-- ⭐ MỨC ĐỘ DÙNG: CREATE TABLE và constraint thường xuyên với DE; GENERATED nâng cao.
-- 🔒 AN TOÀN: DROP TABLE xóa bảng và dữ liệu trong đó. File chỉ dùng bảng `example_*`.
-- 🧠 CẦN NHỚ: Constraint bảo vệ dữ liệu ở database, không chỉ ở giao diện ứng dụng.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢN CHẤT CỦA CÁC RÀNG BUỘC TOÀN VẸN (DATABASE INTEGRITY)
-- ------------------------------------------------------------------------------
-- 💡 NGUYÊN TẮC CỦA DATA ENGINEER:
-- "Rác ở tầng Database sẽ tạo ra thảm họa ở tầng Analytics & Machine Learning."
-- Các ràng buộc DDL là chốt chặn cuối cùng ngăn chặn dữ liệu bẩn xâm nhập vào hệ thống
-- ngay cả khi code backend của ứng dụng bị bug!

DROP TABLE IF EXISTS example_order_items CASCADE;
DROP TABLE IF EXISTS example_orders CASCADE;
DROP TABLE IF EXISTS example_users CASCADE;

-- 1.1 Tạo bảng Người dùng với CHECK Constraint bảo vệ logic nghiệp vụ
CREATE TABLE example_users (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Khóa chính tự tăng chuẩn SQL:2008
    username VARCHAR(50) NOT NULL UNIQUE,                -- Chống trùng lặp tài khoản
    email VARCHAR(100) NOT NULL UNIQUE,
    age INT CHECK (age >= 18 AND age <= 120),             -- Ràng buộc tuổi hợp lệ
    balance NUMERIC(12, 2) DEFAULT 0.00 CHECK (balance >= 0), -- Số dư tài khoản không được âm
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------------------------
-- 2. HÀNH VI XÓA KHÓA NGOẠI (FOREIGN KEY DELETION ACTIONS)
-- ------------------------------------------------------------------------------
-- ┌─────────────────────┬────────────────────────────────────────────────────────┐
-- │ Hành vi             │ Cơ chế xử lý khi Dòng Cha bị XÓA                       │
-- ├─────────────────────┼────────────────────────────────────────────────────────┤
-- │ ON DELETE RESTRICT  │ Chặn đứng (Throw Error) không cho xóa Cha nếu còn Con. │
-- │ ON DELETE CASCADE   │ Tự động XÓA TOÀN BỘ Con theo Cha (Cực kỳ nguy hiểm!).  │
-- │ ON DELETE SET NULL  │ Giữ lại Con nhưng gán giá trị khóa ngoại về NULL.      │
-- └─────────────────────┴────────────────────────────────────────────────────────┘

CREATE TABLE example_orders (
    order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    order_status VARCHAR(20) DEFAULT 'Pending' CHECK (order_status IN ('Pending', 'Processing', 'Completed', 'Cancelled')),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_orders_user 
        FOREIGN KEY (user_id) 
        REFERENCES example_users(user_id) 
        ON DELETE RESTRICT -- An toàn nhất cho hệ thống Tài chính / E-commerce
);


-- ------------------------------------------------------------------------------
-- 3. GENERATED COLUMNS (CỘT TỰ ĐỘNG TÍNH TOÁN LƯU TRỮ VẬT LÝ)
-- ------------------------------------------------------------------------------
-- `GENERATED ALWAYS AS (expr) STORED` giúp Database tự động tính toán giá trị từ các cột khác
-- và ghi trực tiếp xuống đĩa. Mỗi khi `quantity` hoặc `unit_price` thay đổi, `final_amount`
-- sẽ tự động cập nhật mà KHÔNG CẦN viết Trigger hay can thiệp code ứng dụng!

CREATE TABLE example_order_items (
    item_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INT NOT NULL REFERENCES example_orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    discount_rate NUMERIC(5, 2) DEFAULT 0.00 CHECK (discount_rate BETWEEN 0.00 AND 1.00),
    
    -- Cột tính toán tự động lưu trữ trên đĩa:
    final_amount NUMERIC(12, 2) GENERATED ALWAYS AS (
        quantity * unit_price * (1.00 - discount_rate)
    ) STORED
);
