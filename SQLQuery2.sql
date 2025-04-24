select location, date, total_cases, total_deaths, population
from CovidDeaths$
where continent is not null
order by 1,2

-- looking at Total Cases vs Total Deaths

Select location, date, population, total_cases, (total_cases/ population)*100 as DeathPercentage
from CovidDeaths$
where location like '%states%'
order by 1,2

-- Shows what percentage of population got covid

Select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/ population))*100 as PercentPopulationInfected
from CovidDeaths$
Group by location, population
order by PercentPopulationInfected desc

-- Infection rates per population

Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
Group by location, population
order by TotalDeathCount desc

-- Deaths per country

Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is null
Group by location
order by TotalDeathCount desc

--deaths per continent 

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
Group by continent
order by TotalDeathCount desc

Select SUM(new_cases)as Totalcases, sum(cast(new_deaths as int)) as ToatalDeaths,SUM(cast (new_deaths as int))/sum(new_cases)*100 as Deathspercentage
from CovidDeaths$
where continent is not null 
order by 1,2

--looking at total population vs vac

With PopvsVac (Contient, location, date, Population, New_vaccinations, Rollingpeoplevac)
As
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location Order by dea.location
,dea.date) as rollingpeoplevac
from CovidDeaths$ dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingpeoplevac/Population) * 100 as vac_percentage 
from PopvsVac
--use CTE

--temp table
Drop table if exists #percentpopulationVaccinated
Create Table #percentpopulationVaccinated
(
Continent nvarchar(255),
location nvarchar (255),
Date datetime,
Population numeric,
new_vaccinations numeric,
rollingpeoplevac numeric 
)

insert into #percentpopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location Order by dea.location
,dea.date) as rollingpeoplevac
from CovidDeaths$ dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null

select *, (rollingpeoplevac/population)*100
from #percentpopulationVaccinated

--creating view to store data for vis

create view percentpopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(convert(int,vac.new_vaccinations)) over (partition by dea.location Order by dea.location
,dea.date) as rollingpeoplevac
from CovidDeaths$ dea
join CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *
from percentpopulationVaccinated