USE fmban_sql_analysis;


-- Table with healthy products by category. The highest category with healthy products is meat. 
-- The average price of meat is higher than desserts one. 
SELECT category, ROUND(avg(price/100),2) AS avg_price,COUNT(product) AS num_products
FROM fmban_data
WHERE sugarconscious = 1 AND category != 'NULL' OR lowsodium = 1 AND category != 'NULL'
GROUP BY category;

-- Table with unhealthy products by category. The highest category with unhealthiest products is desserts.
SELECT category, ROUND(avg(price/100),2) AS avg_price,COUNT(product) AS num_products
FROM fmban_data
WHERE sugarconscious = 0 AND category != 'NULL' AND lowsodium = 0 AND category != 'NULL' and ID != '178'
GROUP BY category;



SELECT product, 
	   (price/100) AS price, 
       case -- here we want to mark all the products that are considered not healty within the same category
	   when sugarconscious = 1 or lowsodium = 1 then 'product that is healty'
       when sugarconscious = 0 or lowsodium = 0 then 'product that is not healty'
       END AS result
FROM fmban_data
where category like 'meat%';


-- Comparison of two categories within 1 table 
SELECT
	(SELECT category
	FROM fmban_data
	WHERE category LIKE 'meat%'
	LIMIT 1) AS healthy_category, 
    (SELECT ROUND(avg(price/100),2) 
	FROM fmban_data
	WHERE category LIKE 'meat%') AS avg_healthy_price, 
    (SELECT category
	FROM fmban_data
	WHERE category LIKE 'desser%'
	LIMIT 1) AS unhealthy_category,
    (SELECT ROUND(avg(price/100),2) 
	FROM fmban_data
	WHERE category LIKE 'desser%') AS avg_unhealthy_price
FROM fmban_data
LIMIT 1;
