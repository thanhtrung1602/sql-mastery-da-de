-- ==============================================================================
-- KHÓA HỌC: SQL MASTERY CHO DATA ANALYST & DATA ENGINEER
-- FOLDER 04: ADVANCED ANALYTICS FOR DATA ANALYST
-- BÀI GIẢNG 06: MÔ HÌNH PHÂN KHÚC KHÁCH HÀNG RFM (RECENCY, FREQUENCY, MONETARY)
-- ==============================================================================
--
-- 📚 MỤC LỤC BÀI HỌC:
--   1. Phương pháp luận Phân khúc khách hàng RFM chuẩn quốc tế.
--   2. Tính toán 3 chỉ số gốc: Recency (Ngày), Frequency (Số đơn), Monetary (Tổng chi tiêu).
--   3. Chấm điểm phân vị (Scoring 1 - 4) bằng hàm NTILE().
--   4. Gán nhãn phân khúc (Champions, Loyal, At Risk, Lost) & Đề xuất hành động kinh doanh thực chiến.
-- ==============================================================================

-- ==============================================================================
-- 🧑‍🎓 BẢN ĐỒ BÀI HỌC CHO NGƯỜI MỚI
-- MỤC TIÊU: Hiểu mỗi bước biến đơn hàng thành điểm RFM và nhãn khách hàng như thế nào.
-- CÂU LỆNH: WITH (đặt tên từng bước), MAX/COUNT/SUM (R/F/M), COALESCE (thay tổng NULL),
-- NTILE (chia nhóm điểm), CASE (gán nhãn), GROUP BY (tổng hợp cuối).
-- ⭐ MỨC ĐỘ DÙNG: CTE, aggregate, CASE rất thường xuyên; NTILE là nâng cao nhưng hữu ích.
-- 🧠 CẦN NHỚ: Recency là số ngày nên nhỏ là tốt; vì NTILE trao số lớn cho cuối thứ tự,
-- bài dùng ORDER BY recency_days DESC để người có ít ngày nhận điểm cao.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Ý NGHĨA KINH DOANH CỦA 3 TRỤ CỘT RFM
-- ------------------------------------------------------------------------------
-- ┌─────────────────┬────────────────────────────────────────────────────────────────────────┐
-- │ Trụ cột         │ Định nghĩa & Quy tắc tính điểm                                         │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 1. Recency (R)  │ Số ngày kể từ lần mua gần nhất đến mốc phân tích.                      │
-- │                 │ (CÀNG GẦN ĐÂY CÀNG TỐT -> Số ngày nhỏ thì Điểm R phải CAO NHẤT).       │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 2. Frequency (F)│ Tổng số lần đặt hàng thành công.                                       │
-- │                 │ (CÀNG MUA NHIỀU LẦN CÀNG TỐT -> Số đơn lớn thì Điểm F CAO NHẤT).       │
-- ├─────────────────┼────────────────────────────────────────────────────────────────────────┤
-- │ 3. Monetary (M) │ Tổng số tiền thực tế khách hàng đã chi tiêu.                           │
-- │                 │ (CÀNG CHI NHIỀU TIỀN CÀNG TỐT -> Số tiền lớn thì Điểm M CAO NHẤT).     │
-- └─────────────────┴────────────────────────────────────────────────────────────────────────┘

-- 💬 CÁCH ĐỌC TOÀN BỘ QUERY: base_rfm tạo 1 dòng/khách với ba số R/F/M; rfm_scores giữ
-- 1 dòng/khách và thêm điểm 1–4; rfm_segmented giữ 1 dòng/khách và thêm nhãn; SELECT cuối
-- gộp các khách có cùng nhãn thành 1 dòng/phân khúc. Điều này giúp bạn không nhầm số liệu
-- của "một khách" với số liệu của "một phân khúc".

WITH base_rfm AS (
    -- BƯỚC 1: Tính toán các giá trị R, F, M thô cho từng khách hàng (Mốc phân tích: '2024-03-01')
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        ('2024-03-01'::DATE - MAX(o.order_date)::DATE) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),
rfm_scores AS (
    -- BƯỚC 2: Chia phân vị chấm điểm từ 1 đến 4 với NTILE(4)
    SELECT 
        customer_id,
        customer_name,
        email,
        recency_days,
        frequency_orders,
        monetary_value,
        -- ⚠️ Lưu ý: Recency càng ít ngày thì càng tốt -> Sắp xếp DESC để người ít ngày nhất nhận điểm 4:
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency_orders ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM base_rfm
),
rfm_segmented AS (
    -- BƯỚC 3: Gán nhãn phân khúc dựa trên tổ hợp điểm R, F, M
    SELECT 
        customer_id,
        customer_name,
        recency_days,
        frequency_orders,
        monetary_value,
        r_score,
        f_score,
        m_score,
        CASE 
            WHEN r_score = 4 AND f_score = 4 AND m_score >= 3 THEN 'Champions (Khách hàng VIP Cốt lõi)'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers (Khách hàng Trung thành)'
            WHEN r_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists (Khách hàng Tiềm năng)'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (Khách hàng Nguy cơ rời bỏ)'
            WHEN r_score = 1 AND f_score <= 2 THEN 'Lost Customers (Khách hàng Đã rời bỏ)'
            ELSE 'Promising / Needs Attention (Cần kích hoạt)'
        END AS customer_segment
    FROM rfm_scores
)
-- BƯỚC 4: Báo cáo Tổng hợp phục vụ Chiến lược Marketing & Retention
SELECT 
    customer_segment,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 1) AS avg_order_frequency,
    ROUND(SUM(monetary_value), 0) AS segment_total_revenue,
    ROUND(AVG(monetary_value), 0) AS segment_avg_clv
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY segment_total_revenue DESC;
-- 💡 TẠI SAO SUM ở bước cuối không nhân đôi tiền: base_rfm đã gom order_items về một tổng
-- monetary_value cho mỗi khách; mỗi khách chỉ xuất hiện đúng một lần trong rfm_segmented.
