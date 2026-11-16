#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма выведите его название, год выпуска и средний рейтинг. Добавьте столбец rank_by_avg_rating (ранг по убыванию среднего рейтинга). Оставить 10 фильмов с наибольшим рангом."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH MovieAvg AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_r FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id) SELECT title, year, ROUND(avg_r, 2) AS avg_rating, RANK() OVER (ORDER BY avg_r DESC) AS rank_by_avg_rating FROM MovieAvg ORDER BY rank_by_avg_rating LIMIT 10;"
echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов. Для каждого жанра рассчитать средний рейтинг. Выведите genre, avg_rating и ранг жанра по убыванию среднего рейтинга."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 0, INSTR(rest, '|')), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split_genres WHERE rest != ''), GenreRatings AS (SELECT sg.genre, AVG(r.rating) AS avg_r FROM split_genres sg JOIN ratings r ON sg.id = r.movie_id WHERE sg.genre != '' GROUP BY sg.genre) SELECT genre, ROUND(avg_r, 2) AS avg_rating, RANK() OVER (ORDER BY avg_r DESC) AS genre_rank FROM GenreRatings;"
echo " "

echo "3. Посчитайте количество фильмов в каждом жанре. Выведите genre и movie_count, отсортировав по убыванию количества."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 0, INSTR(rest, '|')), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split_genres WHERE rest != '') SELECT genre, COUNT(DISTINCT id) AS movie_count FROM split_genres WHERE genre != '' GROUP BY genre ORDER BY movie_count DESC;"
echo " "

echo "4. Найдите жанры, в которых чаще всего оставляют теги. Выведите genre, tag_count и долю жанра в общем числе тегов (tag_share в процентах)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split_genres(id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies UNION ALL SELECT id, SUBSTR(rest, 0, INSTR(rest, '|')), SUBSTR(rest, INSTR(rest, '|') + 1) FROM split_genres WHERE rest != ''), TagCounts AS (SELECT sg.genre, COUNT(t.id) AS tag_count FROM split_genres sg JOIN tags t ON sg.id = t.movie_id WHERE sg.genre != '' GROUP BY sg.genre), TotalTags AS (SELECT COUNT(*) AS total FROM tags) SELECT genre, tag_count, ROUND((tag_count * 100.0 / total), 2) AS tag_share FROM TagCounts, TotalTags ORDER BY tag_count DESC;"
echo " "

echo "5. Для каждого пользователя рассчитайте: общее количество оценок, средний рейтинг, дату первой и последней оценки. Отсортируйте по убыванию количества оценок (топ 10)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT user_id, COUNT(*) AS rating_count, ROUND(AVG(rating), 2) AS avg_rating, MIN(DATE(timestamp, 'unixepoch')) AS first_rating_date, MAX(DATE(timestamp, 'unixepoch')) AS last_rating_date FROM ratings GROUP BY user_id ORDER BY rating_count DESC LIMIT 10;"
echo " "

echo "6. Сегментируйте пользователей по типу поведения (Комментаторы, Оценщики, Активные, Пассивные). Выведите user_id, число оценок, число тегов и категорию."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH UserStats AS (SELECT u.id AS user_id, (SELECT COUNT(*) FROM ratings r WHERE r.user_id = u.id) AS rating_count, (SELECT COUNT(*) FROM tags t WHERE t.user_id = u.id) AS tag_count FROM users u) SELECT user_id, rating_count, tag_count, CASE WHEN rating_count >= 10 AND tag_count >= 10 THEN 'Активные' WHEN rating_count < 5 AND tag_count < 5 THEN 'Пассивные' WHEN tag_count > rating_count THEN 'Комментаторы' WHEN rating_count > tag_count THEN 'Оценщики' ELSE 'Другие' END AS behavior_category FROM UserStats;"
echo " "

echo "7. Для каждого пользователя выведите его имя и последний фильм, который он оценил (по времени). Если не оценивал - NULL."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RankedRatings AS (SELECT user_id, movie_id, timestamp, ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY timestamp DESC) AS rn FROM ratings) SELECT u.id AS user_id, u.name, m.title AS last_rated_movie_title, rr.timestamp AS last_rating_timestamp FROM users u LEFT JOIN RankedRatings rr ON u.id = rr.user_id AND rr.rn = 1 LEFT JOIN movies m ON rr.movie_id = m.id;"
echo " "