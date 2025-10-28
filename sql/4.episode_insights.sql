-- What are the top 5 episodes with the highest all-time downloads?
DROP MATERIALIZED VIEW IF EXISTS top_5_episodes_by_all_time_downloads;

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
/* Our first 5 episodes in portuguese are the most downloaded ones.
This is not only because they are the first ones, but also because 
they are in portuguese which is the language of our main audience.

We can also see that the number of downloads drops significantly after the first 5 episodes.
This is related to the retention rate of our podcast.

This is a common pattern in these types of podcasts, where the first episodes are the most downloaded ones.
*/


-- What episodes that are currently trending?
DROP MATERIALIZED VIEW IF EXISTS trending_episodes;

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

/* This analysis identifies episodes that are currently trending based on their recent download growth.
The top trending episode is our most recent episode, which indicates a strong initial interest from our audience.
This is expected as new episodes often attract more attention shortly after release.

The last 10 episodes have growth_ratio 0 which means that there are no downloads in the last 7 days or 30 days.
These episodes have essentially flattened.

Trending episodes are not always the highest total downloads as we can see from our very first episode
"Portugal - D. Afonso I - Parte 1" which has the highest 7d and 30d downloads later in the list, but growth_ratio 
is low (0.16).
This shows that momentum and popularity are distinct metrics.

Multiple episodes can tie in growth rank which indicates similar growth patterns.
Rank gaps highlight that growth momentum has ties which is useful for highlighting clusters of trending content.
In this case, for the top trending episodes, the Interlude II story arc features 3 episodes on this list,
indicating that this arc is resonating well with our audience currently.
*/


/* What is the relative contribution and cumulative distribution over the last 90 days?
Which episodes contribute most to the total downloads?
Does a small number of episodes account for the majority of listens (Pareto principle)?
How concentrated is our audience across episodes?
*/
DROP MATERIALIZED VIEW IF EXISTS episode_contribution_last_90d;

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

/* Only 4 episodes fall into the Top 20% cumulative downloads. Together, these 4 episodes account for 18.68% of total 
downloads over the last 90 days. This shows audience attention is concentrated due to a small number of episodes driving
nearly a fifth of total listens.
This is a classic Pareto distribution: a few hits get the most attention, but many episodes accumulate the remaining 80% 
of downloads.

The Afonso I and Sancho II story arcs dominate the full range of the table.
The fact that the Sancho II story arc has 3 episodes in the top 20% indicates a strong engagement. This can be due to
the fact that Sancho II is the king which there is the least known information, so listeners are more curious about this period.

Our live episodes, which I named the Q&A Session arc, with our 1st anniversary episode and "Comunicado Real" contribute 
meaningfully (2–2.5% each).

Our audience gradually engages with the long tail, but a few episodes remain highly influential.
*/


-- Engagement metrics. How well episodes hold up over the long term? Which episodes perform steadily over 7-30–90 days?
DROP MATERIALIZED VIEW IF EXISTS episode_engagement_metrics;

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

/* 
After filtering out English episodes, we can see that:
- High short-term engagement corresponds to recent or popular episodes.
- Long-term engagement is 'Unknown' for episodes released in the last 90 days.
- Older episodes with high long-term engagement show sustained interest.
- Some episodes have high short-term but low/unknown long-term engagement due to recency.
- This helps identify which episodes perform well initially versus over time, guiding playlist inclusion and promotion.

*/

