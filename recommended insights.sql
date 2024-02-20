-- TOP 10 stores by IR
select store_id,SUM(`revenue(after_promo)`-`revenue(before_promo)`) as Incremental_Revenue
from fact_events 
join dim_stores using (store_id)
group by store_id
order by Incremental_Revenue desc
limit 10;

-- Bottom 10 stores by ISU
select store_id,SUM(`quantity_sold(after_promo_updated)`-`quantity_sold(before_promo)`) as Incremental_Sold_Units
from fact_events 
join dim_stores using (store_id)
group by store_id
order by Incremental_Sold_Units asc
limit 10;

-- Top 2 promotions by IR
select promo_type,SUM(`revenue(after_promo)`-`revenue(before_promo)`) as Incremental_Revenue
from fact_events 
group by promo_type
order by Incremental_Revenue desc
limit 2;

-- Bottom 2 promotions by ISU
select promo_type, SUM(`quantity_sold(after_promo_updated)`-`quantity_sold(before_promo)`) as Incremental_Sold_Units
from fact_events
group by promo_type
order by Incremental_Sold_Units asc
limit 2;

-- Product category by ISU
select category, SUM(`quantity_sold(after_promo_updated)`-`quantity_sold(before_promo)`) as Incremental_Sold_Units
from fact_events
join dim_products using (product_code)
group by category 
order by Incremental_Sold_Units desc;

-- Category wise ISU %
SELECT dp.category,
100 * (SUM(fe.`quantity_sold(after_promo_updated)` - fe.`quantity_sold(before_promo)`)) / SUM(fe.`quantity_sold(before_promo)`) AS incremental_units_sold_percentage
FROM fact_events AS fe
JOIN dim_products AS dp ON fe.product_code=dp.product_code
GROUP BY dp.category
order by incremental_units_sold_percentage desc; 

-- category wise IR%
SELECT dp.category,
100 * SUM(`revenue(after_promo)`-`revenue(before_promo)`) / SUM(`revenue(before_promo)`) AS incremental_revenue_percentage
FROM fact_events AS fe
JOIN dim_products AS dp ON fe.product_code=dp.product_code
GROUP BY dp.category
order by incremental_revenue_percentage desc; 

-- product-wise performance
SELECT product_name,
	100*(sum(`revenue(after_promo)`-`revenue(before_promo)`)/SUM(`revenue(before_promo)`)) AS incremental_revenue_percentage
FROM fact_events
JOIN dim_products USING (product_code)
GROUP BY product_name
ORDER BY incremental_revenue_percentage DESC;
