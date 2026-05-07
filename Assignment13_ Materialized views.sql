-- Assignment instructions

-- Create a materialized view called PARTS in the database DEMO_DB from the following statement:
-- SELECT 
-- AVG(PS_SUPPLYCOST) as PS_SUPPLYCOST_AVG,
-- AVG(PS_AVAILQTY) as PS_AVAILQTY_AVG,
-- MAX(PS_COMMENT) as PS_COMMENT_MAX
-- FROM"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF100"."PARTSUPP"
-- Execute the SELECT before creating the materialized view and note down the time until the query is executed.
-- Questions for this assignment

-- How long did the SELECT statement take initially?
-- How long did the execution of the materialized view take?

ALTER SESSION SET USE_CACHED_RESULT=FALSE; -- disable global caching
ALTER warehouse compute_wh suspend;
ALTER warehouse compute_wh resume;

USE DATABASE DEMO_DB;

------------- Normal View-----------
SELECT 
AVG(PS_SUPPLYCOST) as PS_SUPPLYCOST_AVG,
AVG(PS_AVAILQTY) as PS_AVAILQTY_AVG,
MAX(PS_COMMENT) as PS_COMMENT_MAX
FROM"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF100"."PARTSUPP"; -- 8.2second


----- MATERIALIZED VIEW ---------
CREATE OR REPLACE MATERIALIZED VIEW PARTS
AS
SELECT 
AVG(PS_SUPPLYCOST) as PS_SUPPLYCOST_AVG,
AVG(PS_AVAILQTY) as PS_AVAILQTY_AVG,
MAX(PS_COMMENT) as PS_COMMENT_MAX
FROM"SNOWFLAKE_SAMPLE_DATA"."TPCH_SF100"."PARTSUPP"; -- 5.8second


