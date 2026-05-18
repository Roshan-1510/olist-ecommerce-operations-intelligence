-- =============================================================================
-- OLIST E-COMMERCE OPERATIONS INTELLIGENCE
-- Data Preparation Script
-- Author: Roshan Vishwakarma
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- Tool: MySQL Workbench
-- =============================================================================
-- PURPOSE:
-- This script covers the complete data engineering layer for the Olist
-- Operations Intelligence Dashboard. It includes:
--   1. Database and table creation
--   2. Raw data ingestion
--   3. Geolocation aggregation and indexing
--   4. Star schema construction
--   5. Derived metric engineering
--   6. Analytical validation queries
-- =============================================================================


-- =============================================================================
-- SECTION 1 — DATABASE SETUP
-- =============================================================================

CREATE DATABASE olist_dataset;
USE olist_dataset;


-- =============================================================================
-- SECTION 2 — RAW TABLE CREATION
-- =============================================================================

-- Orders — one row per order, captures full order lifecycle
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(60) PRIMARY KEY,
    customer_id VARCHAR(60),
    order_status VARCHAR(20),
    order_purchase_timestamp VARCHAR(60) NULL,
    order_approved_at VARCHAR(60) NULL,
    order_delivered_carrier_date VARCHAR(60) NULL,
    order_delivered_customer_date VARCHAR(60) NULL,
    order_estimated_delivery_date VARCHAR(60)
);

-- Customers — one row per customer record (customer_id grain)
CREATE TABLE olist_customer_dataset (
    customer_id VARCHAR(60) PRIMARY KEY,
    customer_unique_id VARCHAR(60),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(40),
    customer_state VARCHAR(20)
);

-- Geolocation — one row per ZIP code prefix with coordinates
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(15,13),
    geolocation_lng DECIMAL(15,13),
    geolocation_city VARCHAR(40),
    geolocation_state VARCHAR(20)
);

-- Sellers — one row per seller
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(40) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(40),
    seller_state VARCHAR(20)
);

-- Products — one row per product
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(60) PRIMARY KEY,
    product_category_name VARCHAR(60),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Product Category Translation — Portuguese to English
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(60),
    product_category_name_english VARCHAR(60)
);


-- =============================================================================
-- SECTION 3 — RAW DATA INGESTION
-- =============================================================================
-- Note: Update file paths to match your local directory before running.

LOAD DATA LOCAL INFILE 'D:/Roshan/Olist_E-commerce_Analysis/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp,
 order_approved_at, order_delivered_carrier_date,
 order_delivered_customer_date, order_estimated_delivery_date);

LOAD DATA LOCAL INFILE 'D:/Roshan/Olist_E-commerce_Analysis/olist_customers_dataset.csv'
INTO TABLE olist_customer_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix,
 customer_city, customer_state);

LOAD DATA LOCAL INFILE 'D:/Roshan/Olist_E-commerce_Analysis/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
 geolocation_city, geolocation_state);

LOAD DATA LOCAL INFILE 'D:/Roshan/Olist_E-commerce_Analysis/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(seller_id, seller_zip_code_prefix, seller_city, seller_state);

LOAD DATA LOCAL INFILE 'E:/Programs Roshan/Olist_E-commerce_Analysis/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, product_name_lenght,
 product_description_lenght, product_photos_qty, product_weight_g,
 product_length_cm, product_height_cm, product_width_cm);

LOAD DATA LOCAL INFILE 'E:/Programs Roshan/Olist_E-commerce_Analysis/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_category_name, product_category_name_english);


-- =============================================================================
-- SECTION 4 — GEOLOCATION AGGREGATION
-- =============================================================================
-- Problem: geolocation table has multiple rows per ZIP code prefix.
-- Solution: Aggregate to one row per ZIP prefix using average lat/lng.
-- This table is used as the geolocation lookup for all distance calculations.

CREATE TABLE geo_less AS
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS Avg_lat,
    AVG(geolocation_lng) AS Avg_lng
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;

-- Performance indexes for join operations
CREATE INDEX idx_geo_zip ON geo_less(geolocation_zip_code_prefix);
CREATE INDEX idx_cust_zip ON olist_customer_dataset(customer_zip_code_prefix);
CREATE INDEX idx_seller_zip ON olist_sellers_dataset(seller_zip_code_prefix);

-- Session timeout settings for long-running queries
SET SESSION wait_timeout = 28800;
SET SESSION interactive_timeout = 28800;
SET GLOBAL net_read_timeout = 300;
SET GLOBAL net_write_timeout = 300;


-- =============================================================================
-- SECTION 5 — STAR SCHEMA CONSTRUCTION
-- =============================================================================
-- Builds the dimensional model used in Power BI.
-- All date columns converted from VARCHAR to DATETIME during construction.


-- -----------------------------------------------------------------------------
-- fact_orders — one row per order, core delivery timeline table
-- Derived metrics: delivery_delay_days, order_risk_score
-- -----------------------------------------------------------------------------
CREATE TABLE fact_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') AS order_purchase_timestamp,
    STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s') AS order_approved_at,
    STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s') AS order_delivered_carrier_date,
    STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') AS order_delivered_customer_date,
    STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') AS order_estimated_delivery_date
FROM olist_orders_dataset;

-- Add order_risk_score column (pre-computed for Power BI performance)
ALTER TABLE fact_orders
ADD COLUMN order_risk_score INT DEFAULT 0;

-- Populate order_risk_score using 3 operational signals
-- Flag 1: Late delivery (actual > estimated)
-- Flag 2: Carrier deadline miss (from fact_order_items)
-- Flag 3: High freight-to-price ratio (above platform average)
SET SQL_SAFE_UPDATES = 0;

UPDATE fact_orders fo
LEFT JOIN (
    SELECT
        order_id,
        MAX(CASE WHEN carrier_deadline_miss_days > 0 THEN 1 ELSE 0 END) AS carrier_flag,
        MAX(CASE WHEN (freight_value / NULLIF(price, 0)) >
            (SELECT AVG(freight_value / NULLIF(price, 0)) FROM fact_order_items)
            THEN 1 ELSE 0 END) AS freight_flag
    FROM fact_order_items
    GROUP BY order_id
) foi ON fo.order_id = foi.order_id
SET fo.order_risk_score =
    CASE WHEN DATEDIFF(fo.order_delivered_customer_date,
                       fo.order_estimated_delivery_date) > 0
         THEN 1 ELSE 0 END +
    COALESCE(foi.carrier_flag, 0) +
    COALESCE(foi.freight_flag, 0);

SET SQL_SAFE_UPDATES = 1;


-- -----------------------------------------------------------------------------
-- fact_order_items — one row per product per order
-- Derived metrics: carrier_deadline_miss_days, freight_to_price_ratio,
--                  delivery_distance_km (Haversine formula)
-- -----------------------------------------------------------------------------
CREATE TABLE fact_order_items AS
WITH c AS (
    SELECT
        cu.customer_id,
        g.Avg_lat,
        g.Avg_lng
    FROM olist_customer_dataset cu
    LEFT JOIN geo_less g
        ON cu.customer_zip_code_prefix = g.geolocation_zip_code_prefix
),
s AS (
    SELECT
        se.seller_id,
        g.Avg_lat,
        g.Avg_lng
    FROM olist_sellers_dataset se
    LEFT JOIN geo_less g
        ON se.seller_zip_code_prefix = g.geolocation_zip_code_prefix
)
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    ROUND(oi.freight_value / NULLIF(oi.price, 0), 4) AS freight_to_price_ratio,
    STR_TO_DATE(oi.shipping_limit_date, '%Y-%m-%d %H:%i:%s') AS shipping_limit_date,
    -- Carrier deadline miss: positive = seller missed handoff deadline
    DATEDIFF(
        STR_TO_DATE(o.order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(oi.shipping_limit_date, '%Y-%m-%d %H:%i:%s')
    ) AS carrier_deadline_miss_days,
    -- Haversine formula for delivery distance
    ROUND(
        6371 * ACOS(
            COS(RADIANS(s.Avg_lat)) * COS(RADIANS(c.Avg_lat)) *
            COS(RADIANS(s.Avg_lng) - RADIANS(c.Avg_lng)) +
            SIN(RADIANS(s.Avg_lat)) * SIN(RADIANS(c.Avg_lat))
        ), 2
    ) AS delivery_distance_km
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
JOIN olist_customer_dataset cu ON o.customer_id = cu.customer_id
JOIN c ON cu.customer_id = c.customer_id
JOIN s ON oi.seller_id = s.seller_id;


-- -----------------------------------------------------------------------------
-- fact_payments — one row per payment transaction per order
-- -----------------------------------------------------------------------------
CREATE TABLE fact_payments AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM olist_order_payments_dataset;


-- -----------------------------------------------------------------------------
-- fact_reviews — one row per review, deduplicated on review_id
-- -----------------------------------------------------------------------------
CREATE TABLE fact_reviews AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date DESC) AS rn
    FROM olist_order_reviews_dataset
) ranked
WHERE rn = 1;


-- -----------------------------------------------------------------------------
-- dim_customers — one row per customer_id
-- -----------------------------------------------------------------------------
CREATE TABLE dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM olist_customer_dataset;


-- -----------------------------------------------------------------------------
-- dim_sellers — one row per seller
-- -----------------------------------------------------------------------------
CREATE TABLE dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM olist_sellers_dataset;


-- -----------------------------------------------------------------------------
-- dim_products — one row per product with English category name
-- -----------------------------------------------------------------------------
CREATE TABLE dim_products AS
SELECT
    p.product_id,
    p.product_category_name,
    TRIM(REPLACE(t.product_category_name_english, '\r', '')) AS product_category_name_english
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name;


-- =============================================================================
-- SECTION 6 — ANALYTICAL VALIDATION QUERIES
-- =============================================================================
-- These queries were used to validate derived metrics and derive
-- analytical thresholds used in the Power BI KPI layer.


-- -----------------------------------------------------------------------------
-- Query 1 — Baseline Platform Late Delivery Rate
-- Result: 8.11% — 7,826 late orders out of 96,478 delivered
-- -----------------------------------------------------------------------------
SELECT
    late_delivery,
    total_delivery,
    ROUND((late_delivery / total_delivery) * 100, 2) AS late_delivery_rate_pct
FROM (
    SELECT
        SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 1 ELSE 0 END) AS late_delivery,
        COUNT(order_id) AS total_delivery
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
) AS summary;


-- -----------------------------------------------------------------------------
-- Query 2 — Average Delivery Distance: Late vs On-Time Orders
-- Result: Late orders averaged 735km. On-time orders averaged 585km.
-- This 735km figure became the distance band anchor threshold in Q4.
-- -----------------------------------------------------------------------------
WITH c AS (
    SELECT
        cu.customer_id,
        g.Avg_lat,
        g.Avg_lng
    FROM olist_customer_dataset cu
    LEFT JOIN geo_less g ON cu.customer_zip_code_prefix = g.geolocation_zip_code_prefix
),
s AS (
    SELECT
        se.seller_id,
        g.Avg_lat,
        g.Avg_lng
    FROM olist_sellers_dataset se
    LEFT JOIN geo_less g ON se.seller_zip_code_prefix = g.geolocation_zip_code_prefix
),
i AS (
    SELECT
        it.order_id,
        it.seller_id,
        c.Avg_lat AS customer_lat,
        c.Avg_lng AS customer_lng,
        s.Avg_lat AS seller_lat,
        s.Avg_lng AS seller_lng
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset it ON o.order_id = it.order_id
    JOIN c ON o.customer_id = c.customer_id
    JOIN s ON it.seller_id = s.seller_id
)
SELECT
    delivery_flag,
    ROUND(AVG(distance), 2) AS avg_distance_km
FROM (
    SELECT
        6371 * ACOS(
            COS(RADIANS(i.seller_lat)) * COS(RADIANS(i.customer_lat)) *
            COS(RADIANS(i.seller_lng) - RADIANS(i.customer_lng)) +
            SIN(RADIANS(i.seller_lat)) * SIN(RADIANS(i.customer_lat))
        ) AS distance,
        CASE WHEN ol.order_delivered_customer_date > ol.order_estimated_delivery_date
            THEN 'Late' ELSE 'On_Time' END AS delivery_flag
    FROM i
    JOIN olist_orders_dataset ol ON i.order_id = ol.order_id
    WHERE ol.order_status = 'delivered'
) AS dis
GROUP BY delivery_flag;


-- -----------------------------------------------------------------------------
-- Query 3 — Seller Dispatch Speed: High Volume vs Low Volume Sellers
-- Result: High-volume sellers dispatch in 2.7 days.
--         Low-volume sellers dispatch in 2.9 days.
-- Threshold used: 36 orders (exploratory; final model used 75th percentile = 21.5)
-- -----------------------------------------------------------------------------
WITH c AS (
    SELECT
        i.seller_id,
        o.order_id,
        o.order_delivered_carrier_date,
        o.order_approved_at
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset i ON o.order_id = i.order_id
),
s AS (
    SELECT seller_id, COUNT(order_id) AS order_by_seller
    FROM c
    GROUP BY seller_id
)
SELECT
    AVG(CASE WHEN order_by_seller > 36
        THEN DATEDIFF(c.order_delivered_carrier_date, c.order_approved_at)
        ELSE NULL END) AS avg_high_vol_dispatch_days,
    AVG(CASE WHEN order_by_seller <= 36
        THEN DATEDIFF(c.order_delivered_carrier_date, c.order_approved_at)
        ELSE NULL END) AS avg_low_vol_dispatch_days
FROM c
LEFT JOIN s ON c.seller_id = s.seller_id;


-- -----------------------------------------------------------------------------
-- Query 4 — Category Delivery Performance: Electronics vs All Other
-- Result: Electronics delivered 11.01 days before estimated.
--         Other categories delivered 11.94 days before estimated.
-- -----------------------------------------------------------------------------
SELECT
    AVG(CASE WHEN TRIM(REPLACE(sub.product_category_name_english, '\r', '')) = 'electronics'
        THEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)
        ELSE NULL END) AS avg_electronics_delay,
    AVG(CASE WHEN TRIM(REPLACE(sub.product_category_name_english, '\r', '')) != 'electronics'
        THEN DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)
        ELSE NULL END) AS avg_other_delay
FROM (
    SELECT DISTINCT
        o.order_id,
        n.product_category_name_english,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    JOIN olist_products_dataset p ON i.product_id = p.product_id
    JOIN product_category_name_translation n ON p.product_category_name = n.product_category_name
    WHERE o.order_status = 'delivered'
) sub;


-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
