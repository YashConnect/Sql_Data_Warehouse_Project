-- ============================================================
-- GOLD LAYER: DIMENSION AND FACT VIEWS
-- Purpose:
--   - Create curated dimension views for Customers and Products
--   - Generate surrogate keys using ROW_NUMBER()
--   - Build a Sales Fact view that references dimension surrogate keys
-- ============================================================

------------------------------------------------------------
-- Customer Dimension View
-- ----------------------------------------------------------
-- Surrogate Key: customer_key (ROW_NUMBER over cst_id)
-- Business Keys: cst_id (customer_id), cst_key (customer_number)
-- Attributes: name, country, marital status, gender, birthday, create date
-- Joins:
--   - ERP Customer (birthday, gender)
--   - ERP Location (country)
------------------------------------------------------------
CREATE VIEW Gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,   -- surrogate key
    ci.cst_id            AS customer_id,                      -- business key
    ci.cst_key           AS customer_number,
    ci.cst_firstname     AS first_name,
    ci.cst_lastname      AS last_name,
    el.cntry             AS country,
    ci.cst_material_status AS marital_status,
    COALESCE(NULLIF(ci.cst_gndr, 'N/A'), ec.gen, 'N/A') AS gender, -- prefer CRM gender, fallback to ERP
    ec.bday              AS birthday,
    ci.cst_create_date   AS create_date
FROM Silver.crm_cust_info AS ci
LEFT JOIN Silver.erp_cust_az12 AS ec
    ON ec.cid = ci.cst_key
LEFT JOIN Silver.erp_loc_a101 AS el
    ON el.cid = ci.cst_key;

------------------------------------------------------------
-- Product Dimension View
-- ----------------------------------------------------------
-- Surrogate Key: product_key (ROW_NUMBER over start date + product key)
-- Business Keys: prd_id (product_id), prd_key (product_number)
-- Attributes: product name, category, subcategory, maintenance flag,
--             cost, product line, start date
-- Joins:
--   - ERP Product Category (cat, subcat, maintenance)
------------------------------------------------------------
CREATE VIEW Gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- surrogate key
    pn.prd_id        AS product_id,                                          -- business key
    pn.prd_key       AS product_number,
    pn.prd_nm        AS product_name,
    pn.cat_id        AS category_id,
    pc.cat           AS category,
    pc.subcat        AS subcategory,
    pc.maintenance   AS maintenance_flag,
    pn.prd_cost      AS product_cost,
    pn.prd_line      AS product_line,
    pn.prd_start_dt  AS start_date
FROM Silver.crm_prd_info AS pn
LEFT JOIN Silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id;

------------------------------------------------------------
-- Sales Fact View
-- ----------------------------------------------------------
-- Fact Grain: one row per sales order line
-- Surrogate Keys: product_key, customer_key (from dimensions)
-- Measures: sales_amount, quantity, unit_price
-- Dates: order_date, shipping_date, due_date
-- Joins:
--   - Dim Products (lookup surrogate key by product_number)
--   - Dim Customers (lookup surrogate key by customer_id)
------------------------------------------------------------
CREATE VIEW Gold.fact_sales AS
SELECT
    sd.sls_ord_num   AS order_number,
    pd.product_key   AS product_key,    -- surrogate key from product dimension
    dc.customer_key  AS customer_key,   -- surrogate key from customer dimension
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS unit_price
FROM Silver.crm_sales_details AS sd
LEFT JOIN Gold.dim_products AS pd
    ON sd.sls_prd_key = pd.product_number
LEFT JOIN Gold.dim_customers AS dc
    ON dc.customer_id = sd.sls_cust_id;
