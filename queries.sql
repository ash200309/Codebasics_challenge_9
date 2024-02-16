use retail_events_db;

-- Q1) List of products with base price greater than 500 and Promo_type is "BOGOF".

SELECT DISTINCT product_name,base_price,promo_type
FROM fact_events
JOIN dim_products ON fact_events.product_code=dim_products.product_code
WHERE base_price>500 AND promo_type="BOGOF";

-- Q2) No. of stores in each city in descending order.

SELECT ds.city, COUNT(DISTINCT(ds.store_id)) AS number_of_stores
FROM dim_stores AS ds
JOIN fact_events AS fe ON ds.store_id = fe.store_id
GROUP BY ds.city
ORDER BY number_of_stores DESC;

-- Correcting quanitity_sold(after_promo) for BOGOF type

ALTER TABLE fact_events
ADD COLUMN `quantity_sold(after_promo_updated)` INT;

UPDATE fact_events
SET `quantity_sold(after_promo_updated)` = CASE
                            WHEN promo_type = 'BOGOF' THEN `quantity_sold(after_promo)` * 2
                            ELSE `quantity_sold(after_promo)`
                        END
WHERE event_id IS NOT NULL; 

-- Adding columns  revenue before promo and after promo

ALTER TABLE fact_events
ADD COLUMN `revenue(before_promo)` float;

UPDATE fact_events
SET `revenue(before_promo)` = `base_price`*`quantity_sold(before_promo)`
WHERE event_id IS NOT NULL; 

ALTER TABLE fact_events
ADD COLUMN `revenue(after_promo)` float;

UPDATE fact_events
SET `revenue(after_promo)` = CASE 
	WHEN promo_type='BOGOF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.5
	WHEN promo_type='50% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.5
	WHEN promo_type='25% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.75
	WHEN promo_type='33% OFF' THEN `base_price`*`quantity_sold(after_promo_updated)`*0.67
	ELSE ((`base_price`*`quantity_sold(after_promo_updated)`) - 500)
	END
WHERE event_id IS NOT NULL; 

-- Q3) Calcualte the total revenue before and after promotion by campaign name

SELECT dc.campaign_name,
       ROUND(SUM(fe.`revenue(before_promo)`)/1000000,2) as Revenue_before_promo_in_Millions,
       ROUND(SUM(fe.`revenue(after_promo)`)/1000000,2) as Revenue_after_promo_in_Millions,
      ROUND(SUM(fe.`revenue(after_promo)`-fe.`revenue(before_promo)`)/1000000,2) as Incremental_Revenue_in_Millions
FROM fact_events AS fe
JOIN dim_campaigns AS  dc ON fe.campaign_id = dc.campaign_id
GROUP BY dc.campaign_name;

-- Q4) Incremental Sold Units % for each category during Diwali Campaign along with Ranking

WITH top_category AS (
    SELECT 
        dp.category,
        100 * (SUM(fe.`quantity_sold(after_promo_updated)` - fe.`quantity_sold(before_promo)`)) / SUM(fe.`quantity_sold(before_promo)`) AS incremental_units_sold_percentage
    FROM fact_events AS fe
    JOIN dim_products AS dp ON fe.product_code=dp.product_code
    WHERE fe.campaign_id="CAMP_DIW_01"
    GROUP BY dp.category
)
SELECT 
	category,
    incremental_units_sold_percentage,
    RANK() OVER (ORDER BY incremental_units_sold_percentage DESC) AS ranking
FROM top_category;

-- Q5) Top 5 products ranked by Incremental Revenue %

with top_products as (
	select 
		dp.product_name,
		100*(sum(fe.`revenue(after_promo)`-fe.`revenue(before_promo)`)/SUM(fe.`revenue(before_promo)`)) AS incremental_revenue_percentage
	from fact_events as fe
    join dim_products as dp on fe.product_code=dp.product_code
    group by dp.product_name
)
select product_name,incremental_revenue_percentage
from top_products
order by incremental_revenue_percentage desc
LIMIT 5;

-- END
