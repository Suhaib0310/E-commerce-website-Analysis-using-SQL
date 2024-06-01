-- 1. Determine the monthly session-to-order conversion rate for each traffic source to assess growth.

WITH cte AS (
		SELECT
				YEAR(t1.created_at) AS yr,
				QUARTER(t1.created_at) AS qtr,
				utm_source,
				utm_campaign,
				http_referer,
				t1.website_session_id,
				orders.order_id
		FROM website_sessions AS t1
				LEFT JOIN orders
					ON orders.website_session_id = t1.website_session_id)
SELECT 
	yr,
        qtr,
        COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' AND order_id IS NOT NULL THEN order_id ELSE NULL END)/
        COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)AS 'gsearch_nonbrand_CVR',
        COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' AND order_id IS NOT NULL THEN order_id ELSE NULL END)/
        COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)AS 'bsearch_nonbrand_cvr',
        COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' OR utm_source = 'socialbook' AND order_id IS NOT NULL THEN order_id ELSE NULL END)/
        COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' OR utm_source = 'socialbook' THEN website_session_id ELSE NULL END)AS 'brand_search_overall_cvr',
        COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL AND order_id IS NOT NULL THEN order_id ELSE NULL END)/
        COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END)AS 'organic_search_cvr',
        COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL AND order_id IS NOT NULL THEN order_id ELSE NULL END)/
        COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS 'direct_type_in_cvr'
FROM cte
GROUP BY 1,2;










-- 2. Analyze the monthly trends in the number of visitors, orders, and order rates, 
-- segmented by device type, for the Google Search non-brand campaign to evaluate growth.
 
SELECT 
	year_created_in,
        month_created_in,
        MAX(desktop_session) AS desktop_session,
        MAX(desktop_order)AS desktop_order,
        MAX(mobile_session) AS mobile_session,
        MAX(mobile_order) AS mobile_order,
        MAX(desktop_order)/MAX(desktop_session) AS desktop_order_rate,
        MAX(mobile_order)/MAX(mobile_session) AS mobile_order_rate
        
FROM (SELECT 
	YEAR(t1.created_at) AS year_created_in,
        MONTH(t1.created_at) AS month_created_in,
	SUM(CASE WHEN t1.device_type = 'desktop' THEN 1 ELSE 0 END) AS desktop_session,
        SUM(CASE WHEN t1.device_type = 'desktop' AND order_id IS NOT NULL THEN 1 ELSE 0 END) as desktop_order,
        SUM(CASE WHEN t1.device_type = 'mobile' THEN 1 ELSE 0 END) AS mobile_session,
        SUM(CASE WHEN t1.device_type = 'mobile' AND order_id IS NOT NULL THEN 1 ELSE 0 END) AS mobile_order
FROM website_sessions AS t1
		LEFT JOIN orders
			ON orders.website_session_id = t1.website_session_id
WHERE t1.created_at < '2012-11-27' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY device_type, 1,2) AS first_level_page
GROUP BY 1,2;










-- 3. Analyze the monthly trends in the number of visitors, orders, and order rates 
-- originating from the Google Search traffic source to demonstrate the website's growth.

SELECT 
	MIN(DATE(website_sessions.created_at)) AS month_start_date,
        COUNT(website_sessions.website_session_id) AS total_session,
        COUNT(orders.order_id) AS total_order,
        COUNT(orders.order_id)/COUNT(website_sessions.website_session_id)*100 AS order_rate
FROM website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27' 
	AND utm_source = 'gsearch' 
GROUP BY MONTH(website_sessions.created_at);










-- 4. Analyze the monthly trends for visitors and orders originating from Google Search, 
-- differentiating between brand and non-brand campaigns.
  
SELECT 
	MIN(DATE(t1.created_at)) AS month_start_date,
        SUM(CASE WHEN utm_campaign = 'nonbrand' AND t1.website_session_id IS NOT NULL THEN 1 ELSE 0 END) AS nonbrand_session,
        SUM(CASE WHEN utm_campaign = 'nonbrand' AND order_id IS NOT NULL THEN 1 ELSE 0 END) AS non_brand_order,
        SUM(CASE WHEN utm_campaign = 'brand' AND t1.website_session_id IS NOT NULL THEN 1 ELSE 0 END) AS brand_session,
        SUM(CASE WHEN utm_campaign = 'brand' AND order_id IS NOT NULL THEN 1 ELSE 0 END) AS brand_order
FROM website_sessions AS t1
		LEFT JOIN orders
			ON orders.website_session_id = t1.website_session_id
WHERE t1.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
GROUP BY MONTH(t1.created_at);










-- 5. Extract monthly trends for each traffic source to evaluate their performance.

SELECT 
	YEAR(created_at) AS year_created_in,
        MONTH(created_at) AS month_created_in,
        SUM(CASE WHEN utm_source = 'gsearch' THEN 1 ELSE 0 END) AS gsearch_session,
        SUM(CASE WHEN utm_source = 'bsearch' THEN 1 ELSE 0 END) AS bsearch_session,
        SUM(CASE WHEN utm_source IS NULL  AND http_referer IS NOT NULL THEN 1 ELSE 0 END) AS organic_session,
        SUM(CASE WHEN utm_source IS NULL  AND http_referer IS NULL THEN 1 ELSE 0 END) AS direct_session
        
FROM website_sessions
WHERE created_at < '2012-11-27'
GROUP BY 1,2;









-- 6. Comparing new vs. repeated sessions by channel.

SELECT
        CASE 
		WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
            WHEN utm_source IS NULL AND utm_campaign IS NULL AND http_referer IS NULL THEN 'direct_type_in'
            WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
            WHEN utm_campaign = 'brand' THEN 'paid_brand'
            WHEN utm_source = 'socialbook' THEN 'paid_social'
            ELSE 'check_logic'
            END AS 'channel_group',
        COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
        COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeated_sessions
FROM website_sessions
GROUP BY 1;



