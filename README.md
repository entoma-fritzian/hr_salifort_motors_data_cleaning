# Data-Cleaning-Procedures-SQL-Project

## Salifort Motors Employee Data Cleaning Project

### Overview
This project focuses on cleaning and preparing the Salifort Motors employee dataset using SQL in MySQL Workbench.

The main objective of this project is to apply foundational data cleaning techniques commonly used in real-world analytics workflows.

This project includes:

- Creating staging tables
- Standardizing column names
- Checking inconsistent categorical values
- Detecting null values
- Removing duplicate records
- Detecting outliers using Z-score methodology
- Building a finalized cleaned dataset ready for analysis

This project also represents my hands-on SQL applications beyond tutorial-based learning.

✅ Final SQL script: [salifort_dataset final ver. after cleaning](https://github.com/entoma-fritzian/Data-Cleaning-HR-Salifort-Motors-/blob/main/salifort_motors_cleaned_ready.sql) 

### Final Data Structure
| Column Name            | Data Type |
|-------------------------|----------|
| string_id	          | TEXT     |
| satisfaction_level      | DOUBLE   |
| last_evaluation         | DOUBLE   |
| number_project          | INT	     |
| average_montly_hours    | INT      |
| time_spend_company      | INT      |
| work_accident           | INT	     |
| left	                  | INT	     |
| promotion_last_5years   | INT	     |
| dept			  | TEXT     |
| salary		  | TEXT     |


✅ Salifort Motors dataset available: [salifort.csv](https://github.com/entoma-fritzian/Data-Cleaning-HR-Salifort-Motors-/blob/main/HR_Salifort%20Motors_dataset.csv)

### Data Cleaning Steps (with example SQL)

### 1. Create staging table and duplicate data
-- Purpose: Preserve raw data for safe cleaning
```sql
CREATE TABLE stg_table AS
SELECT *
FROM dataset;
```

### 2. Standardize Column Names

Column names were standardized into snake_case naming convention.

```sql
ALTER TABLE stg_table
CHANGE Work_accident work_accident INT,
CHANGE Department dept TEXT;
```

---

### 3. Check for Inconsistent Values

Categorical fields were checked for inconsistencies.

```sql
SELECT dept, COUNT(dept)
FROM stg_table
GROUP BY dept;

SELECT salary, COUNT(salary)
FROM stg_table
GROUP BY salary;
```

Result

- No major inconsistencies were found.

---

### 4. Detect Null Values

To simplify multi-column null detection, a concatenated "string_id" was created using "CONCAT_WS()" and "IFNULL()".

```sql
WITH cleaned AS (

    SELECT *,

    CONCAT_WS(
        '**',

        IFNULL(satisfaction_level,'[null]'),
        IFNULL(last_evaluation,'[null]'),
        IFNULL(number_project,'[null]'),
        IFNULL(average_montly_hours,'[null]'),
        IFNULL(time_spend_company,'[null]'),
        IFNULL(work_accident,'[null]'),
        IFNULL(left,'[null]'),
        IFNULL(promotion_last_5years,'[null]'),
        IFNULL(dept,'[null]'),
        IFNULL(salary,'[null]')

    ) AS string_id

    FROM stg_table
)

SELECT *,
       string_id LIKE '%[null]%' AS has_null
FROM cleaned;
```

Result

- No null values were detected in the dataset.

---

### 5. Remove Duplicate Records

Duplicates were identified using "ROW_NUMBER()" partitioned by the generated "string_id".

```sql
ROW_NUMBER() OVER(
    PARTITION BY string_id
) AS row_num```

Rows with "row_num = 1" were retained.

Result

- Final deduplicated dataset contains 11,991 rows.
```

---

### 6. Profile Potential Outlier Fields

Numeric fields were profiled using aggregate statistics.

```sql
SELECT
    MIN(average_montly_hours),
    MAX(average_montly_hours),
    AVG(average_montly_hours)
FROM remove_duplicate;

SELECT
    MIN(time_spend_company),
    MAX(time_spend_company),
    AVG(time_spend_company)
FROM remove_duplicate;
```

---

### 7. Detect and Remove Outliers Using Z-Score

```sql
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
		salary

FROM zs_scores
WHERE zs_h <=3 AND zs_h >=-3
AND zs_y <=3 AND zs_y >=-3
ORDER BY zs_h DESC;
```

Result

- Extreme outliers were removed from the dataset.

---

### Results Preview

Key outcomes from the cleaning workflow:

- Standardized column naming convention
- Verified categorical consistency
- Confirmed absence of null values
- Removed duplicate records
- Identified and filtered outliers
- Created a finalized cleaned dataset ("final_table") ready for analysis

Learning through application, iteration, and continuous improvement.
✅ Full SQL script available: [SQL Data Cleaning Salifort_Motors Project Script](https://github.com/entoma-fritzian/Data-Cleaning-HR-Salifort-Motors-/blob/main/salifort_motors_cleaned_ready.sql)


---

### Assumptions and Caveats

- Z-score threshold of ±3 was used to detect extreme outliers.
- The dataset is assumed to approximately follow normal distribution behavior for Z-score application.
- "CONCAT_WS()" was used as a simplified approach for detecting null values across multiple fields.
- No missing values were detected during inspection.
- The project focuses on SQL-based cleaning workflows only.

---

### Tools Used

- MySQL Workbench
- SQL
- Kaggle
- ChatGPT

---

### Author

FRITZ IAN ENTOMA

Aspiring Data Analyst focused on:

- SQL
- Data Cleaning
- Data Analytics
- Business Intelligence
- Power Query

GitHub Profile: https://github.com/YOUR-USERNAME
