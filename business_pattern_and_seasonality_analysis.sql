-- 1. Finding out monthly revenue for each products, their margin and the total revenue and total orders.

SELECT 
		YEAR(created_at) AS yr,
        MONTH(created_at) AS mth,
        SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS 'p1_revenue',
		SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS 'p2_revenue',
        SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS 'p3_revenue',
        SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS 'p4_revenue',
        SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) - 
        SUM(CASE WHEN product_id = 1 THEN cogs_usd ELSE NULL END) AS 'p1_margin',
        SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) - 
        SUM(CASE WHEN product_id = 2 THEN cogs_usd ELSE NULL END) AS 'p2_margin',
        SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) - 
        SUM(CASE WHEN product_id = 3 THEN cogs_usd ELSE NULL END) AS 'p3_margin',
        SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) - 
        SUM(CASE WHEN product_id = 4 THEN cogs_usd ELSE NULL END) AS 'p4_margin',
        SUM(price_usd) AS total_revenue,
        SUM(price_usd) - SUM(cogs_usd) AS total_margin
 FROM order_items
 GROUP BY 1,2
 ORDER BY 1,2;
 
 
 
 
 
 
 
 
 
 
 -- 2. Finding out monthly session-to-order conversion rate, revenue per order and revenue per session

SELECT
		YEAR(t1.created_at) AS yr,
        QUARTER(t1.created_at) AS qtr,
        COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT t1.website_session_id) AS conversion_rate,
        SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS revenue_per_order,
		SUM(orders.price_usd)/COUNT(DISTINCT t1.website_session_id) AS revenue_per_session
FROM website_sessions AS t1
		LEFT JOIN orders 
			ON orders.website_session_id = t1.website_session_id
GROUP BY 1,2;










-- 3. The company is planning to set up the customer care team.
-- Finding out the average sessions per hour per day of the week.

WITH cte AS (
		SELECT 
				DATE(created_at) AS created_date,
				WEEKDAY(created_at) AS wk_day,
				HOUR(created_at) AS hr,
				COUNT(DISTINCT website_session_id) AS sessions
		FROM website_sessions
		WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
		GROUP BY 2,3,1
		ORDER BY 1)
SELECT 
		hr,
        ROUND(AVG(sessions), 2) AS hourly_avg,
        ROUND(AVG(CASE WHEN wk_day = 0 THEN sessions ELSE NULL END), 2) AS mon,
        ROUND(AVG(CASE WHEN wk_day = 1 THEN sessions ELSE NULL END), 2) AS tue,
        ROUND(AVG(CASE WHEN wk_day = 2 THEN sessions ELSE NULL END), 2) AS wed,
        ROUND(AVG(CASE WHEN wk_day = 3 THEN sessions ELSE NULL END), 2) AS thurs,
        ROUND(AVG(CASE WHEN wk_day = 4 THEN sessions ELSE NULL END), 2) AS fri,
        ROUND(AVG(CASE WHEN wk_day = 5 THEN sessions ELSE NULL END), 2) AS sat,
        ROUND(AVG(CASE WHEN wk_day = 6 THEN sessions ELSE NULL END), 2) AS sun
FROM cte
GROUP BY 1;










-- 4. Finding monthly number of sales, total revenue and total_margin.

SELECT 
		YEAR(created_at) AS yr,
        MONTH(created_at) AS mth,
        COUNT(DISTINCT order_id) AS number_of_sales,
        SUM(price_usd) AS total_revenue,
        SUM(price_usd)-SUM(cogs_usd) AS total_margin
FROM orders
GROUP BY 1,2;










-- 5. Finding how many of the website visitors come back for another session.

SELECT
		CASE 
			when repeated_times = 1 THEN 0
            when repeated_times = 2 THEN 1
            when repeated_times = 3 THEN 2
            when repeated_times = 4 THEN 3
            ELSE 'check_logic'
            END AS 'repeated_times',
            COUNT(DISTINCT user_id) AS users
FROM 
(SELECT
		user_id,
        COUNT(DISTINCT website_session_id) AS repeated_times
FROM website_sessions
GROUP BY 1) A
GROUP BY repeated_times;










-- 6. Finding the maximun, minimun and average days between the first and second session
-- for the customers who come back.

WITH cte2 AS (
		WITH cte AS (
					SELECT
							first_session_info.user_id,
							first_session_info.first_session_id,
							first_session_info.first_session_created_at,
							website_sessions.website_session_id AS repeated_session_id,
							website_sessions.created_at AS repeated_created_at
					FROM
							(SELECT
									user_id,
									website_session_id AS first_session_id,
									created_at AS first_session_created_at
							FROM website_sessions 
							WHERE is_repeat_session = 0) AS first_session_info
					LEFT JOIN website_sessions
							ON website_sessions.user_id = first_session_info.user_id
							AND website_sessions.is_repeat_session = 1
							AND website_sessions.website_session_id > first_session_info.first_session_id)
		SELECT 
				user_id,
				first_session_id,
				first_session_created_at,
				MIN(repeated_session_id) AS repeated_session_id,
				MIN(repeated_created_at) AS repeated_created_at
		FROM cte 
		GROUP BY 1,2,3
        HAVING repeated_session_id IS NOT NULL)
SELECT 
        MAX(DATEDIFF(repeated_created_at, first_session_created_at)) AS max,
        MIN(DATEDIFF(repeated_created_at, first_session_created_at)) AS min,
        AVG(DATEDIFF(repeated_created_at, first_session_created_at)) AS average_days
FROM cte2;









-- 7. Comparing session-to-order conversion rate and revenue per session for repeat sessions vs. new sessions.

SELECT
		CASE
			WHEN is_repeat_session = 0 THEN 'new_customer'
            WHEN is_repeat_session = 1 THEN 'old_customer'
            ELSE 'check_logic'
            END AS 'customer_type',
            COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
            COUNT(DISTINCT orders.order_id) AS orders,
            COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_cvr,
            SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
GROUP BY 1;









-- 8. Running a pre_post analysis comparing the month before vs month after launching our new product called 'birthday_bear'
--  in terms of session-to-order conversion rate, AOV, products per order, revenue per session.

SELECT
		CASE 
			WHEN website_sessions.created_at BETWEEN '2013-11-12' AND '2013-12-12' THEN 'pre_birthday_bear'
            WHEN website_sessions.created_at BETWEEN '2013-12-12' AND '2014-01-12' THEN 'post_birthday_bear'
            ELSE 'checl_logic'
            END AS 'tiem_period',
            COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_cvr,
            SUM(price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value,
            SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
            SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
		LEFT JOIN orders
			ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;