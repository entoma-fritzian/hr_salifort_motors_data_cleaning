SELECT * FROM salifort_motors.dataset;
-- Create a staging table to separate the raw dataset
CREATE TABLE stg_table AS 
SELECT * FROM dataset;

-- Check data types and change abnormal datatypes
-- Standardize name header per columns to snake_case
ALTER TABLE stg_table
CHANGE Work_accident  work_accident INT,
CHANGE Department  dept TEXT
;

-- Check for inconsistent data values
SELECT dept, count(dept) 
FROM salifort_motors.stg_table
GROUP BY dept;

SELECT salary, count(salary) 
FROM salifort_motors.stg_table
GROUP BY salary;
-- No inconsistency found, if ever there are inconsistencies we will use [UPDATE SET] query

-- Finding nulls 
-- Since these are 10 multiple fields, looking for null values in each fields is repetitive
-- My goal is to concatenate all fields into a single id and when null is detected in anyfield it will be labeled as null in string id
-- So the string has '%nulls%' then it will return as TRUE, else the dataset is complete.
WITH cleaned AS (SELECT  *, concat_ws
				('**', 
				IFNULL (satisfaction_level,'[null]'),
				IFNULL (last_evaluation, '[null]'),
				IFNULL (number_project, '[null]'), 
				IFNULL (average_montly_hours, '[null]'), 
				IFNULL (time_spend_company,'[null]'), 
				IFNULL (work_accident, '[null]'),
				IFNULL (`left`, '[null]'), 
				IFNULL (promotion_last_5years,'[null]'),
				IFNULL (dept,'[null]'),
				IFNULL (salary,'[null]')
				) AS string_id
				FROM stg_table)
SELECT *, string_id LIKE '%[null]%' as has_null
FROM cleaned
ORDER BY has_null DESC;
-- NO NULLS detected so we are safe. The dataset is completely filled all values in 'had_null' are zero

-- Find missing values

-- Find duplicates using the string_id we generated, use row_number on string_id and delete duplicates where row_number is greater than 1
CREATE TABLE remove_duplicate AS
WITH cleaned AS (SELECT  *, concat_ws
				('**', 
				IFNULL (satisfaction_level,'[null]'),
				IFNULL (last_evaluation, '[null]'),
				IFNULL (number_project, '[null]'), 
				IFNULL (average_montly_hours, '[null]'), 
				IFNULL (time_spend_company,'[null]'), 
				IFNULL (work_accident, '[null]'),
				IFNULL (`left`, '[null]'), 
				IFNULL (promotion_last_5years,'[null]'),
				IFNULL (dept,'[null]'),
				IFNULL (salary,'[null]')
				) AS string_id
				FROM stg_table),
		rn AS (SELECT *,
				ROW_NUMBER() OVER(PARTITION BY string_id) AS row_num
				FROM cleaned) 
SELECT *
FROM rn
WHERE row_num = 1;

-- We verify stg_table3 with another query on duplicates. Returns should be 11991 rows 

WITH stg_b AS (SELECT *,
				ROW_NUMBER() OVER(PARTITION BY satisfaction_level, last_evaluation, number_project, average_montly_hours, time_spend_company, work_accident, `left`, promotion_last_5years, dept, salary) row_id
				FROM salifort_motors.stg_table)
SELECT *
FROM stg_b
WHERE row_id = 1;
-- The duplicates are validates, results shows 11991 rows returned

-- Remove outliers using Inter-quartile range.
-- Profile fields that might possibly have outliers 
SELECT min(average_montly_hours), max(average_montly_hours), avg(average_montly_hours), sum(average_montly_hours)
FROM remove_duplicate;

SELECT average_montly_hours, 
					(average_montly_hours - AVG(average_montly_hours) OVER())/ stddev(average_montly_hours) OVER() as zscore
					from remove_duplicate;

SELECT min(time_spend_company), max(time_spend_company), avg(time_spend_company), sum(time_spend_company)
FROM remove_duplicate;

-- Detect Extreme Outliers in average_hours using z-scores 
-- Finalize the cleaned dataset with a table for backup. 
CREATE TABLE final_table AS
WITH zs_scores AS (SELECT *,
				(average_montly_hours - AVG(average_montly_hours) OVER())/ stddev(average_montly_hours) OVER() as zs_h,
                (time_spend_company - AVG(time_spend_company) OVER())/ stddev(time_spend_company) over() as zs_y
			FROM remove_duplicate)
SELECT 	string_id, 
		satisfaction_level, 
		last_evaluation, 
		number_project, 
		average_montly_hours, 
		time_spend_company, 
		work_accident,
		`left`, 
		promotion_last_5years, 
		dept, 
		salary,
        zs_h,
        zs_y

FROM zs_scores
WHERE zs_h <=3 AND zs_h >=-3
AND zs_y <=3 AND zs_y >=-3
ORDER BY zs_h DESC;

-- The dataset is now ready for the next stage.

