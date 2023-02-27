USE H_Baseball;
SELECT year, COUNT(*) AS number_of_player
FROM players
GROUP BY year;
