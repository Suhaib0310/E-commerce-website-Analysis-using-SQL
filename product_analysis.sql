-- 1. Finding out trends in how each product cross sell with another product by volumne and cross sell rate.

WITH cte2 AS (
		WITH cte AS (
				SELECT 		
						order_id,
						product_id AS primary_product_id,
						order_item_id AS primary_order_item_id
				FROM order_items
				WHERE is_primary_item = 1
						AND created_at > '2014-12-05')
		SELECT 
				cte.order_id,
				primary_product_id,
				primary_order_item_id,
				order_items.product_id AS secondary_product_id,
				order_items.order_item_id AS secondary_order_item_id
		FROM cte
				LEFT JOIN order_items
					ON order_items.order_id  = cte.order_id
					AND order_items.is_primary_item = 0)
SELECT 
	primary_product_id,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 1 THEN secondary_order_item_id ELSE NULL END) AS prod1,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 2 THEN secondary_order_item_id ELSE NULL END) prod2,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 3 THEN secondary_order_item_id ELSE NULL END) prod3,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 4 THEN secondary_order_item_id ELSE NULL END) prod4,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 1 THEN secondary_order_item_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_cross_sell_rt,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 2 THEN secondary_order_item_id ELSE NULL END)/COUNT(DISTINCT order_id) p2_cross_sell_rt,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 3 THEN secondary_order_item_id ELSE NULL END)/COUNT(DISTINCT order_id) p3_cross_sell_rt,
        COUNT(DISTINCT CASE WHEN secondary_product_id = 4 THEN secondary_order_item_id ELSE NULL END)/COUNT(DISTINCT order_id) p4_cross_sell_rt
FROM cte2
GROUP BY 1;










-- 2. We have introduced a feature of cross sell where customer can purchase 2 products together.
-- Comparing the  performing of webstie pre-cross sell and post-cross sell.
-- Finding out number of cart sessions, number of cart clickthrough, cart clickthrough rate, products per order,
-- average order value(aov) and revenue per cart session.

WITH cte AS (
		SELECT
				time_period,
				DATE(pageview_level.created_at),
				pageview_level.website_session_id,
				MAX(cart) AS cart,
				MAX(shipping) AS shipping,
				orders.order_id,
				orders.items_purchased,
				orders.price_usd
		FROM 
				(SELECT 
						CASE
							WHEN created_at BETWEEN '2013-08-25' AND '2013-09-25' THEN 'Pre_Cross_Sell'
							WHEN created_at BETWEEN '2013-09-25' AND '2013-10-25' THEN 'Post_Cross_Sell'
							ELSE 'Check_logic'
							END AS time_period,
						created_at,
						website_session_id,
						pageview_url,
						CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
						CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping
				FROM website_pageviews
				WHERE pageview_url IN ('/cart', '/shipping')
				AND created_at BETWEEN '2013-08-25' AND '2013-10-25') AS pageview_level
LEFT JOIN orders
		ON orders.website_session_id = pageview_level.website_session_id
	GROUP BY 1,2,3,6,7,8)
SELECT 
		time_period,
        SUM(cart) AS cart,
        SUM(shipping) AS clickthroughs,
        SUM(shipping)/SUM(cart) AS cart_clickthrough_rate,
        SUM(items_purchased)/COUNT(DISTINCT order_id) AS products_per_order,
        SUM(price_usd)/COUNT(DISTINCT order_id) AS aov,
        SUM(price_usd)/SUM(cart) AS revenue_per_cart_session
FROM cte
GROUP BY 1;










-- 3. The company has launched their 2nd product.
-- We are comparing the performance of both the products.
-- Finding out the number of product sessions, cart sessions, shipping sessions, billing sessions and their clickthrough rate by product.

WITH cte2 AS (
		WITH cte AS (
				WITH pageview_level AS (
						SELECT 
							website_session_id,
							pageview_url,
							CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
							WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
							END AS product_segment
						FROM website_pageviews
						WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
								AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear'))
				SELECT 
						product_segment,
						pageview_level.website_session_id,
						website_pageviews.pageview_url
				FROM pageview_level
					LEFT JOIN website_pageviews 
						ON website_pageviews.website_session_id = pageview_level.website_session_id
				WHERE website_pageviews.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear', '/cart', '/shipping',
						'/billing-2', '/thank-you-for-your-order', '/billing'))
		SELECT 
				product_segment,
				website_session_id,
				CASE WHEN pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear') THEN 1 ELSE 0 END AS sessions,
				CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
				CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
				CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing,
				CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
		FROM cte)
SELECT 
		product_segment,
        SUM(sessions) AS product_sessions,
        SUM(cart) AS cart_sessions,
        SUM(shipping) AS shipping_sessions,
        SUM(billing) AS billing_sessions,
        SUM(thankyou) AS thankyou_sessions
FROM cte2
GROUP BY 1;










-- 4. Comparing the clickthrough rate of each products.

WITH cte2 AS (
		WITH cte AS (
				WITH pageview_level AS (
						SELECT 
							website_session_id,
							pageview_url,
							CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
							WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
                            WHEN pageview_url = '/the-birthday-sugar-panda' THEN 'birthdaypanda'
                            WHEN pageview_url = '/the-hudson-river-mini-bear' THEN 'hudsonbear'
                            ELSE 'check_logic'
                            
							END AS product_segment
						FROM website_pageviews
						WHERE pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear',
                                '/the-birthday-sugar-panda', '/the-hudson-river-mini-bear'))
				SELECT 
						product_segment,
						pageview_level.website_session_id,
						website_pageviews.pageview_url
				FROM pageview_level
					LEFT JOIN website_pageviews 
						ON website_pageviews.website_session_id = pageview_level.website_session_id
				WHERE website_pageviews.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear',
					'/the-birthday-sugar-panda', '/the-hudson-river-mini-bear', '/cart', '/shipping',
						'/billing-2', '/thank-you-for-your-order', '/billing'))
		SELECT 
				product_segment,
				website_session_id,
				CASE WHEN pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear', 
                '/the-birthday-sugar-panda', '/the-hudson-river-mini-bear') THEN 1 ELSE 0 END AS sessions,
				CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
				CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
				CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing,
				CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
		FROM cte)
SELECT 
		product_segment,
        SUM(cart)/SUM(sessions) AS product_clickrate,
        SUM(shipping)/SUM(cart) AS cart_clickrate,
        SUM(billing)/SUM(shipping) AS shipping_clickrate,
        SUM(thankyou)/ SUM(billing) AS billing_clickrate
FROM cte2
GROUP BY 1;










-- 5. determining monthly refund rate by product.

SELECT
	YEAR(order_items.created_at) AS yr,
        MONTH(order_items.created_at) AS mth,
        COUNT(DISTINCT CASE WHEN product_id = 1 AND order_item_refund_id IS NOT NULL THEN order_item_refund_id ELSE NULL END )/
        COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END)AS prod_1_refund_rate,
        COUNT(DISTINCT CASE WHEN product_id = 2 AND order_item_refund_id IS NOT NULL THEN order_item_refund_id ELSE NULL END )/
        COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END)AS prod_2_refund_rate,
        COUNT(DISTINCT CASE WHEN product_id = 3 AND order_item_refund_id IS NOT NULL THEN order_item_refund_id ELSE NULL END )/
        COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END)AS prod_3_refund_rate,
        COUNT(DISTINCT CASE WHEN product_id = 4 AND order_item_refund_id IS NOT NULL THEN order_item_refund_id ELSE NULL END )/
        COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END)AS prod_4_refund_rate,
        COUNT(DISTINCT order_items.order_item_id) AS total_orders,
        COUNT(DISTINCT order_item_refund_id) AS total_refunds,
        COUNT(DISTINCT order_item_refund_id)/ COUNT(DISTINCT order_items.order_item_id) AS total_refund_rate
FROM order_items
		LEFT JOIN order_item_refunds
				ON order_item_refunds.order_item_id = order_items.order_item_id
GROUP BY 1,2;
