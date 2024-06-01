-- 1.  Analyze the monthly bounce rate for the landing page to assess the website's performance.

-- Creating a temporary table to get all the relevant session ids that landing on the homepage.

CREATE TEMPORARY TABLE first_pageview
SELECT 
	DATE(website_sessions.created_at) AS created_at,
        website_sessions.website_session_id,
        MIN(website_pageviews.website_pageview_id),
        pageview_url
FROM website_sessions
		LEFT JOIN website_pageviews
			ON website_pageviews.website_session_id = website_sessions.website_session_id  
GROUP BY 1,2,4;





-- Creating another temporary table to get all the bounce session ids.

CREATE TEMPORARY TABLE bounce_table
SELECT 
        first_pageview.website_session_id,
        COUNT(website_pageview_id) AS bounce_session
FROM first_pageview
		LEFT JOIN website_pageviews
			ON website_pageviews.website_session_id = first_pageview.website_session_id
GROUP BY 1
HAVING bounce_session = 1;





-- Getting the final output, joining the temporary tables to get the count of total sessions and bounce sessions.

SELECT 
	YEAR(first_pageview.created_at) AS yr,
        MONTH(first_pageview.created_at) AS mth,
        COUNT(first_pageview.website_session_id) AS total_session,
        COUNT(bounce_table.website_session_id) AS bounce_session,
        COUNT(bounce_table.website_session_id)/COUNT(first_pageview.website_session_id) AS bounce_rate
FROM first_pageview
		LEFT JOIN bounce_table
				ON bounce_table.website_session_id = first_pageview.website_session_id
GROUP BY 1,2;










-- 2. Compare each landing page's total sessions, total orders, session-to-order conversion rate, 
-- revenue per order, revenue per session, and total revenue.

SELECT 	
        t2.pageview_url,
        COUNT(DISTINCT t1.website_session_id) AS total_session,
        COUNT(DISTINCT order_id) AS total_order,
        COUNT(DISTINCT order_id)/COUNT(t1.website_session_id) AS order_conversion_rate,
        SUM(orders.price_usd)/COUNT(DISTINCT order_id) AS revenue_per_order,
        SUM(orders.price_usd)/COUNT(DISTINCT t1.website_session_id) AS revenue_per_session,
        SUM(orders.price_usd) AS total_revenue
FROM website_sessions AS t1
		RIGHT JOIN website_pageviews AS t2
			ON t2.website_session_id = t1.website_session_id
		LEFT JOIN orders
			ON orders.website_session_id = t1.website_session_id
WHERE pageview_url IN ('/home','/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5')
GROUP BY 1
ORDER BY 2 DESC;










-- 3. For the landing pages, creating a full conversion funnel from 
-- by using temporary table and subquery

CREATE TEMPORARY TABLE pageviews_visited
	SELECT 
		website_session_id,
		MAX(home_page)AS home,
		MAX(lander_1) AS lander_1,
            MAX(lander_2) AS lander_2,
            MAX(lander_3) AS lander_3,
            MAX(lander_4) AS lander_4,
            MAX(lander_5) AS lander_5,
		MAX(product) AS product,
		MAX(cart) AS cart,
		MAX(shipping) AS shipping,
		MAX(billing) AS billing,
		MAX(thankyou) AS thankyou
	FROM
			(SELECT 
				website_sessions.website_session_id,
				CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS home_page,
				CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1,
                		CASE WHEN pageview_url = '/lander-2' THEN 1 ELSE 0 END AS lander_2,
                		CASE WHEN pageview_url = '/lander-3' THEN 1 ELSE 0 END AS lander_3,
                		CASE WHEN pageview_url = '/lander-4' THEN 1 ELSE 0 END AS lander_4,
                		CASE WHEN pageview_url = '/lander-5' THEN 1 ELSE 0 END AS lander_5,
				CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product,
				CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
				CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END  AS shipping,
				CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END AS billing,
				CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
		FROM website_sessions 
				LEFT JOIN website_pageviews
					ON website_pageviews.website_session_id = website_sessions.website_session_id) AS pageview_level
GROUP BY 1;


SELECT 
		CASE 
	WHEN pageviews_visited.home = 1 THEN 'home'
	WHEN pageviews_visited.lander_1 = 1 THEN 'lander_1'
        WHEN pageviews_visited.lander_2 = 1 THEN 'lander_2'
        WHEN pageviews_visited.lander_3 = 1 THEN 'lander_3'
        WHEN pageviews_visited.lander_4 = 1 THEN 'lander_4'
        WHEN pageviews_visited.lander_5 = 1 THEN 'lander_5'
        ELSE 'something_is_wrong'
        END AS segment,
        COUNT(DISTINCT website_session_id) AS session,
        SUM(product) AS product,
        SUM(cart) AS cart,
        SUM(shipping) AS shipping,
        SUM(billing) AS billing,
        SUM(thankyou) AS thankyou
FROM pageviews_visited
GROUP BY segment;










-- 4. Analyzing the session-to-order conversion rate to evaluate website performance improvements over the first 8 months.

SELECT 
	MIN(DATE(t1.created_at))AS month_start_date,
        COUNT(t1.website_session_id) AS total_session,
        SUM( CASE WHEN order_id IS NOT NULL THEN 1 ELSE 0 END) AS total_order,
        SUM( CASE WHEN order_id IS NOT NULL THEN 1 ELSE 0 END)/ COUNT(t1.website_session_id)*100 AS session_to_order_rate
FROM website_sessions AS t1
		LEFT JOIN orders
			ON orders.website_session_id = t1.website_session_id
WHERE t1.created_at < '2012-11-27'
GROUP BY MONTH(t1.created_at);










-- 5. The company has implemented a new billing page named 'billing-2'. We are analyzing which billing page 
-- generates more orders, revenue, and revenue per billing session.

SELECT 
	pageview_url,
        COUNT(t1.website_session_id) AS total_session,
        SUM(orders.price_usd) AS total_revenue,
        SUM(orders.price_usd)/COUNT(t1.website_session_id) AS revenue_per_billing_session

FROM website_pageviews AS t1
		LEFT JOIN orders
			ON orders.website_session_id = t1.website_session_id
WHERE t1.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND pageview_url LIKE ('%billing%')
GROUP BY 1;










-- 6. Comparing which billing page is performing better.

CREATE TEMPORARY TABLE pageviews
SELECT 
	website_session_id,
        MAX(billing) AS billing,
        MAX(billing_2) AS billing_2,
        MAX(orders) AS orders
FROM
		(SELECT
		website_sessions.website_session_id,
        pageview_url,
        CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
        CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_2,
        CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS orders
FROM website_sessions
		LEFT JOIN website_pageviews
			On website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND pageview_url IN ('/billing','/billing-2','/thank-you-for-your-order')) AS page_visited
GROUP BY 1;

SELECT 
		CASE 
        WHEN billing = 1 THEN 'billing'
        WHEN billing_2 = 1 THEN 'billing_2'
        ELSE 'check_logic'
        END AS segment,
        COUNT(website_session_id) AS total_session,
        SUM(orders) AS total_order,
        SUM(orders) / COUNT(website_session_id) * 100 AS conversion_rate
FROM pageviews
GROUP BY segment;

                
                






                
-- 7. Analyzing the monthly session-to-product conversion, visitor progression to subsequent pages, 
-- and the number of orders, along with calculating the product-to-order conversion rate.

WITH cte AS (
		 SELECT
				DATE(created_at) AS created_at,
				website_session_id,
				website_pageviews.website_pageview_id AS session_to_product_id
		FROM website_pageviews
		WHERE pageview_url = '/products')
SELECT 
		 YEAR(cte.created_at) AS yr,
         MONTH(cte.created_at) AS mth,
		 COUNT(DISTINCT session_to_product_id) AS session_to_products,
         COUNT(DISTINCT website_pageviews.website_session_id) AS clicked_to_next_page,
         COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT session_to_product_id) AS product_clickthrough_rate,
         COUNT(DISTINCT orders.order_id) AS orders,
         COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT cte.website_session_id) AS products_to_order_rt
FROM cte
		LEFT JOIN website_pageviews
			ON website_pageviews.website_session_id = cte.website_session_id
            AND website_pageviews.website_pageview_id > cte.session_to_product_id
		LEFT JOIN orders
			ON orders.website_session_id = cte.website_session_id
GROUP BY 1,2;










-- 8. Analyzing the trends for each landing page.


WITH cte AS (
		SELECT
			website_session_id,
			MIN(website_pageview_id) AS website_pageview_id
		FROM website_pageviews
		GROUP BY 1
		ORDER BY 1,2)
SELECT 
		website_pageviews.pageview_url AS landing_page,
		COUNT(DISTINCT cte.website_session_id) AS sessions
FROM cte
		LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = cte.website_pageview_id
GROUP BY landing_page
ORDER BY 2 DESC;










-- 9. Developing a monthly funnel analysis from the homepage to the thank you page, 
-- and determining the clickthrough rates for each page.

WITH cte4 AS (
		WITH cte3 AS (
				WITH cte2 AS (
						WITH cte AS (
								SELECT
										DATE(created_at) AS created_at,
										website_session_id,
										MIN(website_pageview_id) AS first_pageview_id,
										pageview_url
								FROM website_pageviews
								WHERE pageview_url IN ('/home', '/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5')
								GROUP BY 1,2,4)
						SELECT 
								cte.created_at,
								cte.website_session_id,
								first_pageview_id,
								website_pageviews.website_pageview_id,
								website_pageviews.pageview_url
						FROM cte
								LEFT JOIN website_pageviews
								ON website_pageviews.website_session_id = cte.website_session_id)
				SELECT 
						created_at,
						website_session_id,
						CASE WHEN pageview_url IN ('/home', '/lander-1', '/lander-2','/lander-3','/lander-4','/lander-5')  THEN 1 ELSE 0 END AS 'homepage',
						CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS 'products',
						CASE WHEN pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear',
						'/the-birthday-sugar-panda', '/the-hudson-river-mini-bear') THEN 1 ELSE 0 END as 'item',
						CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END as 'cart',
						CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END as 'shipping',
						CASE WHEN pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END as 'billing',
						CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as 'thankyou'
				FROM cte2)
		SELECT 
				created_at,
				website_session_id,
				MAX(homepage) AS homepage,
				MAX(products) AS products,
				MAX(item) AS item,
				MAX(cart) AS cart,
				MAX(shipping) AS shipping,
				MAX(billing) AS billing,
				MAX(thankyou) AS thankyou
		FROM cte3
		GROUP BY 1,2)
SELECT 
		YEAR(created_at) AS yr,
        MONTH(created_at) AS mth,
        SUM(homepage) AS homepage,
        SUM(products) AS products,
        SUM(item) AS item,
        SUM(cart) AS cart,
        SUM(shipping) AS shipping,
        SUM(billing) AS billing,
        SUM(thankyou) AS thankyou,
        SUM(products)/SUM(homepage) homepage_clickthrough_rate,
        SUM(item)/SUM(products) AS products_clickthrough_rate,
        SUM(cart)/SUM(item) AS item_clickthrough_rate,
        SUM(shipping)/SUM(cart) AS cart_clickthrough_rate,
        SUM(billing)/SUM(shipping) AS shipping_clickthrough_rate,
        SUM(thankyou)/SUM(billing) AS billing_clickthrough_rate
FROM cte4
GROUP BY 1,2;
        
