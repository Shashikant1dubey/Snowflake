-- Assignment: Parsing & handling array

-- Assignment instructions
-- 20 minutes to complete
-- If you have not created the database EXERCISE_DB then you can do so - otherwise use this database for this exercise.

-- 1. Query from the previously created JSON_RAW  table.
-- Note: This table was created in the previous assignment (assignment 7) where you had to create a stage object that is pointing to 's3://snowflake-assignments-mc/unstructureddata/'. We have called the table JSON_RAW.


-- 2. Select the attributes
-- first_name
-- last_name
-- skills
-- and query these columns.

-- 2. The skills column contains an array. Query the first two values in the skills attribute for every record in a separate column:
-- first_name
-- last_name
-- skills_1
-- skills_2

-- 3. Create a table and insert the data for these 4 columns in that table.
-- Questions for this assignment

-- What is the first skill of the person with first_name 'Florina'?

USE DATABASE EXERCISE_DB;

// Second step: Parse & Analyse Raw JSON 

SELECT * FROM JSON_RAW;

// Selecting attribute/column
SELECT 
$1:first_name::STRING,
$1:last_name::STRING,
$1:Skills[0]::STRING,
$1:Skills[1]::STRING
FROM JSON_RAW;


// Copy data in table
CREATE TABLE SKILLS AS
SELECT 
$1:first_name::STRING as first_name,
$1:last_name::STRING as last_name,
$1:Skills[0]::STRING as Skill_1,
$1:Skills[1]::STRING as Skill_2
FROM JSON_RAW;

// Query from table
SELECT * FROM SKILLS
WHERE FIRST_NAME='Florina';






