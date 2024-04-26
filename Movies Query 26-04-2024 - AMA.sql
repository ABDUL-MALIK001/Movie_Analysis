-- Confirm the data Imported
SELECT *
FROM imdb;

--DATA CLEANING
-- Remove full-stop "." showing in Lister_item_index
UPDATE imdb
SET lister_item_index = REPLACE(lister_item_index, '.', '')
WHERE lister_item_index LIKE '%.%';

-- Remove Primary Key set on Lister_item_index
ALTER TABLE imdb
DROP CONSTRAINT PK_imdb;

-- Convert lister_item_index column to INT(Data type)
ALTER TABLE imdb
ALTER COLUMN lister_item_index INT NOT NULL;

-- Add Primary Key Contraint Back to Lister_item_index
ALTER TABLE imdb
ADD CONSTRAINT PK_imdb PRIMARY KEY (lister_item_index);

-- Remove the character 'min' and ',' from runtime column to enable efficient ordering
UPDATE imdb
SET runtime = REPLACE(runtime, 'min', '')
WHERE runtime LIKE '%min%';

UPDATE imdb
SET runtime = REPLACE(runtime, ',', '')
WHERE runtime LIKE '%,%';

-- Convert Runtime column to INT
ALTER TABLE imdb
ALTER COLUMN runtime INT;



-- DATA ANALYSIS
-- First 5 Lister_item_header with the maximum runtime
SELECT TOP 5 lister_item_header, runtime, ROUND(rating, 1) rating
FROM imdb
ORDER BY runtime DESC;


--Split genre into different columns
WITH GENRE_SPLIT AS 
		(
		SELECT lister_item_index,
			genre,
			SUBSTRING(genre, 1, CHARINDEX(',', genre + ',') - 1) AS genre_1,
			SUBSTRING(genre, CHARINDEX(',', genre + ',') + 1, LEN(genre)) AS genre_II
		FROM imdb)
SELECT lister_item_index,
	genre_1,
	SUBSTRING(genre_II, 1, CHARINDEX(',', genre_II + ',') - 1) AS genre_2,
	SUBSTRING(genre_II, (CHARINDEX(',', genre_II + ',') + 1), LEN(genre_II)) AS genre_3
FROM
	GENRE_SPLIT;

-- Create a table for the split to enable join
CREATE TABLE GenreSplit (
    lister_item_index INT,
    genre_1 VARCHAR(MAX),
    genre_2 VARCHAR(MAX),
    genre_3 VARCHAR(MAX)
);

INSERT INTO GenreSplit (lister_item_index, genre_1, genre_2, genre_3)
SELECT lister_item_index,
	genre_1,
	SUBSTRING(genre_II, 1, CHARINDEX(',', genre_II + ',') - 1) AS genre_2,
	SUBSTRING(genre_II, (CHARINDEX(',', genre_II + ',') + 1), LEN(genre_II)) AS genre_3
FROM
	(
		SELECT lister_item_index,
			genre,
			SUBSTRING(genre, 1, CHARINDEX(',', genre + ',') - 1) AS genre_1,
			SUBSTRING(genre, CHARINDEX(',', genre + ',') + 1, LEN(genre)) AS genre_II
		FROM imdb) AS SUB;

-- Join with imdb Table
SELECT *
FROM imdb i
JOIN GenreSplit gs on gs.lister_item_index = i.lister_item_index;


-- Genre with the Highest Voting
SELECT 
	genre, 
	SUM(votes) Votes_Sum
FROM 
	imdb
GROUP BY
	genre
ORDER BY
	Votes_Sum DESC;


-- Certificate with the best average rating over the overall average
SELECT 
	certificate,
	ROUND(AVG(rating), 1) AS Certificate_rating
FROM imdb
GROUP BY
	certificate
ORDER BY
	Certificate_rating DESC;

-- Relationship between Certificate Average rating and Overall rating
WITH Certificate_Overall AS 
	(
	SELECT AVG(rating) AS Overall_rating
	FROM imdb),
Cert_rating AS	
	(
	SELECT 
		DISTINCT certificate,
		AVG(rating) OVER(PARTITION BY certificate) AS Certificate_rating
	FROM imdb
	)
SELECT certificate, ROUND(Certificate_rating, 1) Cert_rating, ROUND(Overall_rating, 1) Overall_rate
FROM 
	Certificate_Overall, Cert_rating
ORDER BY
	Certificate_rating DESC;

-- Certificate higher than the overall rating
WITH Certificate_Overall AS 
	(
	SELECT AVG(rating) AS Overall_rating
	FROM imdb),
Cert_rating AS	
	(
	SELECT 
		DISTINCT certificate,
		AVG(rating) OVER(PARTITION BY certificate) AS Certificate_rating
	FROM imdb
	)
SELECT certificate, ROUND(Certificate_rating, 1) Cert_rating, ROUND(Overall_rating, 1) Overall_rate
FROM 
	Certificate_Overall, Cert_rating
WHERE
	Certificate_rating >= Overall_rating
ORDER BY
	Certificate_rating DESC;

-- Relationship between Certificate with the votes and rating
SELECT 
	certificate,
	SUM(votes) AS Votes_SUM,
	ROUND(AVG(rating), 1) AS Overall_rating
FROM imdb
GROUP BY
	certificate
ORDER BY
	Votes_SUM DESC;

-- Top 5 lister_item_header with the highest runtime
SELECT TOP 5 
	lister_item_header, 
	SUM(runtime) runtime_minutes
FROM imdb
GROUP BY 
	lister_item_header
ORDER BY 
	runtime_minutes DESC;

-- Is there any relationship between the Bottom 5 lister_item_header with the lowest runtime with rating and votes
SELECT TOP 5 
	lister_item_header, 
	SUM(runtime) runtime_minutes, 
	ROUND(rating, 1) rating, votes,
	ROUND((votes * 100.0) / SUM(votes) OVER (), 2) AS percentage_of_total_votes
FROM imdb
GROUP BY 
	lister_item_header, rating, votes
ORDER BY 
	runtime_minutes ASC;

-- Lister_item_header with rating greater than the average rating
SELECT 
	lister_item_header,
	ROUND(rating, 1) rating
FROM
	imdb
WHERE rating > (SELECT AVG(rating)
				FROM imdb)
ORDER BY rating DESC;

-- TOP 3 Most enjoyed genre
SELECT 
	lister_item_header, genre, ROUND(rating, 1) rating, rating_rank
FROM (
    SELECT 
		lister_item_header, genre, rating, DENSE_RANK() OVER(ORDER BY rating DESC) AS rating_rank
    FROM 
		imdb
	) AS ranked_movies
WHERE rating_rank <= 3;
