-- Top countries by number of downloads
DROP MATERIALIZED VIEW IF EXISTS top_countries_by_downloads;

CREATE VIEW top_countries_by_downloads AS

SELECT
    country,
    SUM(downloads) AS total_downloads
FROM
    geo_downloads
GROUP BY
    country
ORDER BY
    total_downloads DESC
LIMIT 10;
/* The top countries by number of downloads are the United States, United Kingdom, Canada, 
Australia, and Germany, indicating a strong presence in English-speaking countries.
Although it must be said that the countries with the highest number of portuguese immigrants 
are also in the top 10, such as the UK, France, Switzerland, Germany, Spain, Luxembourg, Brazil and the US.*/


-- Top continents by number of downloads
DROP MATERIALIZED VIEW IF EXISTS top_continents_by_downloads;

CREATE VIEW top_continents_by_downloads AS

SELECT
    continent,
    SUM(downloads) AS total_downloads
FROM geo_downloads
GROUP BY continent
ORDER BY total_downloads DESC;
/* The top 3 continents by number of downloads are Europe, South America, and North America, 
reflecting the podcast's global reach and popularity across diverse regions.*/


-- City and state-level insights
DROP MATERIALIZED VIEW IF EXISTS top_cities_by_downloads;

CREATE VIEW top_cities_by_downloads AS

SELECT
    city,
    state,
    country,
    SUM(downloads) AS total_downloads
FROM geo_downloads
GROUP BY
    city,
    state,
    country
ORDER BY
    total_downloads DESC
LIMIT 10;
-- The cities with the highest number of downloads are Lisbon and Porto in Portugal.
-- This indicates a strong local audience in Portugal, particularly in major urban centers.


-- Top international cities by number of downloads (excluding Portugal)
DROP MATERIALIZED VIEW IF EXISTS top_international_cities_by_downloads;

CREATE VIEW top_international_cities_by_downloads AS

SELECT
    city,
    state,
    country,
    SUM(downloads) AS total_downloads
FROM geo_downloads
WHERE country != 'Portugal'
GROUP BY
    city,
    state,
    country
ORDER BY
    total_downloads DESC
LIMIT 10;
/* Internationally, the top 10 cities are Porto Alegre in Brazil, Madrid in Spain, 
Frankfurt am Main in Germany, Luanda in Angola, Luxemboug City in Luxembourg, 
Rio de Janeiro in Brazil, Curitiba in Brazil, Oslo in Norway, one or more undefined cities 
in the UK, and Woodbridge in Canada, showing the podcast's appeal in key cities around the world.*/


