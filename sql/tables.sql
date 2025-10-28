SELECT *
FROM episode_downloads
ORDER BY episode_index;

SELECT *
FROM geo_downloads

SELECT *
FROM platform_downloads


-- Check current user
SELECT current_user;

-- Grant SELECT permission on all materialized views to user 'postgres'
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT matviewname
        FROM pg_matviews
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'GRANT SELECT ON "' || r.matviewname || '" TO postgres;';
    END LOOP;
END $$;

SELECT * 
FROM total_all_time_downloads LIMIT 10;

SELECT matviewname
FROM pg_matviews
WHERE schemaname = 'public';


