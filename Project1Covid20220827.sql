--Preview data

SELECT TOP 5 *
FROM Project1Covid..CovidDeaths
ORDER BY 3,4
 
SELECT TOP 5 *
FROM Project1Covid..CovidVaccinations
ORDER BY 3,4
 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project1Covid..CovidDeaths
ORDER BY 1,2
 
-- total deaths/total cases
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project1Covid..CovidDeaths
ORDER BY 1,2


-- United States total deaths/total cases
-- WHERE continent IS NOT NULL required because when it is NULL the location is showing results for the entire continent 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project1Covid..CovidDeaths
WHERE LOCATION = 'United States'
AND Continent IS NOT NULL
ORDER BY 1,2

-- % of population that got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationInfected
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2

-- Countries with highest infection rate compared to population 
SELECT location, population, MAX(total_cases) AS MaxInfectionCount, MAX((total_cases/population))*100 AS PercentPopluationInfected
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY location, Population
ORDER BY 4 DESC

-- Countries with highest death rate per population. 
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC
 
-- Continents with highest death rate per continent. 
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Global numbers
SELECT date, SUM(new_cases) AS GlovbalCasesPerDay, SUM(new_deaths) AS GlobalDeathsPerDay,
SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentagePerDay
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY 1,2
 
-- Global deaths/cases
SELECT SUM(new_cases) AS GlobalCases, SUM(new_deaths) AS GlobalDeaths,
SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM Project1Covid..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2
 
 
-- JOIN CovidDeaths table with CovidVaccinations table
SELECT *
FROM Project1Covid..CovidDeaths deaths
JOIN Project1Covid..CovidVaccinations vacc
   ON deaths.location = vacc.location
   AND deaths.date = vacc.date

-- JOINED tables to show number of new vaccinations per location per date
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations AS NewVaccinationsPerLocationPerDate
FROM Project1Covid..CovidDeaths deaths
JOIN Project1Covid..CovidVaccinations vacc
   ON deaths.location = vacc.location
   AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3
 
-- Rolling count of new vaccinations per location per day 

SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vacc.new_vaccinations AS NewVaccinationsPerLocationPerDate,
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM Project1Covid..CovidDeaths deaths
JOIN Project1Covid..CovidVaccinations vacc
   ON deaths.location = vacc.location
   AND deaths.date = vacc.date 
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3
 
-- Next we want to get percent rolling vaccinations per location per day / total population. 
-- Because RollingPeopleVaccinated it is a column we created in SQL and we cannot use it. 
-- To use it you need to create a CTE or temp table. The following WITH statement allows us to use the RollingPeopleVaccinated column to perform calculations. 

WITH PopvsVacc (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vacc.new_vaccinations AS NewVaccinationsPerLocationPerDate,
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM Project1Covid..CovidDeaths deaths
JOIN Project1Covid..CovidVaccinations vacc
   ON deaths.location = vacc.location
   AND deaths.date = vacc.date 
WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population) *100
FROM PopvsVacc

-- Create view for data storage and visualizations 
CREATE VIEW PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population,
vacc.new_vaccinations AS NewVaccinationsPerLocationPerDate,
SUM(vacc.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaccinated
FROM Project1Covid..CovidDeaths deaths
JOIN Project1Covid..CovidVaccinations vacc
  ON deaths.location = vacc.location
  AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL