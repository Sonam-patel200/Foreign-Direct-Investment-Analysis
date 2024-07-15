-- Creating Table to load the FDI data
CREATE TABLE fdi_data (
    sector TEXT,
    financial_year TEXT,
    fdi_value REAL
);


-- Loading FDI data from csv file into SQL Database
COPY fdi_data(sector, financial_year, fdi_value)
FROM 'Cleaned FDI data.csv'
DELIMITER ','
CSV HEADER;

-- Checking the loaded data
SELECT * FROM fdi_data



-- Exploratory Data Analysis


-- 1. Key Matrices

-- Total number of sectors
	
SELECT COUNT (DISTINCT sector) AS total_sectors FROM fdi_data;


-- Total number of years in the dataset
SELECT COUNT(DISTINCT financial_year) AS total_years FROM fdi_data;

-- Total FDI over the entire period
SELECT SUM(fdi_value) AS total_fdi FROM fdi_data;

-- Average annual FDI
SELECT AVG(fdi_value) AS average_annual_fdi FROM fdi_data;


-- 2. Year-wise Investment Analysis

-- Annual Trend of FDI
SELECT financial_year, SUM(fdi_value) AS total_fdi
FROM fdi_data
GROUP BY financial_year
ORDER BY financial_year;

-- Yearly Top Sectors
WITH yearly_top_sectors AS (
    SELECT financial_year, sector, SUM(fdi_value) AS total_fdi,
    ROW_NUMBER() OVER(PARTITION BY financial_year ORDER BY SUM(fdi_value) DESC) AS sector_rank
    FROM fdi_data
    GROUP BY financial_year, sector
)
SELECT financial_year, sector, total_fdi
FROM yearly_top_sectors
WHERE sector_rank = 1
ORDER BY financial_year;

-- Year with the highest FDI
SELECT financial_year, SUM(fdi_value) AS total_fdi
FROM fdi_data
GROUP BY financial_year
ORDER BY total_fdi DESC
LIMIT 1;

-- Year with the lowest FDI
SELECT financial_year, SUM(fdi_value) AS total_fdi
FROM fdi_data
GROUP BY financial_year
ORDER BY total_fdi ASC
LIMIT 1;

-- Yearly Growth Rate of FDI
WITH yearly_totals AS (
    SELECT financial_year, SUM(fdi_value) AS total_fdi
    FROM fdi_data
    GROUP BY financial_year
)
SELECT financial_year, total_fdi,
       LAG(total_fdi) OVER (ORDER BY financial_year) AS previous_year_fdi,
       (total_fdi - LAG(total_fdi) OVER (ORDER BY financial_year)) / LAG(total_fdi) OVER (ORDER BY financial_year) * 100 AS growth_rate
FROM yearly_totals;

-- year to year changes
WITH yearly_totals AS (
    SELECT financial_year, SUM(fdi_value) AS total_fdi
    FROM fdi_data
    GROUP BY financial_year
)
SELECT financial_year, total_fdi,
       LAG(total_fdi) OVER (ORDER BY financial_year) AS previous_year_fdi,
       total_fdi - LAG(total_fdi) OVER (ORDER BY financial_year) AS year_over_year_change
FROM yearly_totals;


-- 3. Sector-wise investment analysis

-- top sectors
SELECT sector, SUM(fdi_value) AS total_fdi
FROM fdi_data
GROUP BY sector
ORDER BY total_fdi DESC
LIMIT 10;

-- sector-wise FDI distribution in percentage
SELECT sector, SUM(fdi_value) AS total_fdi,
       SUM(fdi_value) * 100.0 / (SELECT SUM(fdi_value) FROM fdi_data) AS percentage_share
FROM fdi_data
GROUP BY sector
ORDER BY total_fdi DESC;

-- Yearly sector growth
WITH sector_yearly AS (
    SELECT sector, financial_year, SUM(fdi_value) OVER (PARTITION BY sector ORDER BY financial_year) AS yearly_fdi
    FROM fdi_data
    ORDER BY sector, financial_year
)
SELECT sector, financial_year, yearly_fdi,
       LAG(yearly_fdi) OVER (PARTITION BY sector ORDER BY financial_year) AS previous_year_fdi,
       (yearly_fdi - LAG(yearly_fdi) OVER (PARTITION BY sector ORDER BY financial_year)) / LAG(yearly_fdi) OVER (PARTITION BY sector ORDER BY financial_year) * 100 AS growth_rate
FROM sector_yearly;

-- sector volatility
SELECT sector, STDDEV(fdi_value) AS fdi_volatility
FROM fdi_data
GROUP BY sector
ORDER BY fdi_volatility DESC;

-- top 5 sectors each year
SELECT financial_year, sector, total_fdi
FROM (
    SELECT financial_year, sector, SUM(fdi_value) AS total_fdi,
           ROW_NUMBER() OVER (PARTITION BY financial_year ORDER BY SUM(fdi_value) DESC) AS rank
    FROM fdi_data
    GROUP BY financial_year, sector
) ranked
WHERE rank <= 5;