-- ==============================================================================
-- SQL MASTERY FOR DATA ANALYTICS & DATA ENGINEERING
-- SCRIPT: init_database.sql (Master Database Initialization & Seed Data)
-- COMPATIBILITY: PostgreSQL 12+, DuckDB, MySQL 8+ (minor syntax adjustments)
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 DÀNH CHO NGƯỜI MỚI: File này chỉ dùng để chuẩn bị dữ liệu học. Nó tạo bảng mẫu
-- (CREATE TABLE) và nạp dữ liệu mẫu (INSERT INTO). Hãy đọc 00_huong_dan_nguoi_moi.md
-- trước nếu bạn chưa quen table/row/column hoặc cách chạy từng câu SQL.
-- 🔒 CẢNH BÁO: Các lệnh DROP TABLE ngay dưới sẽ xóa những bảng cùng tên cùng dữ liệu bên trong.
-- Chỉ chạy file này trên database thực hành, không chạy trên database công việc/production.
-- 💡 CÁCH CHẠY: Chạy toàn bộ file một lần; sau đó chạy từng bài trong thư mục 01 → 07.
-- ==============================================================================

-- ==============================================================================
-- 1. DROP EXISTING TABLES & TYPES (CLEAN RESET)
-- ==============================================================================
DROP TABLE IF EXISTS web_events CASCADE;
DROP TABLE IF EXISTS inventory_logs CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS staging_orders CASCADE;
DROP TABLE IF EXISTS dim_customers_scd2 CASCADE;
DROP TABLE IF EXISTS pipeline_audit_log CASCADE;

-- ==============================================================================
-- 2. CREATE MASTER TABLES (DDL)
-- ==============================================================================

-- 2.1 Bảng Danh mục Sản phẩm (Categories)
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT REFERENCES categories(category_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.2 Bảng Khách hàng (Customers)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    birth_date DATE,
    city VARCHAR(50),
    country VARCHAR(50) DEFAULT 'Vietnam',
    customer_segment VARCHAR(20) DEFAULT 'Standard', -- Standard, Silver, Gold, VIP
    signup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.3 Bảng Nhân viên (Employees - Hierarchical Org Structure)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50),
    manager_id INT REFERENCES employees(employee_id),
    salary NUMERIC(12, 2) NOT NULL,
    hire_date DATE NOT NULL
);

-- 2.4 Bảng Sản phẩm (Products)
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id INT REFERENCES categories(category_id),
    cost_price NUMERIC(12, 2) NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    is_discontinued BOOLEAN DEFAULT FALSE,
    specs JSONB, -- Semi-structured JSON/JSONB specs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2.5 Bảng Đơn hàng (Orders)
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(20) CHECK (order_status IN ('Pending', 'Processing', 'Completed', 'Cancelled', 'Refunded')),
    shipping_address VARCHAR(255),
    shipping_city VARCHAR(50),
    shipping_fee NUMERIC(10, 2) DEFAULT 0.00,
    payment_method VARCHAR(30) -- Credit Card, Bank Transfer, COD, E-Wallet
);

-- 2.6 Bảng Chi tiết Đơn hàng (Order Items)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL,
    discount_pct NUMERIC(5, 2) DEFAULT 0.00 -- 0.05 = 5%
);

-- 2.7 Bảng Thanh toán (Payments)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    payment_date TIMESTAMP NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    payment_status VARCHAR(20) CHECK (payment_status IN ('Success', 'Failed', 'Pending', 'Refunded')),
    transaction_ref VARCHAR(100) UNIQUE
);

-- 2.8 Bảng Nhật ký Sự kiện Web / Hành vi người dùng (Web Events - High Volume)
CREATE TABLE web_events (
    event_id BIGINT PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL,
    customer_id INT, -- NULL if guest visitor
    event_time TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- page_view, search, add_to_cart, checkout_start, purchase
    page_url VARCHAR(255),
    device_type VARCHAR(20), -- Mobile, Desktop, Tablet
    metadata JSONB
);

-- 2.9 Bảng Lịch sử Tồn kho (Inventory Logs)
CREATE TABLE inventory_logs (
    log_id INT PRIMARY KEY,
    product_id INT REFERENCES products(product_id),
    change_type VARCHAR(20), -- RESTOCK, SALE, RETURN, DAMAGE
    quantity_changed INT NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- ==============================================================================
-- 3. INSERT SEED DATA (DỮ LIỆU MẪU CHUẨN)
-- ==============================================================================

-- 3.1 Thêm Danh mục
INSERT INTO categories (category_id, category_name, parent_category_id, is_active) VALUES
(1, 'Electronics', NULL, TRUE),
(2, 'Smartphones & Tablets', 1, TRUE),
(3, 'Laptops & Computers', 1, TRUE),
(4, 'Audio & Accessories', 1, TRUE),
(5, 'Home & Living', NULL, TRUE),
(6, 'Kitchen Appliances', 5, TRUE),
(7, 'Fashion & Apparel', NULL, TRUE),
(8, 'Books & Media', NULL, FALSE);

-- 3.2 Thêm Khách hàng
INSERT INTO customers (customer_id, first_name, last_name, email, gender, birth_date, city, country, customer_segment, signup_date) VALUES
(1, 'Nguyen', 'Van An', 'an.nguyen@example.com', 'Male', '1992-05-14', 'Ho Chi Minh', 'Vietnam', 'VIP', '2023-01-10 08:30:00'),
(2, 'Tran', 'Thi Bich', 'bich.tran@example.com', 'Female', '1995-11-20', 'Hanoi', 'Vietnam', 'Gold', '2023-02-15 09:45:00'),
(3, 'Le', 'Quoc Cuong', 'cuong.le@example.com', 'Male', '1988-03-08', 'Da Nang', 'Vietnam', 'Silver', '2023-03-01 14:15:00'),
(4, 'Pham', 'Thanh Dung', 'dung.pham@example.com', 'Female', '1998-07-25', 'Ho Chi Minh', 'Vietnam', 'Standard', '2023-03-20 11:20:00'),
(5, 'Hoang', 'Minh Em', 'em.hoang@example.com', 'Male', '1990-12-30', 'Can Tho', 'Vietnam', 'Gold', '2023-04-05 16:50:00'),
(6, 'Vu', 'Thi Giang', 'giang.vu@example.com', 'Female', '2001-09-12', 'Hanoi', 'Vietnam', 'Standard', '2023-05-12 10:05:00'),
(7, 'David', 'Smith', 'david.smith@global.com', 'Male', '1985-04-18', 'Singapore', 'Singapore', 'VIP', '2023-05-25 13:40:00'),
(8, 'Do', 'Hoang Hai', 'hai.do@example.com', 'Male', '1994-01-03', 'Hai Phong', 'Vietnam', 'Silver', '2023-06-18 15:30:00'),
(9, 'Ngo', 'Ngoc Khanh', 'khanh.ngo@example.com', 'Female', '1997-08-19', 'Ho Chi Minh', 'Vietnam', 'Standard', '2023-07-01 08:00:00'),
(10, 'Bui', 'Van Lam', 'lam.bui@example.com', 'Male', '1989-10-10', 'Hanoi', 'Vietnam', 'Standard', '2023-08-10 19:25:00');

-- 3.3 Thêm Nhân viên (Hierarchy)
INSERT INTO employees (employee_id, first_name, last_name, email, department, manager_id, salary, hire_date) VALUES
(1, 'Tran', 'Tung Lam', 'ceo@company.com', 'Executive', NULL, 120000000.00, '2020-01-01'),
(2, 'Nguyen', 'Hoang Nam', 'nam.nguyen@company.com', 'Engineering', 1, 75000000.00, '2020-03-15'),
(3, 'Le', 'Thu Thao', 'thao.le@company.com', 'Sales & Marketing', 1, 70000000.00, '2020-04-01'),
(4, 'Pham', 'Duc Thang', 'thang.pham@company.com', 'Engineering', 2, 45000000.00, '2021-06-01'),
(5, 'Vu', 'Quang Huy', 'huy.vu@company.com', 'Engineering', 2, 38000000.00, '2022-01-15'),
(6, 'Doan', 'My Linh', 'linh.doan@company.com', 'Sales & Marketing', 3, 30000000.00, '2022-03-01'),
(7, 'Ho', 'Bao Ngoc', 'ngoc.ho@company.com', 'Sales & Marketing', 3, 28000000.00, '2022-08-10'),
(8, 'Dang', 'Minh Tri', 'tri.dang@company.com', 'Engineering', 4, 22000000.00, '2023-02-01');

-- 3.4 Thêm Sản phẩm
INSERT INTO products (product_id, product_name, category_id, cost_price, unit_price, stock_quantity, is_discontinued, specs) VALUES
(101, 'iPhone 15 Pro Max 256GB', 2, 26000000, 32000000, 45, FALSE, '{"color": "Natural Titanium", "ram": "8GB", "storage": "256GB", "chip": "A17 Pro", "weight_g": 221}'),
(102, 'Samsung Galaxy S24 Ultra', 2, 24000000, 29990000, 30, FALSE, '{"color": "Titanium Black", "ram": "12GB", "storage": "512GB", "chip": "Snapdragon 8 Gen 3", "stylus": true}'),
(103, 'MacBook Pro 14 M3 Pro', 3, 38000000, 48000000, 18, FALSE, '{"color": "Space Black", "ram": "18GB", "storage": "512GB", "chip": "M3 Pro", "screen_inch": 14.2}'),
(104, 'Dell XPS 15 9530', 3, 32000000, 41500000, 12, FALSE, '{"color": "Silver", "ram": "32GB", "storage": "1TB", "chip": "Intel Core i7-13700H", "gpu": "RTX 4060"}'),
(105, 'Sony WH-1000XM5 Headphone', 4, 6000000, 8490000, 60, FALSE, '{"color": "Silver", "battery_hours": 30, "noise_cancelling": true, "bluetooth": "5.2"}'),
(106, 'AirPods Pro 2 USB-C', 4, 4500000, 5990000, 85, FALSE, '{"color": "White", "battery_hours": 24, "noise_cancelling": true, "chip": "H2"}'),
(107, 'Air Fryer Philips XXL HD9650', 6, 4200000, 6290000, 25, FALSE, '{"capacity_l": 7.3, "power_w": 2225, "digital_display": true}'),
(108, 'Robot Vacuum Dreame L20 Ultra', 6, 16000000, 21900000, 15, FALSE, '{"suction_pa": 7000, "auto_empty": true, "mopping": true, "lidar": true}'),
(109, 'Vintage Leather Jacket', 7, 1200000, 2490000, 40, FALSE, '{"material": "Genuine Cow Leather", "color": "Brown", "sizes": ["M", "L", "XL"]}'),
(110, 'Outdated Android Tablet Gen 1', 2, 2000000, 2500000, 0, TRUE, '{"color": "Black", "storage": "16GB", "os": "Android 5.0"}');

-- 3.5 Thêm Đơn hàng (Orders)
INSERT INTO orders (order_id, customer_id, order_date, order_status, shipping_address, shipping_city, shipping_fee, payment_method) VALUES
(1001, 1, '2023-09-01 10:15:00', 'Completed', '123 Nguyen Hue, District 1', 'Ho Chi Minh', 30000, 'Credit Card'),
(1002, 2, '2023-09-02 14:20:00', 'Completed', '45 Trang Tien, Hoan Kiem', 'Hanoi', 40000, 'Bank Transfer'),
(1003, 3, '2023-09-05 09:00:00', 'Completed', '78 Bach Dang, Hai Chau', 'Da Nang', 35000, 'E-Wallet'),
(1004, 1, '2023-09-12 16:45:00', 'Completed', '123 Nguyen Hue, District 1', 'Ho Chi Minh', 0, 'Credit Card'),
(1005, 4, '2023-09-15 11:30:00', 'Cancelled', '99 Cong Hoa, Tan Binh', 'Ho Chi Minh', 30000, 'COD'),
(1006, 5, '2023-10-01 08:20:00', 'Completed', '12 30/4 Street, Ninh Kieu', 'Can Tho', 50000, 'Bank Transfer'),
(1007, 2, '2023-10-10 17:10:00', 'Completed', '45 Trang Tien, Hoan Kiem', 'Hanoi', 0, 'Credit Card'),
(1008, 6, '2023-10-15 13:00:00', 'Processing', '88 Cau Giay', 'Hanoi', 30000, 'COD'),
(1009, 7, '2023-10-20 19:40:00', 'Completed', '15 Orchard Road', 'Singapore', 150000, 'Credit Card'),
(1010, 3, '2023-11-01 10:00:00', 'Completed', '78 Bach Dang, Hai Chau', 'Da Nang', 35000, 'E-Wallet'),
(1011, 1, '2023-11-15 12:15:00', 'Completed', '123 Nguyen Hue, District 1', 'Ho Chi Minh', 0, 'Credit Card'),
(1012, 8, '2023-11-20 15:50:00', 'Completed', '22 Le Hong Phong, Ngo Quyen', 'Hai Phong', 40000, 'Bank Transfer'),
(1013, 9, '2023-12-05 11:00:00', 'Completed', '55 Phan Xich Long, Phu Nhuan', 'Ho Chi Minh', 30000, 'E-Wallet'),
(1014, 5, '2023-12-12 18:25:00', 'Completed', '12 30/4 Street, Ninh Kieu', 'Can Tho', 0, 'Bank Transfer'),
(1015, 2, '2023-12-24 20:10:00', 'Completed', '45 Trang Tien, Hoan Kiem', 'Hanoi', 0, 'Credit Card'),
(1016, 1, '2024-01-05 09:30:00', 'Completed', '123 Nguyen Hue, District 1', 'Ho Chi Minh', 0, 'Credit Card'),
(1017, 4, '2024-01-18 14:00:00', 'Completed', '99 Cong Hoa, Tan Binh', 'Ho Chi Minh', 30000, 'E-Wallet'),
(1018, 10, '2024-01-25 16:30:00', 'Refunded', '101 Nguyen Trai, Thanh Xuan', 'Hanoi', 40000, 'Bank Transfer'),
(1019, 7, '2024-02-10 11:15:00', 'Completed', '15 Orchard Road', 'Singapore', 150000, 'Credit Card'),
(1020, 3, '2024-02-14 15:00:00', 'Completed', '78 Bach Dang, Hai Chau', 'Da Nang', 35000, 'Credit Card');

-- 3.6 Thêm Chi tiết Đơn hàng (Order Items)
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_pct) VALUES
(1, 1001, 101, 1, 32000000, 0.00),
(2, 1001, 106, 1, 5990000, 0.05),
(3, 1002, 103, 1, 48000000, 0.00),
(4, 1003, 105, 1, 8490000, 0.10),
(5, 1004, 108, 1, 21900000, 0.05),
(6, 1005, 109, 2, 2490000, 0.00),
(7, 1006, 102, 1, 29990000, 0.00),
(8, 1006, 105, 1, 8490000, 0.05),
(9, 1007, 106, 2, 5990000, 0.00),
(10, 1008, 107, 1, 6290000, 0.00),
(11, 1009, 103, 1, 48000000, 0.00),
(12, 1009, 106, 1, 5990000, 0.00),
(13, 1010, 107, 1, 6290000, 0.05),
(14, 1011, 104, 1, 41500000, 0.00),
(15, 1012, 101, 1, 32000000, 0.00),
(16, 1013, 109, 1, 2490000, 0.00),
(17, 1014, 108, 1, 21900000, 0.08),
(18, 1015, 101, 1, 32000000, 0.00),
(19, 1015, 105, 1, 8490000, 0.00),
(20, 1016, 102, 1, 29990000, 0.00),
(21, 1017, 107, 1, 6290000, 0.00),
(22, 1018, 105, 1, 8490000, 0.00),
(23, 1019, 101, 2, 32000000, 0.05),
(24, 1020, 106, 1, 5990000, 0.00);

-- 3.7 Thêm Thanh toán (Payments)
INSERT INTO payments (payment_id, order_id, payment_date, amount, payment_status, transaction_ref) VALUES
(501, 1001, '2023-09-01 10:16:00', 37720500, 'Success', 'TXN-20230901-001'),
(502, 1002, '2023-09-02 14:22:00', 48040000, 'Success', 'TXN-20230902-002'),
(503, 1003, '2023-09-05 09:05:00', 7676000, 'Success', 'TXN-20230905-003'),
(504, 1004, '2023-09-12 16:48:00', 20805000, 'Success', 'TXN-20230912-004'),
(505, 1005, '2023-09-15 11:35:00', 5010000, 'Failed', 'TXN-20230915-005'),
(506, 1006, '2023-10-01 08:25:00', 38105500, 'Success', 'TXN-20231001-006'),
(507, 1007, '2023-10-10 17:15:00', 11980000, 'Success', 'TXN-20231010-007'),
(508, 1008, '2023-10-15 13:05:00', 6320000, 'Pending', 'TXN-20231015-008'),
(509, 1009, '2023-10-20 19:45:00', 54140000, 'Success', 'TXN-20231020-009'),
(510, 1010, '2023-11-01 10:05:00', 6010500, 'Success', 'TXN-20231101-010');

-- 3.8 Thêm Nhật ký Sự kiện Web (Web Events for Funnel / Retention / Session Analysis)
INSERT INTO web_events (event_id, session_id, customer_id, event_time, event_type, page_url, device_type, metadata) VALUES
(1, 'sess_001', 1, '2023-09-01 10:00:00', 'page_view', '/home', 'Desktop', '{"referrer": "google.com"}'),
(2, 'sess_001', 1, '2023-09-01 10:05:00', 'search', '/search?q=iphone', 'Desktop', '{"term": "iphone 15"}'),
(3, 'sess_001', 1, '2023-09-01 10:08:00', 'add_to_cart', '/product/101', 'Desktop', '{"product_id": 101}'),
(4, 'sess_001', 1, '2023-09-01 10:12:00', 'checkout_start', '/checkout', 'Desktop', '{"cart_total": 37690500}'),
(5, 'sess_001', 1, '2023-09-01 10:15:00', 'purchase', '/thank-you', 'Desktop', '{"order_id": 1001}'),

(6, 'sess_002', 4, '2023-09-15 11:10:00', 'page_view', '/home', 'Mobile', '{"referrer": "facebook.com"}'),
(7, 'sess_002', 4, '2023-09-15 11:15:00', 'add_to_cart', '/product/109', 'Mobile', '{"product_id": 109}'),
(8, 'sess_002', 4, '2023-09-15 11:25:00', 'checkout_start', '/checkout', 'Mobile', '{"cart_total": 4980000}'),

(9, 'sess_003', NULL, '2023-09-20 14:00:00', 'page_view', '/home', 'Mobile', '{"referrer": "direct"}'),
(10, 'sess_003', NULL, '2023-09-20 14:02:00', 'page_view', '/category/laptops', 'Mobile', '{}'),

(11, 'sess_004', 2, '2023-10-10 17:00:00', 'page_view', '/home', 'Desktop', '{"referrer": "direct"}'),
(12, 'sess_004', 2, '2023-10-10 17:03:00', 'add_to_cart', '/product/106', 'Desktop', '{"product_id": 106}'),
(13, 'sess_004', 2, '2023-10-10 17:07:00', 'checkout_start', '/checkout', 'Desktop', '{}'),
(14, 'sess_004', 2, '2023-10-10 17:10:00', 'purchase', '/thank-you', 'Desktop', '{"order_id": 1007}');

-- 3.9 Thêm Nhật ký Tồn kho (Inventory Logs)
INSERT INTO inventory_logs (log_id, product_id, change_type, quantity_changed, log_date, notes) VALUES
(1, 101, 'RESTOCK', 50, '2023-08-20 09:00:00', 'Initial bulk stock arrival'),
(2, 101, 'SALE', -1, '2023-09-01 10:15:00', 'Order #1001 fulfilled'),
(3, 103, 'RESTOCK', 20, '2023-08-25 10:30:00', 'Batch #M3-import'),
(4, 103, 'SALE', -1, '2023-09-02 14:20:00', 'Order #1002 fulfilled'),
(5, 105, 'DAMAGE', -2, '2023-09-10 16:00:00', 'Water damage in warehouse sector B');

-- ==============================================================================
-- HOÀN TẤT KHỞI TẠO CSDL
-- ==============================================================================
SELECT 'DATABASE INITIALIZED SUCCESSFULLY! 10 Tables created and seeded.' AS status;
