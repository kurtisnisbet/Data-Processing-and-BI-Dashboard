SELECT *
FROM layoffs_staging2;

-- Exploring if companies had the large layoffs
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Seeing which companies these are
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1;

-- Seeing which companies had the most funding but still had layoffs
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Seeing companies with the largest number of people laid off
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Seeing date range of dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Seeing industry with the largest number of people laid off
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Seeing which countries had the largest number of people laid off
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Seeing which year had the largest number of people laid off
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- Want to do a rolling total of layoffs per month
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
;

-- Rolling total
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `Month`, total_off,
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- Taking a look at how much each company lays off per year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company ASC;

-- We want to rank which years companies laid off most employees
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- We want to partition the company layoffs per year, and order by total laid off, so we can see who laid off the most per year
-- We only want to see the top 5 companies per year
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE RANKING <= 5
;

-- ============================================================
-- Funding Stage Analysis
-- ============================================================

-- Seeing total layoffs and number of companies affected by funding stage
-- Post-IPO companies dominate by volume due to their larger workforce size.
-- However, the spread across Series A-C shows the downturn affected early-stage companies too.
SELECT stage,
       SUM(total_laid_off) AS Total_Laid_Off,
       COUNT(DISTINCT company) AS Companies_Affected
FROM layoffs_staging2
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY Total_Laid_Off DESC;

-- Seeing average layoff size per event by funding stage
-- Helps distinguish between many small layoffs vs. fewer large ones at each stage.
SELECT stage,
       ROUND(AVG(total_laid_off), 0) AS Avg_Laid_Off_Per_Event,
       COUNT(*) AS Layoff_Events
FROM layoffs_staging2
WHERE stage IS NOT NULL
  AND total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY Avg_Laid_Off_Per_Event DESC;

-- ============================================================
-- Funding Efficiency Analysis
-- Layoffs per $1M raised — highlights companies that laid off
-- large numbers relative to the capital they had available.
-- ============================================================

-- Companies with the highest layoffs relative to funding raised
-- Only includes companies with funds_raised_millions > 0 to avoid division errors.
SELECT company,
       SUM(total_laid_off) AS Total_Laid_Off,
       MAX(funds_raised_millions) AS Funds_Raised_Millions,
       ROUND(SUM(total_laid_off) / MAX(funds_raised_millions), 2) AS Layoffs_Per_Million_Raised
FROM layoffs_staging2
WHERE funds_raised_millions > 0
  AND total_laid_off IS NOT NULL
GROUP BY company
ORDER BY Layoffs_Per_Million_Raised DESC
LIMIT 20;

-- Companies that completed full layoffs (percentage_laid_off = 1) ranked by funding raised
-- These companies received significant investment but still shut down entirely.
SELECT company, location, country, stage, funds_raised_millions, YEAR(`date`) AS Year
FROM layoffs_staging2
WHERE percentage_laid_off = 1
  AND funds_raised_millions IS NOT NULL
ORDER BY funds_raised_millions DESC;