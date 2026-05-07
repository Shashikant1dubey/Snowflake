-- Assignment instructions
-- 15 minutes to complete

-- If you have not created the database EXERCISE_DB then you can do so - otherwise use this database for this exercise.

-- 1. Create a stage object that is pointing to 's3://snowflake-assignments-mc/unstructureddata/'

-- 2. Create a file format object that is using TYPE = JSON

-- 3. Create a table called JSON_RAW with one column
-- Column name: Raw
-- Column type: Variant

-- 4. Copy the raw data in the JSON_RAW table using the file format object and stage object

-- Questions for this assignment

-- What is the last name of the person in the first row (id=1)?


-- SOLUTION:

--  Create database (only if not already created in previous assignment)
create database EXERCISE_DB;
 
USE EXERCISE_DB;


 // First step: Load Raw JSON
CREATE OR REPLACE stage JSONSTAGE
     url='s3://snowflake-assignments-mc/unstructureddata/';

CREATE OR REPLACE file format JSONFORMAT
    TYPE = JSON;
    
    
CREATE OR REPLACE table JSON_RAW (
    raw_file variant);
    
COPY INTO JSON_RAW
    FROM @JSONSTAGE
    file_format= JSONFORMAT
    
SELECT * FROM JSON_RAW;
    