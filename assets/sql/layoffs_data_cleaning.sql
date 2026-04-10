-- Data Cleaning

SELECT *
FROM layoffs_data;

-- Data cleaning pathway
-- 0. Copy raw dataset
	-- Dataset will be changed, so retaining a raw version is useful.
    -- Never work on the only copy of the raw data. It is not best practice.
-- 1. Remove Duplicates
	-- Usually first step when cleaning data
-- 2. Standardise data
	-- Removes issues with spelling errors, etc.
-- 3. Null/blank values
	-- Lots of null/blank. Will try to populate these fields
-- 4. Remove unncessary columns and rows
	-- There are instances when you should and shouldn't do this. 

-- Creating copy of raw dataset.
CREATE TABLE layoffs_staging
LIKE layoffs_data;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs_data;

-- Checking for duplicates
SELECT * 
FROM layoffs_staging;

-- Adding new colum called row_num. Adds a column to right. First instance of each company is 1. Any duplicate rows are >1.
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Creating temporary table (CTE) to store all row numbers >1. This is to see how many duplicates there are.
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num >1;

-- There were two duplicates. We will create a layoffs_staging2, and delete the duplicates from that table.alter

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Now we have an empty layoffs_staging2 table. need to insert data now.

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Now duplicates will be deleted from layoffs_staging2
DELETE
FROM layoffs_staging2
WHERE row_num>1;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Standardising data
-- Involves finding issues in the data, then fixing it
-- First step, trim leading spaces

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Now we will standardise the industries column. Lots of duplicates, nulls, blanks, varied spellings, etc.
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- Identified cryptocurreny companies have duplicates

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Now checking for discrepencies in country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER by 1;

-- Identified 'United States' and 'United States.'

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- Trick of the trade = Use TRIM (which normally just removes spaces, but use trailing function and specify full stop to clear full stop from value.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Confirmed this has been fixed (it has)
SELECT DISTINCT country
FROM layoffs_staging2
ORDER by 1;

-- Fixing date format from text to datetime for later time series manipulation
SELECT *
FROM layoffs_staging2;

SELECT `date`,
STR_TO_DATE(`date`, '%d/%m/%Y') -- This is the standard date format
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%d/%m/%Y');

-- Checking it was fixed (it was)
SELECT `date`
FROM layoffs_staging2;

-- Changing variable type from text (in date format) to the actual date format.
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Onto step 3, fixing nulls/blanks
-- Identified where companies had null values for total laid off, and percentage laid off (therefore making their rows useless).
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Now checking industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- AirBNB has two rows, one with blank value and one with travel as the industry. Will aim to fill the cells of a company's industry with another row with the same company name, but with industry filled in.
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company -- company needs to be the same
	AND t1.location = t2.location -- as above
WHERE t1.industry IS NULL OR t1.industry = ''
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Most now filled in. Only one company with industry not filled in. Will leave as a null, since we do not know the industry.
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Now removing rows where total_laid_off, and percentage_laid_off are both empty. No way to deduce what these can be if both are missing from the dataset.
-- We will need to use these variables a lot in eda, and we dont even know if these companies had a layoff or not. Probably safe to delete.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- checking current state of dataset
SELECT *
FROM layoffs_staging2;

-- need to delete row_num column

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;