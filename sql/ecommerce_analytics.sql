SHOW DATABASES;
CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);


CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message LONGTEXT,
    review_creation_date VARCHAR(50),
    review_answer_timestamp VARCHAR(50)
);


CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

CREATE TABLE category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

ALTER TABLE order_items
ADD FOREIGN KEY (order_id) REFERENCES orders(order_id),
ADD FOREIGN KEY (product_id) REFERENCES products(product_id),
ADD FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_payments
ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);

# checking importing is successful or not

SELECT * FROM customers LIMIT 10;
SELECT * FROM geolocation LIMIT 10;
SELECT * FROM order_items LIMIT 10;
SELECT * FROM order_payments LIMIT 10;
SELECT * FROM order_reviews LIMIT 10;
SELECT * FROM orders LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM sellers LIMIT 10;
SELECT * FROM category_translation LIMIT 10;

# checking table size
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM geolocation;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM order_reviews;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM sellers;
SELECT COUNT(*) FROM category_translation;

# fixing order_reviews table

ALTER TABLE order_reviews
ADD COLUMN review_creation_dt DATETIME,
ADD COLUMN review_answer_dt DATETIME;

UPDATE order_reviews
SET review_creation_dt =
    COALESCE(
        STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s.%f'),
        STR_TO_DATE(review_creation_date, '%Y-%m-%d %H:%i:%s')
    ),
    review_answer_dt =
    COALESCE(
        STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s.%f'),
        STR_TO_DATE(review_answer_timestamp, '%Y-%m-%d %H:%i:%s')
    );


SELECT review_creation_dt, review_answer_dt
FROM order_reviews
LIMIT 10;

# Data Cleaning

# Orders NULL Check
SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    SUM(order_purchase_timestamp IS NULL) AS null_purchase_date,
    SUM(order_delivered_customer_date IS NULL) AS null_delivery_date
FROM orders;

# Order Items NULL Check
SELECT 
    'order_items' AS table_name,
    COUNT(*) AS total_rows,
    SUM(price IS NULL) AS null_price,
    SUM(freight_value IS NULL) AS null_freight
FROM order_items;

# Products Null Category Check
SELECT 
    'products' AS table_name,
    COUNT(*) AS total_rows,
    SUM(product_category_name IS NULL) AS null_category
FROM products;

# Price Range Check
SELECT 
    'price_range' AS check_type,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM order_items;

# Freight Range Check
SELECT 
    'freight_range' AS check_type,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM order_items;

# Duplicate Review Check
ALTER TABLE order_reviews
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

SELECT 
    review_id,
    COUNT(*) AS duplicate_count
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;


# Business Timeline
SELECT 
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- to identify active business period and dataset coverage


# Order Status Health
SELECT order_status, COUNT(*) 
FROM orders
GROUP BY order_status;

-- evaluating operational distribution of order outcomes


# Revenue
SELECT ROUND(SUM(price + freight_value),2) AS total_revenue
FROM order_items;

-- calculates total gross revenue generated


# Total Customers vs Orders
SELECT 
    (SELECT COUNT(DISTINCT customer_id) FROM customers) AS total_customers,
    (SELECT COUNT(DISTINCT order_id) FROM orders) AS total_orders;



# Monthly revenue trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price + oi.freight_value),2) AS monthly_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- shows seasonality and revenue growth trend over time


# Monthly Order Count
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT order_id) AS monthly_orders
FROM orders
GROUP BY month
ORDER BY month;

-- tracks transaction volume independent of order value


# Average Order Value
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- measures customer spending behavior over time


# Repeat Purchase Rate
SELECT 
    COUNT(*) AS repeat_customers
FROM (
    SELECT c.customer_unique_id
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(o.order_id) > 1
) t;

SELECT COUNT(DISTINCT c.customer_unique_id) unique_customers
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id;

-- Total orders = 96,461
-- Total customers who ordered = 93,342
-- Repeat customers = 2,800
-- Repeat rate ≈ 3%

-- The company focuses more on acquiring new customers, since repeat purchases are very low and growth is 
-- mostly coming from new buyers.


# Customer Lifetime Value

SELECT 
    c.customer_unique_id,
    ROUND(SUM(oi.price + oi.freight_value),2) AS customer_lifetime_value
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY customer_lifetime_value DESC
LIMIT 10;

-- identifies highest value customers


# Revenue Contribution of Top 10% Customers

WITH customer_revenue AS (
    SELECT 
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),
grouped_customers AS (
    SELECT 
        customer_unique_id,
        total_spent,
        NTILE(10) OVER (ORDER BY total_spent DESC) AS customer_group
    FROM customer_revenue
)

SELECT 
    customer_group,
    ROUND(SUM(total_spent),2) AS revenue_from_group
FROM grouped_customers
GROUP BY customer_group
ORDER BY customer_group;

-- Top 10% customers generate ~37% of total revenue
-- Top 20% (group 1 + 2) generate ~52%

-- A small percentage of customers are driving a large portion of revenue, 
-- which suggests the business should focus on retaining high-value customers.


# Delivery Performance Analysis

SELECT 
    COUNT(*) AS late_deliveries
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

SELECT 
    COUNT(*) AS total_delivered
FROM orders
WHERE order_status = 'delivered';

-- Late delivery rate ≈ 7,826 / 96,455 ≈ 8.1%

# Late deliveries vs reviews

SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    ROUND(AVG(r.review_score),2) AS avg_review_score
FROM orders o
JOIN order_reviews r 
    ON o.order_id = r.order_id
GROUP BY delivery_status;

-- Late deliveries significantly impact customer satisfaction. Orders delivered on time have an average rating of 4.29 
-- while late deliveries drop sharply to 2.57
-- This shows delivery performance directly affects customer reviews and overall experience


# Top product categories by revenue

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- identifies core revenue driving product segments


# Review score distribution
SELECT 
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / 
          (SELECT COUNT(*) FROM order_reviews),2) AS percentage
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Customer satisfaction is generally high with nearly 58% of reviews being 5 star
-- However around 11.5% are 1-star reviews indicating a noticeable dissatisfaction segment 
-- that may be linked to delivery or product issues.

# do high revenue categories have good ratings
SELECT 
    p.product_category_name,
    ROUND(AVG(r.review_score),2) AS avg_rating,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
JOIN order_reviews r 
    ON o.order_id = r.order_id
GROUP BY p.product_category_name
HAVING COUNT(r.review_score) > 100
ORDER BY total_revenue DESC
LIMIT 10;

-- Top revenue categories generally maintain good average ratings (around 4.0+)


# Customer Acquisition Trend
SELECT 
    DATE_FORMAT(first_purchase, '%Y-%m') AS month,
    COUNT(*) AS new_customers
FROM (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) t
GROUP BY month
ORDER BY month;

-- Customer growth closely follows the order trend with strong acquisition spikes in late 2017 and stable growth in 2018

# Cohort Retention
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        DATE_FORMAT(f.first_order_date, '%Y-%m') AS cohort_month
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    JOIN first_purchase f
        ON c.customer_unique_id = f.customer_unique_id
)

SELECT 
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customer_orders
GROUP BY cohort_month
ORDER BY cohort_month;

-- groups customers by first purchase month for retention analysis



# Revenue by State
SELECT 
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- identifies top performing geographic markets


# Average Delivery Time
SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),2) 
    AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered';

-- measures overall operational efficiency in fulfillment


CREATE INDEX idx_orders_date 
ON orders(order_purchase_timestamp);

CREATE INDEX idx_orders_customer 
ON orders(customer_id);

CREATE INDEX idx_order_items_order 
ON order_items(order_id);

CREATE INDEX idx_order_items_product 
ON order_items(product_id);

CREATE INDEX idx_reviews_order 
ON order_reviews(order_id);

-- added indexes to optimize joins and time-based aggregations


# verify index creation and key usage

SHOW INDEX FROM orders;
SHOW INDEX FROM order_items;
SHOW INDEX FROM order_reviews;

EXPLAIN
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    SUM(oi.price + oi.freight_value)
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m');




# top 3 product based on category
SELECT *
FROM (
    SELECT 
        p.product_category_name,
        p.product_id,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_category_name 
            ORDER BY SUM(oi.price + oi.freight_value) DESC
        ) AS rank_in_category
    FROM order_items oi
    JOIN products p 
        ON oi.product_id = p.product_id
    GROUP BY p.product_category_name, p.product_id
) t
WHERE rank_in_category <= 3;


# best products on each city based on first letter of the city
SELECT *
FROM (
    SELECT 
        LEFT(c.customer_city,1) AS first_letter,
        c.customer_city,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROW_NUMBER() OVER (
            PARTITION BY LEFT(c.customer_city,1)
            ORDER BY COUNT(DISTINCT o.order_id) DESC
        ) AS city_rank
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY first_letter, c.customer_city
) t
WHERE city_rank = 1
ORDER BY first_letter;

# sellers that generates the most revenue
SELECT 
    s.seller_id,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM order_items oi
JOIN sellers s 
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

# Sellers having poor ratings
SELECT 
    s.seller_id,
    ROUND(AVG(r.review_score),2) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM order_items oi
JOIN sellers s 
    ON oi.seller_id = s.seller_id
JOIN orders o 
    ON oi.order_id = o.order_id
JOIN order_reviews r 
    ON o.order_id = r.order_id
GROUP BY s.seller_id
HAVING COUNT(r.review_id) > 50
ORDER BY avg_rating ASC
LIMIT 10;

# Customers generates the most revenue per state
SELECT 
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

# Categories having highest cancellation rate

SELECT 
    p.product_category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE 
        WHEN o.order_status = 'canceled' 
        THEN o.order_id 
    END) AS canceled_orders,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN o.order_status = 'canceled' 
            THEN o.order_id 
        END) / COUNT(DISTINCT o.order_id) * 100, 2
    ) AS cancellation_rate_percent
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING canceled_orders > 0
ORDER BY cancellation_rate_percent DESC;


# Installments vs order value
SELECT 
    CASE 
        WHEN payment_installments > 1 THEN 'Installment'
        ELSE 'Single Payment'
    END AS payment_type_group,
    ROUND(AVG(payment_value),2) AS avg_order_value
FROM order_payments
GROUP BY payment_type_group;

# Heavier products are causing late deliveries
# Heavy vs Light products and late delivery rate (order-level correct calculation)
SELECT 
    CASE 
        WHEN p.product_weight_g > 5000 THEN 'Heavy'
        ELSE 'Light'
    END AS weight_category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN o.order_id 
    END) AS late_orders,
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
            THEN o.order_id 
        END)
        / COUNT(DISTINCT o.order_id) * 100, 2
    ) AS late_delivery_rate_percent
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY weight_category;



# Month having highest customer lifetime value (clv)
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
customer_spend AS (
    SELECT 
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)

SELECT 
    f.cohort_month,
    ROUND(AVG(cs.total_spent),2) AS avg_clv
FROM first_purchase f
JOIN customer_spend cs
    ON f.customer_unique_id = cs.customer_unique_id
GROUP BY f.cohort_month
ORDER BY avg_clv DESC;

# enriched order level dataset for analytics
CREATE OR REPLACE VIEW vw_order_enriched AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    SUM(oi.price + oi.freight_value) AS order_value
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY 
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date;

# customer lifetime aggregation view
CREATE OR REPLACE VIEW vw_customer_lifetime AS
SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value),2) AS lifetime_value,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    MAX(o.order_purchase_timestamp) AS last_order_date
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id;

# rfm segmentation for customer value classification
WITH rfm_base AS (
    SELECT 
        customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders),
            MAX(order_purchase_timestamp)
        ) AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM vw_order_enriched
    GROUP BY customer_unique_id
)

SELECT 
    customer_unique_id,
    recency_days,
    frequency,
    monetary
FROM rfm_base
ORDER BY monetary DESC
LIMIT 20;


# month over month revenue growth analysis
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS month,
        SUM(order_value) AS revenue
    FROM vw_order_enriched
    GROUP BY month
)

SELECT 
    month,
    revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) 
        / LAG(revenue) OVER (ORDER BY month) * 100,2
    ) AS mom_growth_percent
FROM monthly_revenue;

# weekday vs weekend order behaviour
SELECT 
    CASE 
        WHEN DAYOFWEEK(order_purchase_timestamp) IN (1,7) 
        THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_value),2) AS avg_order_value
FROM vw_order_enriched
GROUP BY day_type;

# order funnel from purchase to delivery

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN order_status IN ('approved','shipped','delivered') THEN order_id END) AS approved_stage,
    COUNT(DISTINCT CASE WHEN order_status IN ('shipped','delivered') THEN order_id END) AS shipped_stage,
    COUNT(DISTINCT CASE WHEN order_status = 'delivered' THEN order_id END) AS delivered_stage,
    COUNT(DISTINCT CASE WHEN order_status = 'canceled' THEN order_id END) AS canceled_stage
FROM orders;




# Executive Summary

-- Revenue growth is strong and primarily driven by new customer acquisition rather than repeat purchases.

-- Repeat purchase rate is approximately 3%, indicating weak customer retention and loyalty.

-- Top 10% of customers contribute around 37% of total revenue, highlighting revenue concentration risk.

-- Late deliveries (around 8%) significantly reduce customer satisfaction, with average ratings dropping from 4.29 to 2.57.

-- High revenue product categories maintain average ratings above 4.0, suggesting good product-market alignment.

-- Revenue peaked in late 2017, supported by strong customer acquisition during that period.

-- Strategic focus should shift toward improving retention programs and delivery efficiency to ensure sustainable growth.












