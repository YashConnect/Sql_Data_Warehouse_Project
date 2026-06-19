/*
===========================================================
   📦 Process: Data Warehouse Initialization Script
===========================================================

🎯 Purpose:
- Create a fresh database named 'WareHouse'.
- Define three schemas (Bronze, Silver, Gold) to support
  a layered data architecture:
    • Bronze → Raw, unprocessed data
    • Silver → Cleansed, transformed data
    • Gold   → Curated, business-ready data

⚠️ Warnings:
- This script will DROP the existing 'WareHouse' database
  if it already exists. All data inside will be lost.
- Ensure backups are taken before running in production.
- Use cautiously in shared environments to avoid conflicts.
===========================================================
*/

-- Switch to master database to perform DB-level operations
USE master;

-- If WareHouse DB exists, force single-user mode, rollback active transactions, then drop it
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'WareHouse')
BEGIN
    ALTER DATABASE WareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WareHouse;
END;

GO

-- Create a fresh WareHouse database
CREATE DATABASE WareHouse;

-- Switch context to the new database
USE WareHouse;

GO

-- Schema for raw ingestion layer
CREATE SC
