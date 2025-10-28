-- Total downloads by platform
DROP MATERIALIZED VIEW IF EXISTS total_downloads_by_platform;

CREATE VIEW total_downloads_by_platform AS

SELECT
    app,
    SUM(downloads) AS total_downloads
FROM 
    platform_downloads
GROUP BY
    app
ORDER BY
    total_downloads DESC;

/* The highest three performing platforms by total downloads are Spotify,
Apple Podcasts and our publisher's website.
This indicates a strong listener preference for streaming via Spotify which
may influence our marketing and distribution strategies. The significant 
downloads from our publisher's website also highlight the importance of 
direct access to our content.*/


-- Total downloads by geography
DROP MATERIALIZED VIEW IF EXISTS total_downloads_by_geography;

CREATE VIEW total_downloads_by_geography AS

SELECT
    continent,
    SUM(downloads) AS total_downloads
FROM
    geo_downloads
GROUP BY
    continent
ORDER BY
    total_downloads DESC;

/* Unsurprisingly, Europe leads in total downloads, (due to the podcast 
being mainly in portuguese) followed by South America (in which Brazil is 
a portuguese speaking country) and North America. 
This suggests a strong listener base in these regions, which could guide 
future content localization and marketing efforts.*/

--Average downloads per episode
DROP MATERIALIZED VIEW IF EXISTS average_downloads_per_episode;

CREATE VIEW average_downloads_per_episode AS

SELECT
    ROUND(AVG(all_time_downloads), 2) AS avg_all_time_downloads
FROM
    episode_downloads;

/* The average downloads per episode is approximately 500. This metric provides 
a benchmark for evaluating the performance of individual episodes and can help 
identify trends in listener engagement over time.

We are a bit behind on our english language episodes, most of them being much 
more recently uploaded, the publish date doesn't reflect that due to us wanting 
to maintain a certain playlist order in the podcast platforms. Therefore, these
episodes tend to have much lower all-time downloads compared to the portuguese episodes 
*/


-- Downloads in the last 7 days
DROP MATERIALIZED VIEW IF EXISTS downloads_last_7_days;

CREATE VIEW downloads_last_7_days AS

SELECT
    SUM(downloads_last_7d) AS total_downloads_last_7_days
FROM
    episode_downloads;


-- Downloads in the last 30 days
DROP MATERIALIZED VIEW IF EXISTS downloads_last_30_days;

CREATE VIEW downloads_last_30_days AS

SELECT
    SUM(downloads_last_30d) AS total_downloads_last_30_days
FROM
    episode_downloads;


-- Downloads in the last 90 days
DROP MATERIALIZED VIEW IF EXISTS downloads_last_90_days;

CREATE VIEW downloads_last_90_days AS

SELECT
    SUM(downloads_last_90d) AS total_downloads_last_90_days
FROM
    episode_downloads;


-- Total all-time downloads
DROP MATERIALIZED VIEW IF EXISTS total_all_time_downloads;

CREATE VIEW total_all_time_downloads AS

SELECT
    SUM(all_time_downloads) AS total_all_time_downloads
FROM
    episode_downloads;