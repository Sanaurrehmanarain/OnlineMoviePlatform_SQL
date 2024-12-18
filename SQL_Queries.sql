use netflix;
SELECT * FROM netflix_titles;

SELECT 
COUNT(*) as total_count
FROM netflix_titles;

SELECT 
DISTINCT type
from netflix_titles;

SELECT 
DISTINCT rating
from netflix_titles;

SELECT 
DISTINCT country
from netflix_titles;

-- Business Problems

-- (1) Count the number of Movies vs TV-Shows
-----------------------------------------------------

SELECT 
type,
COUNT(*) AS total_count
FROM netflix_titles
GROUP BY type;

-- (2) Find the most common rating for movies and TV shows
---------------------------------------------------------------

SELECT 
    type,
    rating
FROM (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count,
        RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
    FROM netflix_titles
    GROUP BY type, rating
) AS t1
WHERE ranking = 1;

-- (3) List all movies realeased in a specific year (e.g ,2000)
---------------------------------------------------------------------

SELECT *
FROM netflix_titles

WHERE release_year = 2000
AND type = 'Movie';

-- (4) Find the top 5  contries with the most content on Netflix
-----------------------------------------------------------------------
SELECT 
    new_country,
    COUNT(*) as total_content
FROM (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', n.n), ',', -1)) AS new_country
    FROM netflix_titles
    JOIN (
        SELECT a.N + b.N * 10 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n
    WHERE n.n <= 1 + LENGTH(country) - LENGTH(REPLACE(country, ',', ''))
) AS countries
WHERE new_country != ''
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;

/* 
SELECT 
    country,
    COUNT(*) as total_content
FROM 
	netflix_titles
WHERE
	country IS NOT NULL
GROUP BY 
	country
ORDER BY 
	total_content DESC
LIMIT 5;

It will works if the country column in netflix_titles table does not contain comma-separated values 
(i.e., each row represents a single country). If the country column contains multiple countries in a 
single row (comma-separated), this query will treat the entire string as a single entity, potentially skewing the results.
*/

-- (5) Identify the longest movie?
----------------------------------------------------------

SELECT *
FROM netflix_titles
WHERE type = 'Movie'
ORDER BY 
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- (6) Find content added in last 5 years 
-----------------------------------------------------

SELECT title, type, date_added, release_year
FROM netflix_titles
WHERE date_added >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
ORDER BY date_added DESC;

-- (7a) Find all the movies/tv shows by director "Eva Orner"
-----------------------------------------------------------------------

SELECT 
	* 
FROM 
	netflix_titles
WHERE 
	director = "Eva Orner";
    
-- (7b) If you want to make the search more flexible (in case of slight name variations or partial matches).
-----------------------------------------------------------------------
 
SELECT title, type, release_year, rating, duration
FROM netflix_titles
WHERE director LIKE '%Eva Orner%';

-- (7c) To get the count of their works.
-----------------------------------------------------------------------

SELECT 
    COUNT(*) as total_works,
    COUNT(DISTINCT type) as work_types
FROM netflix_titles
WHERE director LIKE '%Eva Orner%';

-- (8) List all  TV shows with more than 5 seasons
----------------------------------------------------------

SELECT title, duration, release_year, rating
FROM netflix_titles
WHERE 
    type = 'TV Show'
    AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5
ORDER BY 
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC;

-- (9) Count the number of content items in each genre
-----------------------------------------------------------------

SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.listed_in, ',', n.n), ',', -1)) as genre,
    COUNT(*) as content_count
FROM 
    netflix_titles t
    CROSS JOIN (
        SELECT 1 AS n UNION ALL
        SELECT 2 UNION ALL
        SELECT 3 UNION ALL
        SELECT 4 UNION ALL
        SELECT 5
    ) n 
WHERE 
    n.n <= LENGTH(t.listed_in) - LENGTH(REPLACE(t.listed_in, ',', '')) + 1
    AND listed_in IS NOT NULL
GROUP BY 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.listed_in, ',', n.n), ',', -1))
ORDER BY 
    content_count DESC;
    
/* 
Alternative simplified version (if you just want to count exact matches without splitting)
SELECT 
    listed_in,
    COUNT(*) as content_count
FROM netflix_titles
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY content_count DESC;
*/

-- (10a) Find each year  and the average numbers of content rleased by India on Netflix.
------------------------------------------------------------------------------------------------

SELECT 
    release_year,
    COUNT(*) as total_content,
    AVG(CASE 
        WHEN type = 'Movie' THEN 1 
        ELSE 0 
    END) as avg_movies,
    AVG(CASE 
        WHEN type = 'TV Show' THEN 1 
        ELSE 0 
    END) as avg_tv_shows
FROM netflix_titles
WHERE 
    country LIKE '%India%'
    AND release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC;

-- (10b) Alternative version with percentages:
------------------------------------------------------------------------------------------------

SELECT 
    release_year,
    COUNT(*) as total_content,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) 
                               FROM netflix_titles 
                               WHERE country LIKE '%India%')), 2) as percentage_of_total,
    ROUND(AVG(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) * 100, 2) as movie_percentage,
    ROUND(AVG(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) * 100, 2) as tv_show_percentage
FROM netflix_titles
WHERE 
    country LIKE '%India%'
    AND release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year DESC;

-- (11) List all movies that are documentaries
------------------------------------------------------------------------------------------------

SELECT 
    *
FROM 
	netflix_titles
WHERE 
    type = 'Movie'
    AND listed_in LIKE '%Documentaries%'
ORDER BY 
    release_year DESC;

-- (12) Find all content without a director
------------------------------------------------------------------------------------------------

SELECT 
	* 
FROM
	netflix_titles
WHERE 
	director IS NULL
     OR director = ''
ORDER BY 
    type, release_year DESC;

-- (13) Find how many movies actor 'Salman Khan' appeared in last 10 years !
------------------------------------------------------------------------------------------------

SELECT 
	*
FROM 
	netflix_titles
WHERE 
	cast LIKE '%Salman Khan%'
AND 
release_year >EXTRACT(YEAR FROM CURRENT_DATE)-10

-- (14) Find the top 10 actor who have appeared in the highest number of movies prouced in India
------------------------------------------------------------------------------------------------

WITH RECURSIVE ActorList AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.cast, ',', n.n), ',', -1)) as actor_name,
        t.title,
        t.release_year
    FROM 
        netflix_titles t
        CROSS JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 
            UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6
            UNION ALL SELECT 7 UNION ALL SELECT 8
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n
    WHERE 
        t.country LIKE '%India%'
        AND t.type = 'Movie'
        AND t.cast IS NOT NULL
        AND LENGTH(t.cast) - LENGTH(REPLACE(t.cast, ',', '')) >= n.n - 1
)
SELECT 
    actor_name,
    COUNT(*) as movie_count,
    GROUP_CONCAT(DISTINCT release_year ORDER BY release_year) as years_active,
    MIN(release_year) as earliest_movie,
    MAX(release_year) as latest_movie
FROM 
    ActorList
WHERE 
    actor_name != ''
GROUP BY 
    actor_name
ORDER BY 
    movie_count DESC, 
    actor_name
LIMIT 10;
    
-- (15) 
-- Catagorize the content based on the presence of the key words 'kill' and 'voilence' in the description
-- field. Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into 
-- each catagory.
------------------------------------------------------------------------------------------------

WITH categorized_content AS (
    SELECT 
        *,
        CASE
            WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad_Content'
            ELSE 'Good_Content'
        END AS category
    FROM netflix_titles
)
SELECT category, COUNT(*) AS total_count
FROM categorized_content
GROUP BY category;

-- (16) Identify Seasonal Trends in Content Additions.
-- Find which month has the highest number of content additions over the years.
------------------------------------------------------------------------------------------------

SELECT 
    MONTH(date_added) as month_number,
    MONTHNAME(date_added) as month_name,
    COUNT(*) as content_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies_added,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as shows_added
FROM netflix_titles
WHERE 
    date_added IS NOT NULL
GROUP BY 
    MONTH(date_added),
    MONTHNAME(date_added)
ORDER BY 
    content_added DESC;

-- (17a) Popular Genre by Year
-- Identify the most popular genre for each year.
------------------------------------------------------------------------------------------------

WITH GenreSplit AS (
    SELECT 
        release_year,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.listed_in, ',', n.n), ',', -1)) as genre
    FROM 
        netflix_titles t
        CROSS JOIN (
            SELECT 1 AS n UNION ALL 
            SELECT 2 UNION ALL 
            SELECT 3 UNION ALL 
            SELECT 4 UNION ALL 
            SELECT 5
        ) n
    WHERE 
        LENGTH(t.listed_in) - LENGTH(REPLACE(t.listed_in, ',', '')) >= n.n - 1
),
GenreCounts AS (
    SELECT 
        release_year,
        genre,
        COUNT(*) as genre_count,
        RANK() OVER (PARTITION BY release_year ORDER BY COUNT(*) DESC) as genre_rank
    FROM 
        GenreSplit
    WHERE 
        genre IS NOT NULL 
        AND genre != ''
        AND release_year IS NOT NULL
    GROUP BY 
        release_year, 
        genre
)
SELECT 
    gc.release_year,
    gc.genre as most_popular_genre,
    gc.genre_count,
    ROUND((gc.genre_count * 100.0 / 
        (SELECT COUNT(*) 
         FROM GenreSplit gs 
         WHERE gs.release_year = gc.release_year)
    ), 2) as percentage_of_year
FROM 
    GenreCounts gc
WHERE 
    genre_rank = 1
ORDER BY 
    release_year DESC;
    
-- (17b)  runner-up genres:
------------------------------------------------------------------------------------------------
    
WITH GenreSplit AS (
    SELECT 
        release_year,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.listed_in, ',', n.n), ',', -1)) as genre
    FROM 
        netflix_titles t
        CROSS JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        ) n
    WHERE 
        LENGTH(t.listed_in) - LENGTH(REPLACE(t.listed_in, ',', '')) >= n.n - 1
),
GenreCounts AS (
    SELECT 
        release_year,
        genre,
        COUNT(*) as genre_count,
        DENSE_RANK() OVER (PARTITION BY release_year ORDER BY COUNT(*) DESC) as genre_rank
    FROM 
        GenreSplit
    WHERE 
        genre IS NOT NULL 
        AND genre != ''
        AND release_year IS NOT NULL
    GROUP BY 
        release_year, 
        genre
)
SELECT 
    gc.release_year,
    MAX(CASE WHEN genre_rank = 1 THEN CONCAT(genre, ' (', genre_count, ')') END) as top_genre,
    MAX(CASE WHEN genre_rank = 2 THEN CONCAT(genre, ' (', genre_count, ')') END) as second_genre,
    MAX(CASE WHEN genre_rank = 3 THEN CONCAT(genre, ' (', genre_count, ')') END) as third_genre
FROM 
    GenreCounts gc
WHERE 
    genre_rank <= 3
GROUP BY 
    release_year
ORDER BY 
    release_year DESC;

-- (18a) Content Share by Show Type Over Time
-- Analyze the proportion of Movies vs. TV Shows added every year.
------------------------------------------------------------------------------------------------

SELECT 
    YEAR(date_added) as year_added,
    COUNT(*) as total_content,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows,
    ROUND((COUNT(CASE WHEN type = 'Movie' THEN 1 END) * 100.0 / COUNT(*)), 2) as movie_percentage,
    ROUND((COUNT(CASE WHEN type = 'TV Show' THEN 1 END) * 100.0 / COUNT(*)), 2) as tv_show_percentage
FROM netflix_titles
WHERE 
    date_added IS NOT NULL
GROUP BY 
    YEAR(date_added)
ORDER BY 
    year_added DESC;

-- (18b) Trend Analysis
------------------------------------------------------------------------------------------------
WITH YearlyStats AS (
    SELECT 
        YEAR(date_added) as year_added,
        COUNT(*) as total_content,
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) as movies,
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) as tv_shows
    FROM netflix_titles
    WHERE date_added IS NOT NULL
    GROUP BY YEAR(date_added)
)
SELECT 
    year_added,
    total_content,
    movies,
    tv_shows,
    ROUND((movies * 100.0 / total_content), 2) as movie_percentage,
    ROUND((tv_shows * 100.0 / total_content), 2) as tv_show_percentage,
    ROUND(((movies - LAG(movies) OVER (ORDER BY year_added)) * 100.0 / 
        LAG(movies) OVER (ORDER BY year_added)), 2) as movie_growth,
    ROUND(((tv_shows - LAG(tv_shows) OVER (ORDER BY year_added)) * 100.0 / 
        LAG(tv_shows) OVER (ORDER BY year_added)), 2) as tv_show_growth
FROM YearlyStats
ORDER BY year_added DESC;

-- (19) Directors with Most Content by Genre
-- Find the top directors producing content for each genre.
------------------------------------------------------------------------------------------------

WITH split_genres AS (
  SELECT 
    director,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n), ',', -1)) as genre
  FROM netflix_titles
  CROSS JOIN (
    SELECT 1 as n UNION ALL
    SELECT 2 UNION ALL
    SELECT 3
  ) n
  WHERE director != ''
  AND n.n <= 1 + LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', ''))
),
director_genre_count AS (
  SELECT 
    genre,
    director,
    COUNT(*) as content_count,
    RANK() OVER (PARTITION BY genre ORDER BY COUNT(*) DESC) as rnk
  FROM split_genres
  GROUP BY genre, director
)
SELECT 
  genre,
  director,
  content_count
FROM director_genre_count
WHERE rnk = 1
ORDER BY content_count DESC;

-- (20) Identify Content Gaps
-- List genres or countries with no content added in the last 2 years.
------------------------------------------------------------------------------------------------

-- First for Genres
WITH split_genres AS (
  SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n), ',', -1)) as genre,
    date_added,
    YEAR(date_added) as year_added
  FROM netflix_titles
  CROSS JOIN (
    SELECT 1 as n UNION ALL
    SELECT 2 UNION ALL
    SELECT 3
  ) n
  WHERE n.n <= 1 + LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', ''))
),
all_genres AS (
  SELECT DISTINCT genre FROM split_genres
),
recent_genres AS (
  SELECT DISTINCT genre 
  FROM split_genres
  WHERE year_added >= YEAR(CURDATE()) - 2
)
SELECT ag.genre AS genres_with_no_recent_content
FROM all_genres ag
LEFT JOIN recent_genres rg ON ag.genre = rg.genre
WHERE rg.genre IS NULL;

-- Then for Countries
WITH split_countries AS (
  SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', n.n), ',', -1)) as country,
    date_added,
    YEAR(date_added) as year_added
  FROM netflix_titles
  CROSS JOIN (
    SELECT 1 as n UNION ALL
    SELECT 2 UNION ALL
    SELECT 3
  ) n
  WHERE n.n <= 1 + LENGTH(country) - LENGTH(REPLACE(country, ',', ''))
  AND country IS NOT NULL
  AND country != ''
),
all_countries AS (
  SELECT DISTINCT country FROM split_countries
),
recent_countries AS (
  SELECT DISTINCT country 
  FROM split_countries
  WHERE year_added >= YEAR(CURDATE()) - 2
)
SELECT ac.country AS countries_with_no_recent_content
FROM all_countries ac
LEFT JOIN recent_countries rc ON ac.country = rc.country
WHERE rc.country IS NULL;

-- (21) Audience Retention Analysis by Content Duration
-- Problem: Categorize movies into buckets based on their duration and analyze their count.
------------------------------------------------------------------------------------------------

WITH movie_durations AS (
    SELECT 
        CASE 
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 60 THEN 'Under 1 hour'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 90 THEN '1-1.5 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 120 THEN '1.5-2 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 150 THEN '2-2.5 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 180 THEN '2.5-3 hours'
            ELSE 'Over 3 hours'
        END as duration_bucket,
        COUNT(*) as movie_count
    FROM netflix_titles
    WHERE 
        type = 'Movie'
        AND duration LIKE '%min%'
    GROUP BY 
        CASE 
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 60 THEN 'Under 1 hour'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 90 THEN '1-1.5 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 120 THEN '1.5-2 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 150 THEN '2-2.5 hours'
            WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS SIGNED) <= 180 THEN '2.5-3 hours'
            ELSE 'Over 3 hours'
        END
)
SELECT 
    duration_bucket,
    movie_count,
    ROUND(movie_count * 100.0 / SUM(movie_count) OVER (), 2) as percentage
FROM movie_durations
ORDER BY 
    CASE duration_bucket
        WHEN 'Under 1 hour' THEN 1
        WHEN '1-1.5 hours' THEN 2
        WHEN '1.5-2 hours' THEN 3
        WHEN '2-2.5 hours' THEN 4
        WHEN '2.5-3 hours' THEN 5
        WHEN 'Over 3 hours' THEN 6
    END;

-- (22) How many movies and TV shows are there in the dataset? Display the count for each type
------------------------------------------------------------------------------------------------

SELECT 
    type, COUNT(*) AS count
FROM
    netflix_titles
GROUP BY type;

-- (23) What percentage of content doesn’t have a country associated with it?
------------------------------------------------------------------------------------------------

SELECT 
    COUNT(CASE WHEN country IS NULL THEN 1 END) 
	/ COUNT(*) AS percentage_without_country
FROM
    netflix_titles;
    
-- (24) Find the top 3 directors with the most content on Netflix. Display the director's name, 
-- the count of their titles, and the year of their most recent content.
------------------------------------------------------------------------------------------------

WITH director_stats AS (
	SELECT
		director,
        COUNT(*) AS title_count,
        MAX(release_year) AS most_recent_year
	FROM 
		netflix_titles
	WHERE 
		director != '' AND director IS NOT NULL
	GROUP BY 
		director
)
SELECT
	director,
    title_count,
    most_recent_year
FROM 
	director_stats
ORDER BY 
	title_count DESC
LIMIT 3;

-- (25) For each year from 2015 to 2021, calculate the percentage of movies vs TV shows added to Netflix.
-------------------------------------------------------------------------------------------

WITH yearly_counts AS (
	SELECT
		EXTRACT(YEAR FROM DATE(date_added)) AS year,
        type,
        COUNT(*) AS count
	FROM netflix_titles
    WHERE date_added BETWEEN '2015-01-01' AND '2021-12-31'
    GROUP BY 1, 2
)
SELECT
	year,
    SUM(CASE WHEN type = 'Movie' THEN count ELSE 0 END)
    / SUM(count) AS movie_percentage,
    SUM(CASE WHEN type = 'TV Show' THEN count ELSE 0 END)
    / SUM(count) AS tv_show_percentage
FROM 
	yearly_counts
GROUP BY year
ORDER BY year;

-- (26) Calculate the average month-over-month growth rate of content added to Netflix 
-- for each genre. What are the top 5 fastest growing genres?
-------------------------------------------------------------------------------------------

WITH genre_months AS (
    SELECT
        DATE_FORMAT(date_added, '%Y-%m-01') AS month,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', numbers.n), ',', -1)) AS genre,
        COUNT(*) AS monthly_count
    FROM
        netflix_titles
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        ) numbers
        ON CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) >= numbers.n - 1
    WHERE
        date_added IS NOT NULL
    GROUP BY DATE_FORMAT(date_added, '%Y-%m-01'), genre
),
growth_rates AS (
    SELECT
        genre,
        month,
        monthly_count,
        LAG(monthly_count) OVER (PARTITION BY genre ORDER BY month) AS prev_month_count,
        CASE 
            WHEN LAG(monthly_count) OVER (PARTITION BY genre ORDER BY month) = 0 THEN 1.0
            ELSE (monthly_count - LAG(monthly_count) OVER (PARTITION BY genre ORDER BY month)) / NULLIF(LAG(monthly_count) OVER (PARTITION BY genre ORDER BY month), 0)
        END AS growth_rate
    FROM genre_months
),
avg_growth_rates AS (
    SELECT
        genre,
        AVG(growth_rate) AS avg_growth_rate
    FROM
        growth_rates
    WHERE growth_rate IS NOT NULL
    GROUP BY genre
)
SELECT
    genre,
    avg_growth_rate
FROM
    avg_growth_rates
ORDER BY
    avg_growth_rate DESC
LIMIT 5;


-- (27) New Content Added by Rating Over the Years
-- Problem: Track the trends of content addition by rating year by year.
------------------------------------------------------------------------------------------------

WITH monthly_additions AS (
    SELECT 
        YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) as added_year,
        rating,
        COUNT(*) as content_count
    FROM netflix_titles
    WHERE 
        date_added IS NOT NULL 
        AND rating IS NOT NULL 
        AND rating != ''
    GROUP BY 
        YEAR(STR_TO_DATE(date_added, '%M %d, %Y')),
        rating
)
SELECT 
    added_year,
    rating,
    content_count,
    ROUND(content_count * 100.0 / SUM(content_count) OVER (PARTITION BY added_year), 2) as percentage_in_year
FROM monthly_additions
WHERE added_year IS NOT NULL
ORDER BY 
    added_year DESC,
    content_count DESC;

-- (28) Genre-Country Matrix
-- Problem: Create a matrix of the number of titles by genre and country.
------------------------------------------------------------------------------------------------

WITH split_genres AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n), ',', -1)) AS genre,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', m.n), ',', -1)) AS country
    FROM netflix_titles
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
    ) n
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
    ) m
    WHERE 
        listed_in IS NOT NULL 
        AND country IS NOT NULL
        AND n.n <= 1 + LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', ''))
        AND m.n <= 1 + LENGTH(country) - LENGTH(REPLACE(country, ',', ''))
),
clean_data AS (
    SELECT 
        genre,
        country,
        COUNT(DISTINCT show_id) AS title_count
    FROM split_genres
    WHERE 
        genre != '' 
        AND country != ''
    GROUP BY genre, country
),
top_countries AS (
    SELECT country
    FROM (
        SELECT country, SUM(title_count) AS total
        FROM clean_data
        GROUP BY country
        ORDER BY total DESC
        LIMIT 5
    ) top_countries_subquery
)
SELECT 
    clean_data.genre,
    MAX(CASE WHEN clean_data.country = 'United States' THEN clean_data.title_count ELSE 0 END) AS `United States`,
    MAX(CASE WHEN clean_data.country = 'India' THEN clean_data.title_count ELSE 0 END) AS `India`,
    MAX(CASE WHEN clean_data.country = 'United Kingdom' THEN clean_data.title_count ELSE 0 END) AS `United Kingdom`,
    MAX(CASE WHEN clean_data.country = 'Canada' THEN clean_data.title_count ELSE 0 END) AS `Canada`,
    MAX(CASE WHEN clean_data.country = 'France' THEN clean_data.title_count ELSE 0 END) AS `France`
FROM clean_data
GROUP BY clean_data.genre
HAVING SUM(clean_data.title_count) > 0
ORDER BY clean_data.genre;

-- (29) Top Keywords in Descriptions
-- Problem: Identify the most frequently used keywords in the descriptions.
------------------------------------------------------------------------------------------------

-- Step 1: Create a temporary table to hold individual words from descriptions
WITH TokenizedWords AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(description, ' ', n.n), ' ', -1)) AS keyword
    FROM netflix_titles
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    ) n
    WHERE n.n <= 1 + LENGTH(description) - LENGTH(REPLACE(description, ' ', ''))
),
FilteredWords AS (
    -- Step 2: Remove stop words
    SELECT 
        LOWER(keyword) AS keyword
    FROM TokenizedWords
    WHERE keyword NOT IN ('and', 'the', 'of', 'in', 'a', 'to', 'is', 'for', 'on', 'with', 'this', 'it', 'at', 'as', 'by', 'an', 'be', 'from', 'that', 'are', 'or', 'was', 'but', 'they', 'not', 'which', 'so')
      AND keyword REGEXP '^[a-zA-Z]+$' -- Only include alphabetical words
),
WordFrequencies AS (
    -- Step 3: Count the frequency of each word
    SELECT 
        keyword, 
        COUNT(*) AS frequency
    FROM FilteredWords
    GROUP BY keyword
)
-- Step 4: Get the top 10 most frequent keywords
SELECT 
    keyword, 
    frequency
FROM WordFrequencies
ORDER BY frequency DESC
LIMIT 10;

