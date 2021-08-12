# COVID-19 Data Exploration 
# Dataset: https://ourworldindata.org/covid-deaths
# Data pulled on July 6th 2021

# This portfolio piece is to demonstrate some of my SQL skills.
# Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types 



# Creating Database 
CREATE SCHEMA portfolioproject_COVID19_DataExploration;

# import the following tables 
# CovidDeaths.csv
# CovidVaccinations.csv 

# Quick View of the Tables
Select * 
FROM coviddeaths 
ORDER BY 3,4;

DESC coviddeaths;

Select * 
FROM covidvaccinations
ORDER BY 3,4;

DESC covidvaccinations;

# Select Data that we are going to be using 
SELECT location, 
       date, 
       total_cases,
       new_cases,
       total_deaths, 
       population
FROM coviddeaths
ORDER BY 1,2;

# Looking at Total Cases vs Total Deaths 
# Shows likelihood of dying if you contract covid in your country 
SELECT location, 
       date, 
       total_cases,
       total_deaths,
       (total_deaths/total_cases)*100 AS DeathPct 
FROM coviddeaths
WHERE location LIKE "%Canada%"
ORDER BY 1,2;

# Looking at Total Cases vs Population
# Shows what percentage of population got Covid
SELECT location, 
       date, 
       total_cases,
       population,
       (total_cases/population)*100 AS PctPopluationInfected 
FROM coviddeaths
#WHERE location LIKE "%Canada%"
ORDER BY 1,2;

# Looking at Countries with Highest Infection Rate compared to Population
SELECT location, 
       population, 
       MAX(total_cases) AS HighestInfectionCount,
       MAX((total_cases/population))*100 AS PctPopulationInfected 
FROM coviddeaths
GROUP BY location, population
ORDER BY PctPopulationInfected DESC;

# Showing Countries with Highest Death Count per Population 
# total_deaths was set to text dtype when loaded in, I cast it to as UNSIGNED
# we need to filter out the continent or continents will show in the rankings
DESC coviddeaths;
 
SELECT location, 
       MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

# Let's break things down by continent 
# Showing contintents with the highest death count per population 
SELECT location,
       MAX(cast(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

# GLOBAL NUMBERS Per Day 
SELECT date, 
       SUM(new_cases) AS TotalCases,
	   SUM(new_deaths) AS TotalDeaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent != ''
GROUP BY date 
ORDER BY 1,2;

# Total Global Numbers
SELECT SUM(new_cases) AS TotalCases,
	   SUM(new_deaths) AS TotalDeaths,
	   SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE continent != '' 
ORDER BY 1,2;

# Looking at Total Population vs Vaccinations 
# Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT cdeaths.continent, 
	   cdeaths.location, 
	   cdeaths.date, 
       cdeaths.population, 
       cvac.new_vaccinations,
       SUM(cvac.new_vaccinations) OVER (PARTITION BY cdeaths.location ORDER BY cdeaths.location, cdeaths.date) AS RollingCitizenVaccinated       
FROM coviddeaths AS cdeaths
JOIN covidvaccinations AS cvac
ON cdeaths.location = cvac.location AND 
   cdeaths.date = cvac.date
WHERE cdeaths.continent != ''
ORDER BY 2,3; 

# USE CTE to perform Calculation on Partition By in previous query 
WITH PopvsVAC (continent, location, date, population, new_vaccinations, RollingCitizensVaccinated)
AS 
(
SELECT cdeaths.continent, 
	   cdeaths.location, 
	   cdeaths.date, 
       cdeaths.population, 
       cvac.new_vaccinations,
       SUM(cvac.new_vaccinations) OVER (PARTITION BY cdeaths.location ORDER BY cdeaths.location, cdeaths.date) AS RollingCitizensVaccinated       
FROM coviddeaths AS cdeaths
JOIN covidvaccinations AS cvac
ON cdeaths.location = cvac.location AND 
   cdeaths.date = cvac.date
WHERE cdeaths.continent != '' 
)
SELECT *, (RollingCitizensVaccinated / Population) * 100 AS PopulationVaccinatedPercentage 
FROM PopvsVAC;

# Using Temp Table to peform Calculation on Partition By in previous query 
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(continent varchar(255),
 location varchar(255),
 date datetime,
 population numeric,
 new_vaccinations varchar(255),
 RollingCitizensVaccinated numeric
);
  
INSERT INTO PercentPopulationVaccinated
SELECT cdeaths.continent, 
	   cdeaths.location, 
	   cdeaths.date, 
       cdeaths.population, 
       cvac.new_vaccinations,
       SUM(cvac.new_vaccinations) OVER (PARTITION BY cdeaths.location ORDER BY cdeaths.location, cdeaths.date) AS RollingCitizensVaccinated       
FROM coviddeaths AS cdeaths
JOIN covidvaccinations AS cvac
ON cdeaths.location = cvac.location AND 
   cdeaths.date = cvac.date
WHERE cdeaths.continent != '';

SELECT *, (RollingCitizensVaccinated/Population)*100 AS PctPopulationVaccinated
From PercentPopulationVaccinated;

# Create View to store data for later visualizations 
DROP VIEW IF EXISTS PercentPopulationVaccinated;
CREATE VIEW PercentPopulationVaccinated AS 
SELECT cdeaths.continent, 
	   cdeaths.location, 
	   cdeaths.date, 
       cdeaths.population, 
       cvac.new_vaccinations,
       SUM(cvac.new_vaccinations) OVER (PARTITION BY cdeaths.location ORDER BY cdeaths.location, cdeaths.date) AS RollingCitizensVaccinated       
FROM coviddeaths AS cdeaths
JOIN covidvaccinations AS cvac
ON cdeaths.location = cvac.location AND 
   cdeaths.date = cvac.date
WHERE cdeaths.continent != ''
ORDER BY 2,3;