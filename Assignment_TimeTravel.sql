-- 1. Create exercise table
-- -- Switch to role of accountadmin --
 
-- USE ROLE ACCOUNTADMIN;
-- USE DATABASE DEMO_DB;
-- USE WAREHOUSE COMPUTE_WH;
 
-- CREATE OR REPLACE TABLE DEMO_DB.PUBLIC.PART
-- AS
-- SELECT * FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."PART";
 
-- SELECT * FROM PART
-- ORDER BY P_MFGR DESC;

-- 2. Update the table
-- UPDATE DEMO_DB.PUBLIC.PART
-- SET P_MFGR='Manufacturer#CompanyX'
-- WHERE P_MFGR='Manufacturer#5';
 
-- ----> Note down query id here:
 
-- SELECT * FROM PART
-- ORDER BY P_MFGR DESC;

-- 3.1: Travel back using the offset until you get the result of before the update

-- 3.2: Travel back using the query id to get the result before the update
-- Questions for this assignment

-- How did you do it? Feel free to share the code or your experience.


// 1. Create exercise table

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE DATABASE DEMO_DB;
USE WAREHOUSE COMPUTE_WH;
 
CREATE OR REPLACE TABLE DEMO_DB.PUBLIC.PART
AS
SELECT * FROM "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1"."PART";
 
SELECT * FROM PART
ORDER BY P_MFGR DESC;


// 2. Update the table

UPDATE DEMO_DB.PUBLIC.PART
SET P_MFGR='Manufacturer#CompanyX'
WHERE P_MFGR='Manufacturer#5';
----> Note down query id here: 01c3b8d4-3202-966e-0016-32ae00053e9e

SELECT * FROM PART
ORDER BY P_MFGR DESC;

// 3.1: Travel back using the offset until you get the result of before the update:

SELECT * FROM DEMO_DB.PUBLIC.PART AT(OFFSET => -60*3) ORDER BY P_MFGR DESC;

// 3.2: Travel back using the query id to get the result before the update

SELECT * FROM DEMO_DB.PUBLIC.PART BEFORE(Statement => '01c3b8d4-3202-966e-0016-32ae00053e9e');