# Bắt đầu từ số 0: cách đọc và học các file SQL trong khoá này

Tài liệu này dành cho người **chưa từng lập trình**. Đừng cố học thuộc cả một câu SQL dài ngay lần đầu. Hãy chạy từng khối lệnh, đọc chú thích `--` ngay phía trên hoặc bên phải dòng lệnh, rồi thay một giá trị nhỏ để quan sát kết quả thay đổi.

## 1. SQL là gì?

SQL là ngôn ngữ để nói chuyện với cơ sở dữ liệu (database). Hãy hình dung:

| Khái niệm | Hình dung gần gũi | Ví dụ trong bộ dữ liệu |
|---|---|---|
| Database | Một tủ hồ sơ lớn | Toàn bộ dữ liệu cửa hàng |
| Table (bảng) | Một trang tính / một ngăn hồ sơ | `customers`, `orders` |
| Row (dòng, bản ghi) | Một người hoặc một sự việc | Một khách hàng, một đơn hàng |
| Column (cột) | Một thuộc tính của mỗi dòng | `email`, `order_date` |
| Value (giá trị) | Nội dung của một ô | `'Hanoi'`, `250000` |
| Query (truy vấn) | Một câu hỏi gửi cho database | “Những khách ở Hà Nội là ai?” |

Phần lớn bài đầu chỉ **đọc** dữ liệu bằng `SELECT`; dữ liệu gốc không bị sửa. Các bài về `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP` có thể thay đổi cấu trúc hoặc dữ liệu. Những lệnh đó luôn được ghi cảnh báo trong bài.

## 2. Chuẩn bị trước khi học

1. Dùng PostgreSQL (khuyến nghị) vì một số ví dụ dùng cú pháp riêng của PostgreSQL như `ILIKE`, `DISTINCT ON`, `::DATE`, `JSONB`.
2. Chạy [init_database.sql](init_database.sql) **một lần** để tạo bảng và dữ liệu mẫu.
3. Học lần lượt thư mục `01` → `07`; không nên nhảy vào `JOIN`, CTE hay Window Function khi chưa quen `SELECT`, `WHERE`, `GROUP BY`.
4. Trong một file, chạy **từng khối kết thúc bằng dấu `;`**, không chạy toàn bộ file nếu khối đó có `DROP`, `DELETE`, hoặc tạo bảng minh hoạ.

## 3. Những dấu hiệu cần nhận ra trong một file SQL

```sql
-- Dòng bắt đầu bằng hai dấu gạch ngang là ghi chú cho con người, database bỏ qua.
SELECT c.first_name AS ten_khach_hang  -- chọn cột và đổi tên cột khi hiển thị
FROM customers AS c                    -- lấy dữ liệu từ bảng customers, gọi tắt là c
WHERE c.city = 'Hanoi';                -- chỉ giữ dòng có city đúng bằng Hanoi
```

| Ký hiệu | Nghĩa | Điều cần nhớ |
|---|---|---|
| `--` | Ghi chú một dòng | Không được chạy như SQL; dùng để giải thích mã. |
| `;` | Kết thúc một câu lệnh | Hãy coi đây là dấu chấm hết câu. |
| `'text'` | Giá trị văn bản | Chuỗi luôn dùng nháy đơn, không phải nháy kép. |
| `()` | Nhóm biểu thức / truyền tham số cho hàm | Ví dụ `COUNT(*)`, `ROUND(gia, 2)`. |
| `,` | Ngăn cách cột, giá trị hoặc điều kiện | Quên dấu phẩy là lỗi cú pháp rất thường gặp. |
| `.` | Chỉ ra bảng và cột | `c.city` nghĩa là cột `city` của bảng có bí danh `c`. |
| `AS` | Đặt tên tạm (alias) | `AS doanh_thu` chỉ đổi tên kết quả, không đổi cột thật. |
| `NULL` | Chưa có / không biết giá trị | Không phải `0`, không phải chuỗi rỗng `''`. |

## 4. Cách database hiểu một truy vấn SELECT

Ta thường viết `SELECT` trước cho dễ đọc, nhưng với truy vấn có đủ thành phần, hãy hiểu theo thứ tự logic bên dưới:

```text
FROM / JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  DISTINCT  →  ORDER BY  →  LIMIT / OFFSET
chọn nguồn       lọc       gom nhóm      lọc nhóm   chọn cột    bỏ trùng     sắp xếp       lấy một phần
```

Ví dụ “5 thành phố có nhiều khách hàng nhất”:

```sql
SELECT city, COUNT(*) AS so_khach_hang
FROM customers
WHERE city IS NOT NULL
GROUP BY city
ORDER BY so_khach_hang DESC
LIMIT 5;
```

Hãy đọc như sau:

1. `FROM customers`: lấy các dòng khách hàng.
2. `WHERE city IS NOT NULL`: bỏ các dòng chưa có thành phố.
3. `GROUP BY city`: gom các khách cùng thành phố thành một nhóm.
4. `SELECT city, COUNT(*)`: mỗi nhóm xuất ra tên thành phố và số dòng trong nhóm.
5. `ORDER BY ... DESC`: đưa số lớn nhất lên trước.
6. `LIMIT 5`: chỉ giữ 5 kết quả đầu.

## 5. Từ khoá nên thuộc, điều không cần học vẹt

### Cần nhận diện và gõ được ngay

- Đọc dữ liệu: `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT`.
- Điều kiện: `=`, `<>`, `>`, `<`, `AND`, `OR`, `IN`, `BETWEEN`, `LIKE`, `IS NULL`.
- Tổng hợp: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`.
- Ghép bảng: `JOIN ... ON`, đặc biệt là `INNER JOIN` và `LEFT JOIN`.
- Làm truy vấn nhiều bước: `WITH ... AS (...)` (CTE).

### Cần hiểu nguyên lý, không cần thuộc từng ký tự

- Hàm ngày giờ, JSON, phân vị, Window Function, index, partition, SCD, `EXPLAIN`.
- Cú pháp hiếm hoặc phụ thuộc hệ quản trị: `DISTINCT ON`, `LATERAL`, `FILTER`, `ROLLUP`, `CUBE`, `MERGE`.
- Tên bảng, tên cột và tên bí danh. Hãy tra schema hoặc dùng gợi ý của công cụ thay vì đoán.

### Quy tắc vàng dễ quên

- Muốn so sánh với `NULL`, dùng `IS NULL` hoặc `IS NOT NULL`, **không** viết `= NULL`.
- `WHERE` lọc **dòng trước khi** gom nhóm; `HAVING` lọc **nhóm sau khi** gom.
- Khi `LEFT JOIN`, điều kiện chỉ thuộc bảng bên phải thường đặt trong `ON` nếu vẫn muốn giữ mọi dòng bảng bên trái.
- `COUNT(column)` bỏ qua `NULL`; `COUNT(*)` đếm mọi dòng.
- Không dùng `SELECT *` trong báo cáo hay ứng dụng thật; chỉ chọn các cột cần dùng.
- Nếu có phép chia, bảo vệ mẫu số bằng `NULLIF(mau_so, 0)` để tránh lỗi chia cho 0.

## 6. Nhãn chú thích được dùng trong các bài

| Nhãn | Cách dùng |
|---|---|
| `💬 ĐỌC DÒNG NÀY` | Diễn giải dòng lệnh bằng tiếng Việt thông thường. |
| `💡 TẠI SAO` | Lý do đặt lệnh ở vị trí đó hoặc chọn cách viết đó. |
| `📌 DÙNG KHI NÀO` | Tình huống công việc thường gặp. |
| `⭐ MỨC ĐỘ DÙNG` | Mức độ phổ biến: rất thường xuyên / thường xuyên / nâng cao / hiếm. |
| `🧠 CẦN NHỚ` | Ý tưởng hoặc cú pháp cần nhớ sau bài. |
| `⚠️ CẠM BẪY` | Lỗi dễ làm kết quả sai hoặc gây rủi ro dữ liệu. |
| `🔒 AN TOÀN DỮ LIỆU` | Lệnh có thể tạo, sửa, xoá dữ liệu hoặc bảng. |

## 7. Quy trình học chậm mà chắc cho mỗi truy vấn

1. Đọc phần **Mục tiêu** và **Bản đồ câu lệnh** ở đầu file.
2. Đoán kết quả trước khi chạy: có bao nhiêu cột, một dòng đại diện cho cái gì, dòng nào bị loại?
3. Chạy truy vấn và đối chiếu. Nếu sai dự đoán, đọc lại các dòng `FROM`, `JOIN`, `WHERE`, `GROUP BY`.
4. Đổi một giá trị an toàn: ví dụ `'Hanoi'` thành `'Da Nang'`, `LIMIT 5` thành `LIMIT 10`, hoặc `DESC` thành `ASC`.
5. Viết lại truy vấn từ trí nhớ, sau đó mới mở lời giải để so sánh.

Không cần hiểu hết mọi câu trong lần đầu. Mục tiêu đúng là: sau mỗi bài, bạn tự nói được “mỗi dòng dữ liệu đầu ra đại diện cho điều gì, câu lệnh lọc/gom/sắp xếp ở đâu, và vì sao nó ở đó”.
