-- Which platforms have the largest audience?
DROP MATERIALIZED VIEW IF EXISTS platform_audience;

CREATE VIEW platform_audience AS
SELECT
    app,
    downloads
FROM
    platform_downloads
ORDER BY
    downloads DESC

-- Spotify has the largest audience with 18233 downloads, followed by apple podcasts with 3371 and our website in third place with 914 downloads.

-- What is the percentage share of each platform?
DROP MATERIALIZED VIEW IF EXISTS platform_percentage_share;

CREATE VIEW platform_percentage_share AS
SELECT
    app,
    downloads,
    ROUND(downloads * 100.0 / SUM(downloads) OVER (), 2) AS percentage_share
FROM
    platform_downloads
ORDER BY
    downloads DESC
-- Spotify holds the majority share with 73.78%, followed by apple podcasts with 13.64% and our website with 3.70%.


-- Identify platforms with a smaller audience
DROP MATERIALIZED VIEW IF EXISTS small_audience_platforms;

CREATE VIEW small_audience_platforms AS
SELECT
    app,
    downloads
FROM
    platform_downloads
WHERE
    downloads < 500
-- Platforms with less than 500 downloads include google podcasts, pocket casts, and others, indicating potential areas for growth or targeted marketing efforts.
-- Platforms such as Overcast, Castro, Castbox, Goodpods, and TrueFans are automatically available via Apple Podcasts, which may explain their lower individual download numbers.


-- What is the cumulative percentage of downloads for the top platforms?
DROP MATERIALIZED VIEW IF EXISTS platform_cumulative_percentage;

CREATE VIEW platform_cumulative_percentage AS

SELECT
    app,
    downloads,
    ROUND(
        SUM(downloads) OVER (ORDER BY downloads DESC) * 100.0 / SUM(downloads) OVER (), 
    2) AS cumulative_percentage
FROM platform_downloads
ORDER BY downloads DESC;
-- The top three platforms (Spotify, Apple Podcasts, and our website) account for approximately 91.12% of total downloads, indicating a strong concentration of audience on these platforms.
-- This suggests that focusing marketing and content strategies on these top platforms could be beneficial for maximizing reach and engagement.


-- Which platforms contribute to 80% of total downloads?
DROP MATERIALIZED VIEW IF EXISTS platforms_80_percent;

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
-- Platforms contributing to 80% of total downloads include Spotify and Apple Podcasts.

