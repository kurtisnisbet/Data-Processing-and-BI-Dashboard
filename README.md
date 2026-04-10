# Data Processing, Exploration, and Dashboard Visualisation (Global Layoffs Analysis)

This project analyses global employee layoffs from 2020 to 2024, showcasing advanced SQL skills for data cleaning and exploration, complemented by Power BI visualisations for insights. The dataset includes over 1,500 companies across 31 industries, highlighting layoff trends by company, industry, geography, and time. The analysis contextualises layoff patterns within global economic events and demonstrates technical proficiency in data analytics.

---

## Table of Contents
- [Project Structure](#project-structure)
- [Technical Workflow](#technical-workflow)
  - [Data Cleaning](#data-cleaning)
  - [Exploratory Data Analysis (EDA)](#exploratory-data-analysis-eda)
  - [Visualisations](#visualisations)
- [Key Findings](#key-findings)
- [Original Dataset](#original-dataset)

---

## Project Structure

```
├── assets/
│   ├── eda/                          # CSV outputs from SQL EDA queries
│   │   ├── closed_companie_and_funding.csv
│   │   ├── complete_layoffs_by_funding.csv
│   │   ├── layoffs_by_stage.csv
│   │   ├── layoffs_per_country.csv
│   │   ├── layoffs_per_industry.csv
│   │   ├── layoffs_per_year.csv
│   │   ├── rolling_total_of_layoffs.csv
│   │   └── top_5_companies_with_most_layoffs.csv
│   ├── img/                          # Workflow diagrams and dashboard screenshots
│   ├── powerbi/                      # Power BI dashboard file (.pbix)
│   └── sql/
│       ├── layoffs_data.csv          # Raw dataset
│       ├── layoffs_data_2.csv        # Cleaned dataset
│       ├── layoffs_data_cleaning.sql # Data cleaning script
│       └── layoffs_eda.sql           # Exploratory data analysis queries
```

---

## Technical Workflow

![Technical_workflow](assets/img/workflow.jpg)

### Data Cleaning
SQL was used to clean the raw dataset.

My approach to data cleaning follows the steps of:

![Data_cleaning_workflow](assets/img/data_cleaning.png)

- **Removed Duplicates**:

  Columns were counted, and duplicates after the first are identified with the *row_num > 1* and removed.

  ```sql
  DELETE
  FROM layoffs_staging2
  WHERE row_num > 1;
  ```

- **Standardised Columns** (e.g., ensuring industries, countries, etc are consistent)

  Values in columns were standardised. For example, different companies had various versions of 'crypto', 'cryptocurrencies' as their business type. This was done by using the *%* wildcard after *crypto* to identify any variations in spelling, which were then updated.

  ```sql
  UPDATE layoffs_staging2
  SET industry = 'Crypto'
  WHERE industry LIKE 'Crypto%';
  ```

  Likewise, some countries had trailing full-stops in their string. These were also identified and removed.

  ```sql
  UPDATE layoffs_staging2
  SET country = TRIM(TRAILING '.' FROM country)
  WHERE country LIKE 'United States%';
  ```

- **Handled Null Values**

  A self-join on company name was used to populate missing industry values where another row for the same company had the industry filled in. Where *both* industry and company were null, rows were removed as they could not contribute to any meaningful EDA.

  ```sql
  UPDATE layoffs_staging2 t1
  JOIN layoffs_staging2 t2
  ON t1.company = t2.company
  SET t1.industry = t2.industry
  WHERE t1.industry IS NULL;
  ```

---

## Exploratory Data Analysis (EDA)
SQL queries were used to perform the EDA. The following queries aim to identify layoff trends by year, company and industry, geography, and funding stage. The analysis also determines which companies received relief funding yet recorded 100% layoffs.

- **Temporal Trends**
  ```sql
  SELECT YEAR(`date`) AS Year, SUM(total_laid_off) AS Total_Laid_Off
  FROM layoffs_staging2
  GROUP BY Year
  ORDER BY Total_Laid_Off DESC;
  ```

Layoffs peaked in 2022–2023, accounting for 68.9% of all layoffs in the dataset. This was possibly driven by overhiring during the pandemic and subsequent economic corrections.

Lower layoffs in 2020–2021 were likely due to pandemic relief efforts, while the dip in 2024 may reflect market stabilisation.

| Year | Total Laid Off |
|------|----------------|
| 2023 | 212,585        |
| 2022 | 150,707        |
| 2024 | 77,194         |
| 2020 | 70,755         |
| 2021 | 15,810         |


- **Industry and Company Insights**
  ```sql
  SELECT industry, SUM(total_laid_off) AS Total_Laid_Off
  FROM layoffs_staging2
  GROUP BY industry
  ORDER BY Total_Laid_Off DESC;
  ```

Retail and Consumer industries led layoffs, together accounting for nearly 25% of all layoffs recorded. Technology companies including Amazon and Meta were among the top contributors by individual company.

| Industry       | Total Laid Off |
|----------------|----------------|
| Retail         | 67,368         |
| Consumer       | 63,814         |
| Transportation | 57,163         |
| Other          | 55,864         |
| Food           | 42,165         |
| ...            | ...            |


- **Geographic Trends**
  ```sql
  SELECT country, SUM(total_laid_off) AS Total_Laid_Off
  FROM layoffs_staging2
  GROUP BY country
  ORDER BY Total_Laid_Off DESC;
  ```

The United States alone accounted for 69.8% of all layoffs, driven primarily by large-scale cuts at major tech companies headquartered there.

| Country        | Total Laid Off |
|----------------|----------------|
| United States  | 367,630        |
| India          | 47,127         |
| Germany        | 25,345         |
| United Kingdom | 16,733         |
| Sweden         | 12,969         |
| ...            | ...            |


- **Funding Stage Analysis**
  ```sql
  SELECT stage, SUM(total_laid_off) AS Total_Laid_Off,
         COUNT(DISTINCT company) AS Companies_Affected
  FROM layoffs_staging2
  GROUP BY stage
  ORDER BY Total_Laid_Off DESC;
  ```

Post-IPO companies accounted for the largest volume of layoffs by far (289,644), affecting 285 companies. This reflects the outsized scale of publicly listed firms. Notably, even early-stage companies (Series A–C) collectively contributed over 59,000 layoffs, showing the downturn cut across all stages of company maturity.

| Stage          | Total Laid Off | Companies Affected |
|----------------|----------------|--------------------|
| Post-IPO       | 289,644        | 285                |
| Series B       | 28,372         | 243                |
| Series D       | 24,395         | 170                |
| Series C       | 24,155         | 215                |
| Series E       | 22,041         | 98                 |
| Series A       | 7,173          | 126                |
| Seed           | 1,723          | 37                 |
| ...            | ...            | ...                |


- **Funding and Layoffs**
  ```sql
  SELECT company, location, percentage_laid_off, funds_raised_millions
  FROM layoffs_staging2
  WHERE percentage_laid_off = 1
  ORDER BY funds_raised_millions DESC;
  ```

51 companies underwent complete layoffs (100% of workforce) despite collectively raising over $10 billion in funding. This highlights that significant investment was no guarantee of survival.

| Company               | Location       | Percentage Laid Off | Funds Raised (Millions) |
|-----------------------|----------------|---------------------|--------------------------|
| Britishvolt           | London         | 1                   | 2,400                    |
| Deliveroo Australia   | Melbourne      | 1                   | 1,700                    |
| Katerra               | SF Bay Area    | 1                   | 1,600                    |
| Convoy                | Seattle        | 1                   | 1,100                    |
| ...                   | ...            | ...                 | ...                      |


- **Monthly Rolling Totals**
  ```sql
  WITH Rolling_Total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS Month, SUM(total_laid_off) AS Total_Laid_Off
    FROM layoffs_staging2
    GROUP BY Month
  )
  SELECT Month, Total_Laid_Off,
  SUM(Total_Laid_Off) OVER(ORDER BY Month) AS Rolling_Total
  FROM Rolling_Total;
  ```

Rolling totals provided a cumulative view of layoffs, highlighting key inflection points such as the sharp acceleration through 2022 and into early 2023.

| Month   | Total Off | Rolling Total |
|---------|-----------|---------------|
| 2020-03 | 8,981     | 8,981         |
| 2020-04 | 25,271    | 34,252        |
| 2020-05 | 22,699    | 56,951        |
| ...     | ...       | ...           |
| 2024-06 | 1,410     | 527,051       |

*The data for the above findings can also be found in the .csv files stored under assets/eda.*

---

## Visualisations

To provide greater clarity on the EDA results above, Power BI was used to create a dashboard.

The cleaned dataset and dashboard are available to download in this repository.

![PowerBI Visualisation Dashboard](assets/img/dashboard.png)

---

## Key Findings

**1. Temporal Trends:**
Layoffs spiked sharply in 2022–2023, with these two years accounting for 68.9% (363,292) of all layoffs recorded. This is consistent with widespread overhiring during the pandemic followed by economic corrections as interest rates rose. Layoffs were minimal in 2020–2021 (86,565 combined), likely cushioned by government relief efforts, with signs of stabilisation emerging in 2024.

**2. Industry Impact:**
Retail and Consumer industries were the most affected, together comprising nearly 25% of total layoffs. Technology companies drove the largest individual layoffs by volume, with Amazon (27,840), Google (13,472), and Meta among the top contributors.

**3. Geographic Insights:**
The United States accounted for 69.8% of all recorded layoffs — a concentration driven by the scale of US-headquartered tech and retail firms. India (47,127) and Germany (25,345) were the next most affected countries.

**4. Funding Stage:**
Post-IPO companies recorded the highest absolute layoff volumes (289,644), reflecting their larger workforces. However, the downturn was broad-based, with Series A–C companies collectively contributing over 59,000 layoffs across hundreds of firms.

**5. Funding vs. Survival:**
51 companies underwent complete workforce eliminations despite collectively raising over $10 billion in funding. High capitalisation was no guarantee of survival, with Britishvolt ($2.4B raised) and Katerra ($1.6B raised) among the highest-profile closures.

---

## Original Dataset
Lee, R. (2022) Layoffs Data 2022. Available at: https://www.kaggle.com/datasets/theakhilb/layoffs-data-2022 (Accessed: 21st Dec 2024).
