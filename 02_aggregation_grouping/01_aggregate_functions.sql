-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 02: AGGREGATION & GROUPING (GOM NHÓM & TÍNH TOÁN TỔNG HỢP)
-- BÀI GIẢNG 01: BẢN CHẤT CÁC HÀM TỔNG HỢP VÀ THỐNG KÊ MÔ TẢ
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Cơ chế hoạt động của Aggregate Functions (N dòng -> 1 dòng kết quả).
--   2. Phân tích sự khác biệt cốt tử: COUNT(*), COUNT(col), và COUNT(DISTINCT col).
--   3. Cách các hàm tổng hợp (SUM, AVG, MIN, MAX) xử lý giá trị NULL.
--   4. Gom chuỗi và mảng: STRING_AGG() và ARRAY_AGG().
--   5. Thống kê nâng cao: Trung vị (Median / PERCENTILE_CONT), Phân vị (Quantiles), Phương sai & Độ lệch chuẩn.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Biết biến nhiều dòng thành một con số có ý nghĩa, như tổng doanh thu hay số khách.
-- CÂU LỆNH: COUNT (đếm), SUM (cộng), AVG (trung bình), MIN/MAX (nhỏ/lớn nhất),
-- STRING_AGG/ARRAY_AGG (gom text/mảng), PERCENTILE_CONT (phân vị).
-- ⭐ MỨC ĐỘ DÙNG: COUNT/SUM/AVG/MIN/MAX rất thường xuyên; percentile là nâng cao.
-- 🧠 CẦN NHỚ: Hàm tổng hợp bỏ NULL, trừ COUNT(*). Không trộn cột thường với aggregate
-- nếu chưa GROUP BY; bài sau giải thích quy tắc này.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CƠ CHẾ BÊN DƯỚI CỦA HÀM TỔNG HỢP (AGGREGATE ENGINE MECHANICS)
-- ------------------------------------------------------------------------------
-- Hàm tổng hợp nhận vào một tập hợp nhiều giá trị từ một cột và nén (Reduce/Fold) chúng
-- thành một giá trị duy nhất đại diện cho toàn bộ tập dữ liệu.
--
-- ┌────────────────┐
-- │ Giá trị 1: 100 │
-- │ Giá trị 2: 200 │ ───> [ HÀM TỔNG HỢP SUM() / AVG() ] ───> Kết quả duy nhất: 450 / 150
-- │ Giá trị 3: 150 │
-- └────────────────┘


-- ------------------------------------------------------------------------------
-- 2. PHÂN BIỆT SỰ KHÁC NHAU GIỮA CÁC BIẾN THỂ CỦA COUNT
-- ------------------------------------------------------------------------------
-- ┌──────────────────────┬────────────────────────────────────────────────────────────────┐
-- │ Biến thể             │ Cơ chế xử lý & Lưu ý                                          │
-- ├──────────────────────┼────────────────────────────────────────────────────────────────┤
-- │ COUNT(*)             │ Đếm TẤT CẢ các dòng trong bảng, BẤT KỂ dòng đó có NULL hay ko.  │
-- │ COUNT(1)             │ Tương đương 100% với COUNT(*) về cả ngữ nghĩa lẫn tốc độ.       │
-- │ COUNT(column_name)   │ CHỈ ĐẾM các dòng mà giá trị tại cột đó KHÁC NULL (Bỏ qua NULL). │
-- │ COUNT(DISTINCT col)  │ Khử trùng lặp giá trị trước rồi mới đếm (Bỏ qua NULL).          │
-- └──────────────────────┴────────────────────────────────────────────────────────────────┘

SELECT 
    COUNT(*) AS tong_so_san_pham,
    COUNT(category_id) AS so_sp_co_danh_muc,          -- Bỏ qua các SP có category_id là NULL
    COUNT(DISTINCT category_id) AS so_danh_muc_duy_nhat, -- Đếm số danh mục phân biệt
    MIN(unit_price) AS gia_thap_nhat,
    MAX(unit_price) AS gia_cao_nhat,
    ROUND(AVG(unit_price), 2) AS gia_trung_binh,
    SUM(stock_quantity) AS tong_so_luong_ton_kho
FROM products;

-- ⚠️ CẠM BẪY VỚI HÀM AVG() VÀ NULL:
-- Trong SQL: AVG(col) = SUM(col) / COUNT(col).
-- Nếu bạn có 4 dòng với giá trị: (10, 20, NULL, 30):
--   - AVG(col) = (10 + 20 + 30) / 3 = 20 (Do NULL bị bỏ qua ở cả tử số và mẫu số).
--   - Nếu nghiệp vụ muốn xem NULL là 0: Phải viết `AVG(COALESCE(col, 0))` = 60 / 4 = 15.


-- ------------------------------------------------------------------------------
-- 3. GOM CHUỖI VÀ MẢNG: STRING_AGG() VÀ ARRAY_AGG()
-- ------------------------------------------------------------------------------

-- 3.1 STRING_AGG(col, delimiter [ORDER BY ...]): Nối tất cả giá trị thành một chuỗi văn bản duy nhất
SELECT 
    STRING_AGG(product_name, ' | ' ORDER BY unit_price DESC) AS danh_sach_sp_tu_dat_den_re
FROM products;

-- 3.2 ARRAY_AGG(col [ORDER BY ...]): Gom tất cả giá trị vào một mảng cấu trúc (Array)
SELECT 
    ARRAY_AGG(customer_id ORDER BY signup_date ASC) AS mang_id_khach_hang_theo_ngay_dk
FROM customers;


-- ------------------------------------------------------------------------------
-- 4. THỐNG KÊ NÂNG CAO CHO DATA ANALYST (PERCENTILE & STATISTICS)
-- ------------------------------------------------------------------------------
-- Trong thực tế phân tích kinh doanh, GIÁ TRỊ TRUNG BÌNH (Mean) rất dễ bị bóp méo bởi các giá trị ngoại lai
-- cực đoan (Outliers). Vì vậy, TRUNG VỊ (Median - 50th Percentile) là thước đo chuẩn xác hơn nhiều.

-- CÚ PHÁP:
-- PERCENTILE_CONT(p) WITHIN GROUP (ORDER BY col ASC) : Phân vị liên tục (Nội suy nếu tập chẵn).
-- PERCENTILE_DISC(p) WITHIN GROUP (ORDER BY col ASC) : Phân vị rời rạc (Lấy chính xác giá trị có trong tập).

SELECT 
    ROUND(AVG(salary), 0) AS luong_trung_binh_mean,
    
    -- Trung vị (50th Percentile - Median):
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY salary) AS luong_trung_vi_p50,
    
    -- Phân vị 75th và 90th (Top 10% thu nhập cao nhất bắt đầu từ mức này):
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS phan_vi_p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY salary) AS phan_vi_p90_top_earners,
    
    -- Độ lệch chuẩn mẫu (Sample Standard Deviation) và Phương sai mẫu (Sample Variance):
    ROUND(STDDEV_SAMP(salary), 2) AS do_lech_chuan_stddev,
    ROUND(VAR_SAMP(salary), 2) AS phuong_sai_variance
FROM employees;
