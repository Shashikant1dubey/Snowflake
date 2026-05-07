====================== Lec 10: SETTING WAREHOUSE USING SQL =======================================
-- 1. To be able to create the virtual warehouse, you have to use at least the role SYSADMIN (or SECURITYADMIN or ACCOUNTADMIN).
USE ROLE SYSADMIN;

-- 2. Set up a virtual warehouse using SQL command:
CREATE OR REPLACE WAREHOUSE EXERCISE_WH
WITH
    WAREHOUSE_SIZE = XSMALL
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT =3
    AUTO_SUSPEND = 600  -- automatically suspend the virtual warehouse after 10 minutes of not being used
    AUTO_RESUME = TRUE 
    COMMENT = 'This is a virtual warehouse of size X-SMALL that can be used to process queries.'
    SCALING_POLICY =  'ECONOMY';

-- 3. Drop the virtual warehouse
DROP WAREHOUSE EXERCISE_WH;

====================== Lec 11: Manage Warehouse =======================================
ALTER WAREHOUSE EXERCISE_WH RESUME;

ALTER WAREHOUSE EXERCISE_WH SUSPEND;

ALTER WAREHOUSE EXERCISE_WH SET WAREHOUSE_SIZE ='SMALL'

ALTER WAREHOUSE EXERCISE_WH SET WAREHOUSE_SIZE = XSMALL

ALTER WAREHOUSE EXERCISE_WH SET AUTO_SUSPEND = 60

DROP WAREHOUSE EXERCISE_WH


====================== Lec 12: Scaling Policy =======================================

-- AUTO_SCALING: When to start additional cluster?

-- Scaling policy : Two types
--                  1. Standard : Default, Favours starting additional warehouses.
--                  2. Economy : Favours conserving credits rather than additional warehouses.



--              Standard Policy (default)
-- Description:            Prevents/minimizes queuing by favoring starting additional clusters over conserving credits.
-- Cluster Starts... :     Immediately when either a query is queued or the system detects that there are more queries than can be                                             executed by the currently available clusters.
-- Cluster Shuts Down...: After 2 to 3 consecutive successful checks



--              Economy Policy
-- Description:            Conserves credits by favoring keeping running clusters fully-loaded rather than starting additional                                         clusters,Result: May result in queries being queued and taking longer to complete.
-- Cluster Starts...:      Only if the system estimates there's enough query load to keep the cluster busy for at least 6 minutes.
-- Cluster Shuts Down...:  After 5 to 6 consecutive successful checks ...


====================== Lec 13: EXPLORING TABLES & DATABASES =======================================

CREATE OR REPLACE TABLE FIRST_TABLE
FIRST_COLUMN INT,
SECOND_COLUMN TEXT
COMMENT ='This is my first table'

select * from FIRST_DB.FIRST_SCHEMA.FIRST_TABLE;


====================== Lec 14: LOADING DATA IN SNOWFLAKE =======================================

//Rename data base & creating the table + meta data
USE ROLE ACCOUNTADMIN;
ALTER DATABASE FIRST_DB RENAME TO OUR_FIRST_DB;

CREATE TABLE "OUR_FIRST_DB"."PUBLIC"."LOAN_PAYMENT" (
  "Loan_ID" STRING,
  "loan_status" STRING,
  "Principal" STRING,
  "terms" STRING,
  "effective_date" STRING,
  "due_date" STRING,
  "paid_off_time" STRING,
  "past_due_days" STRING,
  "age" STRING,
  "education" STRING,
  "Gender" STRING);
  
  
 //Check that table is empty
 USE DATABASE OUR_FIRST_DB;

 SELECT * FROM LOAN_PAYMENT;

 
 //Loading the data from S3 bucket
  
 COPY INTO LOAN_PAYMENT
    FROM s3://bucketsnowflakes3/Loan_payments_data.csv
    file_format = (type = csv 
                   field_delimiter = ',' 
                   skip_header=1);
    

//Validate
 SELECT * FROM LOAN_PAYMENT;

 ====================== Lec 15: WHAT IS DATA WAREHOUSE =======================================

-- What is datawarehouse?
-- Database that is used for reporting and Data analysis

-- Different Layer:
--             HR data + Sales Data
--                             ⬇︎
--             RAW Data (Also called Staging Area) 
--                             ⬇︎
--             Data Integration / Data Transformation (ETL process is carried out here)
--                             ⬇︎
--             Access Layer -> Data Science/ Reporting / Other apps.
            

--       RAW Layer ➡️ Data Integration ➡️ Access Layer ➡️ Data Science / Reporting




====================== Lec 26: WHAT IS DATA WAREHOUSE =======================================

// Database to manage stage objects, fileformats etc.

CREATE OR REPLACE DATABASE MANAGE_DB;

CREATE OR REPLACE SCHEMA external_stages;


// Creating external stage

CREATE OR REPLACE STAGE MANAGE_DB.external_stages.aws_stage
    url='s3://bucketsnowflakes3'
    credentials=(aws_key_id='ABCD_DUMMY_ID' aws_secret_key='1234abcd_key');


// Description of external stage

DESC STAGE MANAGE_DB.external_stages.aws_stage; 
    
    
// Alter external stage   

ALTER STAGE aws_stage
    SET credentials=(aws_key_id='XYZ_DUMMY_ID' aws_secret_key='987xyz');
        
// Description of external stage

DESC STAGE MANAGE_DB.external_stages.aws_stage; 


// Publicly accessible staging area    

CREATE OR REPLACE STAGE MANAGE_DB.external_stages.aws_stage
    url='s3://bucketsnowflakes3';

// List files in stage

LIST @aws_stage;


//Load data WITH PATTERNS using copy command

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*';


====================== Lec 27: COPY COMMAND =======================================

// Creating ORDERS table

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS;
   
// First copy command
-- (gets error as file name is not specified below in COPY INTO command.)
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @aws_stage
    file_format = (type = csv field_delimiter=',' skip_header=1);




// Copy command with fully qualified stage object
-- (gets error as file name is not specified below in COPY INTO command.)
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @MANAGE_DB.external_stages.aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1);


// List files contained in stage

LIST @MANAGE_DB.external_stages.aws_stage;    




// Copy command with specified file(s)

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @MANAGE_DB.external_stages.aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails.csv');
    



// Copy command with pattern for file names

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @MANAGE_DB.external_stages.aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*';
    

====================== Lec 28: Data Transformation during loading OR staging =======================================

// Transforming using the SELECT statement

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM (select s.$1, s.$2 from @MANAGE_DB.external_stages.aws_stage s)
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files=('OrderDetails.csv');


// Example 1 - Table

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT
    );
   
   
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
   
// Example 2 - Table    

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    PROFITABLE_FLAG VARCHAR(30)
  
    );

SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;

// Example 2 - Copy Command using a SQL function (subset of functions available)

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM (select 
            s.$1,
            s.$2, 
            s.$3,
            CASE WHEN CAST(s.$3 as int) < 0 THEN 'not profitable' ELSE 'profitable' END 
          from @MANAGE_DB.external_stages.aws_stage s)
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files=('OrderDetails.csv');


SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;


// Example 3 - Table

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    CATEGORY_SUBSTRING VARCHAR(5)
  
    );


// Example 3 - Copy Command using a SQL function (subset of functions available)

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM (select 
            s.$1,
            s.$2, 
            s.$3,
            substring(s.$5,1,5) 
          from @MANAGE_DB.external_stages.aws_stage s)
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files=('OrderDetails.csv');


SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;


====================== Lec29: More Transformation Technique =======================================
//Example 3 - Table

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    PROFITABLE_FLAG VARCHAR(30)
  
    );



//Example 4 - Using subset of columns

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX (ORDER_ID,PROFIT)
    FROM (select 
            s.$1,
            s.$3
          from @MANAGE_DB.external_stages.aws_stage s)
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files=('OrderDetails.csv');

SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;



//Example 5 - Table Auto increment

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID number autoincrement start 1 increment 1,
    AMOUNT INT,
    PROFIT INT,
    PROFITABLE_FLAG VARCHAR(30)
  
    );



//Example 5 - Auto increment ID

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX (PROFIT,AMOUNT)
    FROM (select 
            s.$2,
            s.$3
          from @MANAGE_DB.external_stages.aws_stage s)
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files=('OrderDetails.csv');


SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX WHERE ORDER_ID > 15;


    
DROP TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX

====================== Lec30: Copy Option: ON_ERROR =======================================

 // Create new stage
 CREATE OR REPLACE STAGE MANAGE_DB.external_stages.aws_stage_errorex
    url='s3://bucketsnowflakes4';
 
 // List files in stage
 LIST @MANAGE_DB.external_stages.aws_stage_errorex;
 
 
 // Create example table
 CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));
 
 // Demonstrating error message
 COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv');
    

 // Validating table is empty    
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;    
    

  // Error handling using the ON_ERROR option
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv')
    ON_ERROR = 'CONTINUE';
    
  // Validating results and truncating table 
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
SELECT COUNT(*) FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;

TRUNCATE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX;

// Error handling using the ON_ERROR option = ABORT_STATEMENT (default)
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv','OrderDetails_error2.csv')
    ON_ERROR = 'ABORT_STATEMENT';


  // Validating results and truncating table 
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
SELECT COUNT(*) FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;

TRUNCATE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX;

// Error handling using the ON_ERROR option = SKIP_FILE
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv','OrderDetails_error2.csv')
    ON_ERROR = 'SKIP_FILE';
    
    
  // Validating results and truncating table 
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
SELECT COUNT(*) FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;

TRUNCATE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX;    
    

// Error handling using the ON_ERROR option = SKIP_FILE_<number>
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv','OrderDetails_error2.csv')
    ON_ERROR = 'SKIP_FILE_2';    
    
    
  // Validating results and truncating table 
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
SELECT COUNT(*) FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;

TRUNCATE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX;    

    
// Error handling using the ON_ERROR option = SKIP_FILE_<number>
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv','OrderDetails_error2.csv')
    ON_ERROR = 'SKIP_FILE_0.5%'; 
  
  
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;
SELECT COUNT(*) FROM OUR_FIRST_DB.PUBLIC.ORDERS_EX;


 CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));





COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv','OrderDetails_error2.csv')
    ON_ERROR = SKIP_FILE_3 
    SIZE_LIMIT = 30;



====================== Lec31: File Format Object  =======================================


// Specifying file_format in Copy command
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format = (type = csv field_delimiter=',' skip_header=1)
    files = ('OrderDetails_error.csv')
    ON_ERROR = 'SKIP_FILE_3'; 
    
    

// Creating table
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.ORDERS_EX (
    ORDER_ID VARCHAR(30),
    AMOUNT INT,
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));    
    
// Creating schema to keep things organized
CREATE OR REPLACE SCHEMA MANAGE_DB.file_formats;

// Creating file format object
CREATE OR REPLACE file format MANAGE_DB.file_formats.my_file_format;

// See properties of file format object
DESC file format MANAGE_DB.file_formats.my_file_format;


// Using file format object in Copy command       
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (FORMAT_NAME=MANAGE_DB.file_formats.my_file_format)
    files = ('OrderDetails_error.csv')
    ON_ERROR = 'SKIP_FILE_3'; 


// Altering file format object
ALTER file format MANAGE_DB.file_formats.my_file_format
    SET SKIP_HEADER = 1;
    
// Defining properties on creation of file format object   
CREATE OR REPLACE file format MANAGE_DB.file_formats.my_file_format
    TYPE=JSON,
    TIME_FORMAT=AUTO;    
    
// See properties of file format object    
DESC file format MANAGE_DB.file_formats.my_file_format;   

  
// Using file format object in Copy command       
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM @MANAGE_DB.external_stages.aws_stage_errorex
    file_format= (FORMAT_NAME=MANAGE_DB.file_formats.my_file_format)
    files = ('OrderDetails_error.csv')
    ON_ERROR = 'SKIP_FILE_3'; 


// Altering the type of a file format is not possible
ALTER file format MANAGE_DB.file_formats.my_file_format
SET TYPE = CSV;

-- Once the file format is changed from JSON to CSV in order to load file in CSV, we need to create new CSV file foramt

// Recreate file format (default = CSV)
CREATE OR REPLACE file format MANAGE_DB.file_formats.my_file_format;


// See properties of file format object    
DESC file format MANAGE_DB.file_formats.my_file_format;   



// Truncate table
TRUNCATE table OUR_FIRST_DB.PUBLIC.ORDERS_EX;



// Overwriting properties of file format object      
COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS_EX
    FROM  @MANAGE_DB.external_stages.aws_stage_errorex
    file_format = (FORMAT_NAME= MANAGE_DB.file_formats.my_file_format  field_delimiter = ',' skip_header=1 )
    files = ('OrderDetails_error.csv')
    ON_ERROR = 'SKIP_FILE_3'; 

DESC STAGE MANAGE_DB.external_stages.aws_stage_errorex;

We can also change the file_format under stage as well since format_type is mostly supported under STAGE.


====================== Lec34: Validation_Mode.sql =======================================

---- VALIDATION_MODE ----
-- # Validation mode does not load the actual data but it is used to verify the data and find the error in file.

// Prepare database & table
CREATE OR REPLACE DATABASE COPY_DB;


CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));

// Prepare stage object
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/size/';
  
LIST @COPY_DB.PUBLIC.aws_stage_copy;
  
    
 //Load data using copy command
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    VALIDATION_MODE = RETURN_ERRORS;

SELECT * FROM ORDERS;
    
    
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
   VALIDATION_MODE = RETURN_5_ROWS;

SELECT * FROM ORDERS; -- data is not loaded as VALIDATION_MODE is given in above query.

-- Use file with Errors
create or replace stage copy_db.public.aws_stage_copy 
url ='s3://snowflakebucket-copyoption/returnfailed/';

List @copy_db.public.aws_stage_copy;

-- show all errors
copy into copy_db.public.orders
    from @copy_db.public.aws_stage_copy
    file_format = (type=csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    validation_mode=return_errors;


-- validate first n rows
copy into copy_db.public.orders
    from @copy_db.public.aws_stage_copy
    file_format = (type=csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    validation_mode = return_5_rows;

-- validate with errors
copy into copy_db.public.orders
    from @copy_db.public.aws_stage_copy
    file_format = (type=csv field_delimiter=',' skip_header=1)
    pattern='.*error.*'
    validation_mode = return_5_rows;



====================== Lec 35: Working with Rejected Records  =======================================
  ---- Use files with errors ----
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/returnfailed/';

LIST @COPY_DB.PUBLIC.aws_stage_copy;    


COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    VALIDATION_MODE = RETURN_ERRORS;



COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    VALIDATION_MODE = RETURN_1_rows;
    



-------------- Working with error results -----------

---- 1) Saving rejected files after VALIDATION_MODE ---- 

CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));


COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    VALIDATION_MODE = RETURN_ERRORS; ---- at the end of this query result it has column named REJECTED_RECORD which is used for furthur solving the error.


// Storing rejected /failed results in a table
-- CREATE OR REPLACE TABLE rejected AS 
-- select rejected_record from table(result_scan(last_query_id())); -- Template to create rejected_record , -- result_scan gives result from last 24 hr results from COPY INTO command. -- Query_id comes from result and from result we go to information i button as copy query id.


CREATE OR REPLACE TABLE rejected AS 
select rejected_record from table(result_scan('01c397e5-3202-8fc5-0016-32ae000240b2')); -- where last_query_id() = '01c397e5-3202-8fc5-0016-32ae000240b2' 


INSERT INTO rejected
select rejected_record from table(result_scan('01c397e5-3202-8fc5-0016-32ae000240b2'));

SELECT * FROM rejected;




---- 2) Saving rejected files without VALIDATION_MODE ---- 





COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    ON_ERROR=CONTINUE;
  
  
select * from table(validate(orders, job_id => '_last'));

-- validate -- validate([<namespace>.]<table_name>, JOB_ID => { '<query_id>' | '_last' })
--                 Validates the files loaded in a past execution of the COPY INTO command and returns all the errors encountered                      during the load, rather than just the first error


---- 3) Working with rejected records ---- 



SELECT REJECTED_RECORD FROM rejected;

CREATE OR REPLACE TABLE rejected_values as
SELECT 
SPLIT_PART(rejected_record,',',1) as ORDER_ID, 
SPLIT_PART(rejected_record,',',2) as AMOUNT, 
SPLIT_PART(rejected_record,',',3) as PROFIT, 
SPLIT_PART(rejected_record,',',4) as QUATNTITY, 
SPLIT_PART(rejected_record,',',5) as CATEGORY, 
SPLIT_PART(rejected_record,',',6) as SUBCATEGORY
FROM rejected; 


SELECT * FROM rejected_values;

====================== Lec 36: Size_Limit =======================================

---- SIZE_LIMIT ----

// Prepare database & table
CREATE OR REPLACE DATABASE COPY_DB;

CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));
    
    
// Prepare stage object
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/size/';
    
    
// List files in stage
LIST @aws_stage_copy;


//Load data using copy command
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    SIZE_LIMIT=20000; -- 20000 = 20 MB which is the total size of the file to be loaded but first time gets loaded irrespective of size

COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    SIZE_LIMIT=60000; -- both the files gets loaded as the size is less 60mb in total for second file.
    

====================== Lec 37: Returned_Failed_Only  =======================================

---- RETURN_FAILED_ONLY ----



CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));

// Prepare stage object
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/returnfailed/';
  
LIST @COPY_DB.PUBLIC.aws_stage_copy;
  
    
 //Load data using copy command
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    RETURN_FAILED_ONLY = TRUE; -- gets Numeric value error while loading so skip it.
    
    
    
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    ON_ERROR =CONTINUE
    RETURN_FAILED_ONLY = TRUE; -- result shows total file loaded count along with file partially loaded
   


// Default = FALSE

CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));


COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    ON_ERROR =CONTINUE;

     -- Notes: RETURNED_FAILED_ONLY is used wiht ON_ERROR = CONTINUE condition.
     --        By Default RETURNED_FAILED_ONLY = FALSE even if we have not set anything.


====================== Lec38: TRUNCATECOLUMNS  =======================================
-- Notes:
-- • Specifies whether to truncate text strings that exceed the target column length
-- • TRUE = strings are automatically truncated to the target column length
-- • FALSE = COPY produces an error if a loaded string exceeds the target column length
-- • DEFAULT = FALSE



---- TRUNCATECOLUMNS ----



CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(10), -- in Subcategory few words exceeds the given limit of 10 for which we use TRUNCATECOLUMNS as example :                                   Electronis is more than 10 character but when TRUNCATECOLUMNS = TRUE the category gets loaded with                                  value of 10 characeter as Electroni
    SUBCATEGORY VARCHAR(30));

// Prepare stage object
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/size/';
  
LIST @COPY_DB.PUBLIC.aws_stage_copy;
  
    
 //Load data using copy command
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'; -- Error: User character length limit (10) exceeded by string 'Electronics' File 'size/Orders.csv'.


COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    TRUNCATECOLUMNS = true; 
    
    
SELECT * FROM ORDERS;

====================== Lec39: FORCE  =======================================

-- Note:
-- • Specifies to load all files, regardless of whether they've been loaded previously and have not changed since they were loaded.
-- • Note that this option reloads files, potentially duplicating data in a table.
-- • By DEFAULT it is set to FALSE.


---- FORCE ----



CREATE OR REPLACE TABLE  COPY_DB.PUBLIC.ORDERS (
    ORDER_ID VARCHAR(30),
    AMOUNT VARCHAR(30),
    PROFIT INT,
    QUANTITY INT,
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30));

// Prepare stage object
CREATE OR REPLACE STAGE COPY_DB.PUBLIC.aws_stage_copy
    url='s3://snowflakebucket-copyoption/size/';
  
LIST @COPY_DB.PUBLIC.aws_stage_copy;
  
    
 //Load data using copy command
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*';

// Not possible to load file that have been loaded and data has not been modified
COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'; -- Output: Copy executed with 0 files processed. But still we want to load then we proceed futhur because this leads to DUPLICATE.
   

SELECT * FROM ORDERS;    


// Using the FORCE option

COPY INTO COPY_DB.PUBLIC.ORDERS
    FROM @aws_stage_copy
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*Order.*'
    FORCE = TRUE;
    


====================== Lec40: Load History  =======================================
-- Note: 
-- ~ Enables you to retrieve the history of data loaded into tables using the COPY INTO < table> command.


-- Query load history within a database --

USE COPY_DB;

SELECT * FROM information_schema.load_history
















-- Query load history gloabally from SNOWFLAKE database --


SELECT * FROM snowflake.account_usage.load_history


// Filter on specific table & schema
SELECT * FROM snowflake.account_usage.load_history
  where schema_name='PUBLIC' and
  table_name='ORDERS'
  
  
// Filter on specific table & schema
SELECT * FROM snowflake.account_usage.load_history
  where schema_name='PUBLIC' and
  table_name='ORDERS' and
  error_count > 0
  
  
// Filter on specific table & schema
SELECT * FROM snowflake.account_usage.load_history
WHERE DATE(LAST_LOAD_TIME) <= DATEADD(days,-1,CURRENT_DATE)


====================== Lec43: Loading Unstructured Data- Creating stage and  RAW file =======================================
// First step: Load Raw JSON

CREATE OR REPLACE stage MANAGE_DB.EXTERNAL_STAGES.JSONSTAGE
     url='s3://bucketsnowflake-jsondemo';

CREATE OR REPLACE file format MANAGE_DB.FILE_FORMATS.JSONFORMAT
    TYPE = JSON;
    
    
CREATE OR REPLACE table OUR_FIRST_DB.PUBLIC.JSON_RAW (
    raw_file variant);
    
COPY INTO OUR_FIRST_DB.PUBLIC.JSON_RAW
    FROM @MANAGE_DB.EXTERNAL_STAGES.JSONSTAGE
    file_format= MANAGE_DB.FILE_FORMATS.JSONFORMAT
    files = ('HR_data.json');  --- Incase of JSON we use BRACKET for file name.
    
   
SELECT * FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

====================== Lec44: Parsing JSON =======================================
// Second step: Parse & Analyse Raw JSON 

   // Selecting attribute/column

SELECT RAW_FILE:city FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

SELECT $1:city FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


   // Selecting attribute/column - formattted

SELECT RAW_FILE:first_name::string as first_name  FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

SELECT RAW_FILE:id::int as id  FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

SELECT 
    RAW_FILE:id::int as id,  
    RAW_FILE:first_name::STRING as first_name,
    RAW_FILE:last_name::STRING as last_name,
    RAW_FILE:gender::STRING as gender

FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;



   // Handling nested data
   
SELECT RAW_FILE:job as job  FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

====================== Lec45: Handling Nested JSON Data  =======================================
   // Handling nested data
   
SELECT RAW_FILE:job as job  FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


SELECT 
      RAW_FILE:job.salary::INT as salary
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;



SELECT 
    RAW_FILE:first_name::STRING as first_name,
    RAW_FILE:job.salary::INT as salary,
    RAW_FILE:job.title::STRING as title
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


// Handling arreys

SELECT
    RAW_FILE:prev_company as prev_company
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

SELECT
    RAW_FILE:prev_company[1]::STRING as prev_company
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


SELECT
    ARRAY_SIZE(RAW_FILE:prev_company) as prev_company
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;




SELECT 
    RAW_FILE:id::int as id,  
    RAW_FILE:first_name::STRING as first_name,
    RAW_FILE:prev_company[0]::STRING as prev_company
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW
UNION ALL 
SELECT 
    RAW_FILE:id::int as id,  
    RAW_FILE:first_name::STRING as first_name,
    RAW_FILE:prev_company[1]::STRING as prev_company
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW
ORDER BY id


====================== Lec46 : Flatten Hierarchical Data  =======================================

SELECT 
    RAW_FILE:spoken_languages as spoken_languages
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;

SELECT * FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


SELECT 
     array_size(RAW_FILE:spoken_languages) as spoken_languages
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;  -- array_size is an aggregate function which will give total count.


SELECT 
     RAW_FILE:first_name::STRING as first_name,
     array_size(RAW_FILE:spoken_languages) as spoken_languages
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;



SELECT 
    RAW_FILE:spoken_languages[0] as First_language
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


SELECT 
    RAW_FILE:first_name::STRING as first_name,
    RAW_FILE:spoken_languages[0] as First_language
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;


SELECT 
    RAW_FILE:first_name::STRING as First_name,
    RAW_FILE:spoken_languages[0].language::STRING as First_language,
    RAW_FILE:spoken_languages[0].level::STRING as Level_spoken
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW;




SELECT 
    RAW_FILE:id::int as id,
    RAW_FILE:first_name::STRING as First_name,
    RAW_FILE:spoken_languages[0].language::STRING as First_language,
    RAW_FILE:spoken_languages[0].level::STRING as Level_spoken
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW
UNION ALL 
SELECT 
    RAW_FILE:id::int as id,
    RAW_FILE:first_name::STRING as First_name,
    RAW_FILE:spoken_languages[1].language::STRING as First_language,
    RAW_FILE:spoken_languages[1].level::STRING as Level_spoken
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW
UNION ALL 
SELECT 
    RAW_FILE:id::int as id,
    RAW_FILE:first_name::STRING as First_name,
    RAW_FILE:spoken_languages[2].language::STRING as First_language,
    RAW_FILE:spoken_languages[2].level::STRING as Level_spoken
FROM OUR_FIRST_DB.PUBLIC.JSON_RAW
ORDER BY ID;




select
      RAW_FILE:first_name::STRING as First_name,
    f.value:language::STRING as First_language,         -- value is a keyword used with table(flatten)
   f.value:level::STRING as Level_spoken
from OUR_FIRST_DB.PUBLIC.JSON_RAW, table(flatten(RAW_FILE:spoken_languages)) f; 




====================== Lec47: Insert FINAL JSON data  =======================================
USE DATABASE EXERCISE_DB;

// Option 1: CREATE TABLE AS

CREATE OR REPLACE TABLE Languages AS
select
      RAW_FILE:first_name::STRING as First_name,
    f.value:language::STRING as First_language,
   f.value:level::STRING as Level_spoken
from OUR_FIRST_DB.PUBLIC.JSON_RAW, table(flatten(RAW_FILE:spoken_languages)) f;

SELECT * FROM Languages;

truncate table languages;

// Option 2: INSERT INTO

INSERT INTO Languages
select
      RAW_FILE:first_name::STRING as First_name,
    f.value:language::STRING as First_language,
   f.value:level::STRING as Level_spoken
from OUR_FIRST_DB.PUBLIC.JSON_RAW, table(flatten(RAW_FILE:spoken_languages)) f;


SELECT * FROM Languages;

====================== Lec48: Querying PARQUET data  =======================================

    // Create file format and stage object
    
CREATE OR REPLACE FILE FORMAT MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT
    TYPE = 'parquet';

CREATE OR REPLACE STAGE MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
    url = 's3://snowflakeparquetdemo'   
    FILE_FORMAT = MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT;
    
    
    // Preview the data
    
LIST  @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE;   
    
SELECT * FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE;
    


// File format in Queries

CREATE OR REPLACE STAGE MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
    url = 's3://snowflakeparquetdemo';  
    
SELECT * 
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
(file_format => 'MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT');

// Quotes can be omitted in case of the current namespace
USE MANAGE_DB.FILE_FORMATS;

SELECT * 
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
(file_format => MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT);


CREATE OR REPLACE STAGE MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
    url = 's3://snowflakeparquetdemo'   
    FILE_FORMAT = MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT;

SELECT * 
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE
(file_format => MANAGE_DB.FILE_FORMATS.PARQUET_FORMAT);

    // Syntax for Querying unstructured data

SELECT 
$1:__index_level_0__,
$1:cat_id,
$1:date,
$1:"__index_level_0__",
$1:"cat_id",
$1:"d",
$1:"date",
$1:"dept_id",
$1:"id",
$1:"item_id",
$1:"state_id",
$1:"store_id",
$1:"value"
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE;


    // Date conversion
    
SELECT 1;

SELECT DATE(1);

SELECT DATE(365*60*60*24);

-- 1338422400000000 is in second so we convert to date using SELECT DATE(365*60*60*24);


    // Querying with conversions and aliases
    
SELECT 
$1:__index_level_0__::int as index_level,
$1:cat_id::VARCHAR(50) as category,
DATE($1:date::int ) as Date,  
$1:"dept_id"::VARCHAR(50) as Dept_ID,
$1:"id"::VARCHAR(50) as ID,
$1:"item_id"::VARCHAR(50) as Item_ID,
$1:"state_id"::VARCHAR(50) as State_ID,
$1:"store_id"::VARCHAR(50) as Store_ID,
$1:"value"::int as value
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE;


====================== Lec49: Loading Parquet Data  =======================================

    // Adding metadata
    
SELECT 
$1:__index_level_0__::int as index_level,
$1:cat_id::VARCHAR(50) as category,
DATE($1:date::int ) as Date,
$1:"dept_id"::VARCHAR(50) as Dept_ID,
$1:"id"::VARCHAR(50) as ID,
$1:"item_id"::VARCHAR(50) as Item_ID,
$1:"state_id"::VARCHAR(50) as State_ID,
$1:"store_id"::VARCHAR(50) as Store_ID,
$1:"value"::int as value,
METADATA$FILENAME as FILENAME,
METADATA$FILE_ROW_NUMBER as ROWNUMBER,
TO_TIMESTAMP_NTZ(current_timestamp) as LOAD_DATE
FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE;


SELECT TO_TIMESTAMP_NTZ(current_timestamp);
SELECT TO_TIMESTAMP(current_timestamp);



   // Create destination table

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.PARQUET_DATA (
    ROW_NUMBER int,
    index_level int,
    cat_id VARCHAR(50),
    date date,
    dept_id VARCHAR(50),
    id VARCHAR(50),
    item_id VARCHAR(50),
    state_id VARCHAR(50),
    store_id VARCHAR(50),
    value int,
    Load_date timestamp default TO_TIMESTAMP_NTZ(current_timestamp));


   // Load the parquet data
   
COPY INTO OUR_FIRST_DB.PUBLIC.PARQUET_DATA
    FROM (SELECT 
            METADATA$FILE_ROW_NUMBER,
            $1:__index_level_0__::int,
            $1:cat_id::VARCHAR(50),
            DATE($1:date::int ),
            $1:"dept_id"::VARCHAR(50),
            $1:"id"::VARCHAR(50),
            $1:"item_id"::VARCHAR(50),
            $1:"state_id"::VARCHAR(50),
            $1:"store_id"::VARCHAR(50),
            $1:"value"::int,
            TO_TIMESTAMP_NTZ(current_timestamp)
        FROM @MANAGE_DB.EXTERNAL_STAGES.PARQUETSTAGE);
        
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.PARQUET_DATA;

====================== Lec52: Implement dedicated virtual warehouse  =======================================
//  Create virtual warehouse for data scientist & DBA

// Data Scientists
CREATE WAREHOUSE DS_WH 
WITH 
    WAREHOUSE_SIZE = 'SMALL'
    WAREHOUSE_TYPE = 'STANDARD' 
    AUTO_SUSPEND = 300 
    AUTO_RESUME = TRUE 
    MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 1 
    SCALING_POLICY = 'STANDARD';

// DBA
CREATE WAREHOUSE DBA_WH 
WITH 
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD' 
    AUTO_SUSPEND = 300 
    AUTO_RESUME = TRUE 
    MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 1 
    SCALING_POLICY = 'STANDARD';




// Create role for Data Scientists & DBAs

CREATE ROLE DATA_SCIENTIST;
GRANT USAGE ON WAREHOUSE DS_WH TO ROLE DATA_SCIENTIST;

CREATE ROLE DBA;
GRANT USAGE ON WAREHOUSE DBA_WH TO ROLE DBA;


// Setting up users with roles

// Data Scientists
CREATE USER DS1 PASSWORD = 'DS1' LOGIN_NAME = 'DS1' DEFAULT_ROLE='DATA_SCIENTIST' DEFAULT_WAREHOUSE = 'DS_WH'  MUST_CHANGE_PASSWORD = FALSE;
CREATE USER DS2 PASSWORD = 'DS2' LOGIN_NAME = 'DS2' DEFAULT_ROLE='DATA_SCIENTIST' DEFAULT_WAREHOUSE = 'DS_WH'  MUST_CHANGE_PASSWORD = FALSE;
CREATE USER DS3 PASSWORD = 'DS3' LOGIN_NAME = 'DS3' DEFAULT_ROLE='DATA_SCIENTIST' DEFAULT_WAREHOUSE = 'DS_WH'  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE DATA_SCIENTIST TO USER DS1;
GRANT ROLE DATA_SCIENTIST TO USER DS2;
GRANT ROLE DATA_SCIENTIST TO USER DS3;

// DBAs
CREATE USER DBA1 PASSWORD = 'DBA1' LOGIN_NAME = 'DBA1' DEFAULT_ROLE='DBA' DEFAULT_WAREHOUSE = 'DBA_WH'  MUST_CHANGE_PASSWORD = FALSE;
CREATE USER DBA2 PASSWORD = 'DBA2' LOGIN_NAME = 'DBA2' DEFAULT_ROLE='DBA' DEFAULT_WAREHOUSE = 'DBA_WH'  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE DBA TO USER DBA1;
GRANT ROLE DBA TO USER DBA2;

// Drop objects again

DROP USER DBA1;
DROP USER DBA2;

DROP USER DS1;
DROP USER DS2;
DROP USER DS3;

DROP ROLE DATA_SCIENTIST;
DROP ROLE DBA;

DROP WAREHOUSE DS_WH;
DROP WAREHOUSE DBA_WH;

====================== Lec53: Scaling UP or Down  =======================================
ALTER WAREHOUSE COMPUTE_WH
SET WAREHOUSE_SIZE = XSmall;


====================== Lec55: Scaling Out =======================================
-- Below Query is created 10 times and run on different tabs thinking they are different user and then under warehouse named FIRST_MULTICLUSTER_WH created as MULTI CLUSTER as enabled we can see the cluster has activated.

USE WAREHOUSE FIRST_MULTICLUSTER_WH;


SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.WEB_SITE T1
CROSS JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.WEB_SITE T2
CROSS JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.WEB_SITE T3
CROSS JOIN (SELECT TOP 57 * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.WEB_SITE)  T4;

====================== Lec56: Maximize Caching  =======================================
-- We should run similar queries on same Warehouses in order to achieve caching;

USE WAREHOUSE COMPUTE_WH;

SELECT AVG(C_BIRTH_YEAR) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER;

-- Run the above query again to see the caching under QUeryID which we can see the time is reduced as it used caching while running the same query.

SELECT AVG(C_BIRTH_YEAR) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER;



// Setting up an additional user
CREATE ROLE DATA_SCIENTIST;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DATA_SCIENTIST;

CREATE USER DS1 PASSWORD = 'DS1' LOGIN_NAME = 'DS1' DEFAULT_ROLE='DATA_SCIENTIST' DEFAULT_WAREHOUSE = 'DS_WH'  MUST_CHANGE_PASSWORD = FALSE;
GRANT ROLE DATA_SCIENTIST TO USER DS1;

-- Open in INCOGNITO mode in safari and then login with the role as DATA_SCIENTIST using same Warehouse as COMPUTE_WH then we can see the timing taken is very less as compared to original query timing. We can see that using QUERY_ID under output.


DROP ROLE DATA_SCIENTIST;
DROP USER DS1;
====================== Lec58: Clustering  =======================================
-- Maintained by Snowflake but manually also we can do it.
-- Depending on the user case we alter the CLUSTER_KEY based on WHERE clause OR JOIN function used frequently in our query.
-- Pruning concept is used here
-- Cluster_Key is not ideal for  distinct value
-- Cluster key is not very small value or very large value with distinct value but it should be in medium range.


// Publicly accessible staging area    

CREATE OR REPLACE STAGE MANAGE_DB.external_stages.aws_stage
    url='s3://bucketsnowflakes3';

// List files in stage

LIST @MANAGE_DB.external_stages.aws_stage;

//Load data using copy command

COPY INTO OUR_FIRST_DB.PUBLIC.ORDERS
    FROM @MANAGE_DB.external_stages.aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*OrderDetails.*';

-- Run the above query only when we don't have data under OUR_FIRST_DB.PUBLIC.ORDERS table.
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.ORDERS;

// Create table

CREATE OR REPLACE TABLE ORDERS_CACHING (
ORDER_ID	VARCHAR(30)
,AMOUNT	NUMBER(38,0)
,PROFIT	NUMBER(38,0)
,QUANTITY	NUMBER(38,0)
,CATEGORY	VARCHAR(30)
,SUBCATEGORY	VARCHAR(30)
,DATE DATE);    

-- Here we change the Warehouse size to for faster execution of query.

INSERT INTO ORDERS_CACHING 
SELECT
t1.ORDER_ID
,t1.AMOUNT	
,t1.PROFIT	
,t1.QUANTITY	
,t1.CATEGORY	
,t1.SUBCATEGORY	
,DATE(UNIFORM(1500000000,1700000000,(RANDOM())))
FROM ORDERS t1
CROSS JOIN (SELECT * FROM ORDERS) t2
CROSS JOIN (SELECT TOP 100 * FROM ORDERS) t3;


// Query Performance before Cluster Key

SELECT * FROM ORDERS_CACHING  WHERE DATE = '2020-06-09';


// Adding Cluster Key & Compare the result 
-- After adding cluster key depending on the size of data it take time from 30 min to 24hr. Once after that we can see the timing for query execution got reduced by clustering.

ALTER TABLE ORDERS_CACHING CLUSTER BY ( DATE ); 

SELECT * FROM ORDERS_CACHING  WHERE DATE = '2020-01-05';


// Not ideal clustering & adding a different Cluster Key using function

SELECT * FROM ORDERS_CACHING  WHERE MONTH(DATE)=11;

ALTER TABLE ORDERS_CACHING CLUSTER BY ( MONTH(DATE) );

SELECT * FROM ORDERS_CACHING  WHERE MONTH(DATE)=12;


======================   Lec 63: AWS_Creating Storage Integration  =======================================
// Create storage integration object

create or replace storage integration s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE 
  STORAGE_AWS_ROLE_ARN = ''
  STORAGE_ALLOWED_LOCATIONS = ('s3://<your-bucket-name>/<your-path>/', 's3://<your-bucket-name>/<your-path>/')
   COMMENT = 'This an optional comment' 
   
   
// See storage integration properties to fetch external_id so we can update it in S3
DESC integration s3_int;
====================== Lec64: AWS_Loading Data from S3  =======================================
// Create table first
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.movie_titles (
  show_id STRING,
  type STRING,
  title STRING,
  director STRING,
  cast STRING,
  country STRING,
  date_added STRING,
  release_year STRING,
  rating STRING,
  duration STRING,
  listed_in STRING,
  description STRING );
  
  

// Create file format object
CREATE OR REPLACE file format MANAGE_DB.file_formats.csv_fileformat
    type = csv
    field_delimiter = ','
    skip_header = 1
    null_if = ('NULL','null')
    empty_field_as_null = TRUE;
    
    
 // Create stage object with integration object & file format object
CREATE OR REPLACE stage MANAGE_DB.external_stages.csv_folder
    URL = 's3://<your-bucket-name>/<your-path>/'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = MANAGE_DB.file_formats.csv_fileformat;



// Use Copy command       
COPY INTO OUR_FIRST_DB.PUBLIC.movie_titles
    FROM @MANAGE_DB.external_stages.csv_folder;
    
    
    
    
    
// Create file format object
CREATE OR REPLACE file format MANAGE_DB.file_formats.csv_fileformat
    type = csv
    field_delimiter = ','
    skip_header = 1
    null_if = ('NULL','null')
    empty_field_as_null = TRUE    
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'; 
    
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.movie_titles;
    

====================== Lec65: AWS_ handling JSON  =======================================
// Taming the JSON file

// First query from S3 Bucket   

SELECT * FROM @MANAGE_DB.external_stages.json_folder



// Introduce columns 
SELECT 
$1:asin,
$1:helpful,
$1:overall,
$1:reviewText,
$1:reviewTime,
$1:reviewerID,
$1:reviewTime,
$1:reviewerName,
$1:summary,
$1:unixReviewTime
FROM @MANAGE_DB.external_stages.json_folder

// Format columns & use DATE function
SELECT 
$1:asin::STRING as ASIN,
$1:helpful as helpful,
$1:overall as overall,
$1:reviewText::STRING as reviewtext,
$1:reviewTime::STRING,
$1:reviewerID::STRING,
$1:reviewTime::STRING,
$1:reviewerName::STRING,
$1:summary::STRING,
DATE($1:unixReviewTime::int) as Revewtime
FROM @MANAGE_DB.external_stages.json_folder

// Format columns & handle custom date 
SELECT 
$1:asin::STRING as ASIN,
$1:helpful as helpful,
$1:overall as overall,
$1:reviewText::STRING as reviewtext,
DATE_FROM_PARTS( <year>, <month>, <day> )
$1:reviewTime::STRING,
$1:reviewerID::STRING,
$1:reviewTime::STRING,
$1:reviewerName::STRING,
$1:summary::STRING,
DATE($1:unixReviewTime::int) as Revewtime
FROM @MANAGE_DB.external_stages.json_folder

// Use DATE_FROM_PARTS and see another difficulty
SELECT 
$1:asin::STRING as ASIN,
$1:helpful as helpful,
$1:overall as overall,
$1:reviewText::STRING as reviewtext,
DATE_FROM_PARTS( RIGHT($1:reviewTime::STRING,4), LEFT($1:reviewTime::STRING,2), SUBSTRING($1:reviewTime::STRING,4,2) ),
$1:reviewerID::STRING,
$1:reviewTime::STRING,
$1:reviewerName::STRING,
$1:summary::STRING,
DATE($1:unixReviewTime::int) as unixRevewtime
FROM @MANAGE_DB.external_stages.json_folder


// Use DATE_FROM_PARTS and handle the case difficulty
SELECT 
$1:asin::STRING as ASIN,
$1:helpful as helpful,
$1:overall as overall,
$1:reviewText::STRING as reviewtext,
DATE_FROM_PARTS( 
  RIGHT($1:reviewTime::STRING,4), 
  LEFT($1:reviewTime::STRING,2), 
  CASE WHEN SUBSTRING($1:reviewTime::STRING,5,1)=',' 
        THEN SUBSTRING($1:reviewTime::STRING,4,1) ELSE SUBSTRING($1:reviewTime::STRING,4,2) END),
$1:reviewerID::STRING,
$1:reviewTime::STRING,
$1:reviewerName::STRING,
$1:summary::STRING,
DATE($1:unixReviewTime::int) as UnixRevewtime
FROM @MANAGE_DB.external_stages.json_folder


// Create destination table
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.reviews (
asin STRING,
helpful STRING,
overall STRING,
reviewtext STRING,
reviewtime DATE,
reviewerid STRING,
reviewername STRING,
summary STRING,
unixreviewtime DATE
)

// Copy transformed data into destination table
COPY INTO OUR_FIRST_DB.PUBLIC.reviews
    FROM (SELECT 
$1:asin::STRING as ASIN,
$1:helpful as helpful,
$1:overall as overall,
$1:reviewText::STRING as reviewtext,
DATE_FROM_PARTS( 
  RIGHT($1:reviewTime::STRING,4), 
  LEFT($1:reviewTime::STRING,2), 
  CASE WHEN SUBSTRING($1:reviewTime::STRING,5,1)=',' 
        THEN SUBSTRING($1:reviewTime::STRING,4,1) ELSE SUBSTRING($1:reviewTime::STRING,4,2) END),
$1:reviewerID::STRING,
$1:reviewerName::STRING,
$1:summary::STRING,
DATE($1:unixReviewTime::int) Revewtime
FROM @MANAGE_DB.external_stages.json_folder)
   
    
// Validate results
SELECT * FROM OUR_FIRST_DB.PUBLIC.reviews   

====================== Lec 81: Snowpipe_Creating Stage and Pipe from AWS  =======================================
// Create table first
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.employees (
  id INT,
  first_name STRING,
  last_name STRING,
  email STRING,
  location STRING,
  department STRING
  )
    

// Create file format object
CREATE OR REPLACE file format MANAGE_DB.file_formats.csv_fileformat
    type = csv
    field_delimiter = ','
    skip_header = 1
    null_if = ('NULL','null')
    empty_field_as_null = TRUE;
    
    
 // Create stage object with integration object & file format object
CREATE OR REPLACE stage MANAGE_DB.external_stages.csv_folder
    URL = 's3://snowflakes3bucket123/csv/snowpipe'
    STORAGE_INTEGRATION = s3_int
    FILE_FORMAT = MANAGE_DB.file_formats.csv_fileformat
   

 // Create stage object with integration object & file format object
LIST @MANAGE_DB.external_stages.csv_folder  


// Create schema to keep things organized
CREATE OR REPLACE SCHEMA MANAGE_DB.pipes

// Define pipe
CREATE OR REPLACE pipe MANAGE_DB.pipes.employee_pipe
auto_ingest = TRUE
AS
COPY INTO OUR_FIRST_DB.PUBLIC.employees
FROM @MANAGE_DB.external_stages.csv_folder  

// Describe pipe
DESC pipe employee_pipe
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.employees    

====================== Lec 82: Snowpipe_Creating Pipe  =======================================
// Define pipe
CREATE OR REPLACE pipe MANAGE_DB.pipes.employee_pipe
auto_ingest = TRUE
AS
COPY INTO OUR_FIRST_DB.PUBLIC.employees
FROM @MANAGE_DB.external_stages.csv_folder  

// Describe pipe
DESC pipe employee_pipe
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.employees   

====================== Lec84:Error Handling for Snowpipe load  =======================================
// Handling errors


// Create file format object
CREATE OR REPLACE file format MANAGE_DB.file_formats.csv_fileformat
    type = csv
    field_delimiter = ','
    skip_header = 1
    null_if = ('NULL','null')
    empty_field_as_null = TRUE;
    
SELECT * FROM OUR_FIRST_DB.PUBLIC.employees   

ALTER PIPE employee_pipe refresh
 
// Validate pipe is actually working
SELECT SYSTEM$PIPE_STATUS('employee_pipe')

// Snowpipe error message
SELECT * FROM TABLE(VALIDATE_PIPE_LOAD(
    PIPE_NAME => 'MANAGE_DB.pipes.employee_pipe',
    START_TIME => DATEADD(HOUR,-2,CURRENT_TIMESTAMP())))

// COPY command history from table to see error massage

SELECT * FROM TABLE (INFORMATION_SCHEMA.COPY_HISTORY(
   table_name  =>  'OUR_FIRST_DB.PUBLIC.EMPLOYEES',
   START_TIME =>DATEADD(HOUR,-2,CURRENT_TIMESTAMP())))

====================== Lec 85: Snowpipe_Manage Pipe  =======================================
-- Manage pipes -- 

DESC pipe MANAGE_DB.pipes.employee_pipe;

SHOW PIPES;

SHOW PIPES like '%employee%'

SHOW PIPES in database MANAGE_DB

SHOW PIPES in schema MANAGE_DB.pipes

SHOW PIPES like '%employee%' in Database MANAGE_DB



-- Changing pipe (alter stage or file format) --

// Preparation table first
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.employees2 (
  id INT,
  first_name STRING,
  last_name STRING,
  email STRING,
  location STRING,
  department STRING
  )


// Pause pipe
ALTER PIPE MANAGE_DB.pipes.employee_pipe SET PIPE_EXECUTION_PAUSED = true
 
 
// Verify pipe is paused and has pendingFileCount 0 
SELECT SYSTEM$PIPE_STATUS('MANAGE_DB.pipes.employee_pipe') 
 
 // Recreate the pipe to change the COPY statement in the definition
CREATE OR REPLACE pipe MANAGE_DB.pipes.employee_pipe
auto_ingest = TRUE
AS
COPY INTO OUR_FIRST_DB.PUBLIC.employees2
FROM @MANAGE_DB.external_stages.csv_folder  

ALTER PIPE  MANAGE_DB.pipes.employee_pipe refresh

// List files in stage
LIST @MANAGE_DB.external_stages.csv_folder  

SELECT * FROM OUR_FIRST_DB.PUBLIC.employees2

 // Reload files manually that where aleady in the bucket
COPY INTO OUR_FIRST_DB.PUBLIC.employees2
FROM @MANAGE_DB.external_stages.csv_folder  


// Resume pipe
ALTER PIPE MANAGE_DB.pipes.employee_pipe SET PIPE_EXECUTION_PAUSED = false

// Verify pipe is running again
SELECT SYSTEM$PIPE_STATUS('MANAGE_DB.pipes.employee_pipe') 


====================== Lec 90: TimeTravel  =======================================
-- Data Protection LIFECYCLE

-- Current Data Storage : Access and Query data etc..
-- SELECT * FROM table;

-- Drop dabase or table accidentally?
-- DROP DATABASE prod_db;

-- Truncate or update table accidentally?
-- TRUNCATE TABLE prod_table;

-- Time Travel enables accessing historical data.

-- Time Travel:

-- What is possible with Time Travel?
-- - Query deleted or updated data
-- - Restore tables, schemas and databases that have been dropped
-- - Create clones of tables, schemas and and databases from previous state


--                 Time Travel SQL
-- Query historic data within retention period.

-- 1. TIMESTAMP:
-- SELECT * FROM table AT (TIMESTAMP => timestamp)

-- 2. OFFSET:
-- SELECT * FROM table AT (OFFSET => -10×60)

-- 3. QUERY:
-- SELECT * FROM table BEFORE (STATEMENT => query_id)

--                 Time Travel SQL
-- Recover objects that have been dropped within retention period.
-- 1. Table:
-- UNDROP TABLE table_name;

-- 2. Schema:
-- UNDROP SCHEMA schema_name;

-- 3. Database:
-- UNDROP DATABASE database_name;

-- Considerations
-- 1. UNDROP fails if an object with the same name already exists.
-- 2. OWNERSHIP privileges are needed for an object to be restored.

====================== Lec91: Using TimeTravel  =======================================
// Setting up table

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
    


CREATE OR REPLACE FILE FORMAT MANAGE_DB.file_formats.csv_file
    type = csv
    field_delimiter = ','
    skip_header = 1;
    
CREATE OR REPLACE STAGE MANAGE_DB.external_stages.time_travel_stage
    URL = 's3://data-snowflake-fundamentals/time-travel/'
    file_format = MANAGE_DB.file_formats.csv_file;
    


LIST @MANAGE_DB.external_stages.time_travel_stage;



COPY INTO OUR_FIRST_DB.public.test
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');


SELECT * FROM OUR_FIRST_DB.public.test;

// Use-case: Update data (by mistake)

UPDATE OUR_FIRST_DB.public.test
SET FIRST_NAME = 'Joyen'; 



// // // Using time travel: Method 1 - 2 minutes back
SELECT * FROM OUR_FIRST_DB.public.test AT (OFFSET => -60*1.5);  -- where-means going back in time in seconds we need to put always 1.5 minute = 1.5*60;








// // // Using time travel: Method 2 - before timestamp
SELECT * FROM OUR_FIRST_DB.public.test before (timestamp => '2026-04-15 08:41:42.662 +0000'::timestamp);


-- Setting up table
CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);

COPY INTO OUR_FIRST_DB.public.test
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');


SELECT * FROM OUR_FIRST_DB.public.test;

2026-04-15 08:41:42.662 +0000;

-- Setting up UTC time for convenience

ALTER SESSION SET TIMEZONE ='UTC';
SELECT DATEADD(DAY, 0, CURRENT_TIMESTAMP); -- 2026-04-15 08:41:42.662 +0000;


UPDATE OUR_FIRST_DB.public.test
SET Job = 'Data Scientist';


SELECT * FROM OUR_FIRST_DB.public.test;

SELECT * FROM OUR_FIRST_DB.public.test before (timestamp => '2026-04-15 08:41:42.662 +0000'::timestamp);








// // // Using time travel: Method 3 - before Query ID

// Preparing table
CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Phone string,
  Job string);

COPY INTO OUR_FIRST_DB.public.test
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');


SELECT * FROM OUR_FIRST_DB.public.test;


// Altering table (by mistake)
UPDATE OUR_FIRST_DB.public.test
SET EMAIL = null;



SELECT * FROM OUR_FIRST_DB.public.test;

SELECT * FROM OUR_FIRST_DB.public.test before (statement => '01c3b8cd-3202-966e-0016-32ae0005396e');




====================== Lec 92: TimeTravel_ Restoring Data  =======================================
// Setting up table

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
    

COPY INTO OUR_FIRST_DB.public.test
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');

SELECT * FROM OUR_FIRST_DB.public.test;

// Use-case: Update data (by mistake)


UPDATE OUR_FIRST_DB.public.test
SET LAST_NAME = 'Tyson';


UPDATE OUR_FIRST_DB.public.test
SET JOB = 'Data Analyst';

SELECT * FROM OUR_FIRST_DB.public.test;

SELECT * FROM OUR_FIRST_DB.public.test before (statement => '01c3b8ef-3202-966e-0016-32ae00054122');



// // // Bad method

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test as
SELECT * FROM OUR_FIRST_DB.public.test before (statement => '01c3b8eb-3202-966e-0016-32ae0005408e');


SELECT * FROM OUR_FIRST_DB.public.test;


CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test as
SELECT * FROM OUR_FIRST_DB.public.test before (statement => '01c3b8eb-3202-966e-0016-32ae0005408e'); -- Error: Time travel data is not available for table TEST. The requested time is either beyond the allowed time travel period or before the object creation time.





// // // Good method - Create Backup table and then Truncate the original table.

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.test_backup as
SELECT * FROM OUR_FIRST_DB.public.test before (statement => '01c3b8ef-3202-966e-0016-32ae0005411a');

TRUNCATE OUR_FIRST_DB.public.test;

INSERT INTO OUR_FIRST_DB.public.test
SELECT * FROM OUR_FIRST_DB.public.test_backup;



SELECT * FROM OUR_FIRST_DB.public.test;

====================== Lec 93: TimeTravel_Undrop Table  =======================================
           
// Setting up table

CREATE OR REPLACE STAGE MANAGE_DB.external_stages.time_travel_stage
    URL = 's3://data-snowflake-fundamentals/time-travel/'
    file_format = MANAGE_DB.file_formats.csv_file;
    

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
    

COPY INTO OUR_FIRST_DB.public.customers
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');

SELECT * FROM OUR_FIRST_DB.public.customers;


// UNDROP command - Tables

DROP TABLE OUR_FIRST_DB.public.customers;

SELECT * FROM OUR_FIRST_DB.public.customers;

UNDROP TABLE OUR_FIRST_DB.public.customers;


// UNDROP command - Schemas

DROP SCHEMA OUR_FIRST_DB.public;

SELECT * FROM OUR_FIRST_DB.public.customers;

UNDROP SCHEMA OUR_FIRST_DB.public;


// UNDROP command - Database

DROP DATABASE OUR_FIRST_DB;

SELECT * FROM OUR_FIRST_DB.public.customers;

UNDROP DATABASE OUR_FIRST_DB;





// Restore replaced table 


UPDATE OUR_FIRST_DB.public.customers
SET LAST_NAME = 'Tyson';


UPDATE OUR_FIRST_DB.public.customers
SET JOB = 'Data Analyst';



// // // Undroping a with a name that already exists

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.customers as
SELECT * FROM OUR_FIRST_DB.public.customers before (statement => '01c3b903-3202-966e-0016-32ae00054506');


SELECT * FROM OUR_FIRST_DB.public.customers;

UNDROP table OUR_FIRST_DB.public.customers; -- SQL compilation error: Object 'CUSTOMERS' already exists.

ALTER TABLE OUR_FIRST_DB.public.customers
RENAME TO OUR_FIRST_DB.public.customers_wrong;

UNDROP table OUR_FIRST_DB.public.customers;

SELECT * FROM OUR_FIRST_DB.public.customers;

DESC table OUR_FIRST_DB.public.customers;
    

====================== Lec 94: Retention Time  =======================================
-- Time Travel
-- 1. Standard: Time travel up to 1 day.
-- 2. Enterprise: Time travel up to 90 days
-- 3. Business Critical: Time travel up to 90 days
-- 4. Virtual Private: Time travel up to 90 days

-- RETENTION PERIOD : DEFAULT = 1




USE DATABASE OUR_FIRST_DB;

SHOW TABLES Like '%custom%'; --> We get a column called 'retention_time'
SELECT * FROM OUR_FIRST_DB. PUBLIC. CUSTOMERS;

ALTER TABLE OUR_FIRST_DB. PUBLIC. CUSTOMERS
SET DATA_RETENTION_TIME_IN_DAYS = 2; --> We get a column called 'retention_time' which gets updated to 2.

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.ret_example (
id int,
first_name string,
last_name string,
email string,
gender string,
Job string,
Phone string)
DATA_RETENTION_TIME_IN_DAYS = 3;

SHOW TABLES Like '%EX%';

DROP TABLE OUR_FIRST_DB.public.ret_example;
UNDROP TABLE OUR_FIRST_DB.public.ret_example;

ALTER TABLE OUR_FIRST_DB.public.ret_example
SET DATA_RETENTION_TIME_IN_DAYS = 0;

DROP Table OUR_FIRST_DB.public.ret_example;
UNDROP Table OUR_FIRST_DB.public.ret_example; --> Error: Table RET_EXAMPLE did not exist or was purged. as RETENTION_TIME is set to 0 in this case.


====================== Lec 95: Time Travel Cost  =======================================
-- Time Travel cost is majorly due to Storage cost apart from warehouse,etc...

USE ROLE ACCOUNTADMIN;

SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE ORDER BY USAGE_DATE DESC;


SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS;

// Query time travel storage
SELECT 	ID, 
		TABLE_NAME, 
		TABLE_SCHEMA,
        TABLE_CATALOG,
		ACTIVE_BYTES / (1024*1024*1024) AS STORAGE_USED_GB,
		TIME_TRAVEL_BYTES / (1024*1024*1024) AS TIME_TRAVEL_STORAGE_USED_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
ORDER BY STORAGE_USED_GB DESC,TIME_TRAVEL_STORAGE_USED_GB DESC;

====================== Lec 96: Understanding Fail Safe  =======================================
--         Fail Safe
-- • Protection of historical data in case of disaster
-- • Non-configurable 7-day period for permanent tables
-- / Period starts immediately after Time Travel period ends
-- • No user interaction & recoverable only by Snowflake
-- • Contributes to storage cost


--     =============Continuous Dato Protection Lifecycle =========
-- • 0 - 90 days retention time
-- • SELECT ... AT | BEFORE


-- Time Travel
-- • UNGROP

-- Current Data Storage
-- • Access and query data etc.

Fail Safe (transient: 0 days permanent: 7 days)
• No user operations/queries
• Recovery beyond Time Travel
• Restoring only by snowflake support



====================== Lec 97: Fail Safe Storage =======================================
-- We can also do this using Snowflake UI under Admin Section.


// Storage usage on account level

SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE ORDER BY USAGE_DATE DESC;


// Storage usage on account level formatted

SELECT 	USAGE_DATE, 
		STORAGE_BYTES / (1024*1024*1024) AS STORAGE_GB,  
		STAGE_BYTES / (1024*1024*1024) AS STAGE_GB,
		FAILSAFE_BYTES / (1024*1024*1024) AS FAILSAFE_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE ORDER BY USAGE_DATE DESC;


// Storage usage on table level

SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS;


// Storage usage on table level formatted

SELECT 	ID, 
		TABLE_NAME, 
		TABLE_SCHEMA,
		ACTIVE_BYTES / (1024*1024*1024) AS STORAGE_USED_GB,
		TIME_TRAVEL_BYTES / (1024*1024*1024) AS TIME_TRAVEL_STORAGE_USED_GB,
		FAILSAFE_BYTES / (1024*1024*1024) AS FAILSAFE_STORAGE_USED_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
ORDER BY FAILSAFE_STORAGE_USED_GB DESC;


-------------------------------

-- Question 1:
-- The ACCOUNTADMIN is the only role that can restore data from the Fail Safe zone. True or False?
-- FALSE

-- Question 2:
-- The default value for the retention period for permanent table is set to...
-- 7 days for permanent table
-- 0 days for temporary table

-- Question 3:
-- We can change the retention period for fail safe from 7 days to 1 day. True or false?
-- False

-- Question 4:
-- If time travel is set to 0 days for a permanent table. The table will immediately enter Fail Safe period. True or false?
-- True


-- For Fail Safe we always  to reach out Snowflake team for help as we can't do it from our end & is majorly used for Disaster Recovery.


====================== Lec 98: Different table types =======================================
--                         Table types

-- Permanent
-- Until dropped
-- CREATE TABLE
-- ✔️ Time Travel Retention Period
-- ✔️Fail Safe

-- Transient
-- Until dropped
-- CREATE TRANSIENT TABLE
-- ✔️Time Travel Retention Period
-- × Fail Safe

-- Temporary
-- Only in session
-- CREATE TEMPORARY TABLE
-- ✔️Time Travel Retention Period
-- × Fail Safe

====================== Lec 99: Permanent tables & database  =======================================
CREATE OR REPLACE DATABASE PDB;

CREATE OR REPLACE TABLE PDB.public.customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
  
CREATE OR REPLACE TABLE PDB.public.helper (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
    
// Stage and file format
CREATE OR REPLACE FILE FORMAT MANAGE_DB.file_formats.csv_file
    type = csv
    field_delimiter = ','
    skip_header = 1;
    
CREATE OR REPLACE STAGE MANAGE_DB.external_stages.time_travel_stage
    URL = 's3://data-snowflake-fundamentals/time-travel/'
    file_format = MANAGE_DB.file_formats.csv_file;
    
LIST  @MANAGE_DB.external_stages.time_travel_stage;


// Copy data and insert in table
COPY INTO PDB.public.helper
FROM @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');




SELECT * FROM PDB.public.helper;

INSERT INTO PDB.public.customers
SELECT
t1.ID
,t1.FIRST_NAME	
,t1.LAST_NAME	
,t1.EMAIL	
,t1.GENDER	
,t1.JOB
,t1.PHONE
 FROM PDB.public.helper t1
CROSS JOIN (SELECT * FROM PDB.public.helper) t2
CROSS JOIN (SELECT TOP 100 * FROM PDB.public.helper) t3;




// Show table and validate
SHOW TABLES;







// Permanent tables

USE OUR_FIRST_DB;

CREATE OR REPLACE TABLE customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
  
CREATE OR REPLACE DATABASE PDB;

SHOW DATABASES;

USE DATABASE OUR_FIRST_DB;

SHOW TABLES;



// View table metrics (takes a bit to appear)
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS;


SELECT 	ID, 
       	TABLE_NAME, 
		TABLE_SCHEMA,
        TABLE_CATALOG,
		ACTIVE_BYTES / (1024*1024*1024) AS ACTIVE_STORAGE_USED_GB,
		TIME_TRAVEL_BYTES / (1024*1024*1024) AS TIME_TRAVEL_STORAGE_USED_GB,
		FAILSAFE_BYTES / (1024*1024*1024) AS FAILSAFE_STORAGE_USED_GB,
        IS_TRANSIENT,
        DELETED,
        TABLE_CREATED,
        TABLE_DROPPED,
        TABLE_ENTERED_FAILSAFE
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
--WHERE TABLE_CATALOG ='PDB'
WHERE TABLE_DROPPED is not null
ORDER BY FAILSAFE_BYTES DESC;


====================== Lec 100: Transient Table & schema  =======================================
CREATE OR REPLACE DATABASE TDB;

CREATE OR REPLACE TRANSIENT TABLE TDB.public.customers_transient (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);

INSERT INTO TDB.public.customers_transient
SELECT t1.* FROM OUR_FIRST_DB.public.customers t1
CROSS JOIN (SELECT * FROM OUR_FIRST_DB.public.customers) t2;

SHOW TABLES;



// Query storage

SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS;


SELECT 	ID, 
       	TABLE_NAME, 
		TABLE_SCHEMA,
        TABLE_CATALOG,
		ACTIVE_BYTES,
		TIME_TRAVEL_BYTES / (1024*1024*1024) AS TIME_TRAVEL_STORAGE_USED_GB,
		FAILSAFE_BYTES / (1024*1024*1024) AS FAILSAFE_STORAGE_USED_GB,
        IS_TRANSIENT,
        DELETED,
        TABLE_CREATED,
        TABLE_DROPPED,
        TABLE_ENTERED_FAILSAFE
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE TABLE_CATALOG ='TDB'
ORDER BY TABLE_CREATED DESC;

// Set retention time to 0

ALTER TABLE TDB.public.customers_transient
SET DATA_RETENTION_TIME_IN_DAYS  = 0;

DROP TABLE TDB.public.customers_transient;

UNDROP TABLE TDB.public.customers_transient;

SHOW TABLES;


// Creating transient schema and then table 

CREATE OR REPLACE TRANSIENT SCHEMA TRANSIENT_SCHEMA;

SHOW SCHEMAS;

CREATE OR REPLACE TABLE TDB.TRANSIENT_SCHEMA.new_table (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
  

ALTER TABLE TDB.TRANSIENT_SCHEMA.new_table
SET DATA_RETENTION_TIME_IN_DAYS = 1;  -- we can only set data retenperiod for transient table as 0 days or 1 days not more than 1days as transient tables are not FailSafe.

SHOW TABLES;



====================== Lec 101: Temporary Table & Schemas  =======================================
USE DATABASE PDB;

// Create permanent table 

CREATE OR REPLACE TABLE PDB.public.customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);


INSERT INTO PDB.public.customers
SELECT t1.* FROM OUR_FIRST_DB.public.customers t1;



SELECT * FROM PDB.public.customers;


// Create temporary table (with the same name)
CREATE OR REPLACE TEMPORARY TABLE PDB.public.customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);


// Validate temporary table is the active table
SELECT * FROM PDB.public.customers;

// Create second temporary table (with a new name)
CREATE OR REPLACE TEMPORARY TABLE PDB.public.temp_table (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);

// Insert data in the new table
INSERT INTO PDB.public.temp_table
SELECT * FROM PDB.public.customers;

SELECT * FROM PDB.public.temp_table;

SHOW TABLES;




====================== Lec102: Zero Copy Cloning  =======================================
            Zero-Copy Cloning
✓ Create copies of a database, a schema or a
table
✓ Cloned object is independent from original
table
✓ Easy to copy all meta data & improved storage
management
✓ Creating backups for development purposes
✓ Works with time travel 

    Clonibg Syntax:
CREATE TABLE table_new
CLONE table_source

    Cloning can be done for:
Database
Schema
Table
Stream
File Format
Sequence
Task
Stage: Named Internal Stages cannot be cloned
Pipe: Pipe can only be cloned if it is referencing to the external stage.

Note: Cloning a database or schema will clone all contained objects


CREATE TABLE <table_name>...
CLONE <source_table_name>
BEFORE ( TIMESTAMP => <timestamp> )

How about Privileges?

What privileges are needed?
SELECT:
    Table
Owner:
    Pipe
    Stream
    Task
    
USAGE:
    All other ojects

Additional Considerations
• Load history meta data is not copied
Loaded data can be loaded again in cloned table not in original table as Origianl table will have Metadata of already.

Cloning from specific point in time is possible for TIME TRAVEL:
    CREATE TABLE table_new
    CLONE table_source
    BEFORE (TIMESTAMP => 'timestamp')



====================== Lec 103: Cloning Tables  =======================================
// Cloning

SELECT * FROM OUR_FIRST_DB. PUBLIC. CUSTOMERS;

CREATE TABLE OUR_FIRST_DB .PUBLIC. CUSTOMERS_CLONE
CLONE OUR_FIRST_DB. PUBLIC. CUSTOMERS ;

// Validate the data
SELECT * FROM OUR_FIRST_DB.PUBLIC. CUSTOMERS_CLONE;

// Update cloned table
UPDATE OUR_FIRST_DB.public. CUSTOMERS_CLONE
SET LAST_NAME = NULL;

SELECT * FROM OUR_FIRST_DB. PUBLIC. CUSTOMERS ;

SELECT * FROM OUR_FIRST_DB. PUBLIC. CUSTOMERS_CLONE;

// Cloning a temporary table is not possible
CREATE OR REPLACE TEMPORARY TABLE OUR_FIRST_DB. PUBLIC. TEMP_TABLE(
id int);

CREATE TEMPORARY TABLE OUR_FIRST_DB. PUBLIC. TABLE_COPY CLONE OUR_FIRST_DB.PUBLIC. TEMP_TABLE;

SELECT * FROM OUR_FIRST_DB. PUBLIC. TABLE_COPY;

CREATE TRANSIENT TABLE OUR_FIRST_DB. PUBLIC. TABLE_COPY CLONE OUR_FIRST_DB.PUBLIC. TEMP_TABLE;

Note:
1. It is not possible to clone a temporary table and make it into permanent table but we can clone from Temporary table to Transient table instead.
2. Creating Temporary table & transient table from Permanent table will work for cloning but vice-vera will not work.


====================== Lec 104: Cloning Schemas & Databases  =======================================
// Cloning Schema
CREATE TRANSIENT SCHEMA OUR_FIRST_DB.COPIED_SCHEMA
CLONE OUR_FIRST_DB.PUBLIC;

SELECT * FROM COPIED_SCHEMA.CUSTOMERS


CREATE TRANSIENT SCHEMA OUR_FIRST_DB.EXTERNAL_STAGES_COPIED
CLONE MANAGE_DB.EXTERNAL_STAGES;



// Cloning Database
CREATE TRANSIENT DATABASE OUR_FIRST_DB_COPY
CLONE OUR_FIRST_DB;

DROP DATABASE OUR_FIRST_DB_COPY
DROP SCHEMA OUR_FIRST_DB.EXTERNAL_STAGES_COPIED
DROP SCHEMA OUR_FIRST_DB.COPIED_SCHEMA


====================== Lec 105: Cloning with time travel  =======================================

// Cloning using time travel

// Setting up table

CREATE OR REPLACE TABLE OUR_FIRST_DB.public.time_travel (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);
    


CREATE OR REPLACE FILE FORMAT MANAGE_DB.file_formats.csv_file
    type = csv
    field_delimiter = ','
    skip_header = 1;
    
CREATE OR REPLACE STAGE MANAGE_DB.external_stages.time_travel_stage
    URL = 's3://data-snowflake-fundamentals/time-travel/'
    file_format = MANAGE_DB.file_formats.csv_file;
    


LIST @MANAGE_DB.external_stages.time_travel_stage;



COPY INTO OUR_FIRST_DB.public.time_travel
from @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');


SELECT * FROM OUR_FIRST_DB.public.time_travel



// Update data 

UPDATE OUR_FIRST_DB.public.time_travel
SET FIRST_NAME = 'Frank' 



// Using time travel
SELECT * FROM OUR_FIRST_DB.public.time_travel at (OFFSET => -60*1)



// Using time travel
CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.time_travel_clone
CLONE OUR_FIRST_DB.public.time_travel at (OFFSET => -60*1.5)

SELECT * FROM OUR_FIRST_DB.PUBLIC.time_travel_clone


// Update data again

UPDATE OUR_FIRST_DB.public.time_travel_clone
SET JOB = 'Snowflake Analyst' 





// Using time travel: Method 2 - before Query
SELECT * FROM OUR_FIRST_DB.public.time_travel_clone before (statement => '<your-query-id>');

CREATE OR REPLACE TABLE OUR_FIRST_DB.PUBLIC.time_travel_clone_of_clone
CLONE OUR_FIRST_DB.public.time_travel_clone before (statement => '<your-query-id>');

SELECT * FROM OUR_FIRST_DB.public.time_travel_clone_of_clone ;



====================== Lec 106: Swapping Tables  =======================================
Swapping Tables
✓ Use-case: Development table into production
table

Development             Production
Meta data <----Swap ----> Meta data


ALTER TABLE <table name>...
SWAP WITH <target_table_name>

ALTER SCHEMA ‹schema_name> ...
SWAP WITH <target_schema_name>





====================== Lec107: Swapping (Hands On)  =======================================

//// Swapping tables

// Setting up dev table
CREATE TRANSIENT SCHEMA OUR_FIRST_DB.COPIED_SCHEMA
CLONE OUR_FIRST_DB.PUBLIC;

SELECT * FROM OUR_FIRST_DB. COPIED_SCHEMA.CUSTOMERS;
SELECT * FROM OUR_FIRST_DB.PUBLIC.CUSTOMERS;


// Modifying "Dev Table"
DELETE FROM OUR_FIRST_DB.COPIED_SCHEMA.CUSTOMERS WHERE ID < 500;

SELECT * FROM OUR_FIRST_DB.COPIED_SCHEMA.CUSTOMERS;


// Swapping Tables
ALTER TABLE OUR_FIRST_DB.COPIED_SCHEMA.CUSTOMERS 
SWAP WITH OUR_FIRST_DB.PUBLIC.CUSTOMERS;

// Verifying results
SELECT * FROM OUR_FIRST_DB.COPIED_SCHEMA_CUSTOMERS;
SELECT * FROM OUR_FIRST_DB.PUBLIC.CUSTOMERS;


====================== Lec 108: Understanding Data Sharing  =======================================
Usually this can be also a rather complicated process....
• Sharing with actually copying data
• Data is always up-to-date
• Compute paid by consumer


                Data Shoring
Standard Edition
Account1 Storage               --> DB             (Account1 provider)
                                    ⬇︎ Data is synchronized
Account2 Compute Resources -->   DB (Read-Only)       (Account2 Consumer)
                            (Cannot be modified!)                   

Standard Edition
Account1 Storage        --> DB (Read-Only) (Account1 provider & Consumer)
                               ⬆︎⬇︎ Data is synchronized
Account2 Compute Resources --> DB (Read-Only)  (Account2 provider & Consumer)
                                           

                            

We use Cloud Service Layer for storage and also we pay only for storage
Whereas Consumer use the compute resources.
As in Snowflake Compute and storage are in seperate layer.

We can share data in same account with the name same data share but it not generally relevant.


//Setting up shore
1. Create share: ACCOUNTADMIN role or CREATE SHARE privileges required
CREATE SHARE my_share;

2. Grant privileges to share:
GRANT USAGE ON DATABASE my_ab TO SHARE my_share;
GRANT USAGE ON SCHEMA my_schema.my_db TO SHARE my_share;
GRANT SELECT ON TABLE my_table.myschema.my_db TO SHARE my_share;

3. Add consumer accounts)
ALTER SHARE my_share ADD ACCOUNT bl67131;

4. Import share: ACCOUNTADMIN role or IMPORT SHARE / CREATE DATABASE privileges required.
CREATE DATABASE my_db FROM SHARE my_share;

5. Grant PRIVILEGES.



// What can be shared
Tables, External Tables, Secure views, Secure materialized views,
Secure UDFs.
                       
   
            Share       |     Best practice for Share
        Database        |   Database
        Schema          |   Schema
        Objects         |   Secure views
        Account (s)     |   Account (s)
        Privileges      |   Privileges






====================== Lec 109: Using Data Shared  =======================================
CREATE OR REPLACE DATABASE DATA_S;


CREATE OR REPLACE STAGE aws_stage
    url='s3://bucketsnowflakes3';

// List files in stage
LIST @aws_stage;

// Create table
CREATE OR REPLACE TABLE ORDERS (
ORDER_ID	VARCHAR(30)
,AMOUNT	NUMBER(38,0)
,PROFIT	NUMBER(38,0)
,QUANTITY	NUMBER(38,0)
,CATEGORY	VARCHAR(30)
,SUBCATEGORY	VARCHAR(30))  ; 


// Load data using copy command
COPY INTO ORDERS
    FROM @MANAGE_DB.external_stages.aws_stage
    file_format= (type = csv field_delimiter=',' skip_header=1)
    pattern='.*OrderDetails.*';
    
SELECT * FROM ORDERS;




// Create a share object
CREATE OR REPLACE SHARE ORDERS_SHARE;

---- Setup Grants ----

// Grant usage on database
GRANT USAGE ON DATABASE DATA_S TO SHARE ORDERS_SHARE; 

// Grant usage on schema
GRANT USAGE ON SCHEMA DATA_S.PUBLIC TO SHARE ORDERS_SHARE; 

// Grant SELECT on table

GRANT SELECT ON TABLE DATA_S.PUBLIC.ORDERS TO SHARE ORDERS_SHARE; 

// Validate Grants
SHOW GRANTS TO SHARE ORDERS_SHARE;


---- Add Consumer Account ----
ALTER SHARE ORDERS_SHARE ADD ACCOUNT=<consumer-account-id>;

We can also DO this using UI under Data Sharing -> External Sharing.
We can also change the database once we have already shared.



------------------ On Consumer Account we need to do following--------

// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC SHARE < producer_account>. ORDERS_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE DATA_S FROM SHARE <producer _account>. ORDERS_SHARE;

// Validate table access
SELECT * FROM DATA_S.PUBLIC. ORDERS;


====================== Lec 111: Sharing with Non-Snowflake Users   =======================================
//    Data Sharing with Non-Snowflake Users

          Storage  ==>   Provider Account (ACCOUNTADMIN)
 compute Resources ==>
                            ⬇︎ Created & Managed by Our Provider Account
                        
Non-Snowflake USERS       Reader Account
Provider responsible 
for all costs




// Data Sharing Considerations
• Share becomes immediately visible once shared
            New objects added immediately visible as well
• Each account can share and consume
            Even own share can be consumed
• Virtual Private Edition doesn't' allow sharing
            Dedicated compute and meta data storage
• Marketplace: Find & Import thhd-party datasets
            ACCOUNTADMIN role or IMPORT SHARE privileges required
• Data Exchange: Private Hub for sharing data
            Members can be invited.


            Producer (Account 1)

                    ⬇︎

            Consumer (Account 2)

====================== Lec112, 113, 114: Reader Account  =======================================

-- Create Reader Account --

CREATE MANAGED ACCOUNT tech_joy_account
ADMIN_NAME = tech_joy_admin,
ADMIN_PASSWORD = 'set-pwd',
TYPE = READER;

// Make sure to have selected the role of accountadmin

// Show accounts
SHOW MANAGED ACCOUNTS; -- 'ACCOUNT LOCATOR URL' is used by Reader account to access the data.

// Drop Reader ACCOUNT
DROP MANAGED ACCOUNT tech_joy_account;


-- Share the data -- 

ALTER SHARE ORDERS_SHARE 
ADD ACCOUNT = <reader-account-id>; -- <reader-account-id> we can also get from 'Data Sharing' -> External Sharing -> Reader Account -> Locator


ALTER SHARE ORDERS_SHARE 
ADD ACCOUNT =  <reader-account-id>
SHARE_RESTRICTIONS=false;


-- LEC 113:


-- Create database from share --

// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC SHARE QNA46172.ORDERS_SHARE; -- QNA46172 is identifier and we will get it from 'owner_acoount' when we run query ' SHOW SHARES' 

// Create a database in consumer account using the share
CREATE DATABASE DATA_SHARE_DB FROM SHARE <account_name_producer>.ORDERS_SHARE; -- <account_name_producer> get it from 'owner_acoount' when we run query ' SHOW SHARES' 

// Validate table access
SELECT * FROM  DATA_SHARE_DB.PUBLIC.ORDERS


// Setup virtual warehouse
CREATE WAREHOUSE READ_WH WITH
WAREHOUSE_SIZE='X-SMALL'
AUTO_SUSPEND = 180
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;






--lec 114:

-- Create and set up users 
''(this is Done on Reader Account after login to reader account.)''

// Create user 
CREATE USER MYRIAM PASSWORD = 'difficult_passw@ord=123'; -- MYRIAM-> UserName

// Grant usage on warehouse
GRANT USAGE ON WAREHOUSE READ_WH TO ROLE PUBLIC;


// Grating privileges on a Shared Database for other users
GRANT IMPORTED PRIVILEGES ON DATABASE DATA_SHARE_DB TO REOLE PUBLIC;



====================== Lec 115: Sharing Database and Schema  =======================================
SHOW SHARES;
// Create share object
CREATE OR REPLACE SHARE COMPLETE_SCHEMA_SHARE;

// Grant usage on dabase & schema
I GRANT USAGE ON DATABASE OUR_FIRST_DB TO SHARE COMEPLETE_SCHEMA_SHARE;
GRANT USAGE ON SCHEMA OUR_FIRST_DB. PUBLIC TO SHARE COMPLETE_SCHEMA_SHARE;

// Grant select on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA OUR_FIRST_DB. PUBLIC TO SHARE COMEPLETE_SCHEMA_SHARE;
GRANT SELECT ON ALL TABLES IN DATABASE OUR_FIRST_DB TO SHARE COMEPLETE_SCHEMA_SHARE;

// Add account to share
ALTER SHARE COMPLETE_SCHEMA_SHARE
ADD ACCOUNT=0W45605;


// Updating data
UPDATE OUR_FIRST_DB.PUBLIC. ORDERS SET PROFIT=O WHERE PROFIT < 0;
// Add new table
CREATE TABLE OUR_FIRST_DB. PUBLIC. NEW_TABLE (ID int) ;

-- Note: Whenever we create new table explicitly we need to grand person for the new table once we have given permission before. Before and after updating the data we have to check in for reader account so then we get to know whether the data after updating is getting shared or not for verfication purpose.



-- Below this need to be done on 'READER ACCOUNT'.


// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC QNA46172. COMPLETE_SCHEMA_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE OUR_FIRST_DB_SHARE FROM SHARE QNA46172. COMPLETE_SCHEMA_SHARE;

// Validate table access
SELECT * FROM OUR_FIRST_DB_SHARE.PUBLIC. ORDERS;

====================== Lec 116: PUBLIC  =======================================
SHOW VIEWS LIKE '%CUSTOMER%';
-- Output for Normal view under Text Column:
-- CREATE OR REPLACE VIEW CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW AS
-- SELECT 
-- FIRST_NAME,
-- LAST_NAME,
-- EMAIL
-- FROM CUSTOMER_DB.PUBLIC.CUSTOMERS
-- WHERE JOB != 'DATA SCIENTIST';

-- and also and is_secure = FALSE.



SHOW VIEWS LIKE '%CUSTOMER%';
-- Output for Secure view under Text Column is Blank
-- and is_secure = TRUE


====================== Lec 116 : Secure vs Normal View  =======================================

-- Create database & table --
CREATE OR REPLACE DATABASE CUSTOMER_DB;

CREATE OR REPLACE TABLE CUSTOMER_DB.public.customers (
   id int,
   first_name string,
  last_name string,
  email string,
  gender string,
  Job string,
  Phone string);

    
// Stage and file format
CREATE OR REPLACE FILE FORMAT MANAGE_DB.file_formats.csv_file
    type = csv
    field_delimiter = ','
    skip_header = 1;
    
CREATE OR REPLACE STAGE MANAGE_DB.external_stages.time_travel_stage
    URL = 's3://data-snowflake-fundamentals/time-travel/'
    file_format = MANAGE_DB.file_formats.csv_file;
    
LIST  @MANAGE_DB.external_stages.time_travel_stage;


// Copy data and insert in table
COPY INTO CUSTOMER_DB.public.customers
FROM @MANAGE_DB.external_stages.time_travel_stage
files = ('customers.csv');

SELECT * FROM  CUSTOMER_DB.PUBLIC.CUSTOMERS;

-- Create VIEW -- 
CREATE OR REPLACE VIEW CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW AS
SELECT 
FIRST_NAME,
LAST_NAME,
EMAIL
FROM CUSTOMER_DB.PUBLIC.CUSTOMERS
WHERE JOB != 'DATA SCIENTIST'; 


-- Grant usage & SELECT --
GRANT USAGE ON DATABASE CUSTOMER_DB TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA CUSTOMER_DB.PUBLIC TO ROLE PUBLIC;
GRANT SELECT ON TABLE CUSTOMER_DB.PUBLIC.CUSTOMERS TO ROLE PUBLIC;
GRANT SELECT ON VIEW CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW TO ROLE PUBLIC;


SHOW VIEWS LIKE '%CUSTOMER%';





-- Create SECURE VIEW -- 

CREATE OR REPLACE SECURE VIEW CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW_SECURE AS
SELECT 
FIRST_NAME,
LAST_NAME,
EMAIL
FROM CUSTOMER_DB.PUBLIC.CUSTOMERS
WHERE JOB != 'DATA SCIENTIST' ;

GRANT SELECT ON VIEW CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW_SECURE TO ROLE PUBLIC;

SHOW VIEWS LIKE '%CUSTOMER%';



// Notes:
-- Normal views shows the underlying data on the screen under Text COLUMN which we don't want to share with someone because of Privacy or only we want to share few columns with condition then we use secure view.
-- Secure view doesnot show the condition under the 'Text Column' which we want for used case then we go for secure view.
-- In some case the optimization of Normal view is better than Secure view for better performance.

======================  Lec 117: Sharing a SECURE View  =======================================
SHOW SHARES;

// Create share object
CREATE OR REPLACE SHARE VIEW_SHARE;

// Grant usage on dabase & schema
GRANT USAGE ON DATABASE CUSTOMER_DB TO SHARE VIEW_SHARE;
GRANT USAGE ON SCHEMA CUSTOMER_DB.PUBLIC TO SHARE VIEW_SHARE;

// Grant select on view
GRANT SELECT ON VIEW  CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW TO SHARE VIEW_SHARE; -- Error:Non-secure object can only be granted to shares with "secure_objects_only" property set to false. So to fix this we use code of Alter SHARE from line 14.
GRANT SELECT ON VIEW  CUSTOMER_DB.PUBLIC.CUSTOMER_VIEW_SECURE TO SHARE VIEW_SHARE;

ALTER SHARE VIEW_SHARE
SET secure_objects_only = FALSE;


// Add account to share
ALTER SHARE VIEW_SHARE
ADD ACCOUNT=KAA74702;


-- Note: By Default we can only share 1 database under SHARE but we can also share multiple Database by making some changes.



////////////// Now move to the Reader Account

// Show all shares (consumer & producers)
SHOW SHARES;

/ See details on share
DESC SHARE NNSACH.CJ29554.VIEW_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE VIEW_DB FROM SHARE NNSACH.CJ29554.VIEW_SHARE;

// Validate table access
SELECT * FROM VIEW_DB.PUBLIC.CUSTOMER_VIEW_SECURE;


====================== Lec 118: Share Data from Multiple databases  =======================================
USE SCHEMA CUSTOMER_DB.PUBLIC;

CREATE OR REPLACE SECURE VIEW SECURE_VIEW_M AS
SELECT
T1.ID,
T1.FIRST_NAME,
T2.JOB
FROM CUSTOMER_DB.PUBLIC.CUSTOMERS T1
INNER JOIN OUR_FIRST_DB.PUBLIC.CUSTOMERS_WRONG T2
ON T1.ID = T2.ID;

SELECT * FROM SECURE_VIEW_M;

SHOW SHARES;

// Create share object
CREATE OR REPLACE SHARE VIEW_SHARE;

// Grant usage on dabase & schema
GRANT USAGE ON DATABASE CUSTOMER_DB TO SHARE VIEW_SHARE;
GRANT USAGE ON SCHEMA CUSTOMER_DB. PUBLIC TO SHARE VIEW_SHARE;
GRANT REFERENCE_USAGE ON DATABASE OUR_FIRST_DB TO SHARE VIEW_SHARE;

// Grant select on view
GRANT SELECT ON VIEW CUSTOMER_DB. PUBLIC. SECURE_VIEW_M TO SHARE VIEW_SHARE; -- Error when we execute without REFERENCE USAGE: SQL compilation error: A view or function being shared cannot reference objects from other databases. Since we used Two different Database and now we need to give REFERENCE_USAGE ON DATABASE to resolve the issue.
GRANT SELECT ON VIEW CUSTOMER_DB. PUBLIC. CUSTOMER_VIEW_SECURE TO SHARE VIEW_SHARE;

alter share VIEW_SHARE
set secure_objects_only = false;

// Add account to share
ALTER SHARE VIEW_SHARE
ADD ACCOUNT=0W45605;


///// Now go to Reader Account to run the below code:

// Show all shares (consumer & producers)
SHOW SHARES;

// See details on share
DESC SHARE NNSACH.CJ29554.VIEW_SHARE;

// Create a database in consumer account using the share
CREATE DATABASE VIEW_DB_M FROM SHARE NNSACH.CJ29554.VIEW_SHARE;

// Validate table access
SELECT * FROM VIEW_DB_M.PUBLIC.CUSTOMER_VIEW_SECURE;

-- Question 1:
-- What virtual warehouse is used if the consumer is querying from a shared table?
-- Consumer Virtual WAREHOUSE

-- Question 2:
-- The data will not be copied and therefore the consumer will not be charged for data storage. True or false?
-- TRUE

-- Question 3:
-- We can share secure views and normal views. True or false?
-- TRUE

-- Question 4:
-- If we want to share data with non-snowlake users ...
-- it is best to set Reader Account.

-- Question 5:
-- What virtual warehouse is used if we share data with a non-snowflake user using a reader account?
-- A dedicated Virtual WH of the provider account has to be setup.



====================== Lec 119, 120, 121: Data Sampling  =======================================
-- ////////////////////================= Lec 119
-- //          Data Sampling
-- Why Sampling?
-- - Use-cases: Query development, data analysis etc.
-- - Faster & more cost efficient (less compute resources)

-- //  Data Sampling Methods
-- ROW or BERNOULLI method
-- BLOCK or SYSTEM method

-- //////////////// ===============   Lec 120
-- Data Sampling Methods
-- | ROW or BERNOULLI method              | BLOCK or SYSTEM method      
-- |Every row is chosen with percentage p | Every block is chosen with percentage p
-- | More randomness                      | More effective processing
-- | Smaller tables                        | Larger tables

//////////////  =================           Lec 121: Samplings Hand-On


CREATE OR REPLACE TRANSIENT DATABASE SAMPLING_DB;

CREATE OR REPLACE VIEW ADDRESS_SAMPLE
AS 
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS 
SAMPLE ROW (1) SEED(27);                                -- Here 1 means 1% of the rows (not exactly 1 row)
                                                        -- ROW sampling = random selection at row level
                                                        -- So each row has a probability of being included
                                                        
                                                        -- 🔥 Key insight (important for interviews)
                                                        -- Without SEED(): results change every execution
                                                        -- With SEED(27): results are stable and repeatable
                                                        -- SAMPLE ROW = row-level randomness (Bernoulli-style sampling)
                                                        
                                                        --🔥 Important concept
                                                -- SEED does NOT change randomness quality
                                                -- It only changes the starting point of randomness
                                                -- Think of it like:
                                                -- “Same lottery machine, different starting shuffle position”
                                                -- 🧠 Best practice (interview-ready)
                                                -- Use fixed seed (like 42, 1, 27) for:             -- 
                                                -- Testing
                                                -- Debugging
                                                -- Reproducible pipelines
                                                -- Avoid random seed in production reporting unless needed
                                -- ⚡ Pro tip
                                -- 42 is commonly used as a “standard demo seed” in data engineering because it is stable and easy to remember.


                                                    

SELECT * FROM ADDRESS_SAMPLE;



SELECT CA_LOCATION_TYPE, COUNT(*)/3254250*100
FROM ADDRESS_SAMPLE
GROUP BY CA_LOCATION_TYPE;



SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS 
SAMPLE SYSTEM (1) SEED(23);

SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS 
SAMPLE SYSTEM (10) SEED(23);

-- Question 1:
-- Sampling using the SYSTEM method is often slower than the row method. True or false?
-- FALSE

====================== Lec 122- 123: Understanding Tasks  =======================================
//////////////// =============== Lec 122: Understanding Tasks


--             Scheduling Tasks
-- • Tasks can be used to schedule SQL statements
-- • Standalone tasks and trees of tasks

-- Here we will learn:
-- 1. Understand tasks
-- 2. Create tasks
-- 3. Schedule tasks
-- 4. Tree of tasks
-- 5. Check task history

/////////////// ============== Lec 123: Creating TASKS

CREATE OR REPLACE TRANSIENT DATABASE TASK_DB;

// Prepare table
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID INT AUTOINCREMENT START = 1 INCREMENT =1,
    FIRST_NAME VARCHAR(40) DEFAULT 'JENNIFER' ,
    CREATE_DATE DATE);
    
    
// Create task
CREATE OR REPLACE TASK CUSTOMER_INSERT
    WAREHOUSE = COMPUTE_WH  -- For SERVERLESS we don't specify WAREHOUSE.
    SCHEDULE = '1 MINUTE'
    AS 
    INSERT INTO CUSTOMERS(CREATE_DATE) VALUES(CURRENT_TIMESTAMP); -- By default it is in SUSPENDED state when we create TASK for first time.
    

SHOW TASKS;

// Task starting and suspending
ALTER TASK CUSTOMER_INSERT RESUME;
ALTER TASK CUSTOMER_INSERT SUSPEND;


SELECT * FROM CUSTOMERS;


====================== Lec 124: Using CRON  =======================================
-- CRON is used for Flexible Scheduling like every Friday @7am.
-- Alternative way of TASKS.




CREATE OR REPLACE TASK CUSTOMER_INSERT
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '60 MINUTE'
    AS 
    INSERT INTO CUSTOMERS(CREATE_DATE) VALUES(CURRENT_TIMESTAMP);
  
  
  
  
CREATE OR REPLACE TASK CUSTOMER_INSERT
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 7,10 * * 5L UTC'
    AS 
    INSERT INTO CUSTOMERS(CREATE_DATE) VALUES(CURRENT_TIMESTAMP);
    

# __________ minute (0-59)
# | ________ hour (0-23)
# | | ______ day of month (1-31, or L)
# | | | ____ month (1-12, JAN-DEC)
# | | | | __ day of week (0-6, SUN-SAT, or L)
# | | | | |
# | | | | |
# * * * * *




// Every minute
SCHEDULE = 'USING CRON * * * * * UTC'


// Every day at 6am UTC timezone
SCHEDULE = 'USING CRON 0 6 * * * UTC'

// Every hour starting at 9 AM and ending at 5 PM on Sundays 
SCHEDULE = 'USING CRON 0 9-17 * * SUN America/Los_Angeles'


CREATE OR REPLACE TASK CUSTOMER_INSERT
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 9,17 * * * UTC'
    AS 
    INSERT INTO CUSTOMERS(CREATE_DATE) VALUES(CURRENT_TIMESTAMP);



CREATE OR REPLACE TASK CUSTOMER_INSERT
WAREHOUSE
= COMPUTE_WH
SCHEDULE = 'USING CRON 0 20 1,15 JAN MON-FRI UTC'
AS
INSERT INTO CUSTOMERS (CREATE_DATE) VALUES (CURRENT_TIMESTAMP):

Where
SCHEDULE = 'USING CRON 0 20 1,15 JAN MON-FRI UTC'
    Represents  
              0 = Every mintue
            20  = 8pm
          1, 15 = every month 1 and 15
            JAN =  January month
        MON-FRI = Every weekdays from Monday to Friday.
            UTC = Time Zone




  


====================== Lec 125 - 126: Tree of TASKS  =======================================
-- //////////// ==========   Lec 125: Tree of TASKS

-- //                Tree of Tasks
            
--                     Root task

                    
--         Task A                           Task B

-- Task C        Task D                  Task E      Task F

-- • Every task has one parent

-- // How to Create Root Task
-- CREATE TASK
-- AFTER <parent task>
-- AS ..

-- // How to Add Root Task to Existing Task.
-- ALTER TASK・・・
-- ADD AFTER <parent task>



////////////// ========= Lec 126: Creating TREE OF TASKS

USE TASK_DB;
 
SHOW TASKS;

SELECT * FROM CUSTOMERS;

// Prepare a second table
CREATE OR REPLACE TABLE CUSTOMERS2 (
    CUSTOMER_ID INT,
    FIRST_NAME VARCHAR(40),
    CREATE_DATE DATE);
    
    
// Suspend parent task
ALTER TASK CUSTOMER_INSERT SUSPEND;
    
// Create a child task
CREATE OR REPLACE TASK CUSTOMER_INSERT2
    WAREHOUSE = COMPUTE_WH
    AFTER CUSTOMER_INSERT
    AS 
    INSERT INTO CUSTOMERS2 SELECT * FROM CUSTOMERS;
    
    
// Prepare a third table
CREATE OR REPLACE TABLE CUSTOMERS3 (
    CUSTOMER_ID INT,
    FIRST_NAME VARCHAR(40),
    CREATE_DATE DATE,
    INSERT_DATE DATE DEFAULT DATE(CURRENT_TIMESTAMP));   
    

// Create a child task
CREATE OR REPLACE TASK CUSTOMER_INSERT3
    WAREHOUSE = COMPUTE_WH
    AFTER CUSTOMER_INSERT2
    AS 
    INSERT INTO CUSTOMERS3 (CUSTOMER_ID,FIRST_NAME,CREATE_DATE) SELECT * FROM CUSTOMERS2;


SHOW TASKS;

ALTER TASK CUSTOMER_INSERT 
SET SCHEDULE = '1 MINUTE';

// Resume tasks (first root task)
ALTER TASK CUSTOMER_INSERT RESUME; -- START LAST as it is PARENT task else will get error. 
ALTER TASK CUSTOMER_INSERT2 RESUME; -- START SECOND 
ALTER TASK CUSTOMER_INSERT3 RESUME; -- START FIRST 

SHOW TASKS;

SELECT * FROM CUSTOMERS;

SELECT * FROM CUSTOMERS2;

SELECT * FROM CUSTOMERS3;

// Suspend tasks again
ALTER TASK CUSTOMER_INSERT SUSPEND;
ALTER TASK CUSTOMER_INSERT2 SUSPEND;
ALTER TASK CUSTOMER_INSERT3 SUSPEND;

DROP TASK CUSTOMER_INSERT;
DROP TASK CUSTOMER_INSERT2;
DROP TASK CUSTOMER_INSERT3;

SHOW TASKS;

---------------------------------------------------------------
Note:
1. Always SUSPEND the PARENT TASK before CREATING CHILD TASK
2. ALWAYS SUSPEND the PARENT TASK before DELETING CHILD TASK else it will throw error.
3. Always START the CHILD TASK first and then START PARENTS TASK.




====================== Lec 127: Calling a STORE PROCEDURE  =======================================
-- Create TASK by using STORED PROCEDURE

// Create a stored procedure
USE TASK_DB;

SELECT * FROM CUSTOMERS;



CREATE OR REPLACE PROCEDURE CUSTOMERS_INSERT_PROCEDURE (CREATE_DATE varchar)
    RETURNS STRING NOT NULL
    LANGUAGE JAVASCRIPT
    AS
        $$
        var sql_command = 'INSERT INTO CUSTOMERS(CREATE_DATE) VALUES(:1);'  
        snowflake.execute(
            {
            sqlText: sql_command,
            binds: [CREATE_DATE]
            });
        return "Successfully executed.";
        $$;
        
   -- -- :1 is for binds     
    
CREATE OR REPLACE TASK CUSTOMER_TAKS_PROCEDURE
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    AS
    CALL  CUSTOMERS_INSERT_PROCEDURE (CURRENT_TIMESTAMP);


SHOW TASKS;

ALTER TASK CUSTOMER_TAKS_PROCEDURE RESUME;


SELECT * FROM CUSTOMERS; -- After 1min the data gets updated as we set time for 1min initally.

ALTER TASK CUSTOMER_TAKS_PROCEDURE SUSPEND;

SHOW TASKS;


====================== Lec 128: Task History & Error Handling  =======================================
SHOW TASKS;



USE DEMO_DB;







// Use the table function "TASK_HISTORY()"
select *
  from table(information_schema.task_history())
  order by scheduled_time desc;
  
  
  
  
  
  
  
  
  
  
  
  
// See results for a specific Task in a given time
select *
from table(information_schema.task_history(
    scheduled_time_range_start=>dateadd('hour',-4,current_timestamp()),  -- (-4) = 4 hour before from current time.
    result_limit => 5,
    task_name=>'CUSTOMER_INSERT'));
  
  












 
// See results for a given time period
select *
  from table(information_schema.task_history(
    scheduled_time_range_start=>to_timestamp_ltz('2026-04-15 09:26:18.583 -0700'),
    scheduled_time_range_end=>to_timestamp_ltz('2026-04-21 09:26:18.583 -0700')));  


// Question: How to get Current Timestamp?
SELECT TO_TIMESTAMP_LTZ(CURRENT_TIMESTAMP); 


====================== LEC 129: TASKS with Condition  =======================================
USE TASK_DB;

// Prepare table
CREATE OR REPLACE TABLE CUSTOMERS(
    CUSTOMER_ID INT AUTOINCREMENT START = 1 INCREMENT = 1,
    FIRST_NAME VARCHAR (40) DEFAULT 'JENNIFER',
    CREATE_DATE DATE
);

// Create task 1
CREATE OR REPLACE TASK CUSTOMER_INSERT
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    WHEN 1=2
AS
INSERT INTO CUSTOMERS (CREATE_DATE, FIRST_NAME) VALUES (CURRENT_TIMESTAMP, 'MIKE');


// Create task 2
CREATE OR REPLACE TASK CUSTOMER_INSERT2
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    WHEN 1=1
AS
INSERT INTO CUSTOMERS (CREATE_DATE, FIRST_NAME) VALUES (CURRENT_TIMESTAMP, 'DEBIKA' ) ;


SELECT *
FROM table (information_schema.task_history())
ORDER BY scheduled_time DESC;


SHOW TASKS;


// Task starting and suspending
ALTER TASK CUSTOMER_INSERT RESUME;
ALTER TASK CUSTOMER_INSERT2 RESUME;

SELECT * FROM CUSTOMERS;

// Delete the task after exection successful.
DROP TASK CUSTOMER_INSERT;
DROP TASK CUSTOMER_INSERT2;

SHOW TASKS; -- Drop any if still running using this command.

// Condition and functions 1
CREATE OR REPLACE TASK CUSTOMER_INSERT2
    WAREHOUSE= COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    WHEN CURRENT_TIMESTAMP LIKE '20%'
AS
INSERT INTO CUSTOMERS (CREATE_DATE, FIRST_NAME) VALUES (CURRENT_TIMESTAMP, 'DEBIKA'); -- GETS ERROR: Only some data type conversions and the following functions are allowed: [SYSTEM$GET_PREDECESSOR_RETURN_VALUE, SYSTEM$STREAM_HAS_DATA]. 


// Condition and functions 2
CREATE OR REPLACE TASK CUSTOMER_INSERT2
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    WHEN SYSTEMSTREAM_HAS_DATA ('<stream name›')
AS
INSERT INTO CUSTOMERS (CREATE_DATE, FIRST_NAME) VALUES (CURRENT_TIMESTAMP, 'DEBIKA');



-- Question 1:
-- One task can execute multiple SQL statements. True or false?
-- FALSE

-- Question 2:
-- What compute resource (virtual warehouse) is used to execute the SQL statement in a task?
-- The Virtial warehouse that is specified in the task.

-- Question 3:
-- In the context of creating a tree of tasks for a data pipeline, which of the following statements is true about task dependencies?
-- A parent task can have upto 100 child tasks.


====================== Lec 130: STREAMS  =======================================
STREAMS

STREAM is not actually Storing any data changes.
The data changes are stored and tracked in ORIGINAL table.
But when we CREATE STREAMS on a given table then it ENABLE TRACKING SYSTEM IN ORIGINAL TABLE these 3 gets added to the original table ie METADATA$ACTION, METADATA$ISUPDATED, METADATA$ROW_ID but it will be just hidden.
When we query these Hidden Columns may not be visible but we can make them visible through the STREAMS.
SELECT * FROM ‹stream name>;

This works so Called OFFSET

It is done using DELTA laod table ie CDC.
Object that records (DML-)changes made to a table
This process is called change data capture (CDC)

DML-> Data Manipulation Language.
    -> INSERT, UPDATE, DELETE only can be performed
    

    Streams
HR + Sales data     -------ETL----> Target Database
(Data scources)

    Stream object        --------------> Table
METADATAŞACTION                            DELETE
METADATAŞUPDATE                            INSERT
METADATAŞROW_ID                            UPDATE 

// CREATE STREAMS

CREATE STREAM ‹stream name>
ON TABLE <table name>;

SELECT * FROM ‹stream name>;


Stream object -------INSERT CDC--------> Table 
once the data is inserted then the STREAM Object gets CONSUMED and becomes EMPTY.



                            

====================== Lec 131: STREAMS- INSERT Operation  =======================================

-------------------- Stream example: INSERT ------------------------
CREATE OR REPLACE TRANSIENT DATABASE STREAMS_DB;

-- Create example table 
// Table 1:
create or replace table sales_raw_staging(
  id varchar,
  product varchar,
  price varchar,
  amount varchar,
  store_id varchar);
  
-- insert values 
insert into sales_raw_staging 
    values
        (1,'Banana',1.99,1,1),
        (2,'Lemon',0.99,1,1),
        (3,'Apple',1.79,1,2),
        (4,'Orange Juice',1.89,1,2),
        (5,'Cereals',5.98,2,1);  

// Table 2:
create or replace table store_table(
  store_id number,
  location varchar,
  employees number);


INSERT INTO STORE_TABLE VALUES(1,'Chicago',33);
INSERT INTO STORE_TABLE VALUES(2,'London',12);

//Table 3:
create or replace table sales_final_table(
  id int,
  product varchar,
  price number,
  amount int,
  store_id int,
  location varchar,
  employees int);

 -- Insert into final table
INSERT INTO sales_final_table 
    SELECT 
    SA.id,
    SA.product,
    SA.price,
    SA.amount,
    ST.STORE_ID,
    ST.LOCATION, 
    ST.EMPLOYEES 
    FROM SALES_RAW_STAGING SA
    JOIN STORE_TABLE ST ON ST.STORE_ID=SA.STORE_ID ;


SELECT * FROM sales_raw_staging;
SELECT * FROM STORE_TABLE;
SELECT * FROM sales_final_table;



-- Create a stream object
create or replace stream sales_stream on table sales_raw_staging;


SHOW STREAMS; -- show output Source_Type as DELTA table;

DESC STREAM sales_stream;

-- Get changes on data using stream (INSERTS)
select * from sales_stream;

select * from sales_raw_staging;
        
                                 

-- insert values 
insert into sales_raw_staging  
    values
        (6,'Mango',1.99,1,2),
        (7,'Garlic',0.99,1,1);
        
-- Get changes on data using stream (INSERTS)
select * from sales_stream;

select * from sales_raw_staging;
                
select * from sales_final_table;        
        

-- Consume stream object
INSERT INTO sales_final_table 
    SELECT 
    SA.id,
    SA.product,
    SA.price,
    SA.amount,
    ST.STORE_ID,
    ST.LOCATION, 
    ST.EMPLOYEES 
    FROM SALES_STREAM SA -- here we Use STREAMs Instead of Source Table ie SALES_STREAM is used instead of sales_raw_staging for CDC only.
    JOIN STORE_TABLE ST ON ST.STORE_ID=SA.STORE_ID ;


-- Get changes on data using stream (INSERTS)
select * from sales_stream; -- once the value from STREAMS is CONSUMED then it becomes EMPTY and also It shows METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID which is used with MERGE STATEMENT.




-- insert values 
insert into sales_raw_staging  
    values
        (8,'Paprika',4.99,1,2),
        (9,'Tomato',3.99,1,2);
        
        
 -- Consume stream object
INSERT INTO sales_final_table 
    SELECT 
    SA.id,
    SA.product,
    SA.price,
    SA.amount,
    ST.STORE_ID,
    ST.LOCATION, 
    ST.EMPLOYEES 
    FROM SALES_STREAM SA
    JOIN STORE_TABLE ST ON ST.STORE_ID=SA.STORE_ID ;
       
              
SELECT * FROM SALES_FINAL_TABLE;        

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;


====================== Lec 132: STREAMS - UPDATE Operation  =======================================
        
-- ******* UPDATE 1 ********

USE DATABASE STREAMS_DB;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM; -- EMPTY FOR NOW

UPDATE SALES_RAW_STAGING
SET PRODUCT ='Potato' WHERE PRODUCT = 'Banana';

SELECT * FROM SALES_RAW_STAGING;



merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
using SALES_STREAM S                -- Stream that has captured the changes
   on  f.id = s.id                 
when matched 
    and S.METADATA$ACTION ='INSERT'
    and S.METADATA$ISUPDATE ='TRUE'        -- Indicates the record has been updated 
    then update 
    set f.product = s.product,
        f.price = s.price,
        f.amount= s.amount,
        f.store_id=s.store_id;
        

SELECT * FROM SALES_FINAL_TABLE;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;  -- AFTER STREAMS get CONSUMED, it become EMPTY.

-- ******* UPDATE 2 ********

UPDATE SALES_RAW_STAGING
SET PRODUCT ='Green apple' WHERE PRODUCT = 'Apple';


merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
using SALES_STREAM S                -- Stream that has captured the changes
   on  f.id = s.id                 
when matched 
    and S.METADATA$ACTION ='INSERT'
    and S.METADATA$ISUPDATE ='TRUE'        -- Indicates the record has been updated 
    then update 
    set f.product = s.product,
        f.price = s.price,
        f.amount= s.amount,
        f.store_id=s.store_id;


SELECT * FROM SALES_FINAL_TABLE;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM; -- It shows METADATA$ACTION, METADATA$ISUPDATE, METADATA$ROW_ID which is used with MERGE STATEMENT and Become EMP


====================== Lec 133: OFFSET in STREAMS  =======================================

-- STREAM is not actually Storing any data changes.
-- The data changes are stored and tracked in ORIGINAL table.
-- But when we CREATE STREAMS on a given table then it ENABLE TRACKING SYSTEM IN ORIGINAL TABLE these 3 gets added to the original table ie METADATA$ACTION, METADATA$ISUPDATED, METADATA$ROW_ID but it will be just hidden.
-- When we query these Hidden Columns may not be visible but we can make them visible through the STREAMS.
-- SELECT * FROM ‹stream name>;
-- This works so Called OFFSET.
-- OFFSET is remembering the state of the table and from that moment it will track the changes.


  
  -------------------- Stream example: OFFSET ------------------------
CREATE OR REPLACE TRANSIENT DATABASE STREAMS_DB_OFFSET;

-- Create example table 
create or replace table sales_raw_staging(
  id varchar,
  product varchar,
  price varchar,
  amount varchar,
  store_id varchar);
  
-- insert values 
insert into sales_raw_staging 
    values
        (1,'Banana',1.99,1,1),
        (2,'Lemon',0.99,1,1),
        (3,'Apple',1.79,1,2),
        (4,'Orange Juice',1.89,1,2),
        (5,'Cereals',5.98,2,1);  


create or replace table store_table(
  store_id number,
  location varchar,
  employees number);


INSERT INTO STORE_TABLE VALUES(1,'Chicago',33);
INSERT INTO STORE_TABLE VALUES(2,'London',12);

create or replace table sales_final_table(
  id int,
  product varchar,
  price number,
  amount int,
  store_id int,
  location varchar,
  employees int);

 -- Insert into final table
INSERT INTO sales_final_table 
    SELECT 
    SA.id,
    SA.product,
    SA.price,
    SA.amount,
    ST.STORE_ID,
    ST.LOCATION, 
    ST.EMPLOYEES 
    FROM SALES_RAW_STAGING SA
    JOIN STORE_TABLE ST ON ST.STORE_ID=SA.STORE_ID ;



-- Create a stream object
create or replace stream sales_stream on table sales_raw_staging;


SHOW STREAMS;  -- Show STALE_AFTER Column which helps us in RETENTION time period.

DESC STREAM sales_stream;

-- Get changes on data using stream (INSERTS)
select * from sales_stream;

select * from sales_raw_staging;
        
                                 

-- insert values 
insert into sales_raw_staging  
    values
        (6,'Mango',1.99,1,2),
        (7,'Garlic',0.99,1,1);
        
-- Get changes on data using stream (INSERTS)
select * from sales_stream;

select * from sales_raw_staging;
                
select * from sales_final_table;        
        

-- Consume stream object
INSERT INTO sales_final_table 
    SELECT 
    SA.id,
    SA.product,
    SA.price,
    SA.amount,
    ST.STORE_ID,
    ST.LOCATION, 
    ST.EMPLOYEES 
    FROM SALES_STREAM SA
    JOIN STORE_TABLE ST ON ST.STORE_ID=SA.STORE_ID AND SA.ID=6
    ;  -- here we consumed only 1 row ie with ID = 6 ignoring all other data.



OFFSET is remembering the state of the table and from that moment it will track the changes.

====================== Lec 134: Staleness of a STREAM  =======================================
-- It is Recommended to CONSUME a STREAM before it going to STALE.
-- STALE Depends upon what is the RETENTION PERIOD we have set during TIME TRAVEL. Else we will LOST the CHANGES.
-- Once we consume the STREAM the OFFSET is set to NOW and gets UPDATED stale_after to next 14 days or days we have set for.

-- By Default MAX_DATA_EXTENSION_TIME_IN_DAYS = 14 but we can change it.

 -------------------- Stream example: STALENESS ------------------------

SHOW STREAMS;

DESC STREAM sales_stream;




-- View Retention time

SHOW PARAMETERS IN TABLE sales_raw_staging;


-- Change retention time

ALTER TABLE sales_raw_staging
SET MAX_DATA_EXTENSION_TIME_IN_DAYS = 14;



====================== Lec 135: Minimal Set of Changes  =======================================
-- STREAMS stores Minimal Changes in data. Streams does not store intermediate result if it done on same row n number of times.

-- ******* How Changes are captured ********
USE STREAMS_DB_OFFSET.PUBLIC;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;

UPDATE SALES_RAW_STAGING
SET PRODUCT ='Potato' WHERE PRODUCT = 'Banana';

SELECT * FROM SALES_RAW_STAGING;

SELECT * FROM SALES_STREAM;

UPDATE SALES_RAW_STAGING
SET PRODUCT ='Potato-NEW' WHERE PRODUCT = 'Potato';

SELECT * FROM SALES_RAW_STAGING;

SELECT * FROM SALES_STREAM;


====================== Lec 136: STREAM - DELETE Operation  =======================================
-- ******* DELETE  ********        
USE DATABASE STREAMS_DB;      
        
SELECT * FROM SALES_FINAL_TABLE;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;    

DELETE FROM SALES_RAW_STAGING
WHERE PRODUCT = 'Lemon';
        
        
SELECT * FROM SALES_FINAL_TABLE;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;    
        
        
-- ******* Process stream  ********            

        
merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
using SALES_STREAM S                -- Stream that has captured the changes
   on  f.id = s.id          
when matched 
    and S.METADATA$ACTION ='DELETE' 
    and S.METADATA$ISUPDATE = 'FALSE'
    then delete;            

-- The above merge query is written to delete 'LEMON' from the SALES_FINAL_TABLE using SALES_STREAM where the CDC is happening. 

SELECT * FROM SALES_FINAL_TABLE;

SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM; 
        

====================== Lec 137: STREAMS - Process all Data changes  =======================================
       
        
        
-- ******* Process UPDATE,INSERT & DELETE simultaneously  ********       
USE DATABASE STREAMS_DB;
        
        
merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
USING ( SELECT STRE.*,ST.location,ST.employees
        FROM SALES_STREAM STRE
        JOIN STORE_TABLE ST
        ON STRE.store_id = ST.store_id
       ) S
ON F.id=S.id
when matched                        -- DELETE condition
    and S.METADATA$ACTION ='DELETE' 
    and S.METADATA$ISUPDATE = 'FALSE'
    then delete                   
when matched                        -- UPDATE condition
    and S.METADATA$ACTION ='INSERT' 
    and S.METADATA$ISUPDATE  = 'TRUE'       
    then update 
    set f.product = s.product,
        f.price = s.price,
        f.amount= s.amount,
        f.store_id=s.store_id
when not matched 
    and S.METADATA$ACTION ='INSERT'
    then insert 
    (id,product,price,store_id,amount,employees,location)
    values
    (s.id, s.product,s.price,s.store_id,s.amount,s.employees,s.location);
        




SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;

SELECT * FROM SALES_FINAL_TABLE;
       

       
       



INSERT INTO SALES_RAW_STAGING VALUES (2,'Lemon',0.99,1,1);




UPDATE SALES_RAW_STAGING
SET PRODUCT = 'Lemonade'
WHERE PRODUCT ='Lemon';



       
DELETE FROM SALES_RAW_STAGING
WHERE PRODUCT = 'Lemonade';       


--- Example 2 ---

INSERT INTO SALES_RAW_STAGING VALUES (10,'Lemon Juice',2.99,1,1);

UPDATE SALES_RAW_STAGING
SET PRICE = 3
WHERE PRODUCT ='Garlic';
       
DELETE FROM SALES_RAW_STAGING
WHERE PRODUCT = 'Potato'; 


SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;

SELECT * FROM SALES_FINAL_TABLE;

merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
USING ( SELECT STRE.*,ST.location,ST.employees
        FROM SALES_STREAM STRE
        JOIN STORE_TABLE ST
        ON STRE.store_id = ST.store_id
       ) S
ON F.id=S.id
when matched                        -- DELETE condition
    and S.METADATA$ACTION ='DELETE' 
    and S.METADATA$ISUPDATE = 'FALSE'
    then delete                   
when matched                        -- UPDATE condition
    and S.METADATA$ACTION ='INSERT' 
    and S.METADATA$ISUPDATE  = 'TRUE'       
    then update 
    set f.product = s.product,
        f.price = s.price,
        f.amount= s.amount,
        f.store_id=s.store_id
when not matched 
    and S.METADATA$ACTION ='INSERT'
    then insert 
    (id,product,price,store_id,amount,employees,location)
    values
    (s.id, s.product,s.price,s.store_id,s.amount,s.employees,s.location);


SELECT * FROM SALES_FINAL_TABLE;

====================== Lec 138: Combine STREAMS & TASKS  =======================================


------- Automatate the updates using tasks --

USE DATABASE STREAMS_DB;

SELECT SYSTEM$STREAM_HAS_DATA('SALES_STREAM'); -- Used when STREAMS has check whether data is Present for capturing CDC.
                                               -- By DEFAULT it is FALSE but when it's TRUE it captures the CDC and resumes the STREAMS.

CREATE OR REPLACE TASK all_data_changes
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('SALES_STREAM')
    AS 
merge into SALES_FINAL_TABLE F      -- Target table to merge changes from source table
USING ( SELECT STRE.*,ST.location,ST.employees
        FROM SALES_STREAM STRE
        JOIN STORE_TABLE ST
        ON STRE.store_id = ST.store_id
       ) S
ON F.id=S.id
when matched                        -- DELETE condition
    and S.METADATA$ACTION ='DELETE' 
    and S.METADATA$ISUPDATE = 'FALSE'
    then delete                   
when matched                        -- UPDATE condition
    and S.METADATA$ACTION ='INSERT' 
    and S.METADATA$ISUPDATE  = 'TRUE'       
    then update 
    set f.product = s.product,
        f.price = s.price,
        f.amount= s.amount,
        f.store_id=s.store_id
when not matched 
    and S.METADATA$ACTION ='INSERT'
    then insert 
    (id,product,price,store_id,amount,employees,location)
    values
    (s.id, s.product,s.price,s.store_id,s.amount,s.employees,s.location);

ALTER TASK all_data_changes RESUME;
SHOW TASKS;

// Change data

INSERT INTO SALES_RAW_STAGING VALUES (11,'Milk',1.99,1,2);
INSERT INTO SALES_RAW_STAGING VALUES (12,'Chocolate',4.49,1,2);
INSERT INTO SALES_RAW_STAGING VALUES (13,'Cheese',3.89,1,1);


UPDATE SALES_RAW_STAGING
SET PRODUCT = 'Chocolate bar'
WHERE PRODUCT ='Chocolate';
       
DELETE FROM SALES_RAW_STAGING
WHERE PRODUCT = 'Milk';


// Verify results
SELECT * FROM SALES_RAW_STAGING;     
        
SELECT * FROM SALES_STREAM;

SELECT * FROM SALES_FINAL_TABLE;



// Verify the history
select *
from table(information_schema.task_history())
order by name asc,scheduled_time desc;

ALTER TASK all_data_changes SUSPEND;
DROP TASK ALL_DATA_CHANGES;
SHOW TASKS;


====================== Lec 139: Append-only STREAMS  =======================================
-- Types of streams:

-- STANDARD                |       APPEND-ONLY
-- ------------------------------------------------------
-- INSERT                  |       INSERT
-- UPDATE                  |
-- DELETE                  |

-- Note: 
--     APPEND-ONLY is good for PERFORMANCE where our ETL mainly depends on INSERT and we don't want track UPDATE & DELETE so in that case we use APPEND-ONLY STREAMS.
-- We cannot alter the existing STREAM into APPEND_ONLY rather we need to CREATE newAPPEND_ONLY STREAMS.
-- APPEND_ONLY tracks INSERT statement only whereas STANDARD STREAM tracks INSERT, UPDATE, DELETE statement as well.

-- Syntax:
            -- CREATE STREAM ‹stream name>
            -- ON TABLE ‹table name>
            -- APPEND_ONLY = TRUE

-- By default it is STANDARD set as DEFAULT mode. Which we can find by Runnig 
-- SHOW STREAMS; --under mode column = DEFAULT


------- Append-only type ------
USE STREAMS_DB;
SHOW STREAMS;

DROP STREAM SALES_STREAM;

 

SELECT * FROM SALES_RAW_STAGING;     

-- Create stream with default
CREATE OR REPLACE STREAM SALES_STREAM_DEFAULT
ON TABLE SALES_RAW_STAGING;

-- Create stream with append-only
CREATE OR REPLACE STREAM SALES_STREAM_APPEND
ON TABLE SALES_RAW_STAGING 
APPEND_ONLY = TRUE;

-- View streams
SHOW STREAMS;


-- Insert values
INSERT INTO SALES_RAW_STAGING VALUES (14,'Honey',4.99,1,1);
INSERT INTO SALES_RAW_STAGING VALUES (15,'Coffee',4.89,1,2);
INSERT INTO SALES_RAW_STAGING VALUES (15,'Coffee',4.89,1,2);

     


SELECT * FROM SALES_STREAM_APPEND;
SELECT * FROM SALES_STREAM_DEFAULT;

-- Delete values
SELECT * FROM SALES_RAW_STAGING;


DELETE FROM SALES_RAW_STAGING WHERE ID=10;


SELECT * FROM SALES_STREAM_APPEND; -- DELETE Operation is not TRACKED in APPEND_ONLY mode.
SELECT * FROM SALES_STREAM_DEFAULT; -- DELETE Operation is TRACKED in DEFAULT mode.


-- Consume stream via "CREATE TABLE ... AS"
CREATE OR REPLACE TEMPORARY TABLE PRODUCT_TABLE
AS SELECT * FROM SALES_STREAM_DEFAULT;
SELECT * FROM PRODUCT_TABLE;

CREATE OR REPLACE TEMPORARY TABLE PRODUCT_TABLE
AS SELECT * FROM SALES_STREAM_APPEND;
SELECT * FROM PRODUCT_TABLE;

-- Update
UPDATE SALES_RAW_STAGING
SET PRODUCT = 'Coffee 200g'
WHERE PRODUCT ='Coffee';
       

SELECT * FROM SALES_STREAM_APPEND;
SELECT * FROM SALES_STREAM_DEFAULT;

SHOW STREAMS;
DROP STREAM SALES_STREAM_APPEND;
DROP STREAM SALES_STREAM_DEFAULT;


====================== Lec 140: Changes Clause  =======================================
----- Change clause ------ 
-- CHANGE Clause is used to get more control over the OFFSET / TIMESTAMP value.
-- Syntax:
--         ALTER TABLE <TABLE_NAME>
--         SET CHANGE_TRACKING = TRUE;
-- If we have already USED STREAMS then CHANGE_TRACKING is already SET to TRUE. Or else if we want control over OFFSET we can do it manually by CHANGE_TRACKING = TRUE.

--- Create example db & table ---

CREATE OR REPLACE DATABASE SALES_DB;

create or replace table sales_raw(
	id varchar,
	product varchar,
	price varchar,
	amount varchar,
	store_id varchar);

-- insert values
insert into sales_raw
	values
		(1, 'Eggs', 1.39, 1, 1),
		(2, 'Baking powder', 0.99, 1, 1),
		(3, 'Eggplants', 1.79, 1, 2),
		(4, 'Ice cream', 1.89, 1, 2),
		(5, 'Oats', 1.98, 2, 1);

ALTER TABLE sales_raw
SET CHANGE_TRACKING = TRUE;

SELECT * FROM SALES_RAW
CHANGES(information => default)
AT (offset => -0.5*60);


SELECT CURRENT_TIMESTAMP; -- 2026-04-25 08:08:50.368 -0700

-- Insert values
INSERT INTO SALES_RAW VALUES (6, 'Bread', 2.99, 1, 2);
INSERT INTO SALES_RAW VALUES (7, 'Onions', 2.89, 1, 2);


SELECT * FROM SALES_RAW
CHANGES(information  => default)
AT (timestamp => '2026-04-25 08:08:50.368 -0700'::timestamp_tz);

UPDATE SALES_RAW
SET PRODUCT = 'Toast2' WHERE ID=6;


// information value


SELECT * FROM SALES_RAW
CHANGES(information  => default)
AT (timestamp => 'your-timestamp'::timestamp_tz);


SELECT * FROM SALES_RAW
CHANGES(information  => append_only)
AT (timestamp => 'your-timestamp'::timestamp_tz);






CREATE OR REPLACE TABLE PRODUCTS 
AS
SELECT * FROM SALES_RAW
CHANGES(information  => append_only)
AT (timestamp => 'your-timestamp'::timestamp_tz)


SELECT * FROM PRODUCTS;



QUIZ:
Question 1:
We can directly query from a stream. What is returned if we do so?
All the columns of the original table that have changed & 3 additional columns containing information about the change.

Question 2:
What values can the column METADATA$ACTION contain?
INSERT or DELETE

Question 3:
How can we consume a stream?
Using the stream with an INSERT or CREATE TABLE statement.

Question 4:
What is tracked if APPEND_ONLY option is set to TRUE?
INSERTS only

Question 5:
What happens after a stream is consumed?
The stream will be EMPTY.


====================== Lec 141 - 146: Materialized Views  =======================================
-- Views:
-- • Physically stored table
-- • Always getting updated whenever view executed.
-- × Bad user experience
-- × More compute consumption
-- Whenever we have multiple join statement and we have to run it over and over again in SELECT VIEW statement then performance gets impacted and because of which Bad user experience and more compute consumption is happing and more over to that if there is any change in data we need to manually update it again & again and then store it in table which is causing in Bad user experience and more compute consumption so there comes MATERIALIZED VIEW.

-- Materialized views
-- • We have a view that is queried frequently and that a long time to be processed.
-- • We can create a materialized view to solve that problem.
-- • Improve performance by storing  a data in Materialized table and updating it data on very frequent basis automatically whenever there is change in underline base table it will manage for us.
-- • Little bit of managing cost is associated with this.
-- • Always have updated Data.
-- • Good Performance.

----------------------- Lec 142: Using Materialized View----------------

-- Remove caching just to have a fair test -- Part 1

ALTER SESSION SET USE_CACHED_RESULT=FALSE; -- disable global caching
ALTER warehouse compute_wh suspend;
ALTER warehouse compute_wh resume;



-- Prepare table
CREATE OR REPLACE TRANSIENT DATABASE ORDERS;

CREATE OR REPLACE SCHEMA TPCH_SF100;

CREATE OR REPLACE TABLE ORDERS.TPCH_SF100.ORDERS AS
SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS;

SELECT * FROM ORDERS LIMIT 100;



-- Example statement view -- 
SELECT
YEAR(O_ORDERDATE) AS YEAR,
MAX(O_COMMENT) AS MAX_COMMENT,
MIN(O_COMMENT) AS MIN_COMMENT,
MAX(O_CLERK) AS MAX_CLERK,
MIN(O_CLERK) AS MIN_CLERK
FROM ORDERS.TPCH_SF100.ORDERS
GROUP BY YEAR(O_ORDERDATE)
ORDER BY YEAR(O_ORDERDATE);




-- Create materialized view
CREATE OR REPLACE MATERIALIZED VIEW ORDERS_MV
AS 
SELECT
YEAR(O_ORDERDATE) AS YEAR,
MAX(O_COMMENT) AS MAX_COMMENT,
MIN(O_COMMENT) AS MIN_COMMENT,
MAX(O_CLERK) AS MAX_CLERK,
MIN(O_CLERK) AS MIN_CLERK
FROM ORDERS.TPCH_SF100.ORDERS
GROUP BY YEAR(O_ORDERDATE);


SHOW MATERIALIZED VIEWS; 
// Behind By column shows -> How much time is it behind the last time Materialized view was refreshed.
// Compacted_on -> show time when the item has any DELETE statement.
// Refreshed_on -> Show time when the item has any INSERT statement.


-- Query view
SELECT * FROM ORDERS_MV
ORDER BY YEAR;



----------------------- LEC 143: Refresh Materialized View----------
-- Remove caching just to have a fair test -- Part 2


-- UPDATE or DELETE values
UPDATE ORDERS
SET O_CLERK='ZZClerk' 
WHERE O_ORDERDATE='1992-01-01';





   -- Test updated data --
-- Example statement view -- 
SELECT
YEAR(O_ORDERDATE) AS YEAR,
MAX(O_COMMENT) AS MAX_COMMENT,
MIN(O_COMMENT) AS MIN_COMMENT,
MAX(O_CLERK) AS MAX_CLERK,
MIN(O_CLERK) AS MIN_CLERK
FROM ORDERS.TPCH_SF100.ORDERS
GROUP BY YEAR(O_ORDERDATE)
ORDER BY YEAR(O_ORDERDATE);



-- Query view
SELECT * FROM ORDERS_MV
ORDER BY YEAR;


SHOW MATERIALIZED VIEWS;




-- Note: 
// Even though the MATERIALIZED VIEW take some time to refresh under view but underlining BASE TABLE get REFRESHED immediately because of which it is showing data near to REAL-TIME data.

----------------------- LEC 144: MAINTAINANCE COST------------

-- Even though Snowflake is managing MATERIALIZED VIEW in SERVERLESS way for us there is some maintainance cost associated with it 

SHOW MATERIALIZED VIEWS;



select * from table(information_schema.materialized_view_refresh_history()); -- By default this query only shows 12hr Materialized view so we can also check under UI Admin -> Cost management Section for MATERIALIZED view along with COMPUTE + STOREAGE cost.


SELECT * FROM TABLE (INFORMATION_SCHEMA.MATERIALIZED_VIEW_REFRESH_HISTORY(
                        DATE_RANGE_START => '2026-04-26 01:38:35.202 -0700')
                    );

SELECT CURRENT_TIMESTAMP; -- 2026-04-26 02:38:35.202 -0700

-- Materialized View FORMAT:
                        MATERIALIZED_VIEW_REFRESH_HISTORY
                        [DATE_RANGE_START => <constant_expr> ]
                        [. DATE_RANGE_END => < constant_expr> ]
                        [. MATERIALIZED_VIEW_NAME => '‹string›')


---------------- LEC 145: When to USE MATERIALIZED VIEW -------------

-- When to use MV?
-- ✔️Benefits
-- ✔️ Maintenance costs

-- • View would take a long time to be processed and is used frequently
-- • Underlaying data is change not frequently and on a rather irregular basis

-- • If the data is updated on a very regular basis...
-- Using tasks & streams could be a better alternative


--                 Alternative - streams & tasks
                        
--  Stream Object------> Underlaying Table  ----VIEW /TABLE---->  Final Table
--                             ^                                       ^
--                             |                                       |
--                             ------------   TASK with MERGE  ---------

-- • Don't use materialized view if data changes are very frequent
-- • Keep maintenance cost in mind
-- • Considder leveraging tasks (& streams) instead


--------------------------- LEC 146: LIMITATIONS OF MATERIALIZED VIEW -------

• Only available for Enterprise edition and higher.
× Joins (including self-joins) are not supported
× Limited amount of aggregation functions:
                APPROX_COUNT_DISTINCT (HLL)
                AVG (except when used in PIVOT).
                BITAND_AGG.
                BITOR_AGG.
                BITXOR_AGG.
                COUNT.
                MIN.
                MAX.
                STDDEV.
                STDDEV_POP.
                STDDEV_SAMP.
                SUM.
                VARIANCE (VARIANCE_SAMP, VAR_SAMP) .
                VARIANCE_POP (VAR_POP).
                
× UDFs
× HAVING clauses.
× ORDER BY clause.
×LIMIT clause




====================== Lec 147 - 151 : Data Masking  =======================================
--------------------    Lec 147: Understanding Data Masking-----------
-- Data Masking
-- * done at Column-level Security
-- * get very fine grain control over column level who can see the actual data.

-- val means the value of the colum in which masking is applied

----------------Lec 148: Creating a Masking Policy-------------

USE DEMO_DB;
USE ROLE ACCOUNTADMIN;


-- Prepare table --
create or replace table customers(
  id number,
  full_name varchar, 
  email varchar,
  phone varchar,
  spent number,
  create_date DATE DEFAULT CURRENT_DATE);

-- insert values in table --
insert into customers (id, full_name, email,phone,spent)
values
  (1,'Lewiss MacDwyer','lmacdwyer0@un.org','262-665-9168',140),
  (2,'Ty Pettingall','tpettingall1@mayoclinic.com','734-987-7120',254),
  (3,'Marlee Spadazzi','mspadazzi2@txnews.com','867-946-3659',120),
  (4,'Heywood Tearney','htearney3@patch.com','563-853-8192',1230),
  (5,'Odilia Seti','oseti4@globo.com','730-451-8637',143),
  (6,'Meggie Washtell','mwashtell5@rediff.com','568-896-6138',600);

SELECT * FROM customers;


-- set up roles
CREATE OR REPLACE ROLE ANALYST_MASKED;
CREATE OR REPLACE ROLE ANALYST_FULL;


-- grant select on table to roles
GRANT SELECT ON TABLE DEMO_DB.PUBLIC.CUSTOMERS TO ROLE ANALYST_MASKED;
GRANT SELECT ON TABLE DEMO_DB.PUBLIC.CUSTOMERS TO ROLE ANALYST_FULL;

GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ANALYST_MASKED;
GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ANALYST_FULL;

GRANT USAGE ON DATABASE DEMO_DB TO ROLE ANALYST_MASKED;
GRANT USAGE ON DATABASE DEMO_DB TO ROLE ANALYST_FULL;

-- grant warehouse access to roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_MASKED;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_FULL;


-- assign roles to a user
GRANT ROLE ANALYST_MASKED TO USER SHASHIKANT;
GRANT ROLE ANALYST_FULL TO USER SHASHIKANT;



-- Set up masking policy

create or replace masking policy phone_masking 
    as (val varchar) returns varchar ->
            case        
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else '##-###-##'
            end;
  

-- Apply policy on a specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone 
SET MASKING POLICY phone_masking;




-- Validating policies

USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;


------------------------ Lec 149: Unset & Replace Policy ---------------------

-- * We cannot directly DELETE the MASKED POLICY.
-- * First we need to find the COLUMNS on which MASKED POLICY is applied to using: 
-- SHOW MASKING POLICIES;

-- SELECT * FROM table(information_schema.policy_references(policy_name=>'<masking_policy_name>'));

-- * Once we find the column from above query then we can UNSET the policy.
-- * After that we can create or drop the policy.

-- #### More examples  #####

USE ROLE ACCOUNTADMIN;

--- 1) Apply policy to multiple columns

-- Apply policy on a specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name 
SET MASKING POLICY phone_masking;

-- Apply policy on another specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone
SET MASKING POLICY phone_masking;

USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;



--- 2) Replace or drop policy
USE ROLE ACCOUNTADMIN;

DROP masking policy phone; -- SQL compilation error: Masking policy 'DEMO_DB.PUBLIC.PHONE' does not exist or not authorized.

create or replace masking policy phone_masking as (val varchar) returns varchar ->
            case
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else CONCAT(LEFT(val,2),'*******')
            end;

-- List and describe policies
DESC MASKING POLICY phone_masking;
SHOW MASKING POLICIES;

-- Show columns with applied policies
SELECT * FROM table(information_schema.policy_references(policy_name=>'phone_masking')); -- shows REF_COLUMN_NAME on which masking is applied


-- Remove policy before replacing/dropping 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name 
SET MASKING POLICY phone_masking;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN email
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone
UNSET MASKING POLICY;



-- replace policy
create or replace masking policy names as (val varchar) returns varchar ->
            case
            when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
            else CONCAT(LEFT(val,2),'*******')
            end;

-- apply policy
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
SET MASKING POLICY names;


-- Validating policies
USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;

SHOW MASKING POLICIES;
DROP MASKING POLICY names;
DROP MASKING POLICY phone;
DROP MASKING POLICY phone_masking;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN phone
UNSET MASKING POLICY;


------------------------ Lec 150: Alter an Existing Policy---------------------


-- Alter existing policies 

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;

USE ROLE ACCOUNTADMIN;



alter masking policy phone_masking set body ->
case        
 when current_role() in ('ANALYST_FULL', 'ACCOUNTADMIN') then val
 else '**-**-**'
 end;

            
ALTER TABLE CUSTOMERS MODIFY COLUMN email UNSET MASKING POLICY;


  

------------------------ Lec 151: Real Life Examples---------------------



### More examples - 1 - ###

USE ROLE ACCOUNTADMIN;

create or replace masking policy emails as (val varchar) returns varchar ->
case
  when current_role() in ('ANALYST_FULL') then val
  when current_role() in ('ANALYST_MASKED') then regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked
  else '********'
end;


-- apply policy
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN email
SET MASKING POLICY emails;


-- Validating policies
USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;

USE ROLE ACCOUNTADMIN;


### More examples - 2 - ###


create or replace masking policy sha2 as (val varchar) returns varchar ->
case
  when current_role() in ('ANALYST_FULL') then val
  else sha2(val) -- return hash of the column value
end;



-- apply policy
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
SET MASKING POLICY sha2;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
UNSET MASKING POLICY;


-- Validating policies
USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;

USE ROLE ACCOUNTADMIN;


### More examples - 3 - ###

create or replace masking policy dates as (val date) returns date ->
case
  when current_role() in ('ANALYST_FULL') then val
  else date_from_parts(0001, 01, 01)::date -- returns 0001-01-01 00:00:00.000
end;


-- Apply policy on a specific column 
ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN create_date 
SET MASKING POLICY dates;


-- Validating policies

USE ROLE ANALYST_FULL;
SELECT * FROM CUSTOMERS;

USE ROLE ANALYST_MASKED;
SELECT * FROM CUSTOMERS;


SHOW MASKING POLICIES;


ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN email
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN full_name
UNSET MASKING POLICY;

ALTER TABLE IF EXISTS CUSTOMERS MODIFY COLUMN create_date
UNSET MASKING POLICY;

DROP MASKING POLICY Dates;
DROP MASKING POLICY Emails;
DROP MASKING POLICY Sha2;


====================== Lec 152 - 164: Access Management  =======================================
-- ---------------- Lec 152: Access Control--------------
-- • 
-- ✔️ Who can access and perform operations on objects in Snowflake
-- ✔️ Two aspects of access control combined

--     1. Discretionary Access Control (DAC) : Each object has an owner who can grant access to that object
--     2. Role-based Access Control (RBAC): Access privileges are assigned to roles, which are in turn assigned to users


--                                 GRANT <role>
--                                 TO <user>
--                                                 ↱ User1
--             Creates                    ↱ Role 2 ↳ User2
--     Role1  ----------> Table(Privilege)       
--             Owns                       ↳ Role 3 -> User3
--                         GRANT <privilege>
--                         ON <obeject>
--                         TO <role>


--                                 Securable objects

--                                     Account
--                                       ⬇︎
-- User         Role           Database            Warehouse       Other Account objects
--                                 ⬇︎
--                             Schema
--                                 ⬇︎
-- Table       View            Stage               Integration     Other Schema objects


-- ✔️ Every object owned by a single role (multiple users)
-- ✔️ Owner (role) has all privileges per default


                            
--                             Snowflake Roles
            
--             ACCQUNTADMIN
--        ↱                            ↰
-- SECURITYADMIN                   SYSADMIN
--      ↑
-- USERADMIN
--     ⤴︎
--     PUBLIC



--                         Key concepts
-- USER : People or systems
-- ROLE: Entity to which privileges are granted (role hierarchy)
-- PRIVILEGE: Level of access to an object (SELECT, DROP, CREATE etc.)
-- SECURABLE OBJECT: Objects to which privileges can be granted (Database, Table, Warehouse etc.)


-- --------------------- Lec 153: Roles Overview -------------------

-- 5 system defined role are in Hierarchy

--                             Snowflake Roles
            
--             ACCQUNTADMIN
--        ↱                            ↰
-- SECURITYADMIN                   SYSADMIN       ↰
--      ↑                              ↑         Custom Role 2 
-- USERADMIN                       Custom Role1
--     ⤴︎
--     PUBLIC



-- ACCOUNTADMIN

-- • SYSADMIN and SECURITYADMIN
-- • top-level role in the System.
-- • should be granted only to a limited number of users

-- SECURITYADMIN

-- • USERADMIN role is granted to SECURITYADMIN.
-- • Can manage users and roles
-- • Can manage any object grant globally

-- SYSADMIN
-- • Create warehouses and databases (and more objects)
-- • Recommended that all custom roles are assigned.

-- USERADMIN
-- • Dedicated to user and role management only.
-- • Can create users and roles.

-- PUBLIC
-- • Automatically granted to every user
-- • Can create own objects like every other role (available to every other user/role.



-- ---------------- Lec 154: ACCOUNTADMIN ----------------------

-- The closest to ACCOUNTADMIN is the SECURITYADMIN but privelages like creating warehouse and seeing the Consumption is not visible to SECURITYADMIN.


--- User 1 ---
CREATE USER maria PASSWORD = '123' 
DEFAULT_ROLE = ACCOUNTADMIN 
MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE ACCOUNTADMIN TO USER maria;


--- User 2 ---
CREATE USER frank PASSWORD = '123' 
DEFAULT_ROLE = SECURITYADMIN 
MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE SECURITYADMIN TO USER frank;


--- User 3 ---
CREATE USER adam PASSWORD = '123' 
DEFAULT_ROLE = SYSADMIN 
MUST_CHANGE_PASSWORD = TRUE;
GRANT ROLE SYSADMIN TO USER adam;

------------------------- Lec 155: AccountAdmin in Practice ----------


-- ACCOUNTADMIN

-- ✔️  Account admin tab
-- ✔️ Billing & Usage: Only available for ACCOUNTADMIN.
-- ✔️ Reader Account : Only available for ACCOUNTADMIN.
-- ✔️ Multi-Factor Authentification: uses CISCO DUO app
-- ✔️ Create other users


----------------------- Lec 156: SecurityAdmin -----------------

-- SECURITYADMIN

-- ✔️ Account admin tab : SECURITYADMIN has also access to ACCOUNTADMIN tab but in a very limited way.
-- ✔️ Create & manage users and roles
-- ✔️ Grant and revoke privileges to roles


----------------------- Lec 157: SecurityAdmin in Practice -------------


-- SECURITYADMIN
-- Manage any object grant globally
-- ✔️ MANAGE GRANTS privilege
-- ✔️ Create, monitor, and manage users & roles
-- ✔️ Inherits USERADMIN privileges


--                             Snowflake Roles
            
--             ACCQUNTADMIN
--        ↱                            ↰
-- SECURITYADMIN                   SYSADMIN       
--      ↑                                   ↑      
-- USERADMIN                          Sales Admin Role     HR Admin Role
--     ⤴︎                                    ↑                   ↑ 
--     PUBLIC                          Sales Role              HR Role


-- SECURITYADMIN role --
--  Create and Manage Roles & Users --

-- Use Incognito mode as USER frank(SecurityAdmin) and then run the below query inside that.

-- Create Sales Roles & Users for SALES--
create role sales_admin;
create role sales_users;

-- Create hierarchy
grant role sales_users to role sales_admin;

-- As per best practice assign roles to SYSADMIN
grant role sales_admin to role SYSADMIN;


-- create sales user
CREATE USER simon_sales PASSWORD = '123' DEFAULT_ROLE =  sales_users 
MUST_CHANGE_PASSWORD = TRUE;
GRANT ROLE sales_users TO USER simon_sales;

-- create user for sales administration
CREATE USER olivia_sales_admin PASSWORD = '123' DEFAULT_ROLE =  sales_admin
MUST_CHANGE_PASSWORD = TRUE;
GRANT ROLE sales_admin TO USER  olivia_sales_admin;

-----------------------------------

-- Create Sales Roles & Users for HR--

create role hr_admin;
create role hr_users;

-- Create hierarchy
grant role hr_users to role hr_admin;

-- This time we will not assign roles to SYSADMIN (against best practice)
-- grant role hr_admin to role SYSADMIN;


-- create hr user
CREATE USER oliver_hr PASSWORD = '123' DEFAULT_ROLE =  hr_users 
MUST_CHANGE_PASSWORD = TRUE;
GRANT ROLE hr_users TO USER oliver_hr;

-- create user for sales administration
CREATE USER mike_hr_admin PASSWORD = '123' DEFAULT_ROLE =  hr_admin
MUST_CHANGE_PASSWORD = TRUE;
GRANT ROLE hr_admin TO USER mike_hr_admin;



-------------- Lec 158: SYSADMIN --------------------

-- ✔️ Create & manage objects
-- ✔️ Create & manage warehouses, databases, tables etc.
-- ✔️ Custom roles should be assigned to the SYSADMIN role as the parent.
-- Then this role also has the ability to grant privileges on warehouses, databases, and other objects to the custom roles.


-------------- Lec 159: SYSADMIN in Practice --------------------

-- SYSADMIN --
-- Create warehouses, databases & other objects
-- ✔️ All custom roles should be assigned to
-- ✔️ Can grant privileges on warehouses, databases, and other objects

-- Then SYSADMIN role also has the ability to grant privileges on warehouses, databases, and other objects to the custom roles.

-- ## log into new user as "adam" & password "123" on snowflake as SYSADMIN then run the below query.

-- Create a warehouse of size X-SMALL
create warehouse public_wh with
warehouse_size='X-SMALL'
auto_suspend=300 
auto_resume= true;

-- grant usage to role public
grant usage on warehouse public_wh 
to role public;

-- create a database accessible to everyone
create database common_db;
grant usage on database common_db to role public;

-- create sales database for sales
create database sales_database;
grant ownership on database sales_database to role sales_admin;
grant ownership on schema sales_database.public to role sales_admin;

SHOW DATABASES;


-- create database for hr
create database hr_db;
-- drop database hr_db;
grant ownership on database hr_db to role hr_admin;
grant ownership on schema hr_db.public to role hr_admin; -- gets error since the hr_db has already given grant to hr_admin and hr_admin is not linked to SYSADMIN so it gets an error.

-------------- Lec 160: Custom Roles ---------------

-- ✔️ Customize roles to our needs & create own hierarchies
-- ✔️ Custom roles are usually created by SECURITYADMIN or USERADMIN
-- ✔️ Should be leading up to the SYSADMIN role


-- Execute the below query using user as "adam" in new window

USE ROLE SALES_ADMIN;
USE SALES_DATABASE;

-- Create table --
create or replace table customers(
  id number,
  full_name varchar, 
  email varchar,
  phone varchar,
  spent number,
  create_date DATE DEFAULT CURRENT_DATE);

-- insert values in table --
insert into customers (id, full_name, email,phone,spent)
values
  (1,'Lewiss MacDwyer','lmacdwyer0@un.org','262-665-9168',140),
  (2,'Ty Pettingall','tpettingall1@mayoclinic.com','734-987-7120',254),
  (3,'Marlee Spadazzi','mspadazzi2@txnews.com','867-946-3659',120),
  (4,'Heywood Tearney','htearney3@patch.com','563-853-8192',1230),
  (5,'Odilia Seti','oseti4@globo.com','730-451-8637',143),
  (6,'Meggie Washtell','mwashtell5@rediff.com','568-896-6138',600);
  
SHOW TABLES;

-- query from table --
SELECT* FROM CUSTOMERS;
USE ROLE SALES_USERS;
SELECT* FROM CUSTOMERS; -- not able to see because we have not given him the privilega to see the Database, scehma's and table yet.

-- grant usage to role
USE ROLE SALES_ADMIN;

GRANT USAGE ON DATABASE SALES_DATABASE TO ROLE SALES_USERS;
GRANT USAGE ON SCHEMA SALES_DATABASE.PUBLIC TO ROLE SALES_USERS;
GRANT SELECT ON TABLE SALES_DATABASE.PUBLIC.CUSTOMERS TO ROLE SALES_USERS;


-- Validate privileges --
USE ROLE SALES_USERS;
SELECT* FROM CUSTOMERS;
DROP TABLE CUSTOMERS;
DELETE FROM CUSTOMERS;
SHOW TABLES;

-- grant DROP on table
USE ROLE SALES_ADMIN;
GRANT DELETE ON TABLE SALES_DATABASE.PUBLIC.CUSTOMERS TO ROLE SALES_USERS;


USE ROLE SALES_ADMIN;


---------------- Lec 161: Custom Role in Practice --------------------

-- Run the below query of Lec 161 as ADAM in new window.
USE ROLE SALES_ADMIN;
USE SALES_DATABASE;

-- Create table --
create or replace table customers(
  id number,
  full_name varchar, 
  email varchar,
  phone varchar,
  spent number,
  create_date DATE DEFAULT CURRENT_DATE);

-- insert values in table --
insert into customers (id, full_name, email,phone,spent)
values
  (1,'Lewiss MacDwyer','lmacdwyer0@un.org','262-665-9168',140),
  (2,'Ty Pettingall','tpettingall1@mayoclinic.com','734-987-7120',254),
  (3,'Marlee Spadazzi','mspadazzi2@txnews.com','867-946-3659',120),
  (4,'Heywood Tearney','htearney3@patch.com','563-853-8192',1230),
  (5,'Odilia Seti','oseti4@globo.com','730-451-8637',143),
  (6,'Meggie Washtell','mwashtell5@rediff.com','568-896-6138',600);
  
SHOW TABLES;

-- query from table --
SELECT* FROM CUSTOMERS;
USE ROLE SALES_USERS;

-- grant usage to role
USE ROLE SALES_ADMIN;  -- Data does not show because of which need to grant permission on table.

GRANT USAGE ON DATABASE SALES_DATABASE TO ROLE SALES_USERS;
GRANT USAGE ON SCHEMA SALES_DATABASE.PUBLIC TO ROLE SALES_USERS;
GRANT SELECT ON TABLE SALES_DATABASE.PUBLIC.CUSTOMERS TO ROLE SALES_USERS;


-- Validate privileges --
USE ROLE SALES_USERS;
SELECT* FROM CUSTOMERS;
DROP TABLE CUSTOMERS;
DELETE FROM CUSTOMERS;
SHOW TABLES;

-- grant DROP on table
USE ROLE SALES_ADMIN;
GRANT DELETE ON TABLE SALES_DATABASE.PUBLIC.CUSTOMERS TO ROLE SALES_USERS;


USE ROLE SALES_ADMIN;


---------------------- Lec 162: USERADMIN ----------------------------

-- ✔️ Create Users & Roles (User & Role Management)
-- ✔️ Not for granting privileges (only the one that is owns)

---------------------- Lec 163: USERADMIN in practice ---------------------------

-- • Dedicated to user and role management
-- ✔️ CREATE USER & CREATE ROLE privileges
-- ✔️ Can mange users and roles that are owned

-- USERADMIN --

USE ROLE USERADMIN;

--- User 4 ---
CREATE USER ben PASSWORD = '123' 
DEFAULT_ROLE = ACCOUNTADMIN 
MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE HR_ADMIN TO USER ben; -- unable to grant peromission to HR_ADMIN as this was created by SYSADMIN. So SYSADMIN has privilege to grant the access. 

SHOW ROLES;

GRANT ROLE HR_ADMIN TO ROLE SYSADMIN;


--------------------- Lec 164: PUBLIC ROLE------------------

-- ✔️ Least privileged role (bottom of hierarchy)
-- ✔️ Every user is automatically assigned to this role
-- ✔️ Can own objects
-- ✔️ These objects are then available to everyone

USE ROLE SYSADMIN; -- since PUBLIC does not have permission to create database so we need to do it as SYSADMIN.

CREATE OR REPLACE DATABASE PUBLIC_DB;

SHOW DATABASES;

USE ROLE SYSADMIN;
USE ROLE PUBLIC;

SHOW DATABASES;

USE ROLE SYSADMIN;

CREATE OR REPLACE DATABASE PUBLIC_DB;
GRANT OWNERSHIP ON DATABASE PUBLIC_DB TO ROLE PUBLIC;

DROP DATABASE PUBLIC_DB;








====================== Lec 165-167 - Visualization : Power BI & Tableau  =======================================
----------------------- Lec 165: Data Visualization -----------------

----------------------- Lec 166: Download & Install Power Bi -----------------

----------------------- Lec 167: Connect Power BI to Snowflake --------------


Snowflake -> Account -> Copy Account URL ->  Account/Server URL: GSKILPG-DA72431.snowflakecomputing.com
Power BI -> Get Data -> Database -> Snowflake -> Account/Server URL: GSKILPG-DA72431.snowflakecomputing.com and then select the WAREHOUSE we want to work. -> Connect -> Enter the USERNAME and PASSWORD for verification -> CONNECT -> Load Data / Transform Data in Power BI. -> Connection Setting -> Choose "DirectQuery" to use Snowflake DWH or else want locally in system we can select Import for smaller amount of data. -> Ok


----------------------- Lec 167: Connect TABLEAU to Snowflake --------------

Under "To A Server" -> More -> Search for Snowflake -> Account/Server URL: GSKILPG-DA72431.snowflakecomputing.com -> Role (Optional) -> USERNAME = ADAM, PASSWORD ='123' -> Sign IN





====================== Lec 173: Best Practices  =======================================
-- ------------------------------ Lec 173: Best Practices -------------
-- • Optimize storage cost and performance.

-- Best practices
-- ✔️ Warehouses
-- ✔️ Table design
-- ✔️ Monitoring
-- ✔️ Retention period

-- ------------------------------ Lec 174: Warehouse Usage -------------

-- Warehouse
-- • Best Practice #1 - Enable Auto-Suspend : When the auto-suspend happens then catching gets cleared so in order to utilize maximum caching we should enable auto-suspend based on work load pattern.
-- • Best Practice #2 - Enable Auto-Resume
-- • Best Practice #3 - Set appropriate timeouts

--                 ETL / Data Loading      BI / SELECT queries     DevOps / Data Science      
-- Auto-Suspend        Immediately             10 min                  
-- 5 min

-- • Best Practice #4 - Choose size based on workload: 



-- CREATE OR REPLACE WAREHOUSE my_warehouse
-- WAREHOUSE_SIZE = 'SMALL'
-- MAX_CLUSTER_COUNT = 1
-- MIN_CLUSTER_COUNT = 3
-- SCALING_POLICY = ECONOMY
-- AUTO_SUSPEND = 1   
-- AUTO_RESUME = TRUE:

-- Notes:
-- --- Lowest value we can use for Auto-Suspend is 1.
-- -- Auto-Suspend = 0 OR NULL is for disabling auto-suspend.
-- -- auto-suspend is generally in the range of few minutes.


-- ------------------------------ Lec 175: Table Design-------------

-- Table design
-- ✔️ Best Practice #1 - Appropiate table type
--             • Staging tables - Transient
--             • Productive tables Permanent
--             • Development tables - Transient

-- ✔️ Best Practice #2 - Appropiate data type
-- ✔️ Best Practice #3 - Since Snowflake already manages the Micropartition so we can SET Cluster key only if Necessary
--             • Large table
--             • Most query time for table scan
--             • Dimensions Table: Dimensions which are frequently queried can be benefited with CLUSTER key. Suppose we have date column but we query based on region column in that case Cluster key can be beneficial.


------------------------------ Lec 176: Monitoring -------------
USE ROLE ACCOUNTADIN;

-- Table Storage

SELECT * FROM "SNOWFLAKE"."ACCOUNT_USAGE"."TABLE_STORAGE_METRICS";

-- How much is queried in databases
SELECT * FROM "SNOWFLAKE"."ACCOUNT_USAGE"."QUERY_HISTORY";

SELECT 
DATABASE_NAME,
COUNT(*) AS NUMBER_OF_QUERIES,
SUM(CREDITS_USED_CLOUD_SERVICES)
FROM "SNOWFLAKE"."ACCOUNT_USAGE"."QUERY_HISTORY"
GROUP BY DATABASE_NAME;


-- Usage of credits by warehouses
SELECT * FROM "SNOWFLAKE"."ACCOUNT_USAGE"."WAREHOUSE_METERING_HISTORY";

-- Usage of credits by warehouses // Grouped by day
SELECT 
DATE(START_TIME),
SUM(CREDITS_USED)
FROM "SNOWFLAKE"."ACCOUNT_USAGE"."WAREHOUSE_METERING_HISTORY"
GROUP BY DATE(START_TIME);

-- Usage of credits by warehouses // Grouped by warehouse
SELECT
WAREHOUSE_NAME,
SUM(CREDITS_USED)
FROM "SNOWFLAKE"."ACCOUNT_USAGE"."WAREHOUSE_METERING_HISTORY"
GROUP BY WAREHOUSE_NAME;

-- Usage of credits by warehouses // Grouped by warehouse & day
SELECT
DATE(START_TIME),
WAREHOUSE_NAME,
SUM(CREDITS_USED)
FROM "SNOWFLAKE"."ACCOUNT_USAGE"."WAREHOUSE_METERING_HISTORY"
GROUP BY WAREHOUSE_NAME,DATE(START_TIME);


------------------------------ Lec 177: Retention Period -------------

Retention period
• Best Practice #1: Staging database - 0 days (transient)
• Best Practice #2 - Production - 4-7 days (1 day min)
• Best Practice #3 - Large high-churn tables - 0 days (transient)

• Best Practice #3 - Large high-churn tables - 0 days

            Active          Time Travel             Fail Safe
Timeout     20GB                400GB                  2.8TB







====================== Lec 29:  =======================================


====================== Lec 29:  =======================================


====================== Lec 29:  =======================================


====================== Lec 29:  =======================================


====================== Lec 29:  =======================================


====================== Lec 29:  =======================================


====================== Lec 29:  =======================================