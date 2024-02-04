# COVID-19 Data Analysis

## Introduction
This data analysis focuses on COVID-19 data from the 'CovidData' database, specifically the 'CovidDeaths' table. The 'CovidDeaths' table contains information about COVID-19 deaths, including details such as location, date, total cases, new cases, total deaths, and population.

### Key Objectives
- Understand the total cases, deaths, infection rates, and vaccination rates across different countries and continents.
- Identify trends and patterns in COVID-19 data.

## Contents
- [1. Selecting Relevant Data](#1-selecting-relevant-data)
- [2. Filtering Data for Analysis](#2-filtering-data-for-analysis)
- [3. Total Cases vs Total Deaths](#3-total-cases-vs-total-deaths)
- [4. Total Cases vs Population](#4-total-cases-vs-population)
- [5. Countries with Highest Infection Rate Compared to Population](#5-countries-with-highest-infection-rate-compared-to-population)
- [6. Countries with Highest Death Count per Population](#6-countries-with-highest-death-count-per-population)
- [7. Continents with the Highest Death Count per Population](#7-continents-with-the-highest-death-count-per-population)
- [8. Global Numbers](#8-global-numbers)
- [9. Joining COVID-19 Deaths and Vaccination Data](#9-joining-covid-19-deaths-and-vaccination-data)
- [10. Using CTE for Rolling People Vaccinated Calculation](#10-using-cte-for-rolling-people-vaccinated-calculation)
- [11. Using Temp Table for Rolling People Vaccinated Calculation](#11-using-temp-table-for-rolling-people-vaccinated-calculation)
- [12. Creating a View for Later Visualizations](#12-creating-a-view-for-later-visualizations)

## 1. Selecting Relevant Data
```sql
-- Selecting all data from the 'CovidDeaths' table for further exploration.
SELECT *
FROM CovidData..CovidDeaths
ORDER BY 3, 4;
```

## 2. Filtering Data for Analysis
```sql
-- Filtering relevant columns for a clearer analysis of total cases, new cases, total deaths, and population.
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidData..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;
```

## 3. Total Cases vs Total Deaths
```sql
-- Comparing total cases with total deaths to analyze the likelihood of dying if contracting COVID-19 in a specific country.
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidData..CovidDeaths
WHERE location LIKE '%india%' AND continent IS NOT NULL
ORDER BY 2 DESC;
```

## 4. Total Cases vs Population
```sql
-- Analyzing what percentage of the population is infected with COVID-19 in a specific country.
SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM CovidData..CovidDeaths
WHERE location LIKE '%india%'
ORDER BY 2 DESC;
```

## 5. Countries with Highest Infection Rate Compared to Population
```sql
-- Identifying countries with the highest infection rates compared to their populations.
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidData..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;
```

## 6. Countries with Highest Death Count per Population
```sql
-- Identifying countries with the highest death count per population.
SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidData..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;
```

## 7. Continents with the Highest Death Count per Population
```sql
-- Identifying continents with the highest death count per population, excluding the top 3.
SELECT location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidData..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
OFFSET 3 ROWS;
```

## 8. Global Numbers
```sql
-- Calculating global total cases, total deaths, and the death percentage.
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int)) / SUM(New_Cases) * 100 as DeathPercentage
FROM CovidData..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;
```

## 9. Joining COVID-19 Deaths and Vaccination Data
```sql
-- Joining COVID-19 deaths and vaccination data for combined analysis.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidData..CovidDeaths dea
JOIN CovidData

..CovidVaccsination$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;
```

## 10. Using CTE for Rolling People Vaccinated Calculation
```sql
-- Using a Common Table Expression (CTE) to calculate the rolling number of people vaccinated.
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
  FROM CovidData..CovidDeaths dea
  JOIN CovidData..CovidVaccsination$ vac
  ON dea.location = vac.location AND dea.date = vac.date
  WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac;
```

## 11. Using Temp Table for Rolling People Vaccinated Calculation
```sql
-- Using a temporary table to store data for rolling people vaccinated calculation.
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
  Continent nvarchar(255),
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_vaccinations numeric,
  RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea
JOIN CovidData..CovidVaccsination$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated;
```

## 12. Creating a View for Later Visualizations
```sql
-- Creating a view to store data for later visualizations.
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea
JOIN CovidData..CovidVaccsination$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
```

## Conclusion
- The analysis provides insights into the global and country-specific impact of COVID-19, including total cases, deaths, infection rates, and vaccination rates.
- Countries with the highest infection rates compared to their populations were identified.
- The continents with the highest death counts per population were explored.
- Global total cases, total deaths, and death percentages were calculated.
- The rolling number of people vaccinated was computed using both CTEs and temporary tables.
- A view was created to store data for future visualizations.
