import os
import re
import json
import sys

# Ensure UTF-8 output on Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')


def parse_sql_values(text):
    rows = []
    i = 0
    n = len(text)
    while i < n:
        while i < n and text[i] != '(':
            i += 1
        if i >= n:
            break
        i += 1  # skip '('
        
        row = []
        cur_val = []
        in_str = False
        str_char = None
        
        while i < n:
            ch = text[i]
            if in_str:
                if ch == str_char:
                    if i + 1 < n and text[i+1] == str_char:
                        cur_val.append(ch)
                        i += 2
                        continue
                    else:
                        in_str = False
                        i += 1
                        continue
                else:
                    cur_val.append(ch)
                    i += 1
            else:
                if ch in ("'", '"'):
                    in_str = True
                    str_char = ch
                    i += 1
                elif ch == ',':
                    row.append(''.join(cur_val).strip())
                    cur_val = []
                    i += 1
                elif ch == ')':
                    row.append(''.join(cur_val).strip())
                    cur_val = []
                    i += 1
                    break
                else:
                    cur_val.append(ch)
                    i += 1
        
        parsed_row = []
        for v in row:
            if v.upper() == 'NULL':
                parsed_row.append(None)
            elif v.upper() == 'TRUE':
                parsed_row.append(True)
            elif v.upper() == 'FALSE':
                parsed_row.append(False)
            elif (v.startswith("'") and v.endswith("'")) or (v.startswith('"') and v.endswith('"')):
                val_content = v[1:-1].replace("''", "'")
                parsed_row.append(val_content)
            else:
                try:
                    if '.' in v:
                        parsed_row.append(float(v))
                    else:
                        parsed_row.append(int(v))
                except:
                    parsed_row.append(v)
        if parsed_row:
            rows.append(parsed_row)
    return rows


def parse_database_init(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract schema tables
    table_defs = {}
    create_tables = re.findall(r'CREATE TABLE (\w+)\s*\((.*?)\);', content, re.DOTALL | re.IGNORECASE)
    for table_name, body in create_tables:
        cols = []
        for line in body.split('\n'):
            line = line.strip()
            if not line or line.startswith('--') or line.startswith('/*'):
                continue
            if line.upper().startswith(('PRIMARY KEY', 'FOREIGN KEY', 'CHECK', 'UNIQUE', 'CONSTRAINT')):
                continue
            parts = line.split()
            if parts:
                col_name = parts[0].strip()
                col_type = parts[1].strip() if len(parts) > 1 else 'TEXT'
                cols.append({'name': col_name, 'type': col_type, 'raw': line.rstrip(',')})
        table_defs[table_name] = cols

    # Extract insert seed data
    table_data = {}
    inserts = re.findall(r'INSERT INTO (\w+)\s*\(([^)]+)\)\s*VALUES\s*(.*?);', content, re.DOTALL | re.IGNORECASE)
    for table_name, cols_str, val_block in inserts:
        col_names = [c.strip() for c in cols_str.split(',')]
        rows = parse_sql_values(val_block)
        dict_rows = []
        for r in rows:
            row_dict = {}
            for idx, col in enumerate(col_names):
                row_dict[col] = r[idx] if idx < len(r) else None
            dict_rows.append(row_dict)
        table_data[table_name] = dict_rows

    return table_defs, table_data


# Reference solutions for exercises that were left open for students
DEFAULT_SOLUTIONS = {
    "m02_05_practice_exercises_ex01": """SELECT 
    shipping_city, 
    COUNT(order_id) AS total_orders, 
    SUM(shipping_fee) AS total_shipping_fee, 
    ROUND(AVG(shipping_fee), 2) AS avg_shipping_fee
FROM orders
GROUP BY shipping_city
HAVING COUNT(order_id) >= 2
ORDER BY total_orders DESC;""",

    "m02_05_practice_exercises_ex02": """SELECT 
    payment_method, 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(SUM(CASE WHEN order_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS completion_rate_pct
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;""",

    "m02_05_practice_exercises_ex03": """SELECT 
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS monthly_net_revenue,
    STRING_AGG(DISTINCT oi.product_id::TEXT, ', ') AS distinct_product_ids_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)::DATE
ORDER BY sales_month ASC;""",

    "m02_05_practice_exercises_ex04": """SELECT 
    COALESCE(department, '== TOÀN CÔNG TY ==') AS department_name,
    manager_id,
    COUNT(*) AS total_headcount,
    SUM(salary) AS total_payroll
FROM employees
GROUP BY ROLLUP(department, manager_id)
ORDER BY department_name, manager_id;""",

    "m03_05_practice_exercises_ex01": """SELECT 
    c.category_name,
    COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)), 0.00) AS total_revenue
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'Completed'
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;""",

    "m03_05_practice_exercises_ex02": """SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    p.stock_quantity
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
);""",

    "m03_05_practice_exercises_ex03": """SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    COALESCE(m.first_name || ' ' || m.last_name, 'None (CEO)') AS direct_manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.employee_id;""",

    "m03_05_practice_exercises_ex04": """SELECT 
    c.category_name,
    p.product_name,
    p.unit_price
FROM categories c
CROSS JOIN LATERAL (
    SELECT product_name, unit_price
    FROM products
    WHERE category_id = c.category_id
    ORDER BY unit_price DESC
    LIMIT 2
) p
ORDER BY c.category_name, p.unit_price DESC;""",

    "m04_07_practice_exercises_ex01": """WITH monthly_product_rev AS (
    SELECT 
        DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS total_rev
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)::DATE, p.product_name
),
ranked AS (
    SELECT 
        sales_month,
        product_name,
        total_rev,
        ROW_NUMBER() OVER (PARTITION BY sales_month ORDER BY total_rev DESC) AS rnk
    FROM monthly_product_rev
)
SELECT 
    sales_month,
    product_name,
    total_rev AS top_product_revenue
FROM ranked
WHERE rnk = 1
ORDER BY sales_month;""",

    "m04_07_practice_exercises_ex02": """SELECT 
    order_id,
    customer_id,
    order_date,
    LAG(order_date, 1) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS prev_order_date,
    ROUND(EXTRACT(EPOCH FROM (order_date - LAG(order_date, 1) OVER (PARTITION BY customer_id ORDER BY order_date ASC))) / 86400.0, 1) AS days_since_previous_order
FROM orders
ORDER BY customer_id, order_date ASC;""",

    "m04_07_practice_exercises_ex03": """WITH daily_rev AS (
    SELECT 
        DATE_TRUNC('day', o.order_date)::DATE AS order_day,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('day', o.order_date)::DATE
)
SELECT 
    order_day,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY order_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
    ROUND(AVG(daily_revenue) OVER (ORDER BY order_day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS moving_avg_30d
FROM daily_rev
ORDER BY order_day;""",

    "m04_07_practice_exercises_ex04": """WITH rfm_raw AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        (DATE '2024-03-01' - MAX(o.order_date)::DATE) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS monetary_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency_orders,
    monetary_value,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(4) OVER (ORDER BY frequency_orders ASC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
FROM rfm_raw
ORDER BY monetary_value DESC;""",

    "m05_07_practice_exercises_ex01": """INSERT INTO products (product_id, product_name, category_id, cost_price, unit_price, stock_quantity)
SELECT product_id, product_name, category_id, cost_price, unit_price, stock_quantity
FROM temp_inventory_sync
ON CONFLICT (product_id) DO UPDATE 
SET stock_quantity = EXCLUDED.stock_quantity,
    unit_price = EXCLUDED.unit_price;""",

    "m05_07_practice_exercises_ex02": """SELECT 
    product_id,
    product_name,
    specs->>'ram' AS ram_spec,
    specs->>'storage' AS storage_spec,
    (specs->>'weight_g')::INT AS weight_in_grams
FROM products
WHERE specs ? 'ram'
ORDER BY product_id;""",

    "m05_07_practice_exercises_ex03": """-- Cập nhật dòng hiện tại:
UPDATE dim_customers_scd2
SET is_current = FALSE,
    valid_to = CURRENT_TIMESTAMP
WHERE customer_id = 1 AND is_current = TRUE;

-- Chèn phiên bản mới:
INSERT INTO dim_customers_scd2 (customer_id, first_name, last_name, email, city, customer_segment, valid_from, valid_to, is_current)
VALUES (1, 'Nguyen', 'Van An', 'an.nguyen@example.com', 'Da Nang', 'VIP', CURRENT_TIMESTAMP, '9999-12-31 23:59:59', TRUE);""",

    "m05_07_practice_exercises_ex04": """CREATE INDEX idx_orders_active_shipping
ON orders (customer_id, shipping_city)
INCLUDE (shipping_fee, order_date)
WHERE order_status IN ('Pending', 'Processing');"""
}


def parse_exercise_blocks(content, file_id):
    exercises = []
    # Match patterns like -- BÀI TẬP 1: ... or -- CÂU HỎI 1: ... or -- ĐỀ BÀI 1: ... or -- BÀI TOÁN 1: ... or -- BƯỚC 1: ...
    pattern = re.compile(
        r'--\s*={3,}\s*\n'
        r'--\s*(BÀI TẬP|CÂU HỎI|ĐỀ BÀI|BÀI TOÁN|CASE STUDY|BƯỚC)\s+(\d+)\s*(?:\(([^)]+)\))?:\s*(.+?)\s*\n'
        r'--\s*={3,}\s*\n'
        r'(.*?)'
        r'(?=(?:--\s*={3,}\s*\n--\s*(?:BÀI TẬP|CÂU HỎI|ĐỀ BÀI|BÀI TOÁN|CASE STUDY|BƯỚC)\s+\d+)|$)',
        re.DOTALL | re.IGNORECASE
    )

    matches = list(pattern.finditer(content))
    for m in matches:
        kind = m.group(1).strip()
        num = int(m.group(2).strip())
        level = m.group(3).strip() if m.group(3) else ('Thực hành' if kind in ('BÀI TẬP', 'ĐỀ BÀI') else kind)
        title = m.group(4).strip()
        body = m.group(5)

        # Extract requirements/description
        req_match = re.search(r'--\s*(?:YÊU CẦU|Đề bài|MÔ TẢ|Insight mong muốn):\s*(.*?)(?=\n--\s*(?:GỢI Ý|Kỹ thuật gợi ý|KẾT QUẢ|VIẾT CÂU|LỜI GIẢI|💬)|$)', body, re.DOTALL | re.IGNORECASE)
        requirements = ""
        if req_match:
            lines = [re.sub(r'^--\s*', '', l) for l in req_match.group(1).strip().split('\n')]
            requirements = '\n'.join(lines).strip()
        elif not req_match:
            # Maybe first few comments
            comments = []
            for line in body.split('\n'):
                line_str = line.strip()
                if line_str.startswith('--') and not any(k in line_str for k in ['GỢI Ý', 'KẾT QUẢ', 'VIẾT CÂU', 'LỜI GIẢI']):
                    comments.append(re.sub(r'^--\s*', '', line_str))
                elif not line_str.startswith('--'):
                    break
            requirements = '\n'.join(comments).strip()

        # Extract hints
        hint_match = re.search(r'--\s*(?:GỢI Ý|Kỹ thuật gợi ý|Ứng dụng):\s*(.*?)(?=\n--\s*(?:KẾT QUẢ|VIẾT CÂU|LỜI GIẢI|💬)|$)', body, re.DOTALL | re.IGNORECASE)
        hints = ""
        if hint_match:
            lines = [re.sub(r'^--\s*', '', l) for l in hint_match.group(1).strip().split('\n')]
            hints = '\n'.join(lines).strip()

        # Extract expected output
        expected_match = re.search(r'--\s*KẾT QUẢ ĐẦU RA MONG ĐỢI[^\n]*\n(.*?)(?=\n--\s*VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY|\n--\s*LỜI GIẢI|\n(?:SELECT|WITH|INSERT|CREATE)|$)', body, re.DOTALL | re.IGNORECASE)
        expected_output = ""
        if expected_match:
            lines = [re.sub(r'^--\s*', '', l) for l in expected_match.group(1).strip().split('\n')]
            expected_output = '\n'.join(lines).strip()

        # Extract solution SQL and notes
        sol_match = re.search(r'(?:--\s*VIẾT CÂU LỆNH SQL CỦA BẠN TẠI ĐÂY:\s*\n)?(?:--\s*LỜI GIẢI[^\n]*\n)?(.*)', body, re.DOTALL | re.IGNORECASE)
        sol_text = sol_match.group(1) if sol_match else body

        # Extract callout notes: lines starting with -- 💡, -- 🧠, -- 💬, -- ⚠️, -- 📌
        notes = []
        sql_lines = []
        for line in sol_text.split('\n'):
            stripped = line.strip()
            if any(stripped.startswith(f'-- {icon}') or stripped.startswith(f'--{icon}') for icon in ['💡', '🧠', '💬', '⚠️', '📌', '⭐']):
                notes.append(re.sub(r'^--\s*', '', stripped))
            elif stripped.startswith('-- LỜI GIẢI') or stripped.startswith('-- VIẾT CÂU LỆNH'):
                continue
            elif stripped.startswith('-- KẾT QUẢ') or stripped.startswith('-- YÊU CẦU') or stripped.startswith('-- GỢI Ý'):
                continue
            else:
                sql_lines.append(line)

        solution_sql = '\n'.join(sql_lines).strip()
        solution_sql = re.sub(r'^\s*;\s*', '', solution_sql).strip()

        ex_id = f"{file_id}_ex{num:02d}"

        # If solution is blank, check DEFAULT_SOLUTIONS
        if not solution_sql and ex_id in DEFAULT_SOLUTIONS:
            solution_sql = DEFAULT_SOLUTIONS[ex_id]

        exercises.append({
            'id': ex_id,
            'kind': kind,
            'num': num,
            'level': level,
            'title': title,
            'requirements': requirements,
            'hints': hints,
            'expected_output': expected_output,
            'solution_sql': solution_sql,
            'notes': notes
        })
    return exercises


def parse_sql_lecture(content, file_id):
    title_match = re.search(r'--\s*BÀI GIẢNG\s*\d*:\s*(.+?)\n', content, re.IGNORECASE)
    title = title_match.group(1).strip() if title_match else ""

    target_match = re.search(r'--\s*MỤC TIÊU:\s*(.+?)(?=\n--\s*[A-ZÀ-Ỹ]|\n--\s*={3,}|$)', content, re.DOTALL | re.IGNORECASE)
    target = ""
    if target_match:
        lines = [re.sub(r'^--\s*', '', l) for l in target_match.group(1).strip().split('\n')]
        target = ' '.join(lines).strip()

    sections = []
    raw_sections = re.split(r'\n--\s*-{10,}\s*\n--\s*(\d+(?:\.\d+)?\.?\s+[^\n]+)\s*\n--\s*-{10,}\s*\n', content)
    if len(raw_sections) > 1:
        for i in range(1, len(raw_sections), 2):
            sec_title = raw_sections[i].strip()
            sec_content = raw_sections[i+1] if i + 1 < len(raw_sections) else ""
            sections.append({
                'title': sec_title,
                'content': sec_content.strip()
            })
    return title, target, sections


def build_all():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    site_dir = os.path.join(base_dir, 'site')
    os.makedirs(site_dir, exist_ok=True)

    print("1. Parsing init_database.sql...")
    db_file = os.path.join(base_dir, 'init_database.sql')
    table_defs, table_data = parse_database_init(db_file)
    print(f"   Found {len(table_defs)} tables, {len(table_data)} seeded tables.")

    # Write seed_data.js
    seed_js_path = os.path.join(site_dir, 'seed_data.js')
    with open(seed_js_path, 'w', encoding='utf-8') as f:
        f.write("// Auto-generated from init_database.sql\n")
        f.write("window.DB_SCHEMA = " + json.dumps(table_defs, ensure_ascii=False, indent=2) + ";\n\n")
        f.write("window.DB_SEED = " + json.dumps(table_data, ensure_ascii=False, indent=2) + ";\n")
    print(f"   Written {seed_js_path} ({os.path.getsize(seed_js_path)} bytes)")

    print("\n2. Scanning and parsing all lesson files...")
    modules = [
        {
            'id': 'm00',
            'folder': '',
            'name': '📖 00. Hướng Dẫn Dành Cho Người Mới',
            'desc': 'Khái niệm Database, Table, Row, Column, thứ tự thực thi truy vấn và cách học an toàn.',
            'badge': 'Bắt đầu',
            'track': 'All',
            'files': ['00_huong_dan_nguoi_moi.md']
        },
        {
            'id': 'm01',
            'folder': '01_foundation_querying',
            'name': '📌 Module 01: Nền Tảng Truy Vấn (Foundation)',
            'desc': 'SELECT, ALIAS, WHERE, ORDER BY, LIMIT, ép kiểu CAST, xử lý NULL và DISTINCT ON.',
            'badge': 'Cốt lõi',
            'track': 'Foundation',
            'files': [
                '01_select_from.sql',
                '02_where_filtering.sql',
                '03_order_limit.sql',
                '04_data_types_type_casting.sql',
                '05_practice_exercises.sql'
            ]
        },
        {
            'id': 'm02',
            'folder': '02_aggregation_grouping',
            'name': '📌 Module 02: Gom Nhóm & Tổng Hợp (Aggregation)',
            'desc': 'COUNT, SUM, AVG, GROUP BY, HAVING, CASE WHEN, COALESCE, DATE_TRUNC, EXTRACT, CUBE & ROLLUP.',
            'badge': 'Cốt lõi',
            'track': 'Foundation',
            'files': [
                '01_aggregate_functions.sql',
                '02_group_by_having.sql',
                '03_case_when_coalesce.sql',
                '04_date_time_aggregations.sql',
                '05_practice_exercises.sql'
            ]
        },
        {
            'id': 'm03',
            'folder': '03_table_joins',
            'name': '📌 Module 03: Kết Hợp Bảng & Quan Hệ (Table Joins)',
            'desc': 'INNER, LEFT, RIGHT, FULL OUTER, CROSS JOIN, SELF JOIN, Semi-Join, Anti-Join, Non-Equi Joins & LATERAL.',
            'badge': 'Quan trọng',
            'track': 'Foundation',
            'files': [
                '01_inner_left_right.sql',
                '02_full_cross_self_anti.sql',
                '03_set_operations.sql',
                '04_advanced_join_patterns.sql',
                '05_practice_exercises.sql'
            ]
        },
        {
            'id': 'm04',
            'folder': '04_advanced_analytics_da',
            'name': '🎯 Module 04: Phân Tích Nâng Cao (Data Analyst Track)',
            'desc': 'Subqueries, CTE, CTE Đệ quy, Window Functions (Ranking, Running Total, Moving Avg), Cohort Retention, Funnel, RFM.',
            'badge': 'Data Analyst',
            'track': 'DA',
            'files': [
                '01_subqueries_cte.sql',
                '02_window_functions_ranking.sql',
                '03_window_functions_time_series.sql',
                '04_cohort_retention_funnel.sql',
                '05_pivot_unpivot_matrix.sql',
                '06_rfm_customer_segmentation.sql',
                '07_practice_exercises.sql'
            ]
        },
        {
            'id': 'm05',
            'folder': '05_engineering_systems_de',
            'name': '⚙️ Module 05: Kỹ Thuật Hệ Thống & Tối Ưu (Data Engineer Track)',
            'desc': 'DDL & Constraints, ACID Transactions, UPSERT/MERGE, SCD Type 1-4, Performance Tuning (EXPLAIN, B-Tree, GIN, BRIN), Partitioning, JSONB.',
            'badge': 'Data Engineer',
            'track': 'DE',
            'files': [
                '01_ddl_constraints.sql',
                '02_transactions_upsert.sql',
                '03_data_modeling_scd.sql',
                '04_performance_tuning.sql',
                '05_partitioning_maintenance.sql',
                '06_json_semistructured_data.sql',
                '07_practice_exercises.sql'
            ]
        },
        {
            'id': 'm06',
            'folder': '06_real_world_projects_and_interview_prep',
            'name': '🏆 Module 06: Dự Án Thực Chiến & Luyện Phỏng Vấn FAANG',
            'desc': 'Case Study E-commerce DA (7 bài toán chiến lược), Pipeline ETL/ELT DE (5 bước kiến trúc DWH), Tuyển tập 5 câu hỏi FAANG.',
            'badge': 'Thực chiến',
            'track': 'Projects',
            'files': [
                '01_ecommerce_da_case_study.sql',
                '02_data_pipeline_de_project.sql',
                '03_faang_interview_sql_questions.sql'
            ]
        },
        {
            'id': 'm07',
            'folder': '07_capstone_exercises_and_solutions',
            'name': '🎓 Module 07: Đề Thi Thử Capstone Mock Exams',
            'desc': 'Đề thi Senior Data Analyst & Senior Data Engineer tổng hợp kiểm tra toàn bộ kỹ năng thực chiến.',
            'badge': 'Đề thi',
            'track': 'Capstone',
            'files': [
                '01_da_analytics_exam.sql',
                '02_de_pipeline_exam.sql'
            ]
        }
    ]

    all_lessons = []
    total_exercises_count = 0

    for m in modules:
        for filename in m['files']:
            filepath = os.path.join(base_dir, m['folder'], filename) if m['folder'] else os.path.join(base_dir, filename)
            if not os.path.exists(filepath):
                print(f"   [WARN] File not found: {filepath}")
                continue

            with open(filepath, 'r', encoding='utf-8') as f:
                raw_text = f.read()

            file_id = f"{m['id']}_{os.path.splitext(filename)[0]}"
            is_practice = ('practice' in filename.lower() or 
                           'exam' in filename.lower() or 
                           'case_study' in filename.lower() or 
                           'faang' in filename.lower() or
                           'pipeline_de_project' in filename.lower())
            
            is_markdown = filename.endswith('.md')
            
            # Extract exercises if any
            exercises = parse_exercise_blocks(raw_text, file_id)
            total_exercises_count += len(exercises)

            # Extract title and description
            title = ""
            desc = ""
            if is_markdown:
                title_m = re.search(r'^#\s+(.+)$', raw_text, re.MULTILINE)
                title = title_m.group(1).strip() if title_m else filename
                desc = "Hướng dẫn chi tiết từng bước cho người mới bắt đầu học SQL."
            else:
                lec_title, lec_target, sections = parse_sql_lecture(raw_text, file_id)
                title = lec_title if lec_title else filename
                desc = lec_target

            if not title or title.endswith('.sql'):
                # Fallback clean title
                clean_name = os.path.splitext(filename)[0]
                if clean_name == '01_ecommerce_da_case_study':
                    title = "Case Study DA: 7 Bài Toán Phân Tích Kinh Doanh E-commerce"
                elif clean_name == '02_data_pipeline_de_project':
                    title = "Dự Án DE: Xây Dựng Data Pipeline & ETL/ELT Warehouse"
                elif clean_name == '03_faang_interview_sql_questions':
                    title = "Tuyển Tập 5 Câu Hỏi SQL Phỏng Vấn FAANG / Big Tech"
                elif clean_name == '01_da_analytics_exam':
                    title = "Đề Thi Thử Senior Data Analyst (3 Bài Toán Chiến Lược)"
                elif clean_name == '02_de_pipeline_exam':
                    title = "Đề Thi Thử Senior Data Engineer (Data Quality & SCD2)"
                elif 'practice_exercises' in clean_name:
                    mod_num = m['id'].replace('m', '')
                    title = f"✍️ Bài Tập Thực Hành & Thử Thách Module {mod_num}"
                else:
                    title = clean_name.replace('_', ' ').capitalize()

            lesson_data = {
                'id': file_id,
                'moduleId': m['id'],
                'moduleName': m['name'],
                'track': m['track'],
                'filename': filename,
                'filepath': os.path.relpath(filepath, base_dir).replace('\\', '/'),
                'title': title,
                'desc': desc,
                'isPractice': is_practice or len(exercises) > 0,
                'isMarkdown': is_markdown,
                'exerciseCount': len(exercises),
                'exercises': exercises,
                'rawContent': raw_text
            }
            all_lessons.append(lesson_data)
            print(f"   [OK] {filename} -> {len(exercises)} exercises parsed. Title: {title[:40]}...")

    # Also load README.md and init_database.sql as special reference docs
    readme_path = os.path.join(base_dir, 'README.md')
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            all_lessons.append({
                'id': 'doc_readme',
                'moduleId': 'docs',
                'moduleName': '📚 Giới Thiệu & Lộ Trình',
                'track': 'All',
                'filename': 'README.md',
                'filepath': 'README.md',
                'title': '🚀 Lộ Trình & Tổng Quan SQL Mastery (DA & DE)',
                'desc': 'Tổng quan dự án, sơ đồ ERD, chuẩn Clean Code và phương pháp học.',
                'isPractice': False,
                'isMarkdown': True,
                'exerciseCount': 0,
                'exercises': [],
                'rawContent': f.read()
            })

    init_sql_path = os.path.join(base_dir, 'init_database.sql')
    if os.path.exists(init_sql_path):
        with open(init_sql_path, 'r', encoding='utf-8') as f:
            all_lessons.append({
                'id': 'doc_init_db',
                'moduleId': 'docs',
                'moduleName': '🗄️ Cấu Trúc Database Mẫu',
                'track': 'All',
                'filename': 'init_database.sql',
                'filepath': 'init_database.sql',
                'title': '🗄️ Script Khởi Tạo CSDL E-commerce & Seed Data',
                'desc': 'DDL tạo 8 bảng quan hệ, ràng buộc và dữ liệu thực hành.',
                'isPractice': False,
                'isMarkdown': False,
                'exerciseCount': 0,
                'exercises': [],
                'rawContent': f.read()
            })

    # Output data.js
    data_js_path = os.path.join(site_dir, 'data.js')
    output_bundle = {
        'modules': modules,
        'lessons': all_lessons,
        'stats': {
            'totalModules': len(modules),
            'totalLessons': len(all_lessons),
            'totalExercises': total_exercises_count,
            'tablesCount': len(table_defs)
        }
    }

    with open(data_js_path, 'w', encoding='utf-8') as f:
        f.write("// Auto-generated by build.py\n")
        f.write("window.SQL_MASTERY_DATA = " + json.dumps(output_bundle, ensure_ascii=False) + ";\n")

    print(f"\n3. Complete! Generated site/data.js ({os.path.getsize(data_js_path)} bytes)")
    print(f"   Total Lessons: {len(all_lessons)}")
    print(f"   Total Interactive Exercises: {total_exercises_count}")

if __name__ == '__main__':
    build_all()
