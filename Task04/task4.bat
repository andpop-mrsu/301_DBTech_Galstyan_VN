#!/bin/bash
chcp 65001

# Создаем базу данных
sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм (первые 100 записей)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT
    u1.name AS user1,
    u2.name AS user2,
    m.title AS movie
FROM ratings r1
JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id
JOIN users u1 ON r1.user_id = u1.id
JOIN users u2 ON r2.user_id = u2.id
JOIN movies m ON r1.movie_id = m.id
LIMIT 100;
"
echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей (название, имя, оценка, дата ГГГГ-ММ-ДД)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    u.name AS user,
    r.rating,
    strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS date
FROM ratings r
JOIN users u ON r.user_id = u.id
JOIN movies m ON r.movie_id = m.id
GROUP BY r.user_id
ORDER BY r.timestamp DESC
LIMIT 10;
"
echo " "

echo "3. Фильмы с максимальным и минимальным средним рейтингом. Сортировка по году и названию. Колонка Рекомендуем (Да/Нет)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH movie_ratings AS (
    SELECT movie_id, AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
),
extremes AS (
    SELECT MAX(avg_rating) as max_avg, MIN(avg_rating) as min_avg FROM movie_ratings
)
SELECT
    m.title AS movie,
    m.year,
    mr.avg_rating,
    CASE WHEN mr.avg_rating = e.max_avg THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем'
FROM movie_ratings mr
JOIN movies m ON mr.movie_id = m.id
CROSS JOIN extremes e
WHERE mr.avg_rating = e.max_avg OR mr.avg_rating = e.min_avg
ORDER BY m.year, m.title;
"
echo " "

echo "4. Количество оценок и средняя оценка от женщин в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT
    COUNT(r.rating) AS count_ratings,
    AVG(r.rating) AS avg_rating
FROM ratings r
JOIN users u ON r.user_id = u.id
WHERE u.gender = 'F'
  AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2010' AND '2012';
"
echo " "

echo "5. Список фильмов с средней оценкой и местом в рейтинге. Сортировка по году и названию. Первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH movie_ratings AS (
    SELECT movie_id, AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
)
SELECT
    m.title AS movie,
    m.year,
    mr.avg_rating,
    RANK() OVER (ORDER BY mr.avg_rating DESC) AS rating_place
FROM movie_ratings mr
JOIN movies m ON mr.movie_id = m.id
ORDER BY m.year, m.title
LIMIT 20;
"
echo " "

echo "6. 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
SELECT
    name || '|' || register_date AS 'Фамилия Имя|Дата регистрации'
FROM users
ORDER BY register_date DESC
LIMIT 10;
"
echo " "

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE
  n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x < 10),
  m(y) AS (SELECT 1 UNION ALL SELECT y+1 FROM m WHERE y < 10)
SELECT x || 'x' || y || '=' || (x*y) AS 'Таблица умножения'
FROM n CROSS JOIN m
ORDER BY x, y;
"
echo " "

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE
  split(movie_id, genre, rest) AS (
    SELECT id, '', genres || '|' FROM movies
    UNION ALL
    SELECT movie_id,
           substr(rest, 1, instr(rest, '|') - 1),
           substr(rest, instr(rest, '|') + 1)
    FROM split
    WHERE rest <> ''
  )
SELECT DISTINCT genre
FROM split
WHERE genre <> ''
ORDER BY genre;
"
echo " "