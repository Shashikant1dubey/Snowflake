  -------------------- Stream example: STALENESS ------------------------

SHOW STREAMS;

DESC STREAM sales_stream;




-- View Retention time

SHOW PARAMETERS IN TABLE sales_raw_staging;


-- Change retention time

ALTER TABLE sales_raw_staging
SET MAX_DATA_EXTENSION_TIME_IN_DAYS = 14;