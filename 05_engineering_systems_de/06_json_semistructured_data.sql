-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 05: ENGINEERING SYSTEMS FOR DATA ENGINEER
-- BÀI GIẢNG 06: DỮ LIỆU BÁN CẤU TRÚC: JSON VS JSONB, TOÁN TỬ TRÍCH XUẤT VÀ GIN INDEXING
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Phân biệt bản chất bộ nhớ: JSON (Text-based) vs JSONB (Binary Decomposed).
--   2. Bảng tra cứu các toán tử trích xuất (`->`, `->>`, `#>`, `#>>`).
--   3. Các toán tử kiểm tra chứa (Containment & Existence: `@>`, `?`, `?|`, `?&`).
--   4. Đánh chỉ mục GIN (Generalized Inverted Index) trên cột JSONB.
--   5. Làm phẳng mảng JSON (Unnesting JSON Arrays) & Đóng gói dữ liệu thành JSON API.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Đọc, lọc và lập chỉ mục dữ liệu JSON mà vẫn hiểu kiểu dữ liệu đang nhận được.
-- CÂU LỆNH: `->` (lấy JSON), `->>` (lấy text), `#>`/`#>>` (đường dẫn lồng), `@>` (chứa),
-- jsonb_array_elements (tách mảng), GIN index.
-- ⭐ MỨC ĐỘ DÙNG: `->>` và `@>` thường xuyên khi dùng JSONB; GIN index là tối ưu nâng cao.
-- 🧠 CẦN NHỚ: `->` trả JSON nên chưa so sánh text trực tiếp; `->>` trả text. JSONB thường tốt
-- hơn JSON trong PostgreSQL để tìm kiếm/index, nhưng cột quan hệ lõi vẫn nên được chuẩn hóa.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BẢNG SO SÁNH: JSON VS JSONB TRONG POSTGRESQL
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬──────────────────────────────────┬─────────────────────────────────┐
-- │ Tiêu chí        │ JSON                             │ JSONB (Khuyên dùng 99%)         │
-- ├─────────────────┼──────────────────────────────────┼─────────────────────────────────┤
-- │ Định dạng lưu   │ Chuỗi văn bản thuần túy (Text)   │ Cấu trúc nhị phân phân tách     │
-- │ Tốc độ ghi      │ Rất nhanh (Không cần phân tích)  │ Chậm hơn một chút (Do phân tích)│
-- │ Tốc độ đọc/lọc  │ Rất chậm (Phải parse lại từ đầu) │ CỰC NHANH (Truy xuất trực tiếp) │
-- │ Khử trùng Key   │ Giữ nguyên các key trùng lặp     │ Tự động khử trùng lặp key       │
-- │ Hỗ trợ Index    │ KHÔNG hỗ trợ GIN Index           │ HỖ TRỢ GIN Index siêu tốc       │
-- └─────────────────┴──────────────────────────────────┴─────────────────────────────────┘


-- ------------------------------------------------------------------------------
-- 2. BẢNG TRA CỨU CÁC TOÁN TỬ TRÍCH XUẤT JSONB
-- ------------------------------------------------------------------------------
-- ┌──────────┬──────────────────────────────────────┬────────────────────────────────────┐
-- │ Toán tử  │ Đầu vào                              │ Đầu ra                             │
-- ├──────────┼──────────────────────────────────────┼────────────────────────────────────┤
-- │ `->`     │ Key (Chuỗi) hoặc Index (Số)          │ Trả về phần tử dạng **JSON/JSONB** │
-- │ `->>`    │ Key (Chuỗi) hoặc Index (Số)          │ Trả về phần tử dạng **TEXT thuần** │
-- │ `#>`     │ Mảng đường dẫn `{path, to, key}`     │ Trả về đối tượng dạng **JSON/JSONB│
-- │ `#>>`    │ Mảng đường dẫn `{path, to, key}`     │ Trả về đối tượng dạng **TEXT thuần│
-- └──────────┴──────────────────────────────────────┴────────────────────────────────────┘

SELECT 
    product_id,
    product_name,
    specs -> 'color' AS color_json,           -- Kết quả: "Space Black" (Có ngoặc kép JSON)
    specs ->> 'color' AS color_text,          -- Kết quả: Space Black (Chuỗi thuần túy)
    specs ->> 'ram' AS ram_size,
    (specs ->> 'weight_g')::INT AS weight_in_grams,
    specs #> '{sizes, 0}' AS first_size_json  -- Trích xuất phần tử đầu tiên của mảng nested sizes
FROM products
WHERE specs IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 3. TÌM KIẾM VÀ LỌC TRÊN JSONB (CONTAINMENT & EXISTENCE)
-- ------------------------------------------------------------------------------

-- 3.1 Toán tử `@>` (Kiểm tra xem JSONB có chứa cấu trúc con này không):
-- 🎯 BÀI TOÁN: Tìm các sản phẩm có tính năng chống ồn `{"noise_cancelling": true}`
SELECT product_id, product_name, specs
FROM products
WHERE specs @> '{"noise_cancelling": true}';

-- 3.2 Toán tử `?` (Kiểm tra xem Key có tồn tại trong JSONB không):
-- 🎯 BÀI TOÁN: Tìm sản phẩm có chứa key 'stylus' (Bút cảm ứng)
SELECT product_id, product_name, specs
FROM products
WHERE specs ? 'stylus';


-- ------------------------------------------------------------------------------
-- 4. GIN INDEX TRÊN JSONB (CHỈ MỤC ĐẢO CHO HIỆU NĂNG TỐI THƯỢNG)
-- ------------------------------------------------------------------------------

-- Tạo GIN Index tổng quát:
CREATE INDEX IF NOT EXISTS idx_products_specs_gin ON products USING GIN (specs);

-- Tạo GIN Index chuyên biệt cho toán tử `@>` với `jsonb_path_ops` (Tiết kiệm dung lượng hơn):
CREATE INDEX IF NOT EXISTS idx_products_specs_path_gin ON products USING GIN (specs jsonb_path_ops);


-- ------------------------------------------------------------------------------
-- 5. LÀM PHẲNG MẢNG JSON (FLATTENING) & ĐÓNG GÓI JSON API
-- ------------------------------------------------------------------------------

-- 5.1 Làm phẳng mảng JSON với `jsonb_array_elements_text()`:
-- Tách mảng sizes: ["M", "L", "XL"] thành từng dòng riêng biệt để phân tích
SELECT 
    p.product_id,
    p.product_name,
    jsonb_array_elements_text(p.specs -> 'sizes') AS individual_size
FROM products p
WHERE p.specs ? 'sizes';

-- 5.2 Đóng gói ngược dữ liệu quan hệ thành JSON Payload phục vụ Backend API:
SELECT 
    c.customer_id,
    jsonb_build_object(
        'customer_id', c.customer_id,
        'full_name', c.first_name || ' ' || c.last_name,
        'email', c.email,
        'order_history', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'order_id', o.order_id,
                    'order_date', o.order_date,
                    'status', o.order_status
                )
            )
            FROM orders o
            WHERE o.customer_id = c.customer_id
        )
    ) AS api_response_payload
FROM customers c
LIMIT 2;
