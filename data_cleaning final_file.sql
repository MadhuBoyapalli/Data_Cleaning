

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. 
--We want a table with the raw data in case something happens
SELECT * 
--INTO layoffs_stagging2
FROM [dbo].[layoffs];


SELECT * FROM layoffs_stagging2;

--> now when we are data cleaning we usually follow a few steps
--1) Handling Missing Values/Nulls
--2)Remove Duplicates
--3)Standardzing Text 
--4)Correct Inconsistent Data
--5)Delete Unawanted Columns and Rows

-----------------------------------------------------------------------
--->(1)Handling Missing Values

--I have spot null's in 3 columns we need to replace that 0.

SELECT *,
ISNULL(total_laid_off,0)
FROM layoffs_stagging2

UPDATE layoffs_stagging2
SET total_laid_off=ISNULL(total_laid_off,0)


SELECT ISNULL(funds_raised_millions,0)
FROM layoffs_stagging2

UPDATE layoffs_stagging2
SET funds_raised_millions=ISNULL(funds_raised_millions,0)
WHERE funds_raised_millions IS NULL


SELECT *,
ISNULL(percentage_laid_off,0)
FROM layoffs_stagging2

UPDATE layoffs_stagging2
SET percentage_laid_off=ISNULL(percentage_laid_off,0)

------------------------------------------------------------------------

	
--->let's check for duplicates

--->(2)Remove Duplicates

-- one solution, which I think is a good one is to create a new column and add those row numbers in. 

---Created a new table including row_number.

/****** Object:  Table [dbo].[layoffs_stagging2]    Script Date: 12/10/2024 3:18:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[layoffs_stagging_data](
	[company] [nvarchar](50) NOT NULL,
	[location] [nvarchar](50) NOT NULL,
	[industry] [nvarchar](50) NULL,
	[total_laid_off] [smallint] NULL,
	[percentage_laid_off] [varchar](15) NULL,
	[date] [varchar](15) NULL,
	[stage] [nvarchar](50) NOT NULL,
	[country] [nvarchar](50) NOT NULL,
	[funds_raised_millions] [varchar](50) NULL,
	[row_num] [INT]
) ON [PRIMARY]
GO

--Inserted all values into the table along with row_numbers.

INSERT INTO [dbo].[layoffs_stagging_data]
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY
company,
location,
industry,
country,
funds_raised_millions,
total_laid_off,
percentage_laid_off,
date,
stage
ORDER BY COMPANY) as row_num
FROM layoffs_stagging2;

--After inserting values into table. Now we are ready to delete values with row_num greater than 2.
-- so let's do it!!

DELETE FROM layoffs_stagging_data
WHERE row_num >1

------------------------------------------------------------------------

--->3)Standardzing Text 

--lets remove trailing and leading spaces using TRIM()


SELECT TRIM (company) FROM  layoffs_stagging2

UPDATE layoffs_stagging2
SET company=TRIM (company);

--I have observed a multiple variations in Crypto. We need to standardize that.

SELECT *  FROM layoffs_stagging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_stagging2
SET industry= 'Crypto'
WHERE industry LIKE 'Crypto%';

--While looking into each columns in country column some countries are named as "United States" while other are "United States". 
--We need to remove Trailing "."


SELECT DISTINCT(country ), TRIM(TRAILING '.' FROM  country)
FROM  layoffs_stagging2
ORDER BY country ASC;

UPDATE  layoffs_stagging2
SET country=TRIM(TRAILING '.' FROM  country)
WHERE country LIKE 'United States%'

---------------------------------------------------------------------------

--->(4)Correct Inconsistent Data

-->To represent that amount is in millions. We need to add  "M" for funds_raised_millions column.


SELECT CONCAT(funds_raised_millions,' M')
FROM layoffs_stagging2
WHERE funds_raised_millions!=0;

UPDATE layoffs_stagging2
SET funds_raised_millions= CONCAT(funds_raised_millions,' M')
WHERE funds_raised_millions!=0

-->"%" for percentage_laid_off column.

SELECT CONCAT(percentage_laid_off,'%')
FROM layoffs_stagging2
WHERE percentage_laid_off !=0

UPDATE  layoffs_stagging2
SET  percentage_laid_off=CONCAT(percentage_laid_off,'%')
WHERE percentage_laid_off !=0


----------------------------------------------------------------------------

--Alter Table

--Change data types as per requirement.

ALTER TABLE layoffs_stagging2
ALTER COLUMN [percentage_laid_off]  VARCHAR(15)


----------------------------------------------------------------------------------
	
-->(5)Delete Unawanted Columns and Rows

--Delete Row
--Delete values that really useless.

BEGIN TRANSACTION

DELETE  FROM layoffs_stagging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

COMMIT TRANSACTION

	
-- Delete column
--finally,we need to delete  row_numb column that we have added to remove duplicates.

BEGIN TRANSACTION

ALTER TABLE layoffs_stagging_data
DROP COLUMN row_num;

COMMIT TRANSACTION


