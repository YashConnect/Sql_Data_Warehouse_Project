-- Check for nulls or duplicates in primary key
    -- Expectation: No result
    SELECT cst_id, COUNT(*) 
    FROM Bronze.crm_cust_info 
    GROUP BY cst_id 
    HAVING COUNT(*) > 1 OR cst_id IS NULL;

    -- Deduplicate using window function (keep latest record per cst_id)
    SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_last
        FROM Bronze.crm_cust_info
    ) t 
    WHERE Flag_last = 1 AND cst_id IS NOT NULL;

    -- Detect unwanted spaces
    SELECT * FROM Bronze.crm_cust_info 
    WHERE cst_firstname != TRIM(cst_firstname);

    -- Remove unwanted spaces + keep latest record
    SELECT cst_id, cst_key,
           TRIM(cst_firstname) AS cst_firstname,
           TRIM(cst_lastname)  AS cst_lastname,
           cst_material_status,
           cst_gndr,
           cst_create_date
    FROM (
        SELECT * FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_last
            FROM Bronze.crm_cust_info
        ) t 
        WHERE Flag_last = 1 AND cst_id IS NOT NULL
    ) t;

    -- Check standardization of values
    SELECT DISTINCT cst_material_status FROM Bronze.crm_cust_info;
    SELECT DISTINCT cst_gndr FROM Bronze.crm_cust_info;

    -- Replace abbreviations with friendly names
    SELECT cst_id, cst_key,
           TRIM(cst_firstname) AS cst_firstname,
           TRIM(cst_lastname)  AS cst_lastname,
           CASE 
               WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
               WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
               ELSE 'N/A'
           END AS cst_material_status,
           CASE 
               WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
               WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
               ELSE 'N/A'
           END AS cst_gndr,
           cst_create_date
    FROM (
        SELECT * FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_last
            FROM Bronze.crm_cust_info
        ) t 
        WHERE Flag_last = 1 AND cst_id IS NOT NULL
    ) t;

    -----------------------------------------------------------
    --  Post-Load Validation on Silver Layer
    -----------------------------------------------------------

    -- Check for nulls or duplicates in primary key
    SELECT cst_id, COUNT(*) 
    FROM Silver.crm_cust_info 
    GROUP BY cst_id 
    HAVING COUNT(*) > 1 OR cst_id IS NULL;

    -- Detect unwanted spaces
    SELECT * FROM Silver.crm_cust_info 
    WHERE cst_firstname != TRIM(cst_firstname);

    -- Check standardized values
    SELECT DISTINCT cst_material_status FROM Silver.crm_cust_info;
    SELECT DISTINCT cst_gndr FROM Silver.crm_cust_info;

    -- Verify deduplication (latest record per cst_id)
    SELECT * FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_last
        FROM Silver.crm_cust_info
    ) t 
    WHERE Flag_last = 1;

    /*
    ===========================================================
        Data Cleaning & Loading: CRM Product Info (crm_prd_info)
    ===========================================================
    */

    -----------------------------------------------------------
    --  Duplicate & Null Checks (Bronze)
    -----------------------------------------------------------
    SELECT prd_id, COUNT(*) 
    FROM Bronze.crm_prd_info 
    GROUP BY prd_id 
    HAVING COUNT(*) > 1 OR prd_id IS NULL;

    -----------------------------------------------------------
    --  Derived Columns & Referential Integrity
    -----------------------------------------------------------
    SELECT prd_id, prd_key,
           REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
           prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    FROM Bronze.crm_prd_info
    WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') 
          NOT IN (SELECT DISTINCT id FROM Bronze.erp_px_cat_g1v2);

    SELECT prd_id,
           SUBSTRING(prd_key,1,5) AS cat_id,
           SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
           prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    FROM Bronze.crm_prd_info
    WHERE SUBSTRING(prd_key,1,5) 
          NOT IN (SELECT DISTINCT sls_prd_key FROM Bronze.crm_sales_details);

    -----------------------------------------------------------
    --  Space Checks
    -----------------------------------------------------------
    SELECT prd_nm 
    FROM Bronze.crm_prd_info 
    WHERE prd_nm != TRIM(prd_nm);

    -----------------------------------------------------------
    --  Null & Negative Value Checks
    -----------------------------------------------------------
    SELECT prd_id, prd_key, prd_nm, COALESCE(prd_cost,0) AS prd_cost,
           prd_line, prd_start_dt, prd_end_dt
    FROM Bronze.crm_prd_info
    WHERE prd_cost IS NULL OR prd_cost < 0;

    -----------------------------------------------------------
    --  Data Standardization
    -----------------------------------------------------------
    SELECT DISTINCT prd_line 
    FROM Bronze.crm_prd_info;

    SELECT prd_id,
           SUBSTRING(prd_key,1,5) AS cat_id,
           SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
           prd_nm,
           COALESCE(prd_cost,0) AS prd_cost,
           CASE UPPER(prd_line)
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Others sales'
                WHEN 'T' THEN 'Tourist'
                ELSE 'N/A'
           END AS prd_line,
           prd_start_dt, prd_end_dt
    FROM Bronze.crm_prd_info;

    -----------------------------------------------------------
    --  Date Validations
    -----------------------------------------------------------
    SELECT * FROM Bronze.crm_prd_info 
    WHERE prd_end_dt < prd_start_dt;

    SELECT prd_key, prd_nm, prd_start_dt,
           LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt
    FROM Bronze.crm_prd_info
    WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509');

    -----------------------------------------------------------
    --  Post-Load Validation (Silver)
    -----------------------------------------------------------
    SELECT prd_id, COUNT(*) 
    FROM Silver.crm_prd_info 
    GROUP BY prd_id 
    HAVING COUNT(*) > 1 OR prd_id IS NULL;

    SELECT prd_nm 
    FROM Silver.crm_prd_info 
    WHERE prd_nm != TRIM(prd_nm);

    SELECT prd_id, prd_key, prd_nm, COALESCE(prd_cost,0) AS prd_cost,
           prd_line, prd_start_dt, prd_end_dt
    FROM Silver.crm_prd_info
    WHERE prd_cost IS NULL OR prd_cost < 0;

    SELECT DISTINCT prd_line 
    FROM Silver.crm_prd_info;

    SELECT * FROM Silver.crm_prd_info 
    WHERE prd_end_dt < prd_start_dt;


    /*
    ===========================================================
        Data Cleaning & Loading: CRM Sales Details
    ===========================================================
    */

    -----------------------------------------------------------
    -- Date Validations (Bronze)
    -----------------------------------------------------------
    -----------------------------------------------------------
    --Checking for Duplicates
    -----------------------------------------------------------
    SELECT NULLIF(sls_order_dt,0) AS sls_order_dt
    FROM Bronze.crm_sales_details
    WHERE sls_order_dt <= 0;

    -----------------------------------------------------------
    --Checking date validation
    -----------------------------------------------------------
    SELECT NULLIF(sls_order_dt,0) AS sls_order_dt
    FROM Bronze.crm_sales_details
    WHERE LEN(sls_order_dt) != 8;

    SELECT sls_ord_num, sls_prd_key, sls_cust_id,
           CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
           sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
    FROM Bronze.crm_sales_details;

    SELECT NULLIF(sls_ship_dt,0) AS sls_ship_dt
    FROM Bronze.crm_sales_details
    WHERE LEN(sls_ship_dt) != 8 OR sls_ship_dt <= 0;

    SELECT sls_ord_num, sls_prd_key, sls_cust_id,
           CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
           CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
           sls_due_dt, sls_sales, sls_quantity, sls_price
    FROM Bronze.crm_sales_details;

    SELECT NULLIF(sls_due_dt,0) AS sls_due_dt
    FROM Bronze.crm_sales_details
    WHERE LEN(sls_due_dt) != 8 OR sls_due_dt <= 0;

    SELECT sls_ord_num, sls_prd_key, sls_cust_id,
           CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
           CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
           CASE WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 
                THEN NULL 
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
           sls_sales, sls_quantity, sls_price
    FROM Bronze.crm_sales_details;

    SELECT * FROM Bronze.crm_sales_details
    WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

    -----------------------------------------------------------
    -- Business Rule Validations (Bronze)
    -----------------------------------------------------------
    SELECT DISTINCT sls_sales, sls_quantity, sls_price
    FROM Bronze.crm_sales_details
    WHERE sls_price <= 0 OR sls_price IS NULL
       OR sls_quantity <= 0 OR sls_quantity IS NULL
       OR sls_sales != sls_price * sls_quantity
       OR sls_sales <= 0 OR sls_sales IS NULL;

    SELECT REPLACE(sls_price,'-','') 
    FROM Bronze.crm_sales_details
    WHERE sls_price < 0 OR sls_price IS NULL OR sls_price = 0;

    SELECT CASE WHEN sls_price IS NULL 
                THEN sls_sales / sls_quantity END AS sls_price
    FROM Bronze.crm_sales_details
    WHERE sls_price < 0 OR sls_price IS NULL OR sls_price = 0;

    SELECT CASE WHEN sls_sales IS NULL 
                THEN sls_quantity * sls_price 
                ELSE sls_sales END AS sls_sales
    FROM Bronze.crm_sales_details;

    -----------------------------------------------------------
    -- Post-Load Validation (Silver)
    -----------------------------------------------------------
    SELECT sls_ord_num, COUNT(*) 
    FROM Silver.crm_sales_details 
    GROUP BY sls_ord_num 
    HAVING COUNT(*) > 1 OR sls_ord_num IS NULL;

    SELECT * FROM Silver.crm_sales_details 
    WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

    SELECT DISTINCT sls_sales, sls_quantity, sls_price
    FROM Silver.crm_sales_details
    WHERE sls_price <= 0 OR sls_price IS NULL
       OR sls_quantity <= 0 OR sls_quantity IS NULL
       OR sls_sales != sls_price * sls_quantity
       OR sls_sales <= 0 OR sls_sales IS NULL;


    /*
    ===========================================================
        Data Cleaning & Loading: ERP Data
    ===========================================================
    */

    -----------------------------------------------------------
    -- ERP Customer (erp_cust_az12)
    -----------------------------------------------------------
    PRINT 'Loading ERP Customer data from Bronze';
    SELECT cid, bday, gen FROM Bronze.erp_cust_az12;

    PRINT 'Checking for duplicates in ERP Customer';
    SELECT COUNT(*) FROM Bronze.erp_cust_az12 GROUP BY cid HAVING COUNT(*) > 1;

    PRINT 'Checking standardization in gen column';
    SELECT DISTINCT gen FROM Bronze.erp_cust_az12;

    PRINT 'Standardizing gen values';
    SELECT DISTINCT CASE 
                        WHEN gen IN ('F','FEMALE') THEN 'FEMALE' 
                        WHEN gen IN ('M','MALE')   THEN 'Male' 
                        ELSE 'N/A' 
                     END AS gen 
    FROM Bronze.erp_cust_az12;

    PRINT 'Altering primary key format for ERP Customer';
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END AS cid,
           bday, gen 
    FROM Bronze.erp_cust_az12;

    PRINT 'Identifying invalid birthdates';
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END AS cid,
           bday, gen 
    FROM Bronze.erp_cust_az12 
    WHERE bday < '1924-01-01' OR bday > GETDATE();

    PRINT 'Applying birthdate corrections';
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END AS cid,
           CASE WHEN bday > GETDATE() THEN NULL ELSE bday END AS bday,
           gen 
    FROM Bronze.erp_cust_az12 
    WHERE bday < '1924-01-01' OR bday > GETDATE();

    PRINT 'Inserting cleansed ERP Customer data into Silver';

    PRINT 'Validating ERP Customer data in Silver';
    SELECT COUNT(*) FROM Silver.erp_cust_az12 GROUP BY cid HAVING COUNT(*) > 1;
    SELECT DISTINCT gen FROM Silver.erp_cust_az12;
    SELECT DISTINCT bday FROM Silver.erp_cust_az12 WHERE bday < '1924-01-01' OR bday > GETDATE();

    -----------------------------------------------------------
    -- ERP Location (erp_loc_a101)
    -----------------------------------------------------------
    PRINT 'Loading ERP Location data from Bronze';
    SELECT cid, cntry FROM Bronze.erp_loc_a101;

    PRINT 'Checking for duplicate CIDs in ERP Location';
    SELECT COUNT(*) FROM Bronze.erp_loc_a101 GROUP BY cid HAVING COUNT(*) > 1;

    PRINT 'Checking for missing customer keys in ERP Location';
    SELECT cid 
    FROM Bronze.erp_loc_a101 
    WHERE cid NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info);

    PRINT 'Cleaning CID values in ERP Location';
    SELECT REPLACE(cid,'-','') AS cid FROM Bronze.erp_loc_a101;

    PRINT 'Checking distinct country values in ERP Location';
    SELECT DISTINCT cntry FROM Bronze.erp_loc_a101;

    PRINT 'Standardizing country values';
    SELECT REPLACE(cid,'-','') AS cid,
           CASE 
               WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
               WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
               WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'N/A'
               ELSE TRIM(cntry) 
           END AS cntry
    FROM Bronze.erp_loc_a101;

    PRINT 'Inserting cleansed ERP Location data into Silver';

    PRINT 'Validating ERP Location data in Silver';
    SELECT cid FROM Silver.erp_loc_a101 WHERE cid NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info);
    SELECT DISTINCT cntry FROM Silver.erp_loc_a101;


    -----------------------------------------------------------
    -- ERP Product Category (erp_px_cat_g1v2)
    -----------------------------------------------------------
    PRINT 'Loading ERP Product Category data from Bronze';
    SELECT id, cat, subcat, maintenance FROM Bronze.erp_px_cat_g1v2;

    PRINT 'Checking for missing category IDs';
    SELECT id 
    FROM Bronze.erp_px_cat_g1v2 
    WHERE id NOT IN (SELECT DISTINCT cat_id FROM Silver.crm_prd_info);

    PRINT 'Checking for unwanted spaces in ERP Product Category';
    SELECT * FROM Bronze.erp_px_cat_g1v2 
    WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR TRIM(maintenance) != maintenance;

    PRINT 'Checking distinct category values';
    SELECT DISTINCT cat FROM Bronze.erp_px_cat_g1v2;

    PRINT 'Inserting ERP Product Category data into Silver';
