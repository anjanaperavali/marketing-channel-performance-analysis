-- =====================================
-- DATA EXPLORATION
-- =====================================

SHOW TABLES;

SHOW TABLES;

DESCRIBE campaigns;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;
DESCRIBE `sales items`;
DESCRIBE channels;
DESCRIBE `store details`;

SELECT DISTINCT age_range FROM customers;
SELECT DISTINCT country FROM customers;
SELECT DISTINCT category FROM products;
SELECT DISTINCT country FROM `store details`;

-- =====================================
-- DATA CLEANING & STANDARDIZATION
-- =====================================

-- Date Conversion

UPDATE campaigns
SET start_date = STR_TO_DATE(start_date, '%d-%m-%Y');

ALTER TABLE campaigns
MODIFY COLUMN start_date DATE;


UPDATE campaigns
SET end_date = STR_TO_DATE(end_date, '%d-%m-%Y');

ALTER TABLE campaigns
MODIFY COLUMN end_date DATE;


UPDATE customers
SET signup_date = STR_TO_DATE(signup_date, '%d-%m-%Y');

ALTER TABLE customers
MODIFY COLUMN signup_date DATE;


UPDATE sales
SET sale_date = STR_TO_DATE(sale_date, '%d-%m-%Y');

ALTER TABLE sales
MODIFY COLUMN sale_date DATE;


UPDATE `sales items`
SET sale_date = STR_TO_DATE(sale_date, '%d-%m-%Y');

ALTER TABLE `sales items`
MODIFY COLUMN sale_date DATE;

-- Text Cleaning

UPDATE campaigns SET campaign_name = TRIM(campaign_name);
UPDATE campaigns SET channel = TRIM(channel);
UPDATE campaigns SET discount_type = TRIM(discount_type);

UPDATE channels SET channel = TRIM(channel);
UPDATE channels SET description = TRIM(description);

UPDATE customers SET country = TRIM(country);

UPDATE products SET product_name = TRIM(product_name);
UPDATE products SET category = TRIM(category);
UPDATE products SET brand = TRIM(brand);
UPDATE products SET color = TRIM(color);
UPDATE products SET gender = TRIM(gender);

UPDATE sales SET channel = TRIM(channel);
UPDATE sales SET country = TRIM(country);

UPDATE `sales items` SET channel = TRIM(channel);
UPDATE `sales items` SET channel_campaigns = TRIM(channel_campaigns);

UPDATE `store details` SET country = TRIM(country);


ALTER TABLE campaigns
ADD discount_value_clean DECIMAL(5,2);

UPDATE campaigns
SET discount_value_clean = REPLACE(discount_value, '%', '');


ALTER TABLE `sales items`
ADD discount_percent_clean DECIMAL(5,2);

UPDATE `sales items`
SET discount_percent_clean = REPLACE(discount_percent, '%', '');

-- =====================================
-- DATA MODELING
-- =====================================

-- Product Cleaned View

CREATE OR REPLACE VIEW products_cleaned AS
SELECT 
    product_id,
    product_name,
    category,
    brand,
    color,
    size,
    CASE WHEN size REGEXP '^[0-9]+$' THEN size ELSE NULL END AS numeric_size,
    CASE WHEN size REGEXP '^[A-Za-z]+$' THEN size ELSE NULL END AS clothing_size,
    catalog_price,
    cost_price,
    gender
FROM products;

-- Size Dimension Table

CREATE TABLE dim_size AS
SELECT DISTINCT
    size AS size_value,
    CASE 
        WHEN size REGEXP '^[0-9]+$' THEN 'Numeric'
        WHEN size REGEXP '^[A-Za-z]+$' THEN 'Clothing'
        ELSE 'Other'
    END AS size_type
FROM products;

ALTER TABLE dim_size ADD COLUMN size_sort INT;

UPDATE dim_size
SET size_sort = CASE
    WHEN size_value='XS' THEN 1
    WHEN size_value='S' THEN 2
    WHEN size_value='M' THEN 3
    WHEN size_value='L' THEN 4
    WHEN size_value='XL' THEN 5
    ELSE NULL
END;

-- =====================================
-- DATA VALIDATION
-- =====================================

SELECT DISTINCT country FROM customers;

SELECT DISTINCT country FROM `store details`;

SELECT sale_id, COUNT(*)
FROM sales
GROUP BY sale_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT item_id, COUNT(*)
FROM `sales items`
GROUP BY item_id
HAVING COUNT(*) > 1;


-- =====================================
-- BUSINESS ANALYSIS
-- =====================================

-- Revenue by Channel
SELECT 
    s.channel,
    SUM(si.item_total) AS total_revenue
FROM sales s
JOIN `sales items` si
    ON s.sale_id = si.sale_id
GROUP BY s.channel
ORDER BY total_revenue DESC;

-- Monthly Sales Trend
SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    SUM(total_amount) AS monthly_revenue
FROM sales
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
ORDER BY month;

-- Average Order Value
SELECT 
    AVG(total_amount) AS average_order_value
FROM sales;

-- Revenue Contribution by Country
SELECT 
    country,
    SUM(total_amount) AS total_revenue
FROM sales
GROUP BY country
ORDER BY total_revenue DESC;

-- Top Selling Products
SELECT 
    p.product_name,
    SUM(si.quantity) AS total_units_sold,
    SUM(si.item_total) AS total_revenue
FROM `sales items` si
JOIN products p
    ON si.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Top Customers by Revenue
SELECT 
    c.customer_id,
    c.country,
    SUM(s.total_amount) AS total_spent
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.country
ORDER BY total_spent DESC
LIMIT 10;

-- Campaign Effectiveness (Discount Impact)
SELECT 
    c.campaign_name,
    c.discount_type,
    SUM(si.item_total) AS revenue_generated
FROM campaigns c
JOIN `sales items` si
    ON c.channel = si.channel
GROUP BY c.campaign_name, c.discount_type
ORDER BY revenue_generated DESC;

-- Category Performance Analysis
SELECT 
    p.category,
    SUM(si.quantity) AS units_sold,
    SUM(si.item_total) AS revenue
FROM `sales items` si
JOIN products p
    ON si.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Store Performance (Stock vs Sales Insight)
SELECT 
    sd.country,
    sd.product_id,
    SUM(sd.stock_quantity) AS total_stock,
    COALESCE(SUM(si.quantity), 0) AS total_sold
FROM `store details` sd
LEFT JOIN `sales items` si
    ON sd.product_id = si.product_id
GROUP BY sd.country, sd.product_id
ORDER BY total_sold DESC;
