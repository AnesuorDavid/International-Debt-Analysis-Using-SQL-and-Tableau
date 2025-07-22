-- Analysing international debt
-- DATA IMPORT
SELECT *
FROM international_data;
SELECT COUNT(DISTINCT country_name) AS country_count
FROM international_data;
 
-- Data Cleaning 
-- CHECK FOR NULL VALUES
SELECT *
FROM international_data
WHERE `ï»¿"index"` IS NULL OR `ï»¿"index"` = ''
   OR country_name IS NULL OR country_name = ''
   OR country_code IS NULL OR country_code = ''
   OR indicator_name IS NULL OR indicator_name = ''
   OR indicator_code IS NULL OR indicator_code = ''
   OR debt IS NULL OR debt = '';
-- CREATE A STAGING TABLE
CREATE TABLE in_debt
LIKE international_data;
INSERT INTO in_debt
SELECT *
FROM international_data;
SELECT *			-- check values
FROM in_debt;
-- AGGREGATION
-- 1.	Which countries are the most heavily indebted, and what types of debt contribute most to their burden?
SELECT country_name, country_code, SUM(debt) as most_indebted -- FIND THE MOST INDEBTED COUNTRY
FROM in_debt
GROUP BY country_name, country_code
ORDER BY most_indebted DESC
LIMIT 10;
SELECT country_name, country_code, indicator_name, max(debt) -- LARGEST TYPE OF DEBT
FROM in_debt
WHERE country_name = 'China'
GROUP BY country_name, country_code, indicator_name
ORDER BY indicator_name
LIMIT 1;
-- 2.	Is there a relationship between the type of creditor (bilateral vs. multilateral) and the overall debt levels in developing countries?
SELECT
  country_name,
  SUM(CASE WHEN indicator_code LIKE '%BLAT%' THEN debt ELSE 0 END) AS total_bilateral_debt,
  SUM(CASE WHEN indicator_code LIKE '%MLAT%' THEN debt ELSE 0 END) AS total_multilateral_debt
FROM in_debt
GROUP BY country_name
ORDER BY country_name
LIMIT 20;
-- 3.	Which regions (e.g., Sub-Saharan Africa, South Asia) rely more heavily on long-term external disbursements?
SELECT *
FROM in_debt;
SELECT country_name, indicator_name, sum(debt) as total_debt
FROM in_debt
WHERE debt > 0
GROUP BY country_name, indicator_name
ORDER BY total_debt
LIMIT 5;
-- 4. Which countries rely more on bilateral debt versus multilateral debt, and what does this reveal about their international borrowing patterns?
SELECT
  country_name,
  SUM(CASE WHEN indicator_code LIKE '%BLAT%' THEN debt ELSE 0 END) AS total_bilateral_debt,
  SUM(CASE WHEN indicator_code LIKE '%MLAT%' THEN debt ELSE 0 END) AS total_multilateral_debt
FROM in_debt
GROUP BY country_name
HAVING total_bilateral_debt > total_multilateral_debt;
-- 5. Which countries have a higher multilateral debt than bilateral debt, and by how much?
SELECT
  country_name,
  SUM(CASE WHEN indicator_code LIKE '%MLAT%' THEN debt ELSE 0 END) AS total_multilateral_debt,
  SUM(CASE WHEN indicator_code LIKE '%BLAT%' THEN debt ELSE 0 END) AS total_bilateral_debt, -- AGGREGATE TMD AND TBD
  SUM(CASE WHEN indicator_code LIKE '%MLAT%' THEN debt ELSE 0 END) - -- FIND THE DIFFERENCE
  SUM(CASE WHEN indicator_code LIKE '%BLAT%' THEN debt ELSE 0 END) 
   as debt_difference
FROM in_debt
GROUP BY country_name
HAVING debt_difference > 0 ;  -- AGGREGATE FINAL VALUES
-- 6.	Which countries have the highest total debt across all indicators, and how does it compare across regions?
SELECT country_name, SUM(debt) AS total_debt
from in_debt
GROUP BY country_name
ORDER BY total_debt desc
limit 10;
-- 7. Which country has the most diversified types of debt based on the number of unique indicator codes used?
SELECT country_name, COUNT(distinct(indicator_code)) AS unique_indicator_codes
FROM in_debt
GROUP BY country_name
ORDER BY unique_indicator_codes DESC 
LIMIT 1;
-- 8.	What proportion of total international debt is concentrated among the top 10 debtor countries?
SELECT country_name, SUM(debt) AS total_debt
from in_debt
GROUP BY country_name
ORDER BY total_debt desc
limit 10;
SELECT SUM(debt) as total_world_debt
FROM in_debt;
-- CREATING A RATIO TO SEE WHAT PERCENTAGE IS IN THE TOP TEN
-- First get total world debt
SELECT 
  ROUND(
    (SELECT SUM(total_debt) FROM (
        SELECT country_name, SUM(debt) AS total_debt
        FROM in_debt
        GROUP BY country_name
        ORDER BY total_debt DESC
        LIMIT 10
    ) AS top10
    ) 
    / 
    (SELECT SUM(debt) FROM in_debt) 
    * 100, 
    2
  ) AS top10_debt_percentage;
-- 9. Which indicator code contributes the most to the total global debt, and what percentage does it represent?
-- Total debt per indicator code
SELECT 
  indicator_code,
  SUM(debt) AS total_debt,
  ROUND(SUM(debt) / (SELECT SUM(debt) FROM in_debt) * 100, 2) AS percentage_of_global_debt
FROM in_debt
GROUP BY indicator_code
ORDER BY total_debt DESC
LIMIT 1;
-- 10. Which countries have the highest average debt per debt type?
SELECT 
  country_name,
  ROUND(AVG(debt), 2) AS average_debt_per_type,
  COUNT(DISTINCT indicator_code) AS number_of_types
FROM in_debt
GROUP BY country_name
ORDER BY average_debt_per_type DESC
LIMIT 10;


