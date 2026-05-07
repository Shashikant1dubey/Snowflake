-- Assignment: Create file format object & use copy option
-- 15 minutes to complete

-- We will create a file format object and use a copy option

-- If you have not created the database EXERCISE_DB then you can do so. The same goes for the customer table with the following columns:
-- ID INT,
-- first_name varchar,
-- last_name varchar,
-- email varchar,
-- age int,
-- city varchar


-- 1. Create a stage & file format object
-- The data is available under: s3://snowflake-assignments-mc/fileformat/
-- Data type: CSV - delimited by '|' (pipe)
-- Header is in the first line.

-- 2. List the files in the table

-- 3. Load the data in the existing customers table using the COPY command your stage and the created file format object.

-- 4. How many rows have been loaded in this assignment?
-- Questions for this assignment

-- How many rows have been loaded?

USE DATABASE EXERCISE_DB;

CREATE OR REPLACE TABLE EXERCISE_DB.PUBLIC.CUSTOMERS(
    ID INT,
    first_name varchar,
    last_name varchar,
    email varchar,
    age int,
    city varchar);

 ---- Assignment - Create file format & load data ----
 
-- create stage object
CREATE OR REPLACE STAGE EXERCISE_DB.public.aws_stage
    url='s3://snowflake-assignments-mc/fileformat';

-- List files in stage
LIST @EXERCISE_DB.public.aws_stage;

-- create file format object
CREATE OR REPLACE FILE FORMAT EXERCISE_DB.public.aws_fileformat
TYPE = CSV
FIELD_DELIMITER='|'
SKIP_HEADER=1;

-- Load the data 
COPY INTO EXERCISE_DB.PUBLIC.CUSTOMERS
    FROM @aws_stage
      file_format= (FORMAT_NAME=EXERCISE_DB.public.aws_fileformat);
      
-- Alternative
COPY INTO EXERCISE_DB.PUBLIC.CUSTOMERS
    FROM @aws_stage
      file_format= EXERCISE_DB.public.aws_fileformat;

SELECT * FROM EXERCISE_DB.PUBLIC.CUSTOMERS;



