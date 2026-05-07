-- 1. Create a database called EXERCISE_DB

-- 2. Create a table called CUSTOMERS
-- Set the column names and data types as follows:
-- ID INT,
-- first_name varchar,
-- last_name varchar,
-- email varchar,
-- age int,
-- city varchar

-- 3. Load the data in the table
-- The data is available under: s3://snowflake-assignments-mc/gettingstarted/customers.csv.
-- Data type: CSV - delimited by ',' (comma)
-- Header is in the first line.

-- 4. Query from that table. How many rows are now in the table?

USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE DATABASE EXERCISE_DB;

CREATE TABLE CUSTOMERS (
ID INT,
first_name varchar,
last_name varchar,
email varchar,
age int,
city varchar
);

COPY INTO CUSTOMERS
FROM s3://snowflake-assignments-mc/gettingstarted/customers.csv
    file_format = (type = csv,
                    field_delimiter = ',',
                    skip_header = 1);

select * from customers;
