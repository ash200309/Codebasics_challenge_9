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

-- Q3) Calcualte the total revenue before and after promotion by campaign name

SELECT dc.campaign_name,
       SUM(fe.`base_price` * fe.`quantity_sold(before_promo)`)/1000000 AS total_revenue_before_promotion,
       SUM(fe.`base_price` * fe.`quantity_sold(after_promo)`)/1000000  AS total_revenue_after_promotion,
       SUM(fe.`base_price` * fe.`quantity_sold(after_promo)`)/1000000 -SUM(fe.`base_price` * fe.`quantity_sold(before_promo)`)/1000000  AS Incremental_Revenue
FROM fact_events AS fe
JOIN dim_campaigns AS  dc ON fe.campaign_id = dc.campaign_id
GROUP BY dc.campaign_name;

-- Q4) Incremental Sold Units % for each category during Diwali Campaign along with Ranking

WITH top_category AS (
    SELECT 
        dp.category,
        100 * (SUM(fe.`quantity_sold(after_promo)` - fe.`quantity_sold(before_promo)`)) / NULLIF(SUM(fe.`quantity_sold(before_promo)`), 0) AS incremental_units_sold_percentage
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
        100*(SUM((fe.`quantity_sold(after_promo)` - fe.`quantity_sold(before_promo)`)*fe.`base_price`)/SUM((fe.`quantity_sold(before_promo)`)*fe.`base_price`)) AS incremental_revenue_percentage
	from fact_events as fe
    join dim_products as dp on fe.product_code=dp.product_code
    group by dp.product_name
)
select product_name,incremental_revenue_percentage
from top_products
order by incremental_revenue_percentage desc
LIMIT 5;

-- END