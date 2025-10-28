-- Checking column headers in all tables in the database

SELECT *
FROM information_schema.columns
WHERE table_name = 'platform_downloads'

SELECT *
FROM information_schema.columns
WHERE table_name = 'geo_downloads'

SELECT *
FROM information_schema.columns
WHERE table_name = 'episode_downloads'


-- checking for null values in all tables in the database

SELECT *
FROM platform_downloads
WHERE 
    app IS NULL OR
    downloads IS NULL;
-- There are no null values in platform_downloads table

SELECT *
FROM geo_downloads
WHERE 
    city IS NULL OR
    state IS NULL OR
    country IS NULL OR
    continent IS NULL OR
    downloads IS NULL;
/* There are some null values in city and state columns, but this is expected as not all 
downloads will have this information as it could be dependent on user privacy settings */

SELECT *
FROM episode_downloads
WHERE 
    episode_title IS NULL OR
    episode_id IS NULL OR
    publish_date IS NULL OR
    publish_status IS NULL OR
    downloads_last_7d IS NULL OR
    downloads_last_30d IS NULL OR
    downloads_last_90d IS NULL OR
    all_time_downloads IS NULL;
-- There are no null values in episode_downloads table


-- Standardising NULL values in city and state columns of geo_downloads table to 'Unknown'
UPDATE geo_downloads
SET city = COALESCE(NULLIF(city, ''), 'Unknown'),
    state = COALESCE(NULLIF(state, ''), 'Unknown')

SELECT *
FROM geo_downloads
-- Null values in city and state columns have been standardised to 'Unknown'


-- Adding publish_year and publish_month columns to episode_downloads table for easier analysis
ALTER TABLE episode_downloads
ADD COLUMN publish_year INT,
ADD COLUMN publish_month INT;

UPDATE episode_downloads
SET publish_year = EXTRACT(YEAR FROM publish_date),
    publish_month = EXTRACT(MONTH FROM publish_date);


-- Adding publish_day column to episode_downloads table for more specific day-to-day analysis
ALTER TABLE episode_downloads
ADD COLUMN publish_day INT;

UPDATE episode_downloads
SET publish_day = EXTRACT(DAY FROM publish_date);

SELECT *
FROM episode_downloads


-- Changing one of the platform names in platform_downloads table for clarity

UPDATE platform_downloads
SET app = 'Buzzsprout Website'
WHERE app = 'Web Browser';
-- The platform name has been changed from 'Web Browser' to 'Buzzsprout Website'


-- Creating an index in episode_downloads table to improve insight and query performance
ALTER TABLE episode_downloads
ADD COLUMN episode_index INT;

WITH ordered AS (
    SELECT
        episode_id,
        ROW_NUMBER() OVER (ORDER BY publish_date) AS rn
    FROM episode_downloads
)
UPDATE episode_downloads
SET episode_index = ordered.rn
FROM ordered
WHERE episode_downloads.episode_id = ordered.episode_id;

SELECT *
FROM episode_downloads
ORDER BY episode_index;

-- Adding a language column to episode_downloads table to identify the language of each episode
ALTER TABLE episode_downloads
ADD COLUMN language VARCHAR(2);

UPDATE episode_downloads
SET language = CASE
    WHEN episode_title LIKE '%[EN]%' THEN 'EN'
    ELSE 'PT'
END;

-- Updating the episode_index to reset for each language in episode_downloads table
WITH ordered AS (
    SELECT
        episode_id,
        ROW_NUMBER() OVER (PARTITION BY language ORDER BY publish_date) AS episode_index
    FROM episode_downloads
)
UPDATE episode_downloads
SET episode_index = ordered.episode_index
FROM ordered
WHERE episode_downloads.episode_id = ordered.episode_id;

-- Adding an arc_name column to episode_downloads table to categorize episodes into different story arcs
ALTER TABLE episode_downloads
ADD COLUMN arc_name VARCHAR(50);

-- Assigning arc names based on episode_index and language in episode_downloads table
UPDATE episode_downloads
SET arc_name = CASE
    WHEN language = 'PT' AND episode_index BETWEEN 1 AND 5 THEN 'Afonso I'
    WHEN language = 'PT' AND episode_index BETWEEN 6 AND 7 THEN 'Interlude I'
    WHEN language = 'PT' AND episode_index BETWEEN 8 AND 13 THEN 'Sancho I'
    WHEN language = 'PT' AND episode_index BETWEEN 14 AND 17 THEN 'Interlude II'
    WHEN language = 'PT' AND episode_index BETWEEN 18 AND 23 THEN 'Afonso II'
    WHEN language = 'PT' AND episode_index BETWEEN 24 AND 24 THEN 'Interlude III'
    WHEN language = 'PT' AND episode_index IN (25, 26, 27, 28, 30, 32) THEN 'Sancho II'
    WHEN language = 'PT' AND episode_index IN (29, 31) THEN 'Q&A Session'
    WHEN language = 'PT' AND episode_index BETWEEN 33 AND 34 THEN 'Interlude IV'
    WHEN language = 'PT' AND episode_index BETWEEN 35 AND 35 THEN 'Afonso III'
    WHEN language = 'EN' AND episode_index BETWEEN 1 AND 5 THEN 'Afonso I [EN]'
    WHEN language = 'EN' AND episode_index BETWEEN 6 AND 7 THEN 'Interlude I [EN]'
    WHEN language = 'EN' AND episode_index BETWEEN 8 AND 13 THEN 'Sancho I [EN]'
    /* add more arcs as needed */
    ELSE 'Other'
END;

SELECT *
FROM episode_downloads
ORDER BY episode_index;
