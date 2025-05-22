-- raw data :- https://www.kaggle.com/datasets/snehangsude/audible-dataset?select=audible_uncleaned.csv
-- data cleaning project


SELECT * 
FROM audible;


-- 1 creating staging table
CREATE TABLE audible_staging
LIKE audible;

INSERT audible_staging
SELECT * 
FROM audible;

SELECT *
FROM audible_staging;

-- 2 cheking for duplicate values


SELECT *
FROM (
	SELECT *,
    ROW_NUMBER()OVER(
		PARTITION BY `name`, author, narrator, `time`, releasedate, `language`, stars, price) AS ROW_NUM
	FROM audible_staging
    )DUPLICATES
WHERE ROW_NUM >1;

# NO DUPLICATES FOUND 

-- STANDARDIZE DATA

SELECT * 
FROM audible_staging;

-- author and narrator have a useless string in front of real name so removing it
#changing and viewing the results of updating the author column
SELECT author , REPLACE(author, 'Writtenby:','') As authorname
FROM audible_staging;

UPDATE audible_staging
SET author = REPLACE(author,'Writtenby:','');

SELECT * 
FROM audible_staging;

#changing and viewing the results of updating the narrator column
SELECT narrator , REPLACE(narrator, 'Narratedby:','') As naratorname
FROM audible_staging;

UPDATE audible_staging
SET narrator = REPLACE(narrator,'Narratedby:','');

SELECT * 
FROM audible_staging;

# standardising the releasedate column
SELECT * 
FROM audible_staging;

SELECT releasedate,
       STR_TO_DATE(releasedate, '%d-%m-%y') AS formatted_date
FROM audible_staging;

UPDATE audible_staging
SET releasedate = STR_TO_DATE(releasedate, '%d-%m-%y');

ALTER TABLE audible_staging
MODIFY COLUMN releasedate DATE;

SELECT * 
FROM audible_staging;

# UPDATING STARS COLUMN
#CREATING STAGING TABLE 2
CREATE TABLE `audible_staging2` (
  `name` text,
  `author` text,
  `narrator` text,
  `time` text,
  `releasedate` date DEFAULT NULL,
  `language` text,
  `stars` text,
  `price` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM audible_staging2;

INSERT audible_staging2
SELECT * FROM audible_staging;

ALTER TABLE audible_staging2
ADD COLUMN rating DECIMAL(2,1),
ADD COLUMN ratings_count INT;

SELECT stars,
       SUBSTRING_INDEX(stars, ' out of', 1) AS rating,
       SUBSTRING_INDEX(SUBSTRING_INDEX(stars, 'stars', -1), ' ratings', 1) AS ratings_count
FROM audible_staging2;

UPDATE audible_staging2
SET stars = NULL
WHERE stars = 'Not rated yet';

UPDATE audible_staging2
SET rating = CAST(SUBSTRING_INDEX(stars, ' out of', 1) AS DECIMAL(2,1)),
    ratings_count = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(stars, 'stars', -1), ' ratings', 1) AS UNSIGNED);

ALTER TABLE audible_staging2
DROP COLUMN stars;

SELECT * 
FROM audible_staging2; 

# updating time column
ALTER TABLE audible_staging2 ADD COLUMN time_minutes INT;

UPDATE audible_staging2
SET time_minutes = CASE
    WHEN `time` LIKE '%hr%' AND `time` LIKE '%min%' THEN
        CAST(SUBSTRING_INDEX(`time`, 'hr', 1) AS UNSIGNED) * 60 +
        CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(`time`, 'min', 1), 'and ', -1) AS UNSIGNED)
    WHEN `time` LIKE '%hr%' THEN
        CAST(SUBSTRING_INDEX(`time`, 'hr', 1) AS UNSIGNED) * 60
    WHEN `time` LIKE '%min%' THEN
        CAST(SUBSTRING_INDEX(`time`, 'min', 1) AS UNSIGNED)
    ELSE 0
END;

ALTER TABLE audible_staging2 DROP COLUMN `time`;

ALTER TABLE audible_staging2 CHANGE time_minutes time INT;


SELECT *
FROM audible_staging2;

ALTER TABLE audible_staging2 
MODIFY COLUMN `time` int AFTER narrator;

-- data population not possible due to unavailable date



