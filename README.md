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
    - What are the top countries by downloads?
    - What are top continents by downloads?
    - Which cities/states generate the most views?
  - On Engagement:
    - Which are the most downloaded episodes all-time?
    - What is the episode growth momentum/trending dynamics?
    - How is the long-Term following?
    - What is the relative contribution and cumulative distribution of episodes like?
  - KPIs:
    - Total downloads by platform.
    - Average downloads per episode.
    - Downloads in the last 7 days.
    - Downloads in the last 30 days.
    - Downloads in the last 90 days.

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
|Platform          |Downloads|
|:----------------:|------:|
|Spotify           |18233   |
|Apple Podcasts    |3371    |
|Buzzsprout Website|914     |
|...               |...     |

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
|Platform          |Downloads|Percentage Share|
|:----------------:|--------:|---------------:|
|Spotify           |18233    |73.78           |
|Apple Podcasts    |3371     |13.64           |
|Buzzsprout Website|914      |3.70            |
|...               |...      |...             |

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
    downloads < 900
```

Platforms with less than 900 downloads include google podcasts, pocket casts, and others, indicating potential areas for growth or targeted marketing efforts.
Platforms such as Overcast, Castro, Castbox, and Goodpods are automatically available via Apple Podcasts, which may explain their lower individual download numbers.

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
|Platform          |Downloads|Cumulative Percentage|
|:----------------:|--------:|--------------------:|
|Spotify           |18233    |73.78                |
|Apple Podcasts    |3371     |87.42                |
|Buzzsprout Website|914      |91.11                |
|...               |...      |...                  |

The top three platforms (Spotify, Apple Podcasts, and our website) account for approximately 91.11% of total downloads, indicating a strong concentration of audience on these platforms.
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
Spotify alone contributes to over 73.78% of total downloads, and when combined with Apple Podcasts (13.64%) puts us well over the 80% threshold.
This highlights the dominance of these platforms in our overall download metrics and suggests that they are critical for our distribution strategy.

### Conclusion:

The platform analysis clearly demonstrates a highly concentrated listener base, with Spotify and Apple Podcasts driving the overwhelming majority of downloads. This concentration underscores the importance of prioritizing these platforms for continued growth and audience engagement. While secondary platforms currently contribute marginally, they present potential opportunities for incremental audience expansion through targeted promotion or cross-platform visibility strategies.



## Geography Insights

### Top countries by number of downloads.

```sql
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
```
|Country           |Downloads|
|:----------------:|--------:|
|Portugal          |21566    |
|United Kingdom    |513      |
|Brazil            |469      |
|Spain             |246      |
|Germany           |177      |
|United States     |164      |
|Denmark           |155      |
|Luxembourg        |132      |
|France            |125      |
|Switzerland       |125      |

The top countries by number of downloads are Portugal, United Kingdom, Brazil, Spain, Germany, US, Denmark, Luxembourg, France and Switzerland with a disproportionate presence in Portugal which is to be expected. Many of the other countries with a high count of downloads also have the highest number of portuguese immigrants, such as the UK, France, Switzerland, Germany, Spain, Luxembourg, Brazil and the US.

## Top continents by number of downloads.
```sql
CREATE VIEW top_continents_by_downloads AS

SELECT
    continent,
    SUM(downloads) AS total_downloads
FROM geo_downloads
GROUP BY continent
ORDER BY total_downloads DESC;
```
|Continent         |Downloads|
|:----------------:|--------:|
|Europe            |23566    |
|South America     |541      |
|North America     |277      |
|Africa            |153      |
|Asia              |121      |
|Australia         |58       |

The top 3 continents by number of downloads are Europe, South America, and North America, reflecting the podcast's global reach and popularity across diverse regions.

## City and state-level insights.

```sql
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
```

|City              |State    |Country              |Downloads|
|:----------------:|--------:|--------------------:|--------:|
|Lisbon            |Lisbon   |Portugal             |8497     |
|Porto             |Porto    |Portugal             |4440     |
|Amadora           |Lisbon   |Portugal             |420      |
|Unknown           |Unknown  |Portugal             |408      |
|Vila Nova de Gaia |Porto    |Portugal             |330      |
|Maia              |Porto    |Portugal             |311      |
|Braga             |Braga    |Portugal             |274      |
|Almada            |Setúbal  |Portugal             |250      |
|Coimbra           |Coimbra  |Portugal             |245      |
|Setúbal           |Setúbal  |Portugal             |236      |

The cities with the highest number of downloads are Lisbon and Porto in Portugal, which indicates a strong local audience in Portugal, particularly in the major urban centers.

## Top international cities by number of downloads (excluding Portugal).

```sql
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
```

|City              |State               |Country              |Downloads|
|:----------------:|-------------------:|--------------------:|--------:|
|Porto Alegre      |Rio Grande do Sul   |Brazil               |106      |
|Madrid            |Madrid              |Spain                |99       |
|Frankfurt am Main |Hesse               |Germany              |87       |
|Luanda            |Luanda Province     |Angola               |77       |
|Luxembourg        |Luxembourg          |Luxembourg           |71       |
|Rio de Janeiro    |Rio de Janeiro      |Brazil               |62       |
|Curitiba          |Paraná              |Brazil               |60       |
|Oslo              |Oslo County         |Norway               |54       |
|Unknown           |Unknown             |United Kingdom       |53       |
|Woodbridge        |Ontario             |Canada               |49       |

Internationally, the top 10 cities are Porto Alegre in Brazil, Madrid in Spain, Frankfurt am Main in Germany, Luanda in Angola, Luxemboug City in Luxembourg, Rio de Janeiro in Brazil, Curitiba in Brazil, Oslo in Norway, an unknown city in the UK, and Woodbridge in Canada, showing the podcast's appeal in key cities around the world.

# Episode Insights

## What are the top 5 episodes with the highest all-time downloads?

```sql
CREATE VIEW top_5_episodes_by_all_time_downloads AS

SELECT 
    episode_title,
    all_time_downloads,
    arc_name
FROM
    episode_downloads
ORDER BY
    all_time_downloads DESC
LIMIT 5;
```
|Episode Title             |Downloads   |Arc Name   |
|:------------------------:|-----------:|----------:|
|D. Afonso I - Part 1 - ...|2332        |Afonso I   |
|D. Afonso I - Part 2 - ...|1160        |Afonso I   |
|D. Afonso I - Part 3 - ...|995         |Afonso I   |
|D. Afonso I - Part 4 - ...|889         |Afonso I   |
|D. Afonso I - Part 5 - ...|789         |Afonso I   |

Our first 5 episodes in portuguese are the most downloaded ones.
This is not only because they are the first ones, but also because our narrative is chronological, therefore our viewers, will tend to start from the beginning.
We can also see that the number of downloads drops significantly after the first 5 episodes, which is related to the retention rate of our podcast. This is a common pattern in these types of podcasts, where the first episodes are the most downloaded ones.

## What episodes that are currently trending?

```sql
CREATE VIEW trending_episodes AS

WITH momentum_cte AS (
    SELECT
        episode_index,
        arc_name,
        episode_title,
        downloads_last_7d,
        downloads_last_30d,
        downloads_last_90d,
        (downloads_last_30d - downloads_last_7d) AS downloads_prev_23d,
        CASE
            WHEN (downloads_last_30d - downloads_last_7d) = 0 THEN 0
            ELSE ROUND((downloads_last_7d * 1.0) / (downloads_last_30d - downloads_last_7d), 2)
        END AS growth_ratio
    FROM
        episode_downloads
),

ranked_cte AS (
    SELECT
        *,
        RANK() OVER (ORDER BY growth_ratio DESC) AS growth_rank,
        SUM(downloads_last_7d) OVER () AS total_recent_downloads
    FROM
        momentum_cte
)

SELECT
    episode_index,
    episode_title,
    downloads_last_7d,
    downloads_prev_23d,
    downloads_last_30d,
    growth_ratio,
    growth_rank,
    arc_name,
    CASE
        WHEN growth_rank <= 5 THEN 'Top Trending'
        ELSE 'Regular'
    END AS trending,
    ROUND((downloads_last_7d * 100.0) / total_recent_downloads, 2) AS pct_recent_downloads
FROM
    ranked_cte
ORDER BY
    growth_rank
```
Note: I didn't include a table here due to it's sheer size. The analysis can be seen in the Power B.I. file.

This analysis identifies episodes that are currently trending based on their recent download growth based on a ratio of downloads from the last 7 and 30 days.
The top trending episode is our most recent episode, which indicates a strong initial interest from our audience as is expected as new episodes often attract more attention shortly after release not only to our long-time followes but also new ones that just found us out.

The last 10 episodes have growth ratio of 0, which means that there are no downloads in the previous 7 days or 30 days. These episodes have essentially flattened in this interval of time.

Trending episodes are not always the highest total downloads as we can see from our very first episode "Portugal - D. Afonso I - Parte 1" which has the highest all time downloads and one of the highest 30d downloads later in the list (ranked in 36), but growth_ratio is low (0.16).
This shows that momentum and popularity are distinct metrics.

Multiple episodes can tie in growth rank which indicates similar growth patterns. 
Rank gaps highlight that growth momentum has ties which is useful for highlighting clusters of trending content which in this case, for the top trending episodes, the Interlude II story arc features 3 episodes on this list, indicating that this arc is resonating well with our audience currently.

## What is the relative contribution and cumulative distribution over the last 90 days? Which episodes contribute most to the total downloads? Does a small number of episodes account for the majority of listens (Pareto principle)? How concentrated is our audience across episodes?

```sql
CREATE VIEW episode_contribution_last_90d AS

WITH contribution_cte AS (
    SELECT
        episode_index,
        episode_title,
        downloads_last_90d,
        ROUND((downloads_last_90d * 100.0) / SUM(downloads_last_90d) OVER (), 2) AS pct_of_total, --percentage of total downloads
        SUM(downloads_last_90d) OVER (ORDER BY downloads_last_90d DESC) AS cumulative_downloads, -- cumulative sum of downloads
        arc_name
    FROM
        episode_downloads
),

total_cte AS (
    SELECT
        *,
        ROUND(cumulative_downloads * 100.0 / SUM(downloads_last_90d) OVER (), 2) AS cumulative_pct, -- cumulative percentage
        CASE
            WHEN cumulative_downloads * 100.0 / SUM(downloads_last_90d) OVER () <= 20 THEN 'Top 20%' -- Top 20% contributors
            ELSE 'Other'
        END AS contribution_20
    FROM
        contribution_cte
)

SELECT
    episode_index,
    episode_title,
    downloads_last_90d,
    pct_of_total,
    cumulative_downloads,
    cumulative_pct,
    contribution_20,
    arc_name
FROM
    total_cte
ORDER BY
    downloads_last_90d DESC
```
Note: I didn't include a table here due to it's sheer size. The analysis can be seen in the Power B.I. file.

Only 4 episodes fall into the Top 20% cumulative downloads. Together, these 4 episodes account for 18.68% of total downloads over the last 90 days. 
This shows audience attention is concentrated due to a small number of episodes driving nearly a fifth of total listens. This is a classic Pareto distribution: a few hits get the most attention, but many episodes accumulate the remaining 80% of downloads.

The Afonso I and Sancho II story arcs dominate the top range of the table.
The fact that the Sancho II story arc has 3 episodes in the top 20% indicates a strong engagement. This can be due to the fact that Sancho II is the king of which there is the least known information, so listeners could be more curious about this period in time.

Our live episode, which I named the Q&A Session arc, with our 1st anniversary episode and "Comunicado Real" contribute meaningfully (2–2.5% respectivelly).

Our audience gradually engages with the long tail, but a few episodes remain highly influential.

## Engagement metrics. How well episodes hold up over the long term? Which episodes perform steadily over 7-30–90 days?

```sql
CREATE VIEW episode_engagement_metrics AS

WITH engagement_cte AS ( -- calculate short-term and long-term engagement ratios
    SELECT
        episode_index,
        episode_title,
        publish_date,
        downloads_last_7d,
        downloads_last_30d,
        downloads_last_90d,
        CASE 
            WHEN downloads_last_30d = 0 THEN 0
            ELSE ROUND(CAST(downloads_last_7d AS NUMERIC) / downloads_last_30d, 2) -- short term ratio
        END AS short_term_ratio,
        CASE 
            WHEN downloads_last_90d = 0 THEN 0
            ELSE ROUND(CAST(downloads_last_30d AS NUMERIC) / downloads_last_90d, 2) -- long term ratio
        END AS long_term_ratio
    FROM episode_downloads
),
ranked_cte AS ( -- rank episodes into tertiles based on short-term and long-term engagement ratios
    SELECT
        *,
        NTILE(3) OVER (ORDER BY short_term_ratio DESC) AS short_term_ntile,
        NTILE(3) OVER (ORDER BY long_term_ratio DESC) AS long_term_ntile
    FROM engagement_cte
)
SELECT
    episode_index,
    episode_title,
    publish_date,
    downloads_last_7d,
    downloads_last_30d,
    downloads_last_90d,
    short_term_ratio,
    long_term_ratio,
    CASE short_term_ntile
        WHEN 1 THEN 'High'
        WHEN 2 THEN 'Normal'
        WHEN 3 THEN 'Low'
    END AS short_term_engagement,
    CASE
        WHEN publish_date > DATE '2025-09-15' - INTERVAL '90 days' THEN 'Unknown' -- recent episodes
        WHEN long_term_ntile = 1 THEN 'High'
        WHEN long_term_ntile = 2 THEN 'Normal'
        WHEN long_term_ntile = 3 THEN 'Low'
    END AS long_term_engagement
FROM ranked_cte
WHERE episode_title NOT LIKE '%[EN]%' -- exclude non-portuguese episodes due to the registered publishing date not being the actual date of release. This would skew the engagement ratios.
ORDER BY
    short_term_ntile ASC,
    long_term_ntile ASC;
```
Note: I didn't include a table here due to it's sheer size. The analysis can be seen in the Power B.I. file.

After filtering out English episodes due to some of them being quite recent and skewing data insight, we can see that the high short-term engagement corresponds to recent or popular episodes.
Long-term engagement is 'Unknown' for episodes released in the last 90 days as it would be unfair to judge them comparatively to older episodes this way.
Older episodes with high long-term engagement show sustained interest which can be an indicator of the project's growth since it would make sense for our new audience to start listening from the beginning
Some episodes have high short-term but low/unknown long-term engagement due to recency, this is especially sound when compared to our first episodes for example.
This helps identify which episodes perform well initially versus over time, guiding playlist inclusion and promotion.

# KPIs

## Total all-time downloads.

```sql
CREATE VIEW total_all_time_downloads AS

SELECT
    SUM(all_time_downloads) AS total_all_time_downloads
FROM
    episode_downloads;
```

|Total All Time Downloads|
|:----------------------:|
|24714                   |

## Average downloads per episode.

```sql
CREATE VIEW average_downloads_per_episode AS

SELECT
    ROUND(AVG(all_time_downloads), 2) AS avg_all_time_downloads
FROM
    episode_downloads;
```

|Avg Downloads per Episode|
|:-----------------------:|
|515                      |

We are a bit behind on our english language episodes, most of them being much more recently uploaded, the publish date doesn't reflect that due to us wanting to maintain a certain playlist order in the podcast platforms. Therefore, these episodes tend to have much lower all-time downloads compared to the portuguese episodes, therefore skewing this average.

## Downloads in the last 7 days.

```sql
CREATE VIEW downloads_last_7_days AS

SELECT
    SUM(downloads_last_7d) AS total_downloads_last_7_days
FROM
    episode_downloads;
```

|Downloads Last 7 Days|
|:-------------------:|
|1119                 |

## Downloads in the last 30 days.

```sql
CREATE VIEW downloads_last_30_days AS

SELECT
    SUM(downloads_last_30d) AS total_downloads_last_30_days
FROM
    episode_downloads;
```

|Downloads Last 30 Days|
|:--------------------:|
|5669                  |

## Downloads in the last 90 days.

```sql
CREATE VIEW downloads_last_90_days AS

SELECT
    SUM(downloads_last_90d) AS total_downloads_last_90_days
FROM
    episode_downloads;
```

|Downloads Last 90 Days|
|:--------------------:|
|12052                 |
