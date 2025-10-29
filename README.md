# Kings_of_History_Podcast_Data_Analysis
A data analysis project personal to me on several different levels. As the creator, director and one of the writers for the Kings of History Podcast, and a data analyst in the making, I gathered data available related to my podcast and dived deep into it using SQL as the heavy lifter and Power B.I. to do the pretty.

# Overview
Waht is presented here is an end-to-end analysis with data gathered from the last 90 days of the Kings of History podcast, this podcast is a project that I've been working on for about a year and a half now with three friends of mine where we present to a broader audience the portuguese king's biographies in an educational and not too heavy style.
With the data that was provided from buzzsprout, our publisher, I managed to dive deep into the analytics of the show using SQL in PostgreSQL via VSCode to do all the queries that allowed me to gather insights on the performance, geography and trends currently affecting our many episodes.
There are three main categories that were studied:
  - Platform insights
  - Geography insights
  - Engagement insights
After the analysis was done, I created views so that I could easily import my findings to Power B.I. and create the visual dashboard that allows for a much better reading of the results the data provided me.

# Relevant Files
  - README.md → project explanation
  - Power BI dashboard → power_bi/podcast_stats.pbix
  - SQL queries → sql/...

# Tools Used
  - VSCode as the IDE
  - SQL in PostgreSQL
  - Power B.I.

# Data
The data was gathered directly from the source, buzzsprout. The three CSV files:
  - stats_agent_report.csv → data regarding the platforms we're distributed to.
  - stats_location_report.csv → data regarding the geographical locations of listeners.
  - stats_overview_report.csv → data regarding our downloads in the past 90 days.

## Database Building and Data Cleaning

### Database Building
```sql
--- Create the podcast_stats database
CREATE DATABASE podcast_stats;


-- Platform downloads table
CREATE TABLE platform_downloads (
    app TEXT,
    downloads INT
);

-- Geography downloads table
CREATE TABLE geo_downloads (
    city TEXT,
    state TEXT,
    country TEXT,
    continent TEXT,
    downloads INT
);

-- Episode downloads table
CREATE TABLE episode_downloads (
    episode_title TEXT,
    episode_id INT,
    publish_date DATE,
    publish_status TEXT,
    downloads_last_7d INT,
    downloads_last_30d INT,
    downloads_last_90d INT,
    all_time_downloads INT
);
```

### Database Cleaning
```sql
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


-- Checking for null values in all tables in the database

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
```

# Questions to be answered
  - On Platforms:
    - Which platforms have the largest audience?
    - What is the percentage share of each platform?
    - Identify platforms with small but non-zero audiences.
  - On Geography:
    - What are the top countries by downloads.
    - What are top continents by downloads.
    - Which cities/states generate the most views.
  - On Engagement:
    - Which are the most downloaded episodes all-time.
    - What is the episode growth momentum/trending dynamics?
    - How is the long-Term following?
    - What is the relative contribution and cumulative distribution of episodes like?
  - KPIs:
    - Total downloads by platform
    - Average downloads per episode
    - Downloads in the last 7 days
    - Downloads in the last 30 days
    - Downloads in the last 90 days

# The Analysis

## Platform Performance
### Which platforms have the largest audience?
```sql


CREATE VIEW platform_audience AS
SELECT
    app,
    downloads
FROM
    platform_downloads
ORDER BY
    downloads DESC
```

Spotify has the largest audience with 18233 downloads, followed by apple podcasts with 3371 and our website in third place with 914 downloads.


### What is the percentage share of each platform?
```sql

CREATE VIEW platform_percentage_share AS
SELECT
    app,
    downloads,
    ROUND(downloads * 100.0 / SUM(downloads) OVER (), 2) AS percentage_share
FROM
    platform_downloads
ORDER BY
    downloads DESC
```

Spotify holds the majority share with 73.78%, followed by apple podcasts with 13.64% and our website with 3.70%.

### Identify platforms with a smaller audience
```sql


CREATE VIEW small_audience_platforms AS
SELECT
    app,
    downloads
FROM
    platform_downloads
WHERE
    downloads < 500
```

Platforms with less than 500 downloads include google podcasts, pocket casts, and others, indicating potential areas for growth or targeted marketing efforts.
Platforms such as Overcast, Castro, Castbox, Goodpods, and TrueFans are automatically available via Apple Podcasts, which may explain their lower individual download numbers.

### What is the cumulative percentage of downloads for the top platforms?
```sql

CREATE VIEW platform_cumulative_percentage AS

SELECT
    app,
    downloads,
    ROUND(
        SUM(downloads) OVER (ORDER BY downloads DESC) * 100.0 / SUM(downloads) OVER (), 
    2) AS cumulative_percentage
FROM platform_downloads
ORDER BY downloads DESC;
```

The top three platforms (Spotify, Apple Podcasts, and our website) account for approximately 91.12% of total downloads, indicating a strong concentration of audience on these platforms.
This suggests that focusing marketing and content strategies on these top platforms could be beneficial for maximizing reach and engagement.

### Which platforms contribute to 80% of total downloads?
```sql

CREATE VIEW platforms_80_percent AS

WITH cte AS (
    SELECT
        app,
        downloads,
        ROUND(
            SUM(downloads) OVER (ORDER BY downloads DESC) * 100.0 / SUM(downloads) OVER (), 2) AS cumulative_percentage
    FROM platform_downloads
)
SELECT *
FROM cte
WHERE cumulative_percentage <= 80
ORDER BY downloads DESC;
```
Platforms contributing to 80% of total downloads are Spotify, Apple Podcasts, and our host, Buzzsprout.


Conclusion:

[TO FINISH]

## Which platforms have the largest audience?

```sql

```

## What is the percentage share of each platform?

## Identify platforms with a smaller audience.

## What is the cumulative percentage of downloads for the top platforms?

## Which platforms contribute to 80% of total downloads?

# Geography Insights

## Top countries by number of downloads.

## Top continents by number of downloads.

## City and state-level insights.

## Top international cities by number of downloads (excluding Portugal).

# Episode Insights

## What are the top 5 episodes with the highest all-time downloads?

## What episodes that are currently trending?

## What is the relative contribution and cumulative distribution over the last 90 days? Which episodes contribute most to the total downloads? Does a small number of episodes account for the majority of listens (Pareto principle)? How concentrated is our audience across episodes?

## Engagement metrics. How well episodes hold up over the long term? Which episodes perform steadily over 7-30–90 days?

# KPIs

## Total downloads by platform.

## Total downloads by geography.

## Average downloads per episode.

## Downloads in the last 7 days.

## Downloads in the last 30 days.

## Downloads in the last 90 days.

## Total all-time downloads
