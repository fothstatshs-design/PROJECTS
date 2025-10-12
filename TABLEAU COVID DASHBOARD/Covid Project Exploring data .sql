/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2

SELECT 
    Location, 
    date, 
    total_cases,
    total_deaths,
    (TRY_CAST(total_deaths AS FLOAT) / NULLIF(TRY_CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid



SELECT 
    Location, 
    date, 
    Population, 
    total_cases,  
    (TRY_CAST(total_cases AS FLOAT) / NULLIF(TRY_CAST(population AS FLOAT), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population



SELECT 
    Location,
    Population,
    MAX(TRY_CAST(total_cases AS FLOAT)) AS HighestInfectionCount,
    MAX((TRY_CAST(total_cases AS FLOAT) / NULLIF(TRY_CAST(population AS FLOAT), 0)) * 100) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY 
    Location, Population
ORDER BY 
    PercentPopulationInfected DESC;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

SELECT 
    SUM(CAST(TRY_CAST(new_cases AS FLOAT) AS FLOAT)) AS total_cases,
    SUM(CAST(TRY_CAST(new_deaths AS FLOAT) AS FLOAT)) AS total_deaths,
    (SUM(CAST(TRY_CAST(new_deaths AS FLOAT) AS FLOAT)) 
        / NULLIF(SUM(CAST(TRY_CAST(new_cases AS FLOAT) AS FLOAT)), 0)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
--AND location LIKE '%states%'   -- optional
--GROUP BY date                  -- optional
ORDER BY 
    total_cases, total_deaths;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(CONVERT(int,dea.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(CONVERT(int,dea.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
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
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(CONVERT(int,dea.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations
, SUM(CONVERT(int,dea.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

