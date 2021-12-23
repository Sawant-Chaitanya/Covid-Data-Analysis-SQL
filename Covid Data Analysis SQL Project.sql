SELECT * 
FROM CovidData..CovidDeaths
order by 3,4

--SELECT * 
--FROM CovidData..CovidVaccsination$
--order by 3,4

--SElect Data that we are going to use

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidData..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidData..CovidDeaths
Where location like '%india%'
and continent is not null 
order by 2 DESC


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid


Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidData..CovidDeaths
Where location like '%india%'
order by 2 DESC


-- Countries with Highest Infection Rate compared to Population


Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidData..CovidDeaths
--Where location like '%india%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population


Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidData..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Countries with Highest Death Count per Population


Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidData..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Showing contintents with the highest death count per population


Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidData..CovidDeaths
Where continent is null 
Group by location
order by TotalDeathCount desc
OFFSET 3 ROWS


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidData..CovidDeaths
where continent is not null 
order by 1,2



SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidData..CovidDeaths dea
Join CovidData..CovidVaccsination$ vac
   ON  dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null 
order by 2,3



-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidData..CovidDeaths dea
Join CovidData..CovidVaccsination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac





-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table	if exists #PercentPopulationVaccinated	

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,  SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From CovidData..CovidDeaths dea
Join CovidData..CovidVaccsination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidData..CovidDeaths dea
Join CovidData..CovidVaccsination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3