Segment 1: Database - Tables, Columns, Relationships

--	1.  Find the total number of rows in each table of the schema.
 
 select count(*) from movies.movies; -- 7997 rows
 select count(*) from ratings.ratings; -- 7997 rows
  select count(*) from genre.genre;    -- 14662 rows
   select count(*) from names.names;   -- 7472 rows 
   select count(*) from erd.erd;        -- 0 rows
    
--	2.  Identify which columns in the movie table have null values.

SELECT Count(*) - Count(id)                    AS id_nulls_count,
       Count(*) - Count(title)                 AS title_nulls_count,
       Count(*) - Count(date_published)        AS date_published_nulls_count,
       Count(*) - Count(duration)              AS duration_nulls_count,
       Count(*) - Count(country)               AS country_nulls_count,
       Count(*) - Count(worlwide_gross_income) AS worlwide_gross_income_nulls_count,
       Count(*) - Count(languages)             AS languages_nulls_count,
       Count(*) - Count(production_company)    AS production_company_nulls_count
FROM   movies.movies;

Segment 2: Movie Release Trends

-- 3.	Determine the total number of movies released each year and analyse the month-wise trend.

select year, substr(date_published,4,2) as month, count(id) as movies_released from movies.movies group by year,
substr(date_published,4,2) order by year , substr(date_published,4,2)


-- 4.	Calculate the number of movies produced in the USA or India in the year 2019.

select count(*) as num_movies
from movies.movies 
where (country = 'USA' or country = 'INDIA') and year = 2019;

Segment 3: Production Statistics and Genre Analysis

-- 6.	Retrieve the unique list of genres present in the dataset.

select distinct genre.genre 
from movies.movies
left join genre.genre on (movies.id = genre.movie_id)

-- 7.	Identify the genre with the highest number of movies produced overall.

select genre.genre , count(movie_id) as movies from movies.movies
left join genre.genre on (movies.id = genre.movie_id)
group by genre order by 2 desc


-- 8.	Determine the count of movies that belong to only one genre.
WITH one_genre_movies
     AS (SELECT movie_id,
                Count(genre) genre_count
         FROM   genre.genre
         GROUP  BY movie_id
         HAVING genre_count = 1)
SELECT Count(movie_id) AS one_genre_movies_count
FROM   one_genre_movies ;

-- 9.	Calculate the average duration of movies in each genre.

SELECT genre,
       Avg(duration) AS avg_duration
FROM   genre.genre
       INNER JOIN movies.movies
               ON genre.movie_id = movies.id
GROUP  BY genre;

-- 10.	Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.

SELECT genre,
       Count(movie_id) as movie_count,
       Rank()
         OVER (
           ORDER BY Count(movie_id) DESC) genre_rank
FROM   genre.genre
WHERE  genre = 'thriller'
GROUP  BY genre; 

Segment 4: Ratings Analysis and Crew Members

-- 11.	Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).

select max(avg_rating) as max_avg_rating,
	   min(avg_rating) as min_avg_rating from ratings.ratings

-- 12.	Identify the top 10 movies based on average rating.
WITH movie_ranking
     AS (SELECT movies.title,
                avg_rating,
                Dense_rank()
                  OVER (
                    ORDER BY avg_rating DESC ) AS movie_rank
         FROM   ratings.ratings
                INNER JOIN movies.movies
                        ON movies.id = ratings.movie_id)
SELECT *
FROM   movie_ranking
WHERE  movie_rank <= 10 ;

-- 13.	Summarise the ratings table based on movie counts by median ratings.

SELECT median_rating,
       Count(movie_id) AS movie_count
FROM   ratings.ratings
GROUP  BY median_rating
ORDER  BY median_rating ;

-- 14.	Identify the production house that has produced the most number of hit movies (average rating > 8).

select production_company , count(id) as movies from movies.movies left join ratings.ratings on (movies.id = ratings.movie_id)
where avg_rating > 8 group by production_company order by movies desc



-- 15. Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.


 select genre , count(id) as movies_released from movies.movies 
 left join genre.genre on (movies.id = genre.movie_id)
 left join ratings.ratings on (movies.id = ratings.movie_id)
 where total_votes > 1000
  group by genre
 

-- 16.	Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.

select genre AVG(rating) as average_rating
from movies.movies 
left join ratings.ratings on (movies.id = ratings.movie_id)
where title like 'The%'
group by genre
having AVG(rating) > 8

Segment 5: Crew Analysis

-- 17.	Identify the columns in the names table that have null values.

select sum(case when height is null then 1 else 0 end) as height_nulls,
 sum(case when known_for_movies is null then 1 else 0 end) known_for_movies_null
 from names.names;

select * from names.names limit 100;

-- 18.	Determine the top three directors in the top three genres with movies having an average rating > 8.
 top 3 genre 
 
 WITH top_genre AS
(
           SELECT     genre,
                      Count(*) count_title
           FROM       genre.genre
           INNER JOIN movies.movies
           ON         movies.id=genre.movie_id
           INNER JOIN ratings.ratings
           ON         movies.id=ratings.movie_id
           AND        avg_rating > 8
           GROUP BY   genre
           ORDER BY   count_title DESC limit 3)
SELECT     NAME              AS director_name,
           Count(*) AS movie_count
FROM       names.names
INNER JOIN director.directorm
ON         names.id=directorm.name_id
INNER JOIN genre.genre 
ON         genre.movie_id=directorm.movie_id
INNER JOIN ratings.ratings 
ON         ratings.movie_id=directorm.movie_id
WHERE      avg_rating>8
GROUP BY   director_name
ORDER BY   movie_count DESC limit 3;


-- 19.	Find the top two actors whose movies have a median rating >= 8.
WITH actor_movie_rank
     AS (SELECT NAME                                 AS actor_name,
                Count(role.movie_id)                    AS movie_count,
                Rank()
                  OVER(
                    ORDER BY Count(role.movie_id) DESC) AS actor_rank
         FROM   role.role
                INNER JOIN names.names
                        ON names.id = role.name_id
                INNER JOIN ratings.ratings
                        ON ratings.movie_id = role.movie_id
         WHERE  role.category = 'actor'
                AND median_rating >= 8
         GROUP  BY actor_name)
SELECT *
FROM   actor_movie_rank
WHERE  actor_rank < 3 ;


-- 20.	Identify the top three production houses based on the number of votes received by their movies.

WITH prod_company_rank
     AS (SELECT production_company,
                Sum(total_votes)                     vote_count,
                Rank()
                  OVER (
                    ORDER BY Sum(total_votes) DESC ) prod_comp_rank
         FROM   movies.movies
                INNER JOIN ratings.ratings
                        ON ratings.movie_id = movies.id
         GROUP  BY production_company)
SELECT *
FROM   prod_company_rank
WHERE  prod_comp_rank < 4 

-- 21.	Rank actors based on their average ratings in Indian movies released in India.

SELECT NAME AS actor_name,
       Sum(total_votes) AS total_votes,
       Count(movies.id)		AS movie_count,
       Round(Sum(avg_rating * total_votes) / Sum(total_votes), 2)      AS actor_avg_rating,
       Rank()
         OVER(
           ORDER BY Sum(avg_rating*total_votes)/Sum(total_votes) DESC) AS actor_rank
FROM   movies.movies
       INNER JOIN ratings.ratings
               ON movies.id = ratings.movie_id
       INNER JOIN role.role 
               ON movies.id = role.movie_id
       INNER JOIN names.names
               ON role.name_id = names.id
WHERE  category = 'actor'
       AND country = 'india'
GROUP  BY name
HAVING movie_count >= 5;


-- 22.	Identify the top five actresses in Hindi movies released in India based on their average ratings.

SELECT NAME AS actor_name,
       Sum(total_votes) AS total_votes,
       Count(movies.id) AS movie_count,
       Round(Sum(avg_rating * total_votes) / Sum(total_votes), 2)  AS actor_avg_rating,
       Rank()
         OVER(
           ORDER BY Sum(avg_rating*total_votes)/Sum(total_votes) DESC) AS
       actor_rank
FROM   movies.movies
       INNER JOIN ratings.ratings
               ON movies.id = ratings.movie_id
       INNER JOIN role.role
               ON movies.id = role.movie_id
       INNER JOIN names.names
               ON role.name_id = names.id
WHERE  category = 'actress'
       AND country = 'India'
       AND languages = 'Hindi'
GROUP  BY name
HAVING movie_count >= 3; 

Segment 6: Broader Understanding of Data

-- 23.	Classify thriller movies based on average ratings into different categories.
SELECT id, avg_rating ,
       CASE 
           WHEN avg_rating >= 9.0 THEN 'Excellent'
           WHEN avg_rating >= 8.0 THEN 'Very Good'
           WHEN avg_rating >= 7.0 THEN 'Good'
           ELSE 'Average or Below'
       END AS rating_category
  FROM movies.movies left join genre.genre on (movies.id = genre.movie_id)
  left join ratings.ratings on (movies.id = ratings.movie_id)
  where genre = 'Thriller'
       


-- 24.	analyse the genre-wise running total and moving average of the average movie duration.

SELECT genre,
       Round(Avg(duration))                                   AS avg_duration,
       Round(SUM(Avg(duration))
               over(
                 ORDER BY genre ROWS unbounded preceding), 1) AS
       running_total_duration,
       Round(Avg(Avg(duration))
               over(
                 ORDER BY genre ROWS 10 preceding), 2)        AS
       moving_avg_duration
FROM   movies.movies
       inner join genre.genre
               ON movies.id = genre.movie_id
GROUP  BY genre
ORDER  BY genre; 





-- 25.	Identify the five highest-grossing movies of each year that belong to the top three genres.
WITH top_3_genre
     AS (WITH top_genre
              AS (SELECT genre,
                         Count(movie_id)                    AS movie_count,
                         Rank()
                           OVER(
                             ORDER BY Count(movie_id) DESC) AS genre_rank
                  FROM   genre.genre
                  GROUP  BY genre)
         SELECT *
          FROM   top_genre
          WHERE  genre_rank <= 3),
     top_5_movie
     AS (SELECT year,
                title                                    AS movie_name,
                worlwide_gross_income,
                Rank()
                  OVER (
                    ORDER BY worlwide_gross_income DESC) AS movie_rank
         FROM   movies.movies
                INNER JOIN genre.genre
                        ON movies.id = genre.movie_id
         WHERE  genre.genre IN (SELECT genre
                            FROM   top_3_genre))
SELECT *
FROM   top_5_movie
WHERE  movie_rank <= 5 




-- 26.	Determine the top two production houses that have produced the highest number of hits among multilingual movies.

WITH ranking
     AS (SELECT production_company,
                Count(*)                  AS movie_count,
                Rank()
                  over(
                    ORDER BY Count(id) DESC) AS comp_rank
         FROM   movies.movies
                inner join ratings.ratings
                        ON movies.id = ratings.movie_id
         WHERE  median_rating >= 8
                AND production_company IS NOT NULL
                AND Position(',' IN languages) > 0
         GROUP  BY production_company)
SELECT *
FROM   ranking
WHERE  comp_rank < 3; 





-- 27.	Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
WITH actress_ranking
     AS (SELECT names.name
                AS
                actress_name
                   ,
                Sum(ratings.total_votes)
                   AS total_votes,
                Count(genre.movie_id)
                AS
                   movie_count,
                Round(Sum(ratings.avg_rating * ratings.total_votes) / Sum(ratings.total_votes), 2)
                AS
                actress_avg_rating,
                Rank()
                  OVER(
                    ORDER BY Count(genre.movie_id) DESC)
                AS
                   actress_rank
         FROM   genre.genre
                INNER JOIN movies.movies
                        ON genre.movie_id = movies.id
                INNER JOIN ratings.ratings
                        ON movies.id = ratings.movie_id
                INNER JOIN role.role
                        ON movies.id = role.movie_id
                INNER JOIN names.names
                        ON role.name_id = names.id
         WHERE  genre.genre = 'drama'
                AND role.category = 'actress'
                AND ratings.avg_rating > 8
         GROUP  BY names.name)
SELECT *
FROM   actress_ranking
WHERE  actress_rank <= 3; 





-- 28.	Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.
SELECT name_id           AS director_id,
					name AS director_name,
       Count(directorm.movie_id) AS number_of_movies,
       ratings.avg_rating      AS avg_rating,
       ratings.total_votes     AS total_votes,
       movies.date_published,
       Sum(total_votes)  AS total_votes,
       Min(avg_rating)   AS min_rating,
       Max(avg_rating)   AS max_rating,
       Sum(duration)     AS total_duration
FROM   directorm.directorm
       INNER JOIN names
               ON directorm.name_id = names.id
       INNER JOIN movies.movies
               ON directorm.movie_id = movies.id
       INNER JOIN ratings.ratings
               ON movies.id = ratings.movie_id
GROUP  BY director_id
ORDER  BY number_of_movies DESC
LIMIT  9; 


Segment 7: Recommendations
-- 29.	Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing

     After understaing the data set and performing sevral SQL queries for the given quetions in the scipts we could arrive at some basic points.
 last three years total movies in 2017 is 3025 . Which is the highest among last three year and specially in the month of march which had highest 
 releases of 824 movies . In the year 2019 295 movies were released in INDIA alone, AND from the previous data we could see the no. of movies were 
 produced in action genre and the avg duration of action genre 112.88 min . The top movie which has the avg rating of 10.0 is 'kirket'
           Two of the biggest production houses are drama warrier pictuers and national theater live in 2017 march 54 action genre movies were releasd in USA 
     THE movies whoes start name start with the word 'THE' has highest rating of more than 8 .The highest total votes are german movies than Italian movies.
     the german movies has 106710 . The top three directors whoes average rating is more than 8 are james mandol , Anthony russo , Souvin shahiv . The top two
     actors who has the highest rating are Mammmooty and Mohanlal . THe top three production houses who has more no. votes based on their votes released are marvels 
     studios , twentieth century fox an warrner brois . fahad fasil and pankaj tripathi are the top two actors in the list based on their avg rating 
     Top two actress tapsee pannu , divya dutta and dipti kharbanda . There are more no. of high rated movies in thriller genre . Drama genre has highest number of gross incom.
     Based on the all the above insight the RSVP movies can plan for Drama of thriller genre movies with mammooty or fahadh  as lead male actors , along with tapsee pannu 
     as female lead , and al fahadh or andrew jones as director.
