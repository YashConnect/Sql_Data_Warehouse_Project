-----------------------------------------------------------
-- Data Load & Processing Section
-----------------------------------------------------------
CREATE OR ALTER PROCEDURE Silver.load_silver AS 
BEGIN
    DECLARE @start_time DATETIME,@end_time DATETIME;
    BEGIN TRY
    SET @start_time=GETDATE()
    -----------------------------------------------------------
    --  Insert Cleansed Data into Silver Layer
    -----------------------------------------------------------

    IF OBJECT_ID('Silver.crm_cust_info','U') IS NOT NULL
        TRUNCATE TABLE Silver.crm_cust_info;

    INSERT INTO Silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_date
    )
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

    
    -- Necessary Change: Added Truncate for CRM Product Info
    IF OBJECT_ID('Silver.crm_prd_info','U') IS NOT NULL
        TRUNCATE TABLE Silver.crm_prd_info;

    INSERT INTO Silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
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
           CAST(prd_start_dt AS DATE) AS prd_start_dt,
           CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
    FROM Bronze.crm_prd_info;

    

    -----------------------------------------------------------
    -- Apply All Cleansing Logic Together
    -----------------------------------------------------------

    -- Necessary Change: Added Truncate for CRM Sales Details
    IF OBJECT_ID('Silver.crm_sales_details','U') IS NOT NULL
        TRUNCATE TABLE Silver.crm_sales_details;

    INSERT INTO Silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
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
           CASE WHEN sls_sales IS NULL 
                  OR sls_sales != sls_quantity * ABS(sls_price) 
                  OR sls_sales <= 0 
                THEN ABS(sls_price) * sls_quantity 
                ELSE sls_sales END AS sls_sales,
           sls_quantity,
           CASE WHEN sls_price IS NULL OR sls_price <= 0 
                THEN NULLIF(sls_sales,0) / sls_quantity 
                ELSE sls_price END AS sls_price
    FROM Bronze.crm_sales_details;

    -- Necessary Change: Added Truncate for ERP Customer
    IF OBJECT_ID('Silver.erp_cust_az12','U') IS NOT NULL
        TRUNCATE TABLE Silver.erp_cust_az12;

    INSERT INTO Silver.erp_cust_az12 (cid, bday, gen)
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END AS cid,
           CASE WHEN bday > GETDATE() THEN NULL ELSE bday END AS bday,
           CASE 
               WHEN gen IN ('F','FEMALE') THEN 'FEMALE' 
               WHEN gen IN ('M','MALE')   THEN 'Male' 
               ELSE 'N/A' 
           END AS gen
    FROM Bronze.erp_cust_az12;

    -- Necessary Change: Added Truncate for ERP Location
    IF OBJECT_ID('Silver.erp_loc_a101','U') IS NOT NULL
        TRUNCATE TABLE Silver.erp_loc_a101;

    INSERT INTO Silver.erp_loc_a101 (cid, cntry)
    SELECT REPLACE(cid,'-','') AS cid,
           CASE 
               WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
               WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
               WHEN TRIM(cntry) = '' OR TRIM(cntry) IS NULL THEN 'N/A'
               ELSE TRIM(cntry) 
           END AS cntry
    FROM Bronze.erp_loc_a101;


    -- Necessary Change: Added Truncate for ERP Product Category
    IF OBJECT_ID('Silver.erp_px_cat_g1v2','U') IS NOT NULL
        TRUNCATE TABLE Silver.erp_px_cat_g1v2;

    INSERT INTO Silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance 
    FROM Bronze.erp_px_cat_g1v2;

    SET @end_time=GETDATE()
    PRINT 'Total time taken ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(50)) + ' seconds'

    END TRY
    BEGIN CATCH
        PRINT 'ERROR ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO
-- Execute the procedure
EXEC Silver.load_silver;
