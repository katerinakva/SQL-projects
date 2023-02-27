USE H_Baseball;
SELECT team, FORMAT(AVG(salary), '#,##0') AS player_salary_wo_alex_rodrigez
FROM players
WHERE team = 'New York Yankees'
AND name <> 'Alex Rodriguez'
AND year = 2011
ORDER BY salary DESC;