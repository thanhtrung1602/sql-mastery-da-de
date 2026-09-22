-- ==============================================================================
-- FOLDER 06: REAL-WORLD PROJECTS & INTERVIEW PREPARATION
-- FILE: 02_data_pipeline_de_project.sql
-- MỤC TIÊU:
--   Dự án xây dựng Data Pipeline ELT / ETL hoàn chỉnh dành cho Senior Data Engineer:
--     1. Staging Ingestion Layer: Nhận dữ liệu thô từ nguồn ngoài.
--     2. Data Quality & Assertion Checks: Kiểm thử schema, nullability và logic nghiệp vụ.
--     3. Deduplication & Transformation: Khử trùng lặp và làm sạch.
--     4. SCD Type 2 Dimension & Incremental Fact Loading: Tải dữ liệu vào Data Warehouse.
--     5. Audit & Lineage Logging: Ghi vết nhật ký thực thi pipeline.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 CÁCH ĐỌC DỰ ÁN PIPELINE: Hãy coi đây là một dây chuyền: staging nhận dữ liệu thô →
-- CTE làm sạch/kiểm tra → bảng đích nhận dữ liệu chuẩn → audit lưu kết quả chạy. Lệnh CREATE,
-- DROP, INSERT, UPDATE trong file THAY ĐỔI database; chỉ chạy trên dữ liệu thực hành.
-- 🧠 CẦN NHỚ: "Idempotent" nghĩa là chạy lại cùng một batch thì trạng thái cuối không đổi.
-- `ON CONFLICT` là một cách đạt idempotency khi khóa xung đột được chọn đúng.
-- ==============================================================================

-- ==============================================================================
-- BƯỚC 1: KHỞI TẠO BẢNG NHẬT KÝ AUDIT PIPELINE & BẢNG STAGING
-- ==============================================================================

-- 🔒 AN TOÀN DỮ LIỆU: `DROP TABLE IF EXISTS ... CASCADE` xóa bảng minh họa và các đối tượng
-- phụ thuộc vào nó nếu có. `IF EXISTS` tránh lỗi khi chạy lần đầu, KHÔNG phải cơ chế sao lưu.
-- Mỗi cột trong pipeline_audit_log giải thích một lần chạy; `run_id` là id tự tăng để UPDATE
-- đúng dòng audit của batch hiện tại, không đè lịch sử batch cũ.

DROP TABLE IF EXISTS pipeline_audit_log CASCADE;
CREATE TABLE pipeline_audit_log (
    run_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    batch_start_time TIMESTAMP NOT NULL,
    batch_end_time TIMESTAMP,
    rows_extracted INT DEFAULT 0,
    rows_inserted INT DEFAULT 0,
    rows_updated INT DEFAULT 0,
    rows_rejected INT DEFAULT 0,
    status VARCHAR(20) CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),
    error_message TEXT
);

DROP TABLE IF EXISTS staging_orders CASCADE;
CREATE TABLE staging_orders (
    raw_order_id INT,
    raw_customer_email VARCHAR(100),
    raw_order_timestamp VARCHAR(50),
    raw_status VARCHAR(50),
    raw_amount_str VARCHAR(50),
    raw_payment_type VARCHAR(50),
    ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Nạp dữ liệu thô vào tầng Staging (Giả lập dữ liệu nhận từ CSV / Kafka / API chứa lỗi và trùng lặp)
INSERT INTO staging_orders (raw_order_id, raw_customer_email, raw_order_timestamp, raw_status, raw_amount_str, raw_payment_type) VALUES
(2001, 'an.nguyen@example.com', '2024-03-01 10:00:00', 'completed', '15000000', 'Credit Card'),
(2002, 'bich.tran@example.com', '2024-03-01 11:30:00', 'completed', '8500000', 'Bank Transfer'),
(2001, 'an.nguyen@example.com', '2024-03-01 10:00:00', 'completed', '15000000', 'Credit Card'), -- Dòng trùng lặp (Duplicate)
(2003, 'unknown_user_999@test.com', '2024-03-02 09:15:00', 'completed', '4200000', 'COD'),       -- User chưa tồn tại trong hệ thống
(2004, 'cuong.le@example.com', 'INVALID_DATE_FORMAT', 'completed', '500000', 'E-Wallet');        -- Dòng hỏng định dạng ngày

-- ==============================================================================
-- BƯỚC 2: QUY TRÌNH THỰC THI PIPELINE VỚI TRANSACTION & DATA QUALITY CHECKS
-- ==============================================================================

-- 💬 `DO $$ ... $$` là một khối thủ tục PostgreSQL: phần DECLARE tạo biến chỉ sống trong lần
-- chạy này; BEGIN/END bao quanh các lệnh; EXCEPTION bắt lỗi. Đây không phải SELECT thông thường.
-- Biến v_rows_inserted thực tế nhận số dòng bị INSERT hoặc UPDATE từ lệnh UPSERT; vì thế tên
-- "rows_loaded" sẽ chính xác hơn nếu dùng để báo cáo production.

DO $$
DECLARE
    v_run_id BIGINT;
    v_rows_extracted INT;
    v_rows_inserted INT := 0;
    v_rows_rejected INT := 0;
BEGIN
    -- 1. Ghi nhận bắt đầu pipeline
    INSERT INTO pipeline_audit_log (pipeline_name, batch_start_time, status)
    VALUES ('orders_daily_ingestion_pipeline', CURRENT_TIMESTAMP, 'RUNNING')
    RETURNING run_id INTO v_run_id;

    SELECT COUNT(*) INTO v_rows_extracted FROM staging_orders;

    -- 2. Tách dữ liệu Hợp lệ (Valid) và Dữ liệu Rác (Rejected)
    -- Sử dụng CTE để kiểm tra Data Quality Assertions
    -- 💬 cleaned_staging: 1 dòng/staging hợp định dạng; LOWER+TRIM chuẩn hóa email để JOIN;
    -- CAST chuyển text thành timestamp/số SAU khi Regex bảo đảm định dạng để tránh pipeline lỗi.
    -- ROW_NUMBER đánh số các bản trùng cùng raw_order_id, bản mới nhất nhận dedup_rank = 1.
    WITH cleaned_staging AS (
        SELECT 
            raw_order_id AS order_id,
            LOWER(TRIM(raw_customer_email)) AS email,
            raw_order_timestamp::TIMESTAMP AS order_date,
            INITCAP(raw_status) AS order_status,
            raw_amount_str::NUMERIC(12, 2) AS total_amount,
            raw_payment_type AS payment_method,
            ROW_NUMBER() OVER (PARTITION BY raw_order_id ORDER BY ingestion_time DESC) AS dedup_rank
        FROM staging_orders
        WHERE raw_order_timestamp ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$' -- Kiểm tra regex format ngày
          AND raw_amount_str ~ '^\d+(\.\d+)?$'                            -- Kiểm tra số hợp lệ
    ),
    valid_orders AS (
        -- 💬 valid_orders chỉ giữ dữ liệu đã khớp customer thật qua INNER JOIN. Dòng email lạ
        -- bị loại để không vi phạm khóa ngoại orders.customer_id khi nạp bảng đích.
        SELECT 
            cs.order_id,
            c.customer_id,
            cs.order_date,
            cs.order_status,
            cs.total_amount,
            cs.payment_method
        FROM cleaned_staging cs
        JOIN customers c ON cs.email = c.email -- Data Quality Check: Referential Integrity
        WHERE cs.dedup_rank = 1               -- Khử trùng lặp (Deduplication)
    )
    -- 3. Nạp Idempotent vào bảng đích Orders
    -- 💬 INSERT lấy từng dòng đã sạch. ON CONFLICT(order_id) nói: nếu order_id đã có thì
    -- không tạo thêm đơn; cập nhật các thuộc tính có thể thay đổi từ dòng nguồn `EXCLUDED`.
    INSERT INTO orders (order_id, customer_id, order_date, order_status, shipping_fee, payment_method)
    SELECT 
        vo.order_id,
        vo.customer_id,
        vo.order_date,
        vo.order_status,
        0.00,
        vo.payment_method
    FROM valid_orders vo
    ON CONFLICT (order_id) DO UPDATE SET
        order_status = EXCLUDED.order_status,
        payment_method = EXCLUDED.payment_method;

    GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;
    -- ⚠️ ROW_COUNT của UPSERT không tách riêng "đã chèn" và "đã cập nhật". Vì vậy công thức
    -- rejected = extracted - rows_inserted chỉ là minh họa, không đúng nếu có dòng trùng hoặc
    -- email lạ. Pipeline thật nên đếm valid/rejected bằng các CTE/audit riêng.
    v_rows_rejected := v_rows_extracted - v_rows_inserted;

    -- 4. Cập nhật nhật ký Audit thành công
    UPDATE pipeline_audit_log
    SET 
        batch_end_time = CURRENT_TIMESTAMP,
        rows_extracted = v_rows_extracted,
        rows_inserted = v_rows_inserted,
        rows_rejected = v_rows_rejected,
        status = 'SUCCESS'
    WHERE run_id = v_run_id;

EXCEPTION WHEN OTHERS THEN
    -- Bắt lỗi tự động và ghi nhận nhật ký thất bại
    UPDATE pipeline_audit_log
    SET 
        batch_end_time = CURRENT_TIMESTAMP,
        status = 'FAILED',
        error_message = SQLERRM
    WHERE run_id = v_run_id;
    RAISE NOTICE 'Pipeline execution failed: %', SQLERRM;
END $$;

-- ==============================================================================
-- BƯỚC 3: KIỂM TRA BÁO CÁO AUDIT PIPELINE
-- ==============================================================================
SELECT 
    run_id,
    pipeline_name,
    batch_start_time,
    batch_end_time,
    (batch_end_time - batch_start_time) AS duration,
    rows_extracted,
    rows_inserted,
    rows_rejected,
    status,
    error_message
FROM pipeline_audit_log;
