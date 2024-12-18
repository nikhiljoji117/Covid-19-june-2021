CREATE DATABASE covid_db;

USE covid_db;

SELECT * from covid;

SET SQL_SAFE_UPDATES = 0;

UPDATE covid 
SET date = STR_TO_DATE(date, '%m/%d/%Y');

SET SQL_SAFE_UPDATES = 1;

SELECT 
    MIN(covid_date) AS Min_Date,
    MAX(covid_date) AS Max_Date
FROM 
    covid;

ALTER TABLE covid
CHANGE COLUMN `date` `covid_date` text;

ALTER TABLE covid
MODIFY COLUMN covid_date DATE;

SHOW CREATE TABLE covid;

DESCRIBE covid;


-- total_cases_sum
SELECT 
    location, 
    MAX(total_cases) AS max_total_cases
FROM 
    covid
GROUP BY 
    location
ORDER BY 
    max_total_cases DESC
LIMIT 10;

-- total_deaths
SELECT 
    location, 
    MAX(total_deaths) AS max_total_deaths
FROM 
    covid
GROUP BY 
    location
ORDER BY 
    max_total_deaths DESC
LIMIT 10;

-- case_fatality_rate
SELECT 
    location, 
    (MAX(total_deaths) / MAX(total_cases)) * 100 AS case_fatality_rate
FROM 
    covid
GROUP BY 
    location
ORDER BY 
    case_fatality_rate DESC
LIMIT 10;



-- highest number of total vaccinations
SELECT 
    location, 
    MAX(total_vaccinations) AS total_vaccinations
FROM 
    covid
GROUP BY 
    location
ORDER BY 
    total_vaccinations DESC
LIMIT 10;


-- Total COVID-19 Cases and Deaths Over Time (Monthly)
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths
FROM 
    covid
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;

-- Case Fatality Rate
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths,
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS case_fatality_rate
FROM 
    covid
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
HAVING total_cases > 0  -- To avoid division by zero
ORDER BY 
    month;

-- New COVID-19 Cases Per Month
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(new_cases) AS new_cases
FROM 
    covid
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;


-- New COVID-19 Deaths Per Month
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(new_deaths) AS new_deaths
FROM 
    covid
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;

-- Vaccination Coverage Over Time (Monthly)
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(total_vaccinations) AS total_vaccinations,
    SUM(people_vaccinated) AS people_vaccinated
FROM 
    covid
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;

-- Government Response Stringency Index Over Time (Monthly)
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    AVG(stringency_index) AS stringency_index
FROM 
    covid
WHERE 
    stringency_index IS NOT NULL
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;


-- Total Tests and Positivity Rate Over Time (Monthly)
-- Calculate positivity rate as the ratio of new cases to new tests
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(total_tests) AS total_tests,
    (SUM(new_cases) / SUM(new_tests)) * 100 AS positivity_rate
FROM 
    covid
WHERE 
    new_tests IS NOT NULL AND new_tests > 0
GROUP BY 
    DATE_FORMAT(date, '%Y-%m')
ORDER BY 
    month;



-- Total Covid Cases
WITH LatestDatePerLocation AS (
    SELECT 
        location, 
        MAX(covid_date) AS latest_date
    FROM covid
    GROUP BY location
),
LatestCases AS (
    SELECT 
        c.location, 
        MAX(c.total_cases) AS latest_cases
    FROM covid c
    INNER JOIN LatestDatePerLocation ld
    ON c.location = ld.location AND c.covid_date = ld.latest_date
    GROUP BY c.location
)
SELECT 
    SUM(latest_cases) AS Total_COVID_Cases
FROM LatestCases;


-- Total Deaths
WITH LatestDatePerLocation AS (
    SELECT 
        location, 
        MAX(covid_date) AS latest_date
    FROM covid
    GROUP BY location
),
LatestDeaths AS (
    SELECT 
        c.location, 
        MAX(c.total_deaths) AS latest_deaths
    FROM covid c
    INNER JOIN LatestDatePerLocation ld
    ON c.location = ld.location AND c.covid_date = ld.latest_date
    GROUP BY c.location
)
SELECT 
    SUM(latest_deaths) AS Total_Deaths
FROM LatestDeaths;


-- Case Fatality Rate
WITH LatestData AS (
    SELECT 
        c.location,  -- Explicitly qualify 'location' with the alias 'c'
        MAX(c.total_cases) AS latest_cases,
        MAX(c.total_deaths) AS latest_deaths
    FROM covid c
    INNER JOIN (
        SELECT 
            location, 
            MAX(covid_date) AS latest_date
        FROM covid
        GROUP BY location
    ) LatestDates
    ON c.location = LatestDates.location AND c.covid_date = LatestDates.latest_date
    GROUP BY c.location  -- Ensure 'c.location' is used here as well
)
SELECT 
    ROUND((SUM(latest_deaths) / SUM(latest_cases)) * 100, 2) AS Case_Fatality_Rate_Percentage
FROM LatestData;





-- Total Vaccinations
WITH LatestDatePerLocation AS (
    SELECT 
        location, 
        MAX(covid_date) AS latest_date
    FROM covid
    GROUP BY location
),
LatestVaccinations AS (
    SELECT 
        c.location, 
        MAX(c.total_vaccinations) AS latest_vaccinations
    FROM covid c
    INNER JOIN LatestDatePerLocation ld
    ON c.location = ld.location AND c.covid_date = ld.latest_date
    GROUP BY c.location
)
SELECT 
    SUM(latest_vaccinations) AS Total_Vaccinations
FROM LatestVaccinations;


-- Total test
WITH MaxTestsPerLocation AS (
    SELECT 
        location, 
        MAX(total_tests) AS max_tests
    FROM covid
    WHERE total_tests IS NOT NULL AND total_tests > 0 -- Ensure valid values
    GROUP BY location
)
SELECT 
    SUM(max_tests) AS Total_Tests
FROM MaxTestsPerLocation;




-- People Vaccinated
WITH LatestDatePerLocation AS (
    SELECT 
        location, 
        MAX(covid_date) AS latest_date
    FROM covid
    GROUP BY location
),
LatestPeopleVaccinated AS (
    SELECT 
        c.location, 
        MAX(c.people_vaccinated) AS latest_people_vaccinated
    FROM covid c
    INNER JOIN LatestDatePerLocation ld
    ON c.location = ld.location AND c.covid_date = ld.latest_date
    GROUP BY c.location
)
SELECT 
    SUM(latest_people_vaccinated) AS Total_People_Vaccinated
FROM LatestPeopleVaccinated;


-- Case Fatality Rate by Date
SELECT 
    covid_date,
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS Case_Fatality_Rate_Percentage
FROM covid
GROUP BY covid_date
HAVING SUM(total_cases) > 0  -- Avoid division by zero
ORDER BY covid_date;


-- New Cases Per Day
SELECT 
    covid_date, 
    SUM(new_cases) AS New_Cases_Per_Day
FROM covid
GROUP BY covid_date
ORDER BY covid_date;


-- New Deaths Per Day
SELECT 
    covid_date, 
    SUM(new_deaths) AS New_Deaths_Per_Day
FROM covid
GROUP BY covid_date
ORDER BY covid_date;

 
-- New test per day
SELECT 
    covid_date, 
    SUM(new_tests) AS New_Tests_Per_Day
FROM 
    covid
WHERE 
    new_tests > 0  -- Ensure only valid test counts are included
GROUP BY 
    covid_date
ORDER BY 
    covid_date;



-- Average Daily Positivity Rate
-- SELECT 
--     covid_date,
--     (SUM(new_cases) / SUM(new_tests)) * 100 AS Positivity_Rate_Percentage
-- FROM covid
-- WHERE new_tests > 0 -- Avoid division by zero
-- GROUP BY covid_date
-- ORDER BY covid_date;


-- overrall posivitiy rate
SELECT 
    (SUM(new_cases) / SUM(new_tests)) * 100 AS Positivity_Rate_Percentage
FROM 
    covid
WHERE 
    new_tests > 0; -- Avoid division by zero




-- Average Stringency Index

SELECT 
    covid_date, 
    AVG(stringency_index) AS Average_Stringency_Index
FROM covid
WHERE stringency_index IS NOT NULL
GROUP BY covid_date
ORDER BY covid_date;







