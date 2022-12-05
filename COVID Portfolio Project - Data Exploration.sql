/*
Covid 19 Data Exploration
Skills used: Joins, CTE's, Temp tables, Window functions, Aggregate fucntion, Creating views, Converting data types
*/

Select *
From PortfolioProject..['Covid-deaths']
Where continent is not null
Order by 3,4

--Select Data that we are going to be starting with >>>
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..['Covid-deaths']
Where continent is not null
Order by 1,2

--Total cases vs Total deaths (Shows likelihood of dying if you contract covid in your country) >>>
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..['Covid-deaths']
Where location like '%pakistan'
And continent is not null
Order by 1,2

--Total cases vs population (Shows % of infected population) >>>
Select location, date, population, total_cases, (total_cases/population)*100 as InfectedPercentage
From PortfolioProject..['Covid-deaths']
Where location like '%pakistan'
Order by 1,2

--Countries with highest infection rate compared to population >>>
Select location, population, MAX(total_cases) as HighestInfectedCount, MAX((total_cases/population))*100 as InfectedPercentage
From PortfolioProject..['Covid-deaths']
--Where location like '%pakistan'
Group by location, population
Order by InfectedPercentage desc

--Countries with highest deathcount per population >>>
Select location, MAX(Cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..['Covid-deaths']
Where continent is not null
Group by location
Order by TotalDeathCount desc

--Continents with highest deathcount per population >>>
Select continent, MAX(Cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..['Covid-deaths']
Where continent is not null
Group by continent
Order by TotalDeathCount desc

--Looking at Global numbers >>>
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..['Covid-deaths']
Where continent is not null
Order by 1,2

--Looking at total population vs vaccinations by joinning the two tables >>>
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) Over (Partition by death.location Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..['Covid-deaths'] death
Join PortfolioProject..['Covid-Vacinations'] vac
On death.location = vac.location
And death.date = vac.date
Where death.continent is not null
Order by 2,3

--Using CTE to perform calculation on partition by in previous query >>>
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
As
(
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) Over (Partition by death.location Order by death.location, death.date) as RollingPeopleVaccinated
From PortfolioProject..['Covid-deaths'] death
Join PortfolioProject..['Covid-Vacinations'] vac
On death.location = vac.location
And death.date = vac.date
Where death.continent is not null
)
Select *,(RollingPeopleVaccinated/population)*100
From PopvsVac

--Using Temp Table to perform Calculation on Partition By in previous query >>>
Drop Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Ddate datetime,
Population numeric,
New_vaccinated numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location,death.date) AS RollingPeopleVac
FROM PortfolioProject..['Covid-deaths'] death
JOIN PortfolioProject..['Covid-Vacinations'] vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

--Creating View to store data for later visualizations >>>
Create View PecentPopulationVaccinated As
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location,death.date) AS RollingPeopleVac
FROM PortfolioProject..['Covid-deaths'] death
JOIN PortfolioProject..['Covid-Vacinations'] vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent is not null
