-- =====================================================================
-- OLIST E-COMMERCE SALES & CUSTOMER ANALYTICS
-- SQL Business Analysis (MySQL)
-- =====================================================================

-- ---------------------------------------------------------------------
-- STEP 0: Database + Tables
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS olist_ecommerce;

USE olist_ecommerce;

CREATE TABLE customers (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(5)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city            VARCHAR(100),
    seller_state            VARCHAR(5)
);

CREATE TABLE products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

CREATE TABLE orders (
    order_id                       VARCHAR(50) PRIMARY KEY,
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(30),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price                DECIMAL(10,2),
    freight_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE payments (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(30),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
);

-- Load each CSV with LOAD DATA INFILE
## customers, sellers, products, orders, order_items, payments, reviews)

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_customers_dataset.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_sellers_dataset.csv'
INTO TABLE Sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


LOAD DATA LOCAL INFILE '<PROJECT_PATH>/data/raw/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 1. Total number of orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2. Total customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers;

-- 3. Total sellers
SELECT COUNT(*) AS total_sellers
FROM sellers;

-- 4. Total revenue
SELECT ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM order_items;

-- 5. Average order value
SELECT ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT oi.order_id), 2) AS avg_order_value
FROM order_items oi;

-- 6. Monthly revenue
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
    SUM(oi.price + oi.freight_value) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');



-- 7. Top 10 categories by revenue
SELECT
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 10;

-- 8. Top 10 products by revenue
SELECT
    oi.product_id,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
    COUNT(*) AS units_sold
FROM order_items oi
GROUP BY oi.product_id
ORDER BY revenue DESC
LIMIT 10;

-- 9. Orders by state
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;

-- 10. Payment method distribution
SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value), 2) AS total_value
FROM payments
GROUP BY payment_type
ORDER BY transactions DESC;

-- 11. Month-over-month revenue growth
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (
            revenue - LAG(revenue) OVER (ORDER BY month)
        )
        / LAG(revenue) OVER (ORDER BY month) * 100,
        2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 12. Top customers by spending
SELECT
    c.customer_unique_id,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- 13. Average delivery time by state
SELECT
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 14. Late delivery rate by seller
SELECT
    oi.seller_id,
    COUNT(*) AS total_orders,
    SUM(
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1 ELSE 0 END
    ) AS late_orders,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS late_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
HAVING total_orders >= 10
ORDER BY late_rate_pct DESC
LIMIT 20;


##15. Relationship between delivery delay and review score
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(*) AS total_orders
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

-- 16.repeat customers

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT c.customer_id) AS customer_accounts,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_orders DESC;


-- 17. Revenue by payment method

SELECT
    payment_type,
    ROUND(SUM(payment_value), 2) AS total_payment,
    ROUND(
        SUM(payment_value) * 100.0 /
        (SELECT SUM(payment_value) FROM payments),
        2
    ) AS revenue_share_pct
FROM payments
GROUP BY payment_type
ORDER BY total_payment DESC;

-- 18. Rank products within each category

WITH product_revenue AS (
    SELECT
        p.product_category_name,
        oi.product_id,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name,
        oi.product_id
),
ranked_products AS (
    SELECT
        product_category_name,
        product_id,
        ROUND(revenue, 2) AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY product_category_name
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_revenue
)
SELECT *
FROM ranked_products
WHERE category_rank <= 3
ORDER BY product_category_name, category_rank;


