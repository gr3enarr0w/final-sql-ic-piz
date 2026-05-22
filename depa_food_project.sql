CREATE DATABASE IF NOT EXISTS depa_food_project;
USE depa_food_project;

-- Preview datasets
SELECT * FROM noaa_temperature LIMIT 5;
SELECT * FROM census_population LIMIT 5;
SELECT * FROM yelp LIMIT 5;
SELECT * FROM google_trends_state LIMIT 5;
SELECT * FROM google_trends_time LIMIT 5;

-- Clean column types
ALTER TABLE noaa_temperature
MODIFY state VARCHAR(50),
MODIFY `year_month` VARCHAR(7);

ALTER TABLE yelp
MODIFY business_id VARCHAR(50) NOT NULL,
MODIFY state VARCHAR(50);

ALTER TABLE google_trends_state
MODIFY state VARCHAR(50);

ALTER TABLE census_population
MODIFY state_fips VARCHAR(2) NOT NULL,
MODIFY state VARCHAR(50);

ALTER TABLE google_trends_time
MODIFY `year_month` VARCHAR(7);

-- Add primary keys only if they do not already exist
-- Run these one by one. Skip any that say "Multiple primary key defined."

#ALTER TABLE census_population
#ADD PRIMARY KEY (state_fips);

SHOW INDEX FROM census_population;

ALTER TABLE yelp
ADD PRIMARY KEY (business_id);

ALTER TABLE noaa_temperature
ADD COLUMN noaa_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE google_trends_time
ADD COLUMN trends_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE google_trends_state
ADD COLUMN trends_state_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Indexes
CREATE INDEX idx_noaa_state_month
ON noaa_temperature(state, `year_month`);

CREATE INDEX idx_yelp_state
ON yelp(state);

CREATE INDEX idx_google_state
ON google_trends_state(state);

CREATE INDEX idx_census_state
ON census_population(state);

CREATE INDEX idx_trends_time_month
ON google_trends_time(`year_month`);

-- Check indexes
SHOW INDEX FROM noaa_temperature;
SHOW INDEX FROM google_trends_time;
SHOW INDEX FROM census_population;
SHOW INDEX FROM yelp;
SHOW INDEX FROM google_trends_state;

-- Test NOAA + Google Trends time join
SELECT 
    n.state,
    n.year_month,
    n.avg_temp,
    g.ice_cream,
    g.pizza
FROM noaa_temperature n
JOIN google_trends_time g
    ON n.year_month = g.year_month
LIMIT 10;

-- Analysis view: national monthly temp + trends
CREATE OR REPLACE VIEW vw_monthly_temp_trends AS
SELECT 
    n.year_month,
    AVG(n.avg_temp) AS national_avg_temp,
    AVG(g.ice_cream) AS ice_cream_interest,
    AVG(g.pizza) AS pizza_interest
FROM noaa_temperature n
JOIN google_trends_time g
    ON n.year_month = g.year_month
GROUP BY n.year_month;

SELECT * 
FROM vw_monthly_temp_trends
ORDER BY 'year_month';

-- Additional cleanup 

ALTER TABLE google_trends_time
MODIFY date DATE,
MODIFY season VARCHAR(20);

ALTER TABLE noaa_temperature
MODIFY month VARCHAR(10),
MODIFY date DATE;

ALTER TABLE yelp
MODIFY name VARCHAR(255),
MODIFY city VARCHAR(100);

-- Views

CREATE OR REPLACE VIEW vw_seasonal_trends AS
SELECT
    season,
    AVG(ice_cream) AS avg_ice_cream_interest,
    AVG(pizza) AS avg_pizza_interest
FROM google_trends_time
GROUP BY season;

CREATE OR REPLACE VIEW vw_state_interest AS
SELECT
    g.state,
    c.region,
    c.division,
    g.ice_cream,
    g.pizza,
    c.population_2025,
    
    (g.ice_cream / c.population_2025) * 100000 AS ice_cream_per_100k,
    (g.pizza / c.population_2025) * 100000 AS pizza_per_100k

FROM google_trends_state g
JOIN census_population c
    ON g.state = c.state;
    
    CREATE OR REPLACE VIEW vw_yelp_density AS
SELECT
    y.state,
    c.region,
    COUNT(*) AS business_count,
    AVG(y.stars) AS avg_rating,
    SUM(y.review_count) AS total_reviews
FROM yelp y
JOIN census_population c
    ON y.state = c.state
GROUP BY y.state, c.region;