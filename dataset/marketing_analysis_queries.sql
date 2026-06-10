-- =====================================
-- DATA EXPLORATION
-- =====================================

SHOW TABLES;

DESCRIBE campaigns;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE sales;
DESCRIBE `sales items`;
DESCRIBE channels;
DESCRIBE `store details`;

-- =====================================
-- DATA CLEANING & STANDARDIZATION
-- =====================================

-- Convert text dates to DATE format

UPDATE campaigns
SET start_date = STR_TO_DATE(start_date, '%d-%m-%Y');

ALTER TABLE campaigns
MODIFY COLUMN start_date DATE;

UPDATE campaigns
SET end_date = STR_TO_DATE(end_date, '%d-%m-%Y');

ALTER TABLE campaigns
MODIFY COLUMN end_date DATE;

-- Clean discount values

ALTER TABLE campaigns
ADD discount_value_clean DECIMAL(5,2);

UPDATE campaigns
SET discount_value_clean = REPLACE(discount_value, '%', '');

-- Standardize text fields

UPDATE products
SET size = UPPER(size);

UPDATE channels
SET description = TRIM(description);

-- =====================================
-- DATA QUALITY CHECKS
-- =====================================

-- Duplicate Check

SELECT *, COUNT(*)
FROM campaigns
GROUP BY campaign_id, campaign_name, start_date, end_date
HAVING COUNT(*) > 1;

-- Null Check

SELECT *
FROM customers
WHERE customer_id IS NULL;

-- =====================================
-- DATA MODELING
-- =====================================

-- Create Product View

CREATE OR REPLACE VIEW products_cleaned AS
SELECT
product_id,
product_name,
category,
brand,
color,
size,
catalog_price,
cost_price,
gender
FROM products;

-- Create Size Dimension Table

CREATE TABLE dim_size AS
SELECT DISTINCT
size AS size_value
FROM products;

-- =====================================
-- RELATIONSHIPS & DATA INTEGRITY
-- =====================================

ALTER TABLE sales
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE `sales items`
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE `sales items`
ADD CONSTRAINT fk_sale
FOREIGN KEY (sale_id)
REFERENCES sales(sale_id);

