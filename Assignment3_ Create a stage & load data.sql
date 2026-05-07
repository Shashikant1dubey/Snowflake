-- In this assignment you will create a stage & load data.

--                 Assignment instructions:
-- If you have not created the database EXERCISE_DB then you can do so. The same goes for the customer table with the following columns:
--             ID INT,
--             first_name varchar,
--             last_name varchar,
--             email varchar,
--             age int,
--             city varchar


-- 1. Create a database called EXERCISE_DB (if you have created that in one of the previous lectures you can skip this step)

-- 2. Create a stage object
-- The data is available under: s3://snowflake-assignments-mc/loadingdata/
-- Data type: CSV - delimited by ';' (semicolon)
-- Header is in the first line.

-- 3. List the files in the table

-- 4. Load the data in the existing customers table using the COPY command

-- 4. How many rows have been loaded in this assignment?

--             Questions for this assignment

-- 1. How many rows have been loaded in this assignment?

USE DATABASE EXERCISE_DB;

 ---- Assignment solution - Create stage & load data ----
 
-- create stage object
CREATE OR REPLACE STAGE EXERCISE_DB.public.aws_stage
    url='s3://snowflake-assignments-mc/loadingdata';

-- List files in stage
LIST @EXERCISE_DB.public.aws_stage;

-- Load the data 
COPY INTO EXERCISE_DB.PUBLIC.CUSTOMERS
    FROM @aws_stage
    file_format= (type = csv field_delimiter=';' skip_header=1);

SELECT * FROM EXERCISE_DB.PUBLIC.CUSTOMERS;
    



