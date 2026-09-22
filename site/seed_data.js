// Auto-generated from init_database.sql
window.DB_SCHEMA = {
  "categories": [
    {
      "name": "category_id",
      "type": "INT",
      "raw": "category_id INT PRIMARY KEY"
    },
    {
      "name": "category_name",
      "type": "VARCHAR(100)",
      "raw": "category_name VARCHAR(100) NOT NULL"
    },
    {
      "name": "parent_category_id",
      "type": "INT",
      "raw": "parent_category_id INT REFERENCES categories(category_id)"
    },
    {
      "name": "is_active",
      "type": "BOOLEAN",
      "raw": "is_active BOOLEAN DEFAULT TRUE"
    },
    {
      "name": "created_at",
      "type": "TIMESTAMP",
      "raw": "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
    }
  ],
  "customers": [
    {
      "name": "customer_id",
      "type": "INT",
      "raw": "customer_id INT PRIMARY KEY"
    },
    {
      "name": "first_name",
      "type": "VARCHAR(50)",
      "raw": "first_name VARCHAR(50) NOT NULL"
    },
    {
      "name": "last_name",
      "type": "VARCHAR(50)",
      "raw": "last_name VARCHAR(50) NOT NULL"
    },
    {
      "name": "email",
      "type": "VARCHAR(100)",
      "raw": "email VARCHAR(100) UNIQUE NOT NULL"
    },
    {
      "name": "gender",
      "type": "VARCHAR(10)",
      "raw": "gender VARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other'))"
    },
    {
      "name": "birth_date",
      "type": "DATE,",
      "raw": "birth_date DATE"
    },
    {
      "name": "city",
      "type": "VARCHAR(50),",
      "raw": "city VARCHAR(50)"
    },
    {
      "name": "country",
      "type": "VARCHAR(50)",
      "raw": "country VARCHAR(50) DEFAULT 'Vietnam'"
    },
    {
      "name": "customer_segment",
      "type": "VARCHAR(20)",
      "raw": "customer_segment VARCHAR(20) DEFAULT 'Standard', -- Standard, Silver, Gold, VIP"
    },
    {
      "name": "signup_date",
      "type": "TIMESTAMP",
      "raw": "signup_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
    }
  ],
  "employees": [
    {
      "name": "employee_id",
      "type": "INT",
      "raw": "employee_id INT PRIMARY KEY"
    },
    {
      "name": "first_name",
      "type": "VARCHAR(50)",
      "raw": "first_name VARCHAR(50) NOT NULL"
    },
    {
      "name": "last_name",
      "type": "VARCHAR(50)",
      "raw": "last_name VARCHAR(50) NOT NULL"
    },
    {
      "name": "email",
      "type": "VARCHAR(100)",
      "raw": "email VARCHAR(100) UNIQUE NOT NULL"
    },
    {
      "name": "department",
      "type": "VARCHAR(50),",
      "raw": "department VARCHAR(50)"
    },
    {
      "name": "manager_id",
      "type": "INT",
      "raw": "manager_id INT REFERENCES employees(employee_id)"
    },
    {
      "name": "salary",
      "type": "NUMERIC(12,",
      "raw": "salary NUMERIC(12, 2) NOT NULL"
    },
    {
      "name": "hire_date",
      "type": "DATE",
      "raw": "hire_date DATE NOT NULL"
    }
  ],
  "products": [
    {
      "name": "product_id",
      "type": "INT",
      "raw": "product_id INT PRIMARY KEY"
    },
    {
      "name": "product_name",
      "type": "VARCHAR(150)",
      "raw": "product_name VARCHAR(150) NOT NULL"
    },
    {
      "name": "category_id",
      "type": "INT",
      "raw": "category_id INT REFERENCES categories(category_id)"
    },
    {
      "name": "cost_price",
      "type": "NUMERIC(12,",
      "raw": "cost_price NUMERIC(12, 2) NOT NULL"
    },
    {
      "name": "unit_price",
      "type": "NUMERIC(12,",
      "raw": "unit_price NUMERIC(12, 2) NOT NULL"
    },
    {
      "name": "stock_quantity",
      "type": "INT",
      "raw": "stock_quantity INT DEFAULT 0"
    },
    {
      "name": "is_discontinued",
      "type": "BOOLEAN",
      "raw": "is_discontinued BOOLEAN DEFAULT FALSE"
    },
    {
      "name": "specs",
      "type": "JSONB,",
      "raw": "specs JSONB, -- Semi-structured JSON/JSONB specs"
    },
    {
      "name": "created_at",
      "type": "TIMESTAMP",
      "raw": "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
    }
  ],
  "orders": [
    {
      "name": "order_id",
      "type": "INT",
      "raw": "order_id INT PRIMARY KEY"
    },
    {
      "name": "customer_id",
      "type": "INT",
      "raw": "customer_id INT REFERENCES customers(customer_id)"
    },
    {
      "name": "order_date",
      "type": "TIMESTAMP",
      "raw": "order_date TIMESTAMP NOT NULL"
    },
    {
      "name": "order_status",
      "type": "VARCHAR(20)",
      "raw": "order_status VARCHAR(20) CHECK (order_status IN ('Pending', 'Processing', 'Completed', 'Cancelled', 'Refunded'))"
    },
    {
      "name": "shipping_address",
      "type": "VARCHAR(255),",
      "raw": "shipping_address VARCHAR(255)"
    },
    {
      "name": "shipping_city",
      "type": "VARCHAR(50),",
      "raw": "shipping_city VARCHAR(50)"
    },
    {
      "name": "shipping_fee",
      "type": "NUMERIC(10,",
      "raw": "shipping_fee NUMERIC(10, 2) DEFAULT 0.00"
    },
    {
      "name": "payment_method",
      "type": "VARCHAR(30)",
      "raw": "payment_method VARCHAR(30) -- Credit Card, Bank Transfer, COD, E-Wallet"
    }
  ],
  "order_items": [
    {
      "name": "order_item_id",
      "type": "INT",
      "raw": "order_item_id INT PRIMARY KEY"
    },
    {
      "name": "order_id",
      "type": "INT",
      "raw": "order_id INT REFERENCES orders(order_id) ON DELETE CASCADE"
    },
    {
      "name": "product_id",
      "type": "INT",
      "raw": "product_id INT REFERENCES products(product_id)"
    },
    {
      "name": "quantity",
      "type": "INT",
      "raw": "quantity INT NOT NULL CHECK (quantity > 0)"
    },
    {
      "name": "unit_price",
      "type": "NUMERIC(12,",
      "raw": "unit_price NUMERIC(12, 2) NOT NULL"
    },
    {
      "name": "discount_pct",
      "type": "NUMERIC(5,",
      "raw": "discount_pct NUMERIC(5, 2) DEFAULT 0.00 -- 0.05 = 5%"
    }
  ],
  "payments": [
    {
      "name": "payment_id",
      "type": "INT",
      "raw": "payment_id INT PRIMARY KEY"
    },
    {
      "name": "order_id",
      "type": "INT",
      "raw": "order_id INT REFERENCES orders(order_id)"
    },
    {
      "name": "payment_date",
      "type": "TIMESTAMP",
      "raw": "payment_date TIMESTAMP NOT NULL"
    },
    {
      "name": "amount",
      "type": "NUMERIC(12,",
      "raw": "amount NUMERIC(12, 2) NOT NULL"
    },
    {
      "name": "payment_status",
      "type": "VARCHAR(20)",
      "raw": "payment_status VARCHAR(20) CHECK (payment_status IN ('Success', 'Failed', 'Pending', 'Refunded'))"
    },
    {
      "name": "transaction_ref",
      "type": "VARCHAR(100)",
      "raw": "transaction_ref VARCHAR(100) UNIQUE"
    }
  ],
  "web_events": [
    {
      "name": "event_id",
      "type": "BIGINT",
      "raw": "event_id BIGINT PRIMARY KEY"
    },
    {
      "name": "session_id",
      "type": "VARCHAR(64)",
      "raw": "session_id VARCHAR(64) NOT NULL"
    },
    {
      "name": "customer_id",
      "type": "INT,",
      "raw": "customer_id INT, -- NULL if guest visitor"
    },
    {
      "name": "event_time",
      "type": "TIMESTAMP",
      "raw": "event_time TIMESTAMP NOT NULL"
    },
    {
      "name": "event_type",
      "type": "VARCHAR(50)",
      "raw": "event_type VARCHAR(50) NOT NULL, -- page_view, search, add_to_cart, checkout_start, purchase"
    },
    {
      "name": "page_url",
      "type": "VARCHAR(255),",
      "raw": "page_url VARCHAR(255)"
    },
    {
      "name": "device_type",
      "type": "VARCHAR(20),",
      "raw": "device_type VARCHAR(20), -- Mobile, Desktop, Tablet"
    },
    {
      "name": "metadata",
      "type": "JSONB",
      "raw": "metadata JSONB"
    }
  ],
  "inventory_logs": [
    {
      "name": "log_id",
      "type": "INT",
      "raw": "log_id INT PRIMARY KEY"
    },
    {
      "name": "product_id",
      "type": "INT",
      "raw": "product_id INT REFERENCES products(product_id)"
    },
    {
      "name": "change_type",
      "type": "VARCHAR(20),",
      "raw": "change_type VARCHAR(20), -- RESTOCK, SALE, RETURN, DAMAGE"
    },
    {
      "name": "quantity_changed",
      "type": "INT",
      "raw": "quantity_changed INT NOT NULL"
    },
    {
      "name": "log_date",
      "type": "TIMESTAMP",
      "raw": "log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
    },
    {
      "name": "notes",
      "type": "TEXT",
      "raw": "notes TEXT"
    }
  ]
};

window.DB_SEED = {
  "categories": [
    {
      "category_id": 1,
      "category_name": "Electronics",
      "parent_category_id": null,
      "is_active": true
    },
    {
      "category_id": 2,
      "category_name": "Smartphones & Tablets",
      "parent_category_id": 1,
      "is_active": true
    },
    {
      "category_id": 3,
      "category_name": "Laptops & Computers",
      "parent_category_id": 1,
      "is_active": true
    },
    {
      "category_id": 4,
      "category_name": "Audio & Accessories",
      "parent_category_id": 1,
      "is_active": true
    },
    {
      "category_id": 5,
      "category_name": "Home & Living",
      "parent_category_id": null,
      "is_active": true
    },
    {
      "category_id": 6,
      "category_name": "Kitchen Appliances",
      "parent_category_id": 5,
      "is_active": true
    },
    {
      "category_id": 7,
      "category_name": "Fashion & Apparel",
      "parent_category_id": null,
      "is_active": true
    },
    {
      "category_id": 8,
      "category_name": "Books & Media",
      "parent_category_id": null,
      "is_active": false
    }
  ],
  "customers": [
    {
      "customer_id": 1,
      "first_name": "Nguyen",
      "last_name": "Van An",
      "email": "an.nguyen@example.com",
      "gender": "Male",
      "birth_date": "1992-05-14",
      "city": "Ho Chi Minh",
      "country": "Vietnam",
      "customer_segment": "VIP",
      "signup_date": "2023-01-10 08:30:00"
    },
    {
      "customer_id": 2,
      "first_name": "Tran",
      "last_name": "Thi Bich",
      "email": "bich.tran@example.com",
      "gender": "Female",
      "birth_date": "1995-11-20",
      "city": "Hanoi",
      "country": "Vietnam",
      "customer_segment": "Gold",
      "signup_date": "2023-02-15 09:45:00"
    },
    {
      "customer_id": 3,
      "first_name": "Le",
      "last_name": "Quoc Cuong",
      "email": "cuong.le@example.com",
      "gender": "Male",
      "birth_date": "1988-03-08",
      "city": "Da Nang",
      "country": "Vietnam",
      "customer_segment": "Silver",
      "signup_date": "2023-03-01 14:15:00"
    },
    {
      "customer_id": 4,
      "first_name": "Pham",
      "last_name": "Thanh Dung",
      "email": "dung.pham@example.com",
      "gender": "Female",
      "birth_date": "1998-07-25",
      "city": "Ho Chi Minh",
      "country": "Vietnam",
      "customer_segment": "Standard",
      "signup_date": "2023-03-20 11:20:00"
    },
    {
      "customer_id": 5,
      "first_name": "Hoang",
      "last_name": "Minh Em",
      "email": "em.hoang@example.com",
      "gender": "Male",
      "birth_date": "1990-12-30",
      "city": "Can Tho",
      "country": "Vietnam",
      "customer_segment": "Gold",
      "signup_date": "2023-04-05 16:50:00"
    },
    {
      "customer_id": 6,
      "first_name": "Vu",
      "last_name": "Thi Giang",
      "email": "giang.vu@example.com",
      "gender": "Female",
      "birth_date": "2001-09-12",
      "city": "Hanoi",
      "country": "Vietnam",
      "customer_segment": "Standard",
      "signup_date": "2023-05-12 10:05:00"
    },
    {
      "customer_id": 7,
      "first_name": "David",
      "last_name": "Smith",
      "email": "david.smith@global.com",
      "gender": "Male",
      "birth_date": "1985-04-18",
      "city": "Singapore",
      "country": "Singapore",
      "customer_segment": "VIP",
      "signup_date": "2023-05-25 13:40:00"
    },
    {
      "customer_id": 8,
      "first_name": "Do",
      "last_name": "Hoang Hai",
      "email": "hai.do@example.com",
      "gender": "Male",
      "birth_date": "1994-01-03",
      "city": "Hai Phong",
      "country": "Vietnam",
      "customer_segment": "Silver",
      "signup_date": "2023-06-18 15:30:00"
    },
    {
      "customer_id": 9,
      "first_name": "Ngo",
      "last_name": "Ngoc Khanh",
      "email": "khanh.ngo@example.com",
      "gender": "Female",
      "birth_date": "1997-08-19",
      "city": "Ho Chi Minh",
      "country": "Vietnam",
      "customer_segment": "Standard",
      "signup_date": "2023-07-01 08:00:00"
    },
    {
      "customer_id": 10,
      "first_name": "Bui",
      "last_name": "Van Lam",
      "email": "lam.bui@example.com",
      "gender": "Male",
      "birth_date": "1989-10-10",
      "city": "Hanoi",
      "country": "Vietnam",
      "customer_segment": "Standard",
      "signup_date": "2023-08-10 19:25:00"
    }
  ],
  "employees": [
    {
      "employee_id": 1,
      "first_name": "Tran",
      "last_name": "Tung Lam",
      "email": "ceo@company.com",
      "department": "Executive",
      "manager_id": null,
      "salary": 120000000.0,
      "hire_date": "2020-01-01"
    },
    {
      "employee_id": 2,
      "first_name": "Nguyen",
      "last_name": "Hoang Nam",
      "email": "nam.nguyen@company.com",
      "department": "Engineering",
      "manager_id": 1,
      "salary": 75000000.0,
      "hire_date": "2020-03-15"
    },
    {
      "employee_id": 3,
      "first_name": "Le",
      "last_name": "Thu Thao",
      "email": "thao.le@company.com",
      "department": "Sales & Marketing",
      "manager_id": 1,
      "salary": 70000000.0,
      "hire_date": "2020-04-01"
    },
    {
      "employee_id": 4,
      "first_name": "Pham",
      "last_name": "Duc Thang",
      "email": "thang.pham@company.com",
      "department": "Engineering",
      "manager_id": 2,
      "salary": 45000000.0,
      "hire_date": "2021-06-01"
    },
    {
      "employee_id": 5,
      "first_name": "Vu",
      "last_name": "Quang Huy",
      "email": "huy.vu@company.com",
      "department": "Engineering",
      "manager_id": 2,
      "salary": 38000000.0,
      "hire_date": "2022-01-15"
    },
    {
      "employee_id": 6,
      "first_name": "Doan",
      "last_name": "My Linh",
      "email": "linh.doan@company.com",
      "department": "Sales & Marketing",
      "manager_id": 3,
      "salary": 30000000.0,
      "hire_date": "2022-03-01"
    },
    {
      "employee_id": 7,
      "first_name": "Ho",
      "last_name": "Bao Ngoc",
      "email": "ngoc.ho@company.com",
      "department": "Sales & Marketing",
      "manager_id": 3,
      "salary": 28000000.0,
      "hire_date": "2022-08-10"
    },
    {
      "employee_id": 8,
      "first_name": "Dang",
      "last_name": "Minh Tri",
      "email": "tri.dang@company.com",
      "department": "Engineering",
      "manager_id": 4,
      "salary": 22000000.0,
      "hire_date": "2023-02-01"
    }
  ],
  "products": [
    {
      "product_id": 101,
      "product_name": "iPhone 15 Pro Max 256GB",
      "category_id": 2,
      "cost_price": 26000000,
      "unit_price": 32000000,
      "stock_quantity": 45,
      "is_discontinued": false,
      "specs": "{\"color\": \"Natural Titanium\", \"ram\": \"8GB\", \"storage\": \"256GB\", \"chip\": \"A17 Pro\", \"weight_g\": 221}"
    },
    {
      "product_id": 102,
      "product_name": "Samsung Galaxy S24 Ultra",
      "category_id": 2,
      "cost_price": 24000000,
      "unit_price": 29990000,
      "stock_quantity": 30,
      "is_discontinued": false,
      "specs": "{\"color\": \"Titanium Black\", \"ram\": \"12GB\", \"storage\": \"512GB\", \"chip\": \"Snapdragon 8 Gen 3\", \"stylus\": true}"
    },
    {
      "product_id": 103,
      "product_name": "MacBook Pro 14 M3 Pro",
      "category_id": 3,
      "cost_price": 38000000,
      "unit_price": 48000000,
      "stock_quantity": 18,
      "is_discontinued": false,
      "specs": "{\"color\": \"Space Black\", \"ram\": \"18GB\", \"storage\": \"512GB\", \"chip\": \"M3 Pro\", \"screen_inch\": 14.2}"
    },
    {
      "product_id": 104,
      "product_name": "Dell XPS 15 9530",
      "category_id": 3,
      "cost_price": 32000000,
      "unit_price": 41500000,
      "stock_quantity": 12,
      "is_discontinued": false,
      "specs": "{\"color\": \"Silver\", \"ram\": \"32GB\", \"storage\": \"1TB\", \"chip\": \"Intel Core i7-13700H\", \"gpu\": \"RTX 4060\"}"
    },
    {
      "product_id": 105,
      "product_name": "Sony WH-1000XM5 Headphone",
      "category_id": 4,
      "cost_price": 6000000,
      "unit_price": 8490000,
      "stock_quantity": 60,
      "is_discontinued": false,
      "specs": "{\"color\": \"Silver\", \"battery_hours\": 30, \"noise_cancelling\": true, \"bluetooth\": \"5.2\"}"
    },
    {
      "product_id": 106,
      "product_name": "AirPods Pro 2 USB-C",
      "category_id": 4,
      "cost_price": 4500000,
      "unit_price": 5990000,
      "stock_quantity": 85,
      "is_discontinued": false,
      "specs": "{\"color\": \"White\", \"battery_hours\": 24, \"noise_cancelling\": true, \"chip\": \"H2\"}"
    },
    {
      "product_id": 107,
      "product_name": "Air Fryer Philips XXL HD9650",
      "category_id": 6,
      "cost_price": 4200000,
      "unit_price": 6290000,
      "stock_quantity": 25,
      "is_discontinued": false,
      "specs": "{\"capacity_l\": 7.3, \"power_w\": 2225, \"digital_display\": true}"
    },
    {
      "product_id": 108,
      "product_name": "Robot Vacuum Dreame L20 Ultra",
      "category_id": 6,
      "cost_price": 16000000,
      "unit_price": 21900000,
      "stock_quantity": 15,
      "is_discontinued": false,
      "specs": "{\"suction_pa\": 7000, \"auto_empty\": true, \"mopping\": true, \"lidar\": true}"
    },
    {
      "product_id": 109,
      "product_name": "Vintage Leather Jacket",
      "category_id": 7,
      "cost_price": 1200000,
      "unit_price": 2490000,
      "stock_quantity": 40,
      "is_discontinued": false,
      "specs": "{\"material\": \"Genuine Cow Leather\", \"color\": \"Brown\", \"sizes\": [\"M\", \"L\", \"XL\"]}"
    },
    {
      "product_id": 110,
      "product_name": "Outdated Android Tablet Gen 1",
      "category_id": 2,
      "cost_price": 2000000,
      "unit_price": 2500000,
      "stock_quantity": 0,
      "is_discontinued": true,
      "specs": "{\"color\": \"Black\", \"storage\": \"16GB\", \"os\": \"Android 5.0\"}"
    }
  ],
  "orders": [
    {
      "order_id": 1001,
      "customer_id": 1,
      "order_date": "2023-09-01 10:15:00",
      "order_status": "Completed",
      "shipping_address": "123 Nguyen Hue, District 1",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 30000,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1002,
      "customer_id": 2,
      "order_date": "2023-09-02 14:20:00",
      "order_status": "Completed",
      "shipping_address": "45 Trang Tien, Hoan Kiem",
      "shipping_city": "Hanoi",
      "shipping_fee": 40000,
      "payment_method": "Bank Transfer"
    },
    {
      "order_id": 1003,
      "customer_id": 3,
      "order_date": "2023-09-05 09:00:00",
      "order_status": "Completed",
      "shipping_address": "78 Bach Dang, Hai Chau",
      "shipping_city": "Da Nang",
      "shipping_fee": 35000,
      "payment_method": "E-Wallet"
    },
    {
      "order_id": 1004,
      "customer_id": 1,
      "order_date": "2023-09-12 16:45:00",
      "order_status": "Completed",
      "shipping_address": "123 Nguyen Hue, District 1",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 0,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1005,
      "customer_id": 4,
      "order_date": "2023-09-15 11:30:00",
      "order_status": "Cancelled",
      "shipping_address": "99 Cong Hoa, Tan Binh",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 30000,
      "payment_method": "COD"
    },
    {
      "order_id": 1006,
      "customer_id": 5,
      "order_date": "2023-10-01 08:20:00",
      "order_status": "Completed",
      "shipping_address": "12 30/4 Street, Ninh Kieu",
      "shipping_city": "Can Tho",
      "shipping_fee": 50000,
      "payment_method": "Bank Transfer"
    },
    {
      "order_id": 1007,
      "customer_id": 2,
      "order_date": "2023-10-10 17:10:00",
      "order_status": "Completed",
      "shipping_address": "45 Trang Tien, Hoan Kiem",
      "shipping_city": "Hanoi",
      "shipping_fee": 0,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1008,
      "customer_id": 6,
      "order_date": "2023-10-15 13:00:00",
      "order_status": "Processing",
      "shipping_address": "88 Cau Giay",
      "shipping_city": "Hanoi",
      "shipping_fee": 30000,
      "payment_method": "COD"
    },
    {
      "order_id": 1009,
      "customer_id": 7,
      "order_date": "2023-10-20 19:40:00",
      "order_status": "Completed",
      "shipping_address": "15 Orchard Road",
      "shipping_city": "Singapore",
      "shipping_fee": 150000,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1010,
      "customer_id": 3,
      "order_date": "2023-11-01 10:00:00",
      "order_status": "Completed",
      "shipping_address": "78 Bach Dang, Hai Chau",
      "shipping_city": "Da Nang",
      "shipping_fee": 35000,
      "payment_method": "E-Wallet"
    },
    {
      "order_id": 1011,
      "customer_id": 1,
      "order_date": "2023-11-15 12:15:00",
      "order_status": "Completed",
      "shipping_address": "123 Nguyen Hue, District 1",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 0,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1012,
      "customer_id": 8,
      "order_date": "2023-11-20 15:50:00",
      "order_status": "Completed",
      "shipping_address": "22 Le Hong Phong, Ngo Quyen",
      "shipping_city": "Hai Phong",
      "shipping_fee": 40000,
      "payment_method": "Bank Transfer"
    },
    {
      "order_id": 1013,
      "customer_id": 9,
      "order_date": "2023-12-05 11:00:00",
      "order_status": "Completed",
      "shipping_address": "55 Phan Xich Long, Phu Nhuan",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 30000,
      "payment_method": "E-Wallet"
    },
    {
      "order_id": 1014,
      "customer_id": 5,
      "order_date": "2023-12-12 18:25:00",
      "order_status": "Completed",
      "shipping_address": "12 30/4 Street, Ninh Kieu",
      "shipping_city": "Can Tho",
      "shipping_fee": 0,
      "payment_method": "Bank Transfer"
    },
    {
      "order_id": 1015,
      "customer_id": 2,
      "order_date": "2023-12-24 20:10:00",
      "order_status": "Completed",
      "shipping_address": "45 Trang Tien, Hoan Kiem",
      "shipping_city": "Hanoi",
      "shipping_fee": 0,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1016,
      "customer_id": 1,
      "order_date": "2024-01-05 09:30:00",
      "order_status": "Completed",
      "shipping_address": "123 Nguyen Hue, District 1",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 0,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1017,
      "customer_id": 4,
      "order_date": "2024-01-18 14:00:00",
      "order_status": "Completed",
      "shipping_address": "99 Cong Hoa, Tan Binh",
      "shipping_city": "Ho Chi Minh",
      "shipping_fee": 30000,
      "payment_method": "E-Wallet"
    },
    {
      "order_id": 1018,
      "customer_id": 10,
      "order_date": "2024-01-25 16:30:00",
      "order_status": "Refunded",
      "shipping_address": "101 Nguyen Trai, Thanh Xuan",
      "shipping_city": "Hanoi",
      "shipping_fee": 40000,
      "payment_method": "Bank Transfer"
    },
    {
      "order_id": 1019,
      "customer_id": 7,
      "order_date": "2024-02-10 11:15:00",
      "order_status": "Completed",
      "shipping_address": "15 Orchard Road",
      "shipping_city": "Singapore",
      "shipping_fee": 150000,
      "payment_method": "Credit Card"
    },
    {
      "order_id": 1020,
      "customer_id": 3,
      "order_date": "2024-02-14 15:00:00",
      "order_status": "Completed",
      "shipping_address": "78 Bach Dang, Hai Chau",
      "shipping_city": "Da Nang",
      "shipping_fee": 35000,
      "payment_method": "Credit Card"
    }
  ],
  "order_items": [
    {
      "order_item_id": 1,
      "order_id": 1001,
      "product_id": 101,
      "quantity": 1,
      "unit_price": 32000000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 2,
      "order_id": 1001,
      "product_id": 106,
      "quantity": 1,
      "unit_price": 5990000,
      "discount_pct": 0.05
    },
    {
      "order_item_id": 3,
      "order_id": 1002,
      "product_id": 103,
      "quantity": 1,
      "unit_price": 48000000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 4,
      "order_id": 1003,
      "product_id": 105,
      "quantity": 1,
      "unit_price": 8490000,
      "discount_pct": 0.1
    },
    {
      "order_item_id": 5,
      "order_id": 1004,
      "product_id": 108,
      "quantity": 1,
      "unit_price": 21900000,
      "discount_pct": 0.05
    },
    {
      "order_item_id": 6,
      "order_id": 1005,
      "product_id": 109,
      "quantity": 2,
      "unit_price": 2490000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 7,
      "order_id": 1006,
      "product_id": 102,
      "quantity": 1,
      "unit_price": 29990000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 8,
      "order_id": 1006,
      "product_id": 105,
      "quantity": 1,
      "unit_price": 8490000,
      "discount_pct": 0.05
    },
    {
      "order_item_id": 9,
      "order_id": 1007,
      "product_id": 106,
      "quantity": 2,
      "unit_price": 5990000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 10,
      "order_id": 1008,
      "product_id": 107,
      "quantity": 1,
      "unit_price": 6290000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 11,
      "order_id": 1009,
      "product_id": 103,
      "quantity": 1,
      "unit_price": 48000000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 12,
      "order_id": 1009,
      "product_id": 106,
      "quantity": 1,
      "unit_price": 5990000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 13,
      "order_id": 1010,
      "product_id": 107,
      "quantity": 1,
      "unit_price": 6290000,
      "discount_pct": 0.05
    },
    {
      "order_item_id": 14,
      "order_id": 1011,
      "product_id": 104,
      "quantity": 1,
      "unit_price": 41500000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 15,
      "order_id": 1012,
      "product_id": 101,
      "quantity": 1,
      "unit_price": 32000000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 16,
      "order_id": 1013,
      "product_id": 109,
      "quantity": 1,
      "unit_price": 2490000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 17,
      "order_id": 1014,
      "product_id": 108,
      "quantity": 1,
      "unit_price": 21900000,
      "discount_pct": 0.08
    },
    {
      "order_item_id": 18,
      "order_id": 1015,
      "product_id": 101,
      "quantity": 1,
      "unit_price": 32000000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 19,
      "order_id": 1015,
      "product_id": 105,
      "quantity": 1,
      "unit_price": 8490000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 20,
      "order_id": 1016,
      "product_id": 102,
      "quantity": 1,
      "unit_price": 29990000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 21,
      "order_id": 1017,
      "product_id": 107,
      "quantity": 1,
      "unit_price": 6290000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 22,
      "order_id": 1018,
      "product_id": 105,
      "quantity": 1,
      "unit_price": 8490000,
      "discount_pct": 0.0
    },
    {
      "order_item_id": 23,
      "order_id": 1019,
      "product_id": 101,
      "quantity": 2,
      "unit_price": 32000000,
      "discount_pct": 0.05
    },
    {
      "order_item_id": 24,
      "order_id": 1020,
      "product_id": 106,
      "quantity": 1,
      "unit_price": 5990000,
      "discount_pct": 0.0
    }
  ],
  "payments": [
    {
      "payment_id": 501,
      "order_id": 1001,
      "payment_date": "2023-09-01 10:16:00",
      "amount": 37720500,
      "payment_status": "Success",
      "transaction_ref": "TXN-20230901-001"
    },
    {
      "payment_id": 502,
      "order_id": 1002,
      "payment_date": "2023-09-02 14:22:00",
      "amount": 48040000,
      "payment_status": "Success",
      "transaction_ref": "TXN-20230902-002"
    },
    {
      "payment_id": 503,
      "order_id": 1003,
      "payment_date": "2023-09-05 09:05:00",
      "amount": 7676000,
      "payment_status": "Success",
      "transaction_ref": "TXN-20230905-003"
    },
    {
      "payment_id": 504,
      "order_id": 1004,
      "payment_date": "2023-09-12 16:48:00",
      "amount": 20805000,
      "payment_status": "Success",
      "transaction_ref": "TXN-20230912-004"
    },
    {
      "payment_id": 505,
      "order_id": 1005,
      "payment_date": "2023-09-15 11:35:00",
      "amount": 5010000,
      "payment_status": "Failed",
      "transaction_ref": "TXN-20230915-005"
    },
    {
      "payment_id": 506,
      "order_id": 1006,
      "payment_date": "2023-10-01 08:25:00",
      "amount": 38105500,
      "payment_status": "Success",
      "transaction_ref": "TXN-20231001-006"
    },
    {
      "payment_id": 507,
      "order_id": 1007,
      "payment_date": "2023-10-10 17:15:00",
      "amount": 11980000,
      "payment_status": "Success",
      "transaction_ref": "TXN-20231010-007"
    },
    {
      "payment_id": 508,
      "order_id": 1008,
      "payment_date": "2023-10-15 13:05:00",
      "amount": 6320000,
      "payment_status": "Pending",
      "transaction_ref": "TXN-20231015-008"
    },
    {
      "payment_id": 509,
      "order_id": 1009,
      "payment_date": "2023-10-20 19:45:00",
      "amount": 54140000,
      "payment_status": "Success",
      "transaction_ref": "TXN-20231020-009"
    },
    {
      "payment_id": 510,
      "order_id": 1010,
      "payment_date": "2023-11-01 10:05:00",
      "amount": 6010500,
      "payment_status": "Success",
      "transaction_ref": "TXN-20231101-010"
    }
  ],
  "web_events": [
    {
      "event_id": 1,
      "session_id": "sess_001",
      "customer_id": 1,
      "event_time": "2023-09-01 10:00:00",
      "event_type": "page_view",
      "page_url": "/home",
      "device_type": "Desktop",
      "metadata": "{\"referrer\": \"google.com\"}"
    },
    {
      "event_id": 2,
      "session_id": "sess_001",
      "customer_id": 1,
      "event_time": "2023-09-01 10:05:00",
      "event_type": "search",
      "page_url": "/search?q=iphone",
      "device_type": "Desktop",
      "metadata": "{\"term\": \"iphone 15\"}"
    },
    {
      "event_id": 3,
      "session_id": "sess_001",
      "customer_id": 1,
      "event_time": "2023-09-01 10:08:00",
      "event_type": "add_to_cart",
      "page_url": "/product/101",
      "device_type": "Desktop",
      "metadata": "{\"product_id\": 101}"
    },
    {
      "event_id": 4,
      "session_id": "sess_001",
      "customer_id": 1,
      "event_time": "2023-09-01 10:12:00",
      "event_type": "checkout_start",
      "page_url": "/checkout",
      "device_type": "Desktop",
      "metadata": "{\"cart_total\": 37690500}"
    },
    {
      "event_id": 5,
      "session_id": "sess_001",
      "customer_id": 1,
      "event_time": "2023-09-01 10:15:00",
      "event_type": "purchase",
      "page_url": "/thank-you",
      "device_type": "Desktop",
      "metadata": "{\"order_id\": 1001}"
    },
    {
      "event_id": 6,
      "session_id": "sess_002",
      "customer_id": 4,
      "event_time": "2023-09-15 11:10:00",
      "event_type": "page_view",
      "page_url": "/home",
      "device_type": "Mobile",
      "metadata": "{\"referrer\": \"facebook.com\"}"
    },
    {
      "event_id": 7,
      "session_id": "sess_002",
      "customer_id": 4,
      "event_time": "2023-09-15 11:15:00",
      "event_type": "add_to_cart",
      "page_url": "/product/109",
      "device_type": "Mobile",
      "metadata": "{\"product_id\": 109}"
    },
    {
      "event_id": 8,
      "session_id": "sess_002",
      "customer_id": 4,
      "event_time": "2023-09-15 11:25:00",
      "event_type": "checkout_start",
      "page_url": "/checkout",
      "device_type": "Mobile",
      "metadata": "{\"cart_total\": 4980000}"
    },
    {
      "event_id": 9,
      "session_id": "sess_003",
      "customer_id": null,
      "event_time": "2023-09-20 14:00:00",
      "event_type": "page_view",
      "page_url": "/home",
      "device_type": "Mobile",
      "metadata": "{\"referrer\": \"direct\"}"
    },
    {
      "event_id": 10,
      "session_id": "sess_003",
      "customer_id": null,
      "event_time": "2023-09-20 14:02:00",
      "event_type": "page_view",
      "page_url": "/category/laptops",
      "device_type": "Mobile",
      "metadata": "{}"
    },
    {
      "event_id": 11,
      "session_id": "sess_004",
      "customer_id": 2,
      "event_time": "2023-10-10 17:00:00",
      "event_type": "page_view",
      "page_url": "/home",
      "device_type": "Desktop",
      "metadata": "{\"referrer\": \"direct\"}"
    },
    {
      "event_id": 12,
      "session_id": "sess_004",
      "customer_id": 2,
      "event_time": "2023-10-10 17:03:00",
      "event_type": "add_to_cart",
      "page_url": "/product/106",
      "device_type": "Desktop",
      "metadata": "{\"product_id\": 106}"
    },
    {
      "event_id": 13,
      "session_id": "sess_004",
      "customer_id": 2,
      "event_time": "2023-10-10 17:07:00",
      "event_type": "checkout_start",
      "page_url": "/checkout",
      "device_type": "Desktop",
      "metadata": "{}"
    },
    {
      "event_id": 14,
      "session_id": "sess_004",
      "customer_id": 2,
      "event_time": "2023-10-10 17:10:00",
      "event_type": "purchase",
      "page_url": "/thank-you",
      "device_type": "Desktop",
      "metadata": "{\"order_id\": 1007}"
    }
  ],
  "inventory_logs": [
    {
      "log_id": 1,
      "product_id": 101,
      "change_type": "RESTOCK",
      "quantity_changed": 50,
      "log_date": "2023-08-20 09:00:00",
      "notes": "Initial bulk stock arrival"
    },
    {
      "log_id": 2,
      "product_id": 101,
      "change_type": "SALE",
      "quantity_changed": -1,
      "log_date": "2023-09-01 10:15:00",
      "notes": "Order #1001 fulfilled"
    },
    {
      "log_id": 3,
      "product_id": 103,
      "change_type": "RESTOCK",
      "quantity_changed": 20,
      "log_date": "2023-08-25 10:30:00",
      "notes": "Batch #M3-import"
    },
    {
      "log_id": 4,
      "product_id": 103,
      "change_type": "SALE",
      "quantity_changed": -1,
      "log_date": "2023-09-02 14:20:00",
      "notes": "Order #1002 fulfilled"
    },
    {
      "log_id": 5,
      "product_id": 105,
      "change_type": "DAMAGE",
      "quantity_changed": -2,
      "log_date": "2023-09-10 16:00:00",
      "notes": "Water damage in warehouse sector B"
    }
  ]
};
