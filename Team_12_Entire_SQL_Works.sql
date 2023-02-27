
/* ***********************************************
 * 	TEAM 12 FMBAN's Entire SQL Works
 * 	These queries are merging from indivisual study and co-works.
 * 	Run Whole code will be running Stock Simulator
 *	**********************************************************************************/

/* --------------------------------------------------------------------------------
 *	## Chay's work -- Checking entire stock market's trend data
 *	-------------------------------------------------------------------------------- */
/*
# Total Return of M12, M18, M24 
SELECT
  A.*,
  B.date AS M12_DATE,
  B.value AS M12_VALUE,
  C.date AS M18_DATE,
  C.value AS M18_VALUE,
  D.date AS M24_DATE,
  D.value AS M24_VALUE
FROM
  (
    SELECT
      A.security_name,
      A.ticker,
      A.sp500_weight,
      A.sec_type,
      A.major_asset_class,
      A.minor_asset_class,
      B.date AS CUR_DT,
      B.value AS CUR_PRICE
    FROM
      security_masterlist AS A
      LEFT JOIN pricing_daily_new AS B ON A.ticker = B.ticker
      AND B.date = '2022-09-09'
      AND B.price_type = 'Adjusted'
  ) AS A
  LEFT JOIN pricing_daily_new AS B ON A.ticker = B.ticker
  AND B.date = DATE_SUB(A.CUR_DT, INTERVAL 12 MONTH)
  AND B.price_type = 'Adjusted'
  LEFT JOIN pricing_daily_new AS C ON A.ticker = C.ticker
  AND C.date = DATE_SUB(A.CUR_DT, INTERVAL 18 MONTH)
  AND C.price_type = 'Adjusted'
  LEFT JOIN pricing_daily_new AS D ON A.ticker = D.ticker
  AND D.date = DATE_SUB(A.CUR_DT, INTERVAL 24 MONTH)
  AND D.price_type = 'Adjusted';



# We misunderstood about ROR. Finaly We fixed Base table for analysis
SELECT	* 
  FROM	
			(
			SELECT	B.ticker	
						,B.quantity
						,D.date
						,D.value AS Current_value
						,LAG(D.value, 250) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS Lagged_price
						,(D.value - LAG(D.value, 250) OVER(PARTITION BY D.ticker ORDER BY D.date ASC)) / LAG(D.value, 250) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS ROR
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
						AND A.client_id = 123
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new  AS D
			    ON	B.ticker = D.ticker
			    		AND D.price_type = 'Adjusted'
			    		AND D.value IS NOT NULL
			    		AND D.date > '2020-09-09'
			) AS A
 WHERE	DATE > '2021-09-09';
   */
   

	 		


/* --------------------------------------------------------------------------------
 *	## Ekaterina's work -- Security masterlist data cleanse
 *	-------------------------------------------------------------------------------- */
/*
SELECT DISTINCT(major_asset_class), minor_asset_class
FROM security_masterlist

SELECT sec_type,
major_asset_class,
CASE 
WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
WHEN major_asset_class = 'equty' THEN 'equity' 
ELSE major_asset_class END AS major_asset_class,
minor_asset_class,
CASE 
WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
ELSE minor_asset_class END AS minor_asset_class
FROM security_masterlist



SELECT	sec_type
			,major_asset_class_new
			,minor_asset_class_new
  FROM	(
			SELECT	*
						,CASE 
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class_new
						,CASE 
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class_new
			  FROM	security_masterlist
			) AS A
 GROUP
 	 BY	sec_type
			,major_asset_class_new
			,minor_asset_class_new
 ORDER
 	 BY	1, 2, 3;
*/

/* --------------------------------------------------------------------------------
 *	## Rui's work
 *	-------------------------------------------------------------------------------- */
/*
use invest;

set @account_id_list = '933,252';

select date into @cur_date
from holdings_current
limit 1;

SELECT MAX(date) into @date_12
FROM pricing_daily_new
WHERE date <= DATE_SUB(@cur_date, INTERVAL 12 MONTH);

SELECT MAX(date) into @date_18
FROM pricing_daily_new
WHERE date <= DATE_SUB(@cur_date, INTERVAL 18 MONTH);

SELECT MAX(date) into @date_24
FROM pricing_daily_new
WHERE date <= DATE_SUB(@cur_date, INTERVAL 24 MONTH);

-- 1. What is the most recent 12M**, 18M, 24M (months) return for each of the securities (and for the entire portfolio)? 
-- 1a per security
SELECT
	*,
    100*val_cur/val_12 AS `12 month return`,
    100*val_cur/val_18 AS `18 month return`,
    100*val_cur/val_24 AS `24 month return`
FROM
(
	SELECT 
		ticker, 
		SUM(value * (`date` = @cur_date)) AS val_cur, 
		SUM(value * (`date` = @date_12)) AS val_12, 
		SUM(value * (`date` = @date_18)) AS val_18, 
		SUM(value * (`date` = @date_24)) AS val_24
	FROM pricing_daily_new
	WHERE `date` IN (@cur_date , @date_12, @date_18, @date_24)
	GROUP BY ticker
) t0
;

-- 1b per portfolio for given account_id_list
WITH cte AS (
	SELECT 
		account_id,
		SUM(quantity * t1.value * (t1.`date` = @cur_date)) AS nv_cur,
		SUM(quantity * t1.value * (t1.`date` = @date_12)) AS nv_12,
		SUM(quantity * t1.value * (t1.`date` = @date_18)) AS nv_18,
		SUM(quantity * t1.value * (t1.`date` = @date_24)) AS nv_24
	FROM
	(
		SELECT account_id, ticker, quantity
		FROM holdings_current
		WHERE FIND_IN_SET(account_id, @account_id_list) <> 0
	) t0
	INNER JOIN
	(
		SELECT ticker, date, value
		FROM pricing_daily_new
		WHERE date IN (@cur_date , @date_12, @date_18, @date_24)
	) t1 
	USING (ticker)
	GROUP BY account_id
)
SELECT 
	account_id, 
    100*nv_12/nv_cur AS `12 month return`, 
    100*nv_18/nv_cur AS `18 month return`, 
    100*nv_24/nv_cur AS `24 month return`
FROM cte;

-- What are the correlations between your assets? Are there any interesting correlations?
-- select t0.ticker as ticker_0, t1.ticker as ticker_1,
-- 	(
--     select co
--     from (
-- 	select date, sum(value*(ticker = t0.ticker)) as value_0,sum(value*(ticker = t1.ticker)) as value_1 from pricing_daily_new group by date)
--     )
-- from
-- (
-- select ticker
-- from holdings_current
-- where account_id = '933'
-- ) t0
-- inner join
-- (
-- select ticker
-- from holdings_current
-- where account_id = '933'
-- ) t1
-- on t0.ticker < t1.ticker;


-- base record for analyzing correlation
SELECT 
	B.sec_type
	,CASE 
		WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
		WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
		WHEN major_asset_class = 'equty' THEN 'equity' 
		ELSE major_asset_class 
		END AS major_asset_class
	,CASE 
		WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
		WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
		WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
		WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
		ELSE minor_asset_class END AS minor_asset_class
	,A.date
	,SUM(A.value) AS AMT
FROM	
(
	SELECT *
	FROM pricing_daily_new 
	WHERE DATE > DATE_SUB('2022-09-09', INTERVAL 24 MONTH) 
	AND price_type = 'Adjusted' 
) AS A
LEFT
JOIN security_masterlist  AS B
ON A.ticker = B.ticker
GROUP BY 
	B.sec_type
	,B.major_asset_class
	,B.minor_asset_class
	,A.date;
			
*/


/* --------------------------------------------------------------------------------
 *	## Team's work for building segmentaion
 *	-------------------------------------------------------------------------------- */
 /* Check the Create table queries before you run.
DROP TABLE IF EXISTS pricing_daily_min;
CREATE TABLE `pricing_daily_min` (
	`row_names` INT(10) NOT NULL,
	`date` DATE NOT NULL,
	`variable` VARCHAR(100) NULL DEFAULT NULL,
	`value` DOUBLE NULL DEFAULT NULL,
	`ticker` VARCHAR(8) NOT NULL,
	`price_type` VARCHAR(100) NULL DEFAULT NULL,
	PRIMARY KEY (`row_names`) USING BTREE
); # Customer's accounting open date's value

INSERT	INTO pricing_daily_min
SELECT	A.*
  FROM	pricing_daily_new AS A
  JOIN	(
  			SELECT	ticker
  						,MIN(DATE) AS date
  			  FROM	pricing_daily_new
  			 WHERE	price_type = 'Adjusted'
  			 			AND VALUE IS NOT NULL
  			 GROUP
  			 	 BY	ticker
  			) AS B
  	 ON	A.ticker = B.ticker 
  	 		AND A.date = B.date
  	 		AND A.price_type = 'Adjusted'
  	 		AND A.value IS NOT NULL;

# Each customer's total value calculating
DROP TABLE IF EXISTS cst_total_value;
CREATE TABLE cst_total_value (
	`client_id` INT UNSIGNED NOT NULL,
	`account_id` INT UNSIGNED NOT NULL,
	`ticker` VARCHAR(10) NOT NULL,
	`cur_date` DATE NOT NULL,
	`value` DOUBLE NOT NULL,
	`quantity` INT UNSIGNED NOT NULL,
	`acct_open_date` DATE NOT NULL,
	`FDT` DATE NOT NULL COMMENT 'Customer account open date or Assets first date',
	`FVAL` DOUBLE NOT NULL COMMENT 'Customer Value based on first day',
	KEY idx (`client_id`, `account_id`, `ticker`)
);

INSERT INTO cst_total_value
SELECT	*
  FROM	(
SELECT	A.*
			,CASE 
				WHEN DATEDIFF(A.acct_open_date, B.date) < 0 THEN B.date
				WHEN C.date IS NOT NULL THEN C.date
				WHEN D.date IS NOT NULL THEN D.date
				WHEN E.date IS NOT NULL THEN E.date
				WHEN G.date IS NOT NULL THEN G.date
				END AS FDT
			,CASE 
				WHEN DATEDIFF(A.acct_open_date, B.date) < 0 THEN B.value
				WHEN C.date IS NOT NULL THEN C.value
				WHEN D.date IS NOT NULL THEN D.value
				WHEN E.date IS NOT NULL THEN E.value
				WHEN G.date IS NOT NULL THEN G.value
				END AS FVAL
  FROM	(
			SELECT	B.client_id
						,A.account_id
						,A.ticker
						,A.date
						,A.value
						,A.quantity
						,B.acct_open_date
			  FROM	holdings_current AS A
			  LEFT
			  JOIN	account_dim AS B
			    ON	A.account_id = B.account_id
			 WHERE	A.date IS NOT NULL -- BRK.B, ACCOUNT_ID IN (7102,47501,376,77001) HAS NULL DATA
			) AS A
  LEFT
  JOIN	pricing_daily_min AS B
	 ON	A.ticker = B.ticker	
  LEFT
  JOIN	pricing_daily_new AS C
    ON	A.ticker = C.ticker
    		AND A.acct_open_date = C.date
    		AND C.value IS NOT NULL
    		AND C.price_type = 'Adjusted'
  LEFT
  JOIN	pricing_daily_new AS D
    ON	A.ticker = D.ticker
    		AND A.acct_open_date = DATE_SUB(D.date, INTERVAL 1 DAY)
    		AND D.value IS NOT NULL
    		AND C.price_type = 'Adjusted'
  LEFT
  JOIN	pricing_daily_new AS E
    ON	A.ticker = E.ticker
    		AND A.acct_open_date = DATE_SUB(E.date, INTERVAL 2 DAY)
    		AND E.value IS NOT NULL
    		AND C.price_type = 'Adjusted'
  LEFT
  JOIN	pricing_daily_new AS G
    ON	A.ticker = G.ticker
    		AND A.acct_open_date = DATE_SUB(G.date, INTERVAL 3 DAY)
    		AND G.value IS NOT NULL
    		AND C.price_type = 'Adjusted'
) AS BBBB



# BASE FOR CUSTOMER SEGMENTATION - # Portfolio Analysis Recent Trend
WITH BASE AS (
SELECT	client_id
			,account_id
			,A.ticker
			,cur_date
			,acct_open_date
			,FDT
			,DATEDIFF(CUR_DATE, FDT) AS PERIOD
			,ROUND(VALUE, 2) AS cur_value
			,ROUND(FVAL, 2) AS f_value
			,quantity
			,ROUND(VALUE * quantity, 2) AS current_amount
			,ROUND(FVAL * quantity, 2) AS start_amount
			,ROUND((VALUE * quantity - FVAL * quantity), 2) AS NET_Return
			,ROUND((VALUE * quantity - FVAL * quantity) / (FVAL * quantity) * 100, 3) AS `Return`
			,B.sec_type
			,CASE 
				WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
				WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
				WHEN major_asset_class = 'equty' THEN 'equity' 
				ELSE major_asset_class 
				END AS major_asset_class
			,CASE WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' ELSE minor_asset_class END AS minor_asset_class
			,B.sp500_weight
  FROM	cst_total_value AS A
  LEFT
  JOIN	security_masterlist AS B
    ON	A.ticker = B.ticker
 ORDER
 	 BY	client_id, account_id, ticker
)
, cst_info AS (
SELECT	CLIENT_ID
			,ROUND(SUM(CURRENT_AMOUNT), 2) AS CUR_AMT
			,ROUND(SUM(START_AMOUNT), 2) AS ST_AMT
			,ROUND(SUM(NET_RETURN), 2) AS NET_RETURN
			,ROUND(SUM(NET_RETURN) / SUM(START_AMOUNT) * 100, 2) AS RATE
			,ROUND(AVG(PERIOD), 0) AS PERIOD
  FROM	BASE
 GROUP
 	 BY	CLIENT_ID
)
SELECT	*
			,CASE 
				WHEN CUR_AMT > 5000000 THEN '1_High' -- Final Segmentaion
				WHEN CUR_AMT > 2000000 THEN '2_Mid'
				ELSE '3_Low'
				END AS ASSET_SEG -- Asset Based Segmentation
			,CASE 
				WHEN PERIOD > 365 * 3 THEN '1_High'
				WHEN PERIOD > 365 THEN '2_Mid'
				ELSE '3_Low'
				END AS PERIOD_SEG -- Investment Period based Segmentation
  FROM	cst_info
 	 
;
 	 
 	 */


/* ********************************
 * Prof. Thomas's class Querys 
	Risk Matrix:
		1. Mu: Average - Expected return
		2. Sigma: Standard Deviation - risk
		3. Mu / Sigma: Adjusted Return
		4. Daily sigma X sqrt(250)

 ***********************************/
 /*
 SELECT	ticker
 			,ROUND(AVG(ROD), 6) AS Mu
 			,ROUND(STDDEV_POP(ROD), 6) AS Sigma
 			,ROUND(AVG(ROD)/STDDEV_POP(ROD), 6) AS Risk_adj_returns
 			,ROUND(AVG(ROY), 6) AS Mu_Y
 			,ROUND(STDDEV_POP(ROY), 6) AS Sigma_Y
 			,ROUND(STDDEV_POP(ROD) * SQRT(252), 6) AS Sigma_Y2
 			,ROUND(AVG(ROY)/STDDEV_POP(ROY), 6) AS Risk_adj_returns_Y
   FROM	(
			 SELECT	ticker
			 			,date
			 			,value
			 			,LAG(VALUE, 1) OVER(PARTITION BY ticker ORDER BY DATE ASC) AS LAGGED_VAL_DAILY
			 			,(VALUE - LAG(VALUE, 1) OVER(PARTITION BY ticker ORDER BY DATE ASC))/LAG(VALUE, 1) OVER(PARTITION BY ticker ORDER BY DATE ASC) AS `ROD`
			 			,LAG(VALUE, 250) OVER(PARTITION BY ticker ORDER BY DATE ASC) AS LAGGED_VAL_YEARLY
			 			,(VALUE - LAG(VALUE, 250) OVER(PARTITION BY ticker ORDER BY DATE ASC))/LAG(VALUE, 250) OVER(PARTITION BY ticker ORDER BY DATE ASC) AS `ROY`
			   FROM	pricing_daily_new
			  WHERE	VALUE IS NOT NULL
			  			AND DATE > '2020-09-09'
			  			AND price_type = 'Adjusted'
			) AS A
 GROUP
 	 BY	ticker;
 	 
 

 SELECT	ROUND(AVG(ROD), 6) AS Mu
 			,ROUND(STDDEV_POP(ROD), 6) AS Sigma
 			,ROUND(AVG(ROD)/STDDEV_POP(ROD), 6) AS Risk_adj_returns
 			,ROUND(AVG(ROY), 6) AS Mu_Y
 			,ROUND(STDDEV_POP(ROY), 6) AS Sigma_Y
 			,ROUND(STDDEV_POP(ROD) * SQRT(252), 6) AS Sigma_Y2
 			,ROUND(AVG(ROY)/STDDEV_POP(ROY), 6) AS Risk_adj_returns_Y
   FROM	(
			 SELECT	date
			 			,value
			 			,LAG(VALUE, 1) OVER(ORDER BY DATE ASC) AS LAGGED_VAL_DAILY
			 			,(VALUE - LAG(VALUE, 1) OVER(ORDER BY DATE ASC))/LAG(VALUE, 1) OVER(ORDER BY DATE ASC) AS `ROD`
			 			,LAG(VALUE, 250) OVER(ORDER BY DATE ASC) AS LAGGED_VAL_YEARLY
			 			,(VALUE - LAG(VALUE, 250) OVER(ORDER BY DATE ASC))/LAG(VALUE, 250) OVER(ORDER BY DATE ASC) AS `ROY`
			   FROM	(
						SELECT	date
									,SUM(VALUE) AS value
						  FROM	pricing_daily_new
						 WHERE	VALUE IS NOT NULL
						  			AND DATE > '2020-09-09'
						  			AND price_type = 'Adjusted'
						 GROUP
						 	 BY	date
						) AS A
			) AS A
;
*/


/* --------------------------------------------------------------------------------
 *	## Finalized Version SQL - Building a Simulator
 * These simulator finalized by Yunsik through our teamworks.
 * Above queries are Our study history.
 *	-------------------------------------------------------------------------------- */

###################################################
#	SET Session Variables For Build Report
###################################################
SET @cid = 226; # Client ID
SET @t = 12; # Return period of month
SET @initial_invest_date = (SELECT DATE_ADD(DATE_SUB(MAX(DATE), INTERVAL @t MONTH), INTERVAL 1 DAY) FROM holdings_current); # Initial Investment Date for Calculate Weight
SET @fdt = (SELECT DATE_SUB(@initial_invest_date, INTERVAL @t MONTH)); # Start date of database
SET @lag_var = CAST(@t / 12 * 250 AS SIGNED); # Stock Market Lagged date variable
SET @qty = 2000; # Suggestion of Each New Porfolio Stock's size
SET @remove_item_list = JSON_ARRAY('YOLO', 'KOLD'); # Remove Tickers from client's portfolio
SET @Add_item_list = JSON_ARRAY('BCI', 'DJP', 'FTGC', 'USO', 'PFIX', 'DBMF', 'LBAY', 'BIL'); # Add new Tickers to client's portfolio


 
# Report 1. Personal Client's Portfolio Report
WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,B.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	B.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt # Total Data start date. 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered # (RoR - RoR_MEAN) for calculating Covariance
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR # Rate Of Return
			  FROM	BASE
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
, WEIGHT_BY_CLASS AS(
SELECT	SEC_TYPE
			,major_asset_class
			,SUM(VALUE * quantity) AS amount # Initial Amount of all Portfolio Class
			,SUM(VALUE * quantity) / (SELECT SUM(VALUE * quantity) FROM BASE WHERE	DATE = @initial_invest_date ) AS WEIGHT # Initial Amount Weight of Each Portfolio
			,ROW_NUMBER() OVER() AS RNUM
  FROM	BASE
 WHERE	DATE = @initial_invest_date
 GROUP
 	 BY	SEC_TYPE
			,major_asset_class
)
, STATISTICS_BY_CLASS AS (
	SELECT 	sec_type
				,major_asset_class
				,AVG((VALUE - LAG_VAL) / LAG_VAL) AS Mu # Expected Return 
				,STD((VALUE - LAG_VAL) / LAG_VAL) AS Sigma # Risk of All Class
				,STD((VALUE - LAG_VAL) / LAG_VAL) / AVG((VALUE - LAG_VAL) / LAG_VAL) AS CV # Coefficient of Variance Of All Class
				,VAR_SAMP((VALUE - LAG_VAL) / LAG_VAL) AS Var # Variance of All Class
	  FROM	BASE_BY_CLASS
	 GROUP
	 	 BY	sec_type
				,major_asset_class
) 
, STATISTICS AS ( # Merging Statistics all Class' Statistical values and Weight Information
SELECT	CONCAT(A.sec_type, ' - ', A.major_asset_class) AS class
			,ROUND(Mu, 6) AS Mu
			,ROUND(Sigma, 6) AS Sigma
			,ROUND(CV, 6) AS CV
			,ROUND(Var, 6) AS VAR
			,ROUND(B.WEIGHT, 6) AS Weight
			
  FROM	STATISTICS_BY_CLASS AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
)
, COV_MATRIX AS ( # Calculating Covariance And Correlation Coefficients Base Matrix
SELECT	DISTINCT A.SEC_TYPE AS X1
			,A.major_asset_class AS X2
			,B.SEC_TYPE AS Y1
			,B.major_asset_class AS Y2
  FROM	WEIGHT_BY_CLASS AS A
 CROSS
  JOIN	WEIGHT_BY_CLASS AS B
 ORDER
 	 BY	1, 2 # All Combinations of each Class
),
COV_CORR AS ( # Calculating Covariance And Correlation Coefficients
SELECT	A.*
			,B.Weight AS X_Weight
			,C.Weight AS Y_Weight
  FROM	(
			SELECT	X1,X2,Y1,Y2
						# Covariance = SUM((X - Xmu)(Y - Ymu)) / (N - 1)
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) AS COV # Covariance
						# Correlation Coefficient = Cov(X, Y) / SD(X) SD(Y)
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) / (STDDEV_SAMP(B.ROR_centered)*STDDEV_SAMP(C.ROR_centered)) AS CORR # Correlation Coefficients
			  FROM	COV_MATRIX AS A
			  LEFT
			  JOIN	BASE_BY_CLASS AS B # For X Variable's RoR Centered Value 
			    ON	A.X1 = B.sec_type
			    		AND A.X2 = B.major_asset_class
			  LEFT
			  JOIN	BASE_BY_CLASS AS C # For Y Variable's RoR Centered Value
			    ON	A.Y1 = C.sec_type
			   		AND A.Y2 = C.major_asset_class
			   		AND B.date = C.date
			 GROUP
			 	 BY	X1,X2,Y1,Y2
			) AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B # Weight for X Variable
    ON	A.X1 = B.sec_type 
    		AND A.X2 = B.major_asset_class
  LEFT
  JOIN	WEIGHT_BY_CLASS AS C # Weight for Y Variable
    ON	A.Y1 = C.sec_type 
    		AND A.Y2 = C.major_asset_class
)
# Client's Portfolio Report Build!
SELECT	'Customer Portfolio Report' AS Category, '' AS Statistics
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Full Name' AS category, full_name
  FROM	customer_details
 WHERE	customer_id = @cid
UNION ALL
SELECT	'Initial Invest Date', @initial_invest_date
UNION ALL
SELECT	'Total Invest Amount', FORMAT(SUM(amount), 2)
  FROM	WEIGHT_BY_CLASS
UNION ALL
SELECT	'Current Asset Amount', FORMAT(SUM(VALUE * quantity), 2)
  FROM	holdings_current AS A
  JOIN	account_dim AS B
    ON	A.account_id = B.account_id
 WHERE	B.client_id = @cid
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Portfolio Risk - by Covariance' AS Category, FORMAT(SUM(RISK), 5) AS Statistics
  FROM	(
			SELECT	SUM(POWER(Weight, 2) * VAR) AS RISK FROM STATISTICS
			UNION
			SELECT	SUM(X_Weight * Y_Weight * COV) FROM COV_CORR
			) AS A
UNION ALL
SELECT	'Expected Return of Portfolio', FORMAT(SUM(A.Mu * B.WEIGHT), 5) # Expected Return of total Portfolio
  FROM	STATISTICS_BY_CLASS AS A
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Weight Of Class', ''
UNION ALL
SELECT	CONCAT(sec_type, ' - ', major_asset_class)
			,CONCAT(FORMAT(Weight * 100, 2), '%')
  FROM	WEIGHT_BY_CLASS
UNION ALL
SELECT	'-------------------', '----------------------'
;


############################################################################################################################

/* **************************************************************
# Step 2. Portfolio's Key Purpose Index
	1. Mu: Mean of RoR (Rate of Return) 
	2. Sigma: Standard Deviation of RoR
	3. Coefficient of Variance
	4. Variance
	5. Weight:
 * ***************************************************************/
WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,B.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	B.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR
			  FROM	BASE
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
, WEIGHT_BY_CLASS AS(
SELECT	SEC_TYPE
			,major_asset_class
			,SUM(VALUE * quantity) AS amount # Initial Amount of all Portfolio
			,SUM(VALUE * quantity) / (SELECT SUM(VALUE * quantity) FROM BASE WHERE	DATE = @initial_invest_date ) AS WEIGHT # Initial Amount Weight of Each Portfolio
			,ROW_NUMBER() OVER() AS RNUM
  FROM	BASE
 WHERE	DATE = @initial_invest_date
 GROUP
 	 BY	SEC_TYPE
			,major_asset_class
)
, STATISTICS_BY_CLASS AS (
	SELECT 	sec_type
				,major_asset_class
				,AVG((VALUE - LAG_VAL) / LAG_VAL) AS Mu
				,STD((VALUE - LAG_VAL) / LAG_VAL) AS Sigma
				,STD((VALUE - LAG_VAL) / LAG_VAL) / AVG((VALUE - LAG_VAL) / LAG_VAL) AS CV
				,VAR_SAMP((VALUE - LAG_VAL) / LAG_VAL) AS Var
	  FROM	BASE_BY_CLASS
	 GROUP
	 	 BY	sec_type
				,major_asset_class
) 
, STATISTICS AS (
SELECT	CONCAT(A.sec_type, ' - ', A.major_asset_class) AS class
			,ROUND(Mu, 6) AS Mu
			,ROUND(Sigma, 6) AS Sigma
			,ROUND(Mu / Sigma, 6) AS Adj_RoR
			,ROUND(CV, 6) AS CV
			,ROUND(Var, 6) AS VAR
			,ROUND(B.WEIGHT, 6) AS Weight
			
  FROM	STATISTICS_BY_CLASS AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
)
SELECT	CLASS
			,ROUND(Mu, 3) AS Mu
			,ROUND(Sigma, 3) AS Sigma
			,ROUND(Adj_Ror, 3) AS `Adjusted Return`
			,ROUND(CV, 3) AS `Coefficient of Variance`
			,ROUND(VAR, 5) AS `Variance`
			,ROUND(Weight, 3) AS Weight
  FROM	STATISTICS;


############################################################################################################################

/* **************************************************************
# Step 3. Portfolio's Covariance And Correlation Coefficient Table

 * ***************************************************************/
WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,B.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	B.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR
			  FROM	BASE
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
, WEIGHT_BY_CLASS AS(
SELECT	SEC_TYPE
			,major_asset_class
			,SUM(VALUE * quantity) AS amount # Initial Amount of all Portfolio
			,SUM(VALUE * quantity) / (SELECT SUM(VALUE * quantity) FROM BASE WHERE	DATE = @initial_invest_date ) AS WEIGHT # Initial Amount Weight of Each Portfolio
			,ROW_NUMBER() OVER() AS RNUM
  FROM	BASE
 WHERE	DATE = @initial_invest_date
 GROUP
 	 BY	SEC_TYPE
			,major_asset_class
)
, STATISTICS_BY_CLASS AS (
	SELECT 	sec_type
				,major_asset_class
				,AVG((VALUE - LAG_VAL) / LAG_VAL) AS Mu
				,STD((VALUE - LAG_VAL) / LAG_VAL) AS Sigma
				,STD((VALUE - LAG_VAL) / LAG_VAL) / AVG((VALUE - LAG_VAL) / LAG_VAL) AS CV
				,VAR_SAMP((VALUE - LAG_VAL) / LAG_VAL) AS Var
	  FROM	BASE_BY_CLASS
	 GROUP
	 	 BY	sec_type
				,major_asset_class
) 
, STATISTICS AS (
SELECT	CONCAT(A.sec_type, ' - ', A.major_asset_class) AS class
			,ROUND(Mu, 6) AS Mu
			,ROUND(Sigma, 6) AS Sigma
			,ROUND(CV, 6) AS CV
			,ROUND(Var, 6) AS VAR
			,ROUND(B.WEIGHT, 6) AS Weight
			
  FROM	STATISTICS_BY_CLASS AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
)
, COV_MATRIX AS (
SELECT	DISTINCT A.SEC_TYPE AS X1
			,A.major_asset_class AS X2
			,B.SEC_TYPE AS Y1
			,B.major_asset_class AS Y2
  FROM	WEIGHT_BY_CLASS AS A
 CROSS
  JOIN	WEIGHT_BY_CLASS AS B
 ORDER
 	 BY	1, 2
),
COV_CORR AS (
SELECT	A.*
			,B.Weight AS X_Weight
			,C.Weight AS Y_Weight
  FROM	(
			SELECT	X1,X2,Y1,Y2
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) AS COV
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) / (STDDEV_SAMP(B.ROR_centered)*STDDEV_SAMP(C.ROR_centered)) AS CORR
			  FROM	COV_MATRIX AS A
			  LEFT
			  JOIN	BASE_BY_CLASS AS B
			    ON	A.X1 = B.sec_type
			    		AND A.X2 = B.major_asset_class
			  LEFT
			  JOIN	BASE_BY_CLASS AS C
			    ON	A.Y1 = C.sec_type
			   		AND A.Y2 = C.major_asset_class
			   		AND B.date = C.date
			 GROUP
			 	 BY	X1,X2,Y1,Y2
			) AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.X1 = B.sec_type 
    		AND A.X2 = B.major_asset_class
  LEFT
  JOIN	WEIGHT_BY_CLASS AS C
    ON	A.Y1 = C.sec_type 
    		AND A.Y2 = C.major_asset_class
)
SELECT	CONCAT(X1, ' - ', X2) AS `Class (X)`
			,CONCAT(Y1, ' - ', Y2) AS `Class (Y)`
			,ROUND(COV, 6) AS Covariance
			,ROUND(CORR, 3) AS `Correlation Coefficient`
  FROM	COV_CORR;
  

############################################################################################################################

/* **************************************************************
# Step 4. RAW DATA of Class Leval, date values 

 * ***************************************************************/

WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,B.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	B.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(VALUE * quantity) AS Amount
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR
			  FROM	BASE
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
SELECT	CONCAT(sec_type, ' - ', major_asset_class) AS Class
			,date
			,ROUND(VALUE, 2) AS VALUE # Each day's Class Price
			,ROUND(Amount, 2) AS Amount # Each Day's Amount: Sum of ticker Value X Quantity 
			,ROUND(LAG_VAL, 2) AS `Lagged Value` # Lagged Price of selected Monthly difference
			,ROUND(ROR, 3) AS RoR # Rate of Return
			,ROUND(ROR_centered, 3) AS `RoR - Mu` # RoR centered
  FROM	BASE_BY_CLASS;
  
  
############################################################################################################################



/* **************************************************************
# Step 5. Personal Client's Portfolio Simulation Results

 * ***************************************************************/
WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,D.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,C.ticker
						,C.date
						,C.value 
						,LAG(C.VALUE, @lag_var) OVER(PARTITION BY C.ticker ORDER BY C.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	pricing_daily_new AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	security_masterlist AS D
			    ON	C.ticker = D.ticker 
				 		AND C.value IS NOT NULL
						AND C.date >= @fdt # Total Data start date. 
						AND C.price_type = 'Adjusted'
			 WHERE	D.ticker IS NOT NULL
			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
)
, PORTFOLIO_WEIGHT_ACTURE AS (
SELECT	*
			,VALUE * quantity AS AMOUNT
			,(VALUE * quantity) / SUM(VALUE * quantity) OVER() AS WEIGHT_PER_TICKER
  FROM	BASE
 WHERE	DATE = @initial_invest_date
), BASE_FOR_VISUAL AS (
SELECT	*
			,VALUE * quantity AS AMOUNT
			,(VALUE - LAG_VAL) / LAG_VAL AS ROR
  FROM	BASE
) 
, MARKET_BASE AS (
SELECT	*
			,(VALUE - LAG_VAL) / LAG_VAL AS ROR
  FROM	(
			SELECT	D.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,C.ticker
						,C.date
						,C.value 
						,LAG(C.VALUE, @lag_var) OVER(PARTITION BY C.ticker ORDER BY C.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	pricing_daily_new AS C
			  LEFT
			  JOIN	security_masterlist AS D
			    ON	C.ticker = D.ticker 
				 		AND C.value IS NOT NULL
						AND C.date >= @fdt # Total Data start date. 
						AND C.price_type = 'Adjusted'
			 WHERE	D.ticker IS NOT NULL
 			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
) 
, SIMULATED_HOLD AS ( # 
SELECT	A.quantity
			,A.ticker
  FROM	holdings_current AS A
  JOIN	account_dim AS B
    ON	A.account_id = B.account_id
    		AND B.client_id = @cid
 WHERE	IF(JSON_SEARCH(@remove_item_list, 'ALL', ticker) IS NOT NULL, 1, 0) = 0
UNION		
SELECT	@qty
			,ticker
  FROM	security_masterlist AS A, (SELECT @Add_item_list AS J) AS B
 WHERE	IF(JSON_SEARCH(@Add_item_list, 'ALL', ticker) IS NOT NULL, 1, 0) = 1
)
, BASE_SIM AS (
SELECT	*
  FROM	(
			SELECT	A.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,A.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	SIMULATED_HOLD AS A
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	A.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	A.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt # Total Data start date. 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered # (RoR - RoR_MEAN) for calculating Covariance
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR # Rate Of Return
			  FROM	BASE_SIM
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
, WEIGHT_BY_CLASS AS(
SELECT	SEC_TYPE
			,major_asset_class
			,SUM(VALUE * quantity) AS amount # Initial Amount of all Portfolio Class
			,SUM(VALUE * quantity) / (SELECT SUM(VALUE * quantity) FROM BASE WHERE	DATE = @initial_invest_date ) AS WEIGHT # Initial Amount Weight of Each Portfolio
			,ROW_NUMBER() OVER() AS RNUM
  FROM	BASE_SIM
 WHERE	DATE = @initial_invest_date
 GROUP
 	 BY	SEC_TYPE
			,major_asset_class
)
, STATISTICS_BY_CLASS AS (
	SELECT 	sec_type
				,major_asset_class
				,AVG((VALUE - LAG_VAL) / LAG_VAL) AS Mu # Expected Return 
				,STD((VALUE - LAG_VAL) / LAG_VAL) AS Sigma # Risk of All Class
				,STD((VALUE - LAG_VAL) / LAG_VAL) / AVG((VALUE - LAG_VAL) / LAG_VAL) AS CV # Coefficient of Variance Of All Class
				,VAR_SAMP((VALUE - LAG_VAL) / LAG_VAL) AS Var # Variance of All Class
	  FROM	BASE_BY_CLASS
	 GROUP
	 	 BY	sec_type
				,major_asset_class
) 
, STATISTICS AS ( # Merging Statistics all Class' Statistical values and Weight Information
SELECT	CONCAT(A.sec_type, ' - ', A.major_asset_class) AS class
			,ROUND(Mu, 6) AS Mu
			,ROUND(Sigma, 6) AS Sigma
			,ROUND(CV, 6) AS CV
			,ROUND(Var, 6) AS VAR
			,ROUND(B.WEIGHT, 6) AS Weight
			
  FROM	STATISTICS_BY_CLASS AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
)
, COV_MATRIX AS ( # Calculating Covariance And Correlation Coefficients Base Matrix
SELECT	DISTINCT A.SEC_TYPE AS X1
			,A.major_asset_class AS X2
			,B.SEC_TYPE AS Y1
			,B.major_asset_class AS Y2
  FROM	WEIGHT_BY_CLASS AS A
 CROSS
  JOIN	WEIGHT_BY_CLASS AS B
 ORDER
 	 BY	1, 2 # All Combinations of each Class
),
COV_CORR AS ( # Calculating Covariance And Correlation Coefficients
SELECT	A.*
			,B.Weight AS X_Weight
			,C.Weight AS Y_Weight
  FROM	(
			SELECT	X1,X2,Y1,Y2
						# Covariance = SUM((X - Xmu)(Y - Ymu)) / (N - 1)
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) AS COV # Covariance
						# Correlation Coefficient = Cov(X, Y) / SD(X) SD(Y)
						,SUM(B.ROR_centered * C.ROR_centered) / (COUNT(*) - 1) / (STDDEV_SAMP(B.ROR_centered)*STDDEV_SAMP(C.ROR_centered)) AS CORR # Correlation Coefficients
			  FROM	COV_MATRIX AS A
			  LEFT
			  JOIN	BASE_BY_CLASS AS B # For X Variable's RoR Centered Value 
			    ON	A.X1 = B.sec_type
			    		AND A.X2 = B.major_asset_class
			  LEFT
			  JOIN	BASE_BY_CLASS AS C # For Y Variable's RoR Centered Value
			    ON	A.Y1 = C.sec_type
			   		AND A.Y2 = C.major_asset_class
			   		AND B.date = C.date
			 GROUP
			 	 BY	X1,X2,Y1,Y2
			) AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B # Weight for X Variable
    ON	A.X1 = B.sec_type 
    		AND A.X2 = B.major_asset_class
  LEFT
  JOIN	WEIGHT_BY_CLASS AS C # Weight for Y Variable
    ON	A.Y1 = C.sec_type 
    		AND A.Y2 = C.major_asset_class
)
# Client's Portfolio Report Build!
SELECT	'Customer Portfolio Report' AS Category, '' AS Statistics
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Full Name' AS category, full_name
  FROM	customer_details
 WHERE	customer_id = @cid
UNION ALL
SELECT	'Initial Invest Date', @initial_invest_date
UNION ALL
SELECT	'Total Invest Amount', FORMAT(SUM(amount), 2)
  FROM	WEIGHT_BY_CLASS
UNION ALL
SELECT	'Current Asset Amount', FORMAT(SUM(VALUE * quantity), 2)
  FROM	SIMULATED_HOLD AS A
  JOIN	pricing_daily_new AS B
    ON	A.ticker = B.ticker
    		AND B.price_type = 'Adjusted'
    		AND B.date = (SELECT MAX(DATE) FROM holdings_current)
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Portfolio Risk - by Covariance' AS Category, FORMAT(SUM(RISK), 5) AS Statistics
  FROM	(
			SELECT	SUM(POWER(Weight, 2) * VAR) AS RISK FROM STATISTICS
			UNION
			SELECT	SUM(X_Weight * Y_Weight * COV) FROM COV_CORR
			) AS A
UNION ALL
SELECT	'Expected Return of Portfolio', FORMAT(SUM(A.Mu * B.WEIGHT), 5) # Expected Return of total Portfolio
  FROM	STATISTICS_BY_CLASS AS A
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
UNION ALL
SELECT	'-------------------', '----------------------'
UNION ALL
SELECT	'Weight Of Class', ''
UNION ALL
SELECT	CONCAT(sec_type, ' - ', major_asset_class)
			,CONCAT(FORMAT(Weight * 100, 2), '%')
  FROM	WEIGHT_BY_CLASS
UNION ALL
SELECT	'-------------------', '----------------------'
;

############################################################################################################################

/* **************************************************************
# Step 6. Personal Client's Portfolio Simulation Results 2

 * ***************************************************************/
WITH BASE AS(
SELECT	*
  FROM	(
			SELECT	B.quantity
						,D.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,C.ticker
						,C.date
						,C.value 
						,LAG(C.VALUE, @lag_var) OVER(PARTITION BY C.ticker ORDER BY C.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	account_dim AS A
			  JOIN	holdings_current AS B
			    ON	A.account_id = B.account_id
			    		AND A.client_id = @cid
			  LEFT
			  JOIN	pricing_daily_new AS C
			    ON	B.ticker = C.ticker
			  LEFT
			  JOIN	security_masterlist AS D
			    ON	C.ticker = D.ticker 
				 		AND C.value IS NOT NULL
						AND C.date >= @fdt # Total Data start date. 
						AND C.price_type = 'Adjusted'
			 WHERE	D.ticker IS NOT NULL
			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
)
, PORTFOLIO_WEIGHT_ACTURE AS (
SELECT	*
			,VALUE * quantity AS AMOUNT
			,(VALUE * quantity) / SUM(VALUE * quantity) OVER() AS WEIGHT_PER_TICKER
  FROM	BASE
 WHERE	DATE = @initial_invest_date
), BASE_FOR_VISUAL AS (
SELECT	*
			,VALUE * quantity AS AMOUNT
			,(VALUE - LAG_VAL) / LAG_VAL AS ROR
  FROM	BASE
) 
, MARKET_BASE AS (
SELECT	*
			,(VALUE - LAG_VAL) / LAG_VAL AS ROR
  FROM	(
			SELECT	D.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,C.ticker
						,C.date
						,C.value 
						,LAG(C.VALUE, @lag_var) OVER(PARTITION BY C.ticker ORDER BY C.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	pricing_daily_new AS C
			  LEFT
			  JOIN	security_masterlist AS D
			    ON	C.ticker = D.ticker 
				 		AND C.value IS NOT NULL
						AND C.date >= @fdt # Total Data start date. 
						AND C.price_type = 'Adjusted'
			 WHERE	D.ticker IS NOT NULL
 			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
) 
, SIMULATED_HOLD AS ( # 
SELECT	A.quantity
			,A.ticker
  FROM	holdings_current AS A
  JOIN	account_dim AS B
    ON	A.account_id = B.account_id
    		AND B.client_id = @cid
 WHERE	IF(JSON_SEARCH(@remove_item_list, 'ALL', ticker) IS NOT NULL, 1, 0) = 0
UNION		
SELECT	@qty
			,ticker
  FROM	security_masterlist AS A, (SELECT @Add_item_list AS J) AS B
 WHERE	IF(JSON_SEARCH(@Add_item_list, 'ALL', ticker) IS NOT NULL, 1, 0) = 1
)
, BASE_SIM AS (
SELECT	*
  FROM	(
			SELECT	A.quantity
						,C.sec_type
						,CASE # Data Cleansing For Major Asset Class
							WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
							WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							WHEN major_asset_class = 'equty' THEN 'equity' 
							ELSE major_asset_class 
							END AS major_asset_class
						,CASE # Data Cleansing for Minor Asset Class
							WHEN major_asset_class = 'fixed income corporate' THEN 'corporate' 
							WHEN major_asset_class = 'equity' AND minor_asset_class = '' THEN 'equity'
							WHEN major_asset_class = 'alternatives' AND minor_asset_class = '' THEN 'alternatives'
							WHEN major_asset_class = 'fixed_income' AND minor_asset_class = '' THEN 'fixed income'
							ELSE minor_asset_class END AS minor_asset_class
						,A.ticker
						,D.date
						,D.value 
						,LAG(D.VALUE, @lag_var) OVER(PARTITION BY D.ticker ORDER BY D.date ASC) AS LAG_VAL # Lagged Price By row
			  FROM	SIMULATED_HOLD AS A
			  LEFT
			  JOIN	security_masterlist AS C
			    ON	A.ticker = C.ticker
			  LEFT
			  JOIN	pricing_daily_new AS D
			    ON	A.ticker = D.ticker 
				 		AND D.value IS NOT NULL
						AND D.date >= @fdt # Total Data start date. 
						AND D.price_type = 'Adjusted'
			) AS A
 WHERE	DATE >= @initial_invest_date # Initial Invest date
)
, BASE_BY_CLASS AS (
SELECT	*
			,ROR - AVG(ROR) OVER(PARTITION BY sec_type, major_asset_class) AS ROR_centered # (RoR - RoR_MEAN) for calculating Covariance
  FROM	(
			SELECT	sec_type
						,major_asset_class
						,date
						,SUM(VALUE) AS value
						,SUM(LAG_VAL) AS LAG_VAL
						,((SUM(VALUE) - SUM(LAG_VAL)) / SUM(LAG_VAL)) AS ROR # Rate Of Return
			  FROM	BASE_SIM
			 GROUP
			 	 BY	sec_type
			 	 		,major_asset_class
			 	 		,DATE
			) AS A
)
, WEIGHT_BY_CLASS AS(
SELECT	SEC_TYPE
			,major_asset_class
			,SUM(VALUE * quantity) AS amount # Initial Amount of all Portfolio Class
			,SUM(VALUE * quantity) / (SELECT SUM(VALUE * quantity) FROM BASE WHERE	DATE = @initial_invest_date ) AS WEIGHT # Initial Amount Weight of Each Portfolio
			,ROW_NUMBER() OVER() AS RNUM
  FROM	BASE_SIM
 WHERE	DATE = @initial_invest_date
 GROUP
 	 BY	SEC_TYPE
			,major_asset_class
)
, STATISTICS_BY_CLASS AS (
	SELECT 	sec_type
				,major_asset_class
				,AVG((VALUE - LAG_VAL) / LAG_VAL) AS Mu
				,STD((VALUE - LAG_VAL) / LAG_VAL) AS Sigma
				,STD((VALUE - LAG_VAL) / LAG_VAL) / AVG((VALUE - LAG_VAL) / LAG_VAL) AS CV
				,VAR_SAMP((VALUE - LAG_VAL) / LAG_VAL) AS Var
	  FROM	BASE_BY_CLASS
	 GROUP
	 	 BY	sec_type
				,major_asset_class
) 
, STATISTICS AS (
SELECT	CONCAT(A.sec_type, ' - ', A.major_asset_class) AS class
			,ROUND(Mu, 6) AS Mu
			,ROUND(Sigma, 6) AS Sigma
			,ROUND(Mu / Sigma, 6) AS Adj_RoR
			,ROUND(CV, 6) AS CV
			,ROUND(Var, 6) AS VAR
			,ROUND(B.WEIGHT, 6) AS Weight
			
  FROM	STATISTICS_BY_CLASS AS A
  LEFT
  JOIN	WEIGHT_BY_CLASS AS B
    ON	A.sec_type = B.sec_type
    		AND A.major_asset_class = B.major_asset_class
)
# Client's Portfolio Report Build! By Simulatied Result
SELECT	CLASS
			,ROUND(Mu, 3) AS Mu
			,ROUND(Sigma, 3) AS Sigma
			,ROUND(Adj_Ror, 3) AS `Adjusted Return`
			,ROUND(CV, 3) AS `Coefficient of Variance`
			,ROUND(VAR, 5) AS `Variance`
			,ROUND(Weight, 3) AS Weight
  FROM	STATISTICS;

