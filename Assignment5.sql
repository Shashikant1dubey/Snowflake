-- Assignment instructions
-- 15 minutes to complete

-- 1. Create a table called employees with the following columns and data types:
--   customer_id int,
--   first_name varchar(50),
--   last_name varchar(50),
--   email varchar(50),
--   age int,
--   department varchar(50)

-- 2. Create a stage object pointing to 's3://snowflake-assignments-mc/copyoptions/example1'

-- 3. Create a file format object with the specification
-- TYPE = CSV
-- FIELD_DELIMITER=','
-- SKIP_HEADER=1;

-- 4. Use the copy option to only validate if there are errors and if yes what errors.

-- 5. Load the data anyways regardless of the error using the ON_ERROR option. How many rows have been loaded?
-- Questions for this assignment

-- How many rows have been loaded?

---- Assignment - Create file format & load data ----
 
-- create table
create or replace table employees(
  customer_id int,
  first_name varchar(50),
  last_name varchar(50),
  email varchar(50),
  age int,
  city varchar(50));
 
 
-- create file format object
CREATE OR REPLACE FILE FORMAT EXERCISE_DB.public.aws_fileformat
TYPE = CSV
FIELD_DELIMITER=','
SKIP_HEADER=1;


-- create stage object
CREATE OR REPLACE STAGE EXERCISE_DB.public.aws_stage
    url='s3://snowflake-assignments-mc/copyoptions/example1';
    

-- List files in stage
LIST @EXERCISE_DB.public.aws_stage;      


-- Use validation mode
COPY INTO EXERCISE_DB.PUBLIC.EMPLOYEES
    FROM @aws_stage
      file_format= EXERCISE_DB.public.aws_fileformat
      VALIDATION_MODE = RETURN_ERRORS;
 

-- Use ON_ERROR
COPY INTO EXERCISE_DB.PUBLIC.EMPLOYEES
    FROM @aws_stage
      file_format= EXERCISE_DB.public.aws_fileformat
      ON_ERROR = CONTINUE;      


