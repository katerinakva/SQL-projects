USE H_Baseball;
SELECT team, FORMAT (AVG(salary), '#,##0') AS average_of_salary_team
FROM players
WHERE year = 2011
GROUP BY team
ORDER BY average_of_salary_team DESC;