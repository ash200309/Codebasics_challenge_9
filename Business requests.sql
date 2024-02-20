use retail_events_db;

-- Q1) List of products with base price greater than 500 and Promo_type is "BOGOF".
SELECT DISTINCT product_name,base_price,promo_type
FROM fact_events
JOIN dim_products ON fact_events.product_code=dim_products.product_code
WHERE base_price>500 AND promo_type="BOGOF";

-- Q2) No. of stores in each city in descending order.
SELECT city, COUNT(DISTINCT(store_id)) AS number_of_stores
FROM dim_stores
JOIN fact_events USING (store_id)
GROUP BY city
ORDER BY number_of_stores DESC;

-- Correcting quanitity_sold(after_promo) for BOGOF type

ALTER TABLE fact_events
ADD COLUMN `quantity_sold(after_promo_updated)` INT;

UPDATE fact_events
SET `quantity_sold(after_promo_updated)` = 
	CASE
	    WHEN promo_type = 'BOGOF' THEN `quantity_sold(after_promo)` * 2
	    ELSE `quantity_sold(after_promo)`
	END
WHERE event_id IS NOT NULL; 

-- Adding columns  revenue before promo and after promo

-- before
ALTER TABLE fact_events
ADD COLUMN `revenue(before_promo)` float;

UPDATE fact_events
SET `revenue(before_promo)` = `base_price`*`quantity_sold(before_promo)`
WHERE event_id IS NOT NULL; 

-- after
ALTER TABLE fact_events
ADD COLUMN `revenue(after_promo)` float;

UPDATE fact_events
SET `revenue(after_promo)` = 
	CASE 
		WHEN promo_type='BOGOF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.5
		WHEN promo_type='50% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.5
		WHEN promo_type='25% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.75
		WHEN promo_type='33% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.67
		ELSE ((`base_price`*`quantity_sold(after_promo_updated)`) - 500)
	END
WHERE event_id IS NOT NULL; 

-- Q3) Calcualte the total revenue before and after promotion by campaign name
SELECT campaign_name,
       ROUND(SUM(`revenue(before_promo)`)/1000000,2) as Revenue_before_promo_in_Millions,
       ROUND(SUM(`revenue(after_promo)`)/1000000,2) as Revenue_after_promo_in_Millions,
       ROUND(SUM(`revenue(after_promo)`-`revenue(before_promo)`)/1000000,2) as Incremental_Revenue_in_Millions
FROM fact_events
JOIN dim_campaigns USING (campaign_id)
GROUP BY campaign_name;

-- Q4) Incremental Sold Units % for each category during Diwali Campaign along with Ranking
WITH top_category AS (
    SELECT 
        category,
        100 * (SUM(`quantity_sold(after_promo_updated)` - `quantity_sold(before_promo)`)) / SUM(`quantity_sold(before_promo)`) AS incremental_units_sold_percentage
    FROM fact_events
    JOIN dim_products USING (product_code)
    WHERE campaign_id="CAMP_DIW_01"
    GROUP BY category
)
SELECT 
    category,
    incremental_units_sold_percentage,
    RANK() OVER (ORDER BY incremental_units_sold_percentage DESC) AS ranking
FROM top_category;

-- Q5) Top 5 products ranked by Incremental Revenue %
SELECT product_name,
	100*(sum(`revenue(after_promo)`-`revenue(before_promo)`)/SUM(`revenue(before_promo)`)) AS incremental_revenue_percentage
FROM fact_events
JOIN dim_products USING (product_code)
GROUP BY product_name
ORDER BY incremental_revenue_percentage DESC
LIMIT 5;

-- END
