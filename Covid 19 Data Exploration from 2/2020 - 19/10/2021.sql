/*
Covid 19 Data Exploration from 2/2020 - 19/10/2021
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views
*/

Select *
From project1-329607.COVID19.CovidDeaths
Where continent is not null  
order by 3,4;

Select *
From project1-329607.COVID19.CovidVaccinations
Where continent is not null 
order by 3,4;


-- Starts with the data that we want to look at

Select location, date, total_cases, new_cases, total_deaths, population
From  project1-329607.COVID19.CovidDeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From project1-329607.COVID19.CovidDeaths
Where location LIKE '%States%'
and continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From project1-329607.COVID19.CovidDeaths
Where location like '%States%'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population
-- Viz 3
Select Location, Population, Max(total_cases) as HighestInfectionCount, Max(total_cases/population)*100 as PercentPopulationInfected
From project1-329607.COVID19.CovidDeaths
--Where location like '%Thai%'
Group by Location, Population
order by PercentPopulationInfected desc;

-- Viz 4 (same as Viz 3, added Date col.)
Select Location, Population, date, Max(total_cases) as HighestInfectionCount, Max(total_cases/population)*100 as PercentPopulationInfected
From project1-329607.COVID19.CovidDeaths
--Where location like '%Thai%'
Group by Location, Population, date
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population
Select Location, Population, Max(total_deaths) as HighesDeathCount, Max(total_deaths/population)*100 as PercentPopulationDeath
From project1-329607.COVID19.CovidDeaths
Where continent is not null
Group by Location, Population
order by PercentPopulationDeath desc;

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
select continent, max(total_deaths) as TotalDeathCount
From project1-329607.COVID19.CovidDeaths
where continent is not null 
group by continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS
-- Viz 1
Select Sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
From project1-329607.COVID19.CovidDeaths
--Where location LIKE '%States%'
where continent is not null 
--group by date
order by 1,2;

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe
-- Viz 2
Select location, SUM(new_deaths) as TotalDeathCount
From project1-329607.COVID19.CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from project1-329607.COVID19.CovidDeaths dea
join project1-329607.COVID19.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3;

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, vac.total_vaccinations
from project1-329607.COVID19.CovidDeaths dea
join project1-329607.COVID19.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
order by dea.location, dea.date;


-- Using CTE to perform Calculation on Partition By in previous query 
-- Looking at the proportion of the vaccinated people and total population
-- Partition by location because when it gets to the new location we want the count to start over

With PopvsVac as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100 (Cannot use the column that just created to perform further calculation)
from project1-329607.COVID19.CovidDeaths dea
join project1-329607.COVID19.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac




-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1-329607.COVID19.CovidDeaths dea
join project1-329607.COVID19.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from project1-329607.COVID19.CovidDeaths dea
join project1-329607.COVID19.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
