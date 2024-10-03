/* 

Covid 19 Data Exploration
Skills used: JOINS, CTE'S, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
	FROM Portfolio_Project..CovidDeaths
	WHERE continent is not null
	ORDER BY 3,4

-- Selecting the data I'll be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
	FROM Portfolio_Project..CovidDeaths
	ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in the US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
	FROM Portfolio_Project..CovidDeaths
	WHERE location like '%states%'
	ORDER BY 1,2

-- Looking at total cases vs population 
-- Shows what percentage of the population was infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
	FROM Portfolio_Project..CovidDeaths
	ORDER BY 1,2

-- Looking at Countries with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
	FROM Portfolio_Project..CovidDeaths
	GROUP BY location, population
	ORDER BY PercentPopulationInfected desc

-- Looking at Countries with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
	FROM Portfolio_Project..CovidDeaths
	WHERE continent is not null
	GROUP BY location
	ORDER BY TotalDeathCount desc


-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
	FROM Portfolio_Project..CovidDeaths
	WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount desc

-- Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPecentage
	FROM Portfolio_Project..CovidDeaths
	WHERE continent is not null
	ORDER BY 1,2

-- if you want to see the death percentage for the whole world overall, not percentage day by day

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPecentage
	FROM Portfolio_Project..CovidDeaths
	WHERE continent is not null
	ORDER BY 1,2

-- Looking at total population vs vaccinations, showing what percent of the population had at least 1 Covid vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, dea.new_vaccinations 
	, SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	, (
		FROM Portfolio_Project..CovidDeaths dea
		JOIN Portfolio_Project..CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not null
		ORDER BY 2,3
		)
		

-- Using CTE to perform calculations on PARTITION BY (from pervious query)

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
		FROM Portfolio_Project..CovidDeaths dea
		JOIN Portfolio_Project..CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not null
	) 
	SELECT *, (RollingPeopleVaccinated/population)*100
	FROM PopvsVac


-- using Temp Table to perform calculations on PARTITION BY (from pervious query)

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(
		continent nvarchar(255),
		location nvarchar(255),
		date datetime,
		population numeric,
		new_vaccinations numeric,
		RollingPeopleVaccinated numeric
	)
INSERT INTO #PercentPopulationVaccinated
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
		FROM Portfolio_Project..CovidDeaths dea
		JOIN Portfolio_Project..CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for Tableau visualiztion 

CREATE VIEW PercentPopulationVaccinated as
	 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
		FROM Portfolio_Project..CovidDeaths dea
		JOIN Portfolio_Project..CovidVaccinations vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not null


