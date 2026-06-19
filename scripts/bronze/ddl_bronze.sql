/*
===========================================================
    Process: Bronze Layer Table Creation + Data Load
===========================================================

 Purpose:
- Create raw ingestion tables in the Bronze schema for CRM and ERP data.
- Drop/recreate tables if they already exist to avoid conflicts.
- Bulk load CSV data into each table for downstream ETL.

 Warnings:
- Dropping or truncating tables will remove all existing data.
- Ensure CSV files are not open in Excel/Notepad (avoids OS error 32).
- SQL Server service account must have read access to the file paths.
===========================================================
*/

CREATE OR ALTER PROCEDURE Bronze.load_bronze AS 
BEGIN
DECLARE @start_time DATETIME,@end_time DATETIME;
    BEGIN TRY
        -----------------------------------------------------------
        -- Table Creation Section
        -----------------------------------------------------------
        PRINT 'TABLES ARE BEING CREATED';

        IF OBJECT_ID('Bronze.crm_cust_info','U') IS NOT NULL
            DROP TABLE Bronze.crm_cust_info;

        CREATE TABLE Bronze.crm_cust_info (
            cst_id              INT,
            cst_key             NVARCHAR(50),
            cst_firstname       NVARCHAR(50),
            cst_lastname        NVARCHAR(50),
            cst_material_status NVARCHAR(50),
            cst_gndr            NVARCHAR(50),
            cst_create_date     DATE
        );

        IF OBJECT_ID('Bronze.crm_prd_info','U') IS NOT NULL
            DROP TABLE Bronze.crm_prd_info;

        CREATE TABLE Bronze.crm_prd_info (
            prd_id       INT,
            prd_key      NVARCHAR(50),
            prd_nm       NVARCHAR(50),
            prd_cost     INT,
            prd_line     NVARCHAR(50),
            prd_start_dt DATETIME,
            prd_end_dt   DATETIME
        );

        IF OBJECT_ID('Bronze.crm_sales_details','U') IS NOT NULL
            DROP TABLE Bronze.crm_sales_details;

        CREATE TABLE Bronze.crm_sales_details (
            sls_ord_num   NVARCHAR(50),
            sls_prd_key   NVARCHAR(50),
            sls_cust_id   INT,
            sls_order_dt  INT,
            sls_ship_dt   INT,
            sls_due_dt    INT,
            sls_sales     INT,
            sls_quantity  INT,
            sls_price     INT
        );

        IF OBJECT_ID('Bronze.erp_cust_az12','U') IS NOT NULL
            DROP TABLE Bronze.erp_cust_az12;

        CREATE TABLE Bronze.erp_cust_az12 (
            cid  NVARCHAR(50),
            bday DATE,
            gen  NVARCHAR(50)
        );

        IF OBJECT_ID('Bronze.erp_loc_a101','U') IS NOT NULL
            DROP TABLE Bronze.erp_loc_a101;

        CREATE TABLE Bronze.erp_loc_a101 (
            cid    NVARCHAR(50),
            cntry  NVARCHAR(50)
        );

        IF OBJECT_ID('Bronze.erp_px_cat_g1v2','U') IS NOT NULL
            DROP TABLE Bronze.erp_px_cat_g1v2;

        CREATE TABLE Bronze.erp_px_cat_g1v2 (
            id           NVARCHAR(50),
            cat          NVARCHAR(50),
            subcat       NVARCHAR(50),
            maintenance  NVARCHAR(50)
        );

        PRINT 'TABLES ARE CREATED';

        -----------------------------------------------------------
        --  Data Load Section
        -----------------------------------------------------------
        PRINT 'DATA IS BEING LOADED';
        SET @start_time=GETDATE()
        IF OBJECT_ID('Bronze.crm_cust_info','U') IS NOT NULL
            TRUNCATE TABLE Bronze.crm_cust_info;

        BULK INSERT Bronze.crm_cust_info
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_crm\\cust_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        IF OBJECT_ID('Bronze.crm_prd_info','U') IS NOT NULL
            TRUNCATE TABLE Bronze.crm_prd_info;

        BULK INSERT Bronze.crm_prd_info
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_crm\\prd_info.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        IF OBJECT_ID('Bronze.crm_sales_details','U') IS NOT NULL
            TRUNCATE TABLE Bronze.crm_sales_details;

        BULK INSERT Bronze.crm_sales_details
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_crm\\sales_details.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        IF OBJECT_ID('Bronze.erp_cust_az12','U') IS NOT NULL
            TRUNCATE TABLE Bronze.erp_cust_az12;

        BULK INSERT Bronze.erp_cust_az12
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_erp\\CUST_AZ12.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        IF OBJECT_ID('Bronze.erp_loc_a101','U') IS NOT NULL
            TRUNCATE TABLE Bronze.erp_loc_a101;

        BULK INSERT Bronze.erp_loc_a101
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_erp\\LOC_A101.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        IF OBJECT_ID('Bronze.erp_px_cat_g1v2','U') IS NOT NULL
            TRUNCATE TABLE Bronze.erp_px_cat_g1v2;

        BULK INSERT Bronze.erp_px_cat_g1v2
        FROM 'D:\\sql-data-warehouse-project\\datasets\\source_erp\\PX_CAT_G1V2.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);

        PRINT 'DATA IS LOADED';
        PRINT 'Bronze.load_bronze completed successfully';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR FOUND: ' + ERROR_MESSAGE();
        THROW; -- re-raise the original error for visibility
    END CATCH
    SET @end_time=GETDATE()
    PRINT 'Total time taken ' + CAST(DATEDIFF(SECOND,@start_time,@end_time)AS NVARCHAR(50)) + ' seconds'
END;
GO

-- Execute the procedure
EXEC Bronze.load_bronze;
