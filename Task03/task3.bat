#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, m.year FROM movies m JOIN ratings r ON m.id = r.movie_id ORDER BY m.year, m.title LIMIT 10;"
echo " "

echo "2. Вывести список всех пользователей, фамилии (не имена!) которых начинаются на букву 'A'. Полученный список отсортировать по дате регистрации. В списке оставить первых 5 пользователей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT * FROM users WHERE SUBSTR(name, INSTR(name, ' ') + 1, 1) = 'A' ORDER BY register_date LIMIT 5;"
echo " "

echo "3. Написать запрос, возвращающий информацию о рейтингах: имя и фамилия эксперта, название фильма, год выпуска, оценка и дата оценки в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u.name, m.title, m.year, r.rating, DATE(r.timestamp, 'unixepoch') AS rating_date FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id ORDER BY u.name, m.title, r.rating LIMIT 50;"
echo " "

echo "4. Вывести список фильмов с указанием тегов. Сортировать по году выпуска, затем по названию фильма, затем по тегу. Оставить первые 40 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, t.tag FROM movies m JOIN tags t ON m.id = t.movie_id ORDER BY m.year, m.title, t.tag LIMIT 40;"
echo " "

echo "5. Вывести список самых свежих фильмов. В список должны войти все фильмы последнего года выпуска, имеющиеся в базе данных."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT * FROM movies WHERE year = (SELECT MAX(year) FROM movies) ORDER BY title;"
echo " "

echo "6. Найти все драмы, выпущенные после 2005 года, которые понравились женщинам (оценка не ниже 4.5)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, COUNT(*) AS cnt FROM movies m JOIN ratings r ON m.id = r.movie_id JOIN users u ON r.user_id = u.id WHERE m.genres LIKE '%Drama%' AND m.year > 2005 AND u.gender = 'F' AND r.rating >= 4.5 GROUP BY m.id ORDER BY m.year, m.title;"
echo " "

echo "7. Анализ востребованности ресурса - количество пользователей, регистрировавшихся в каждом году."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT STRFTIME('%Y', register_date) AS year, COUNT(*) AS cnt FROM users GROUP BY year ORDER BY cnt DESC;"
echo " "