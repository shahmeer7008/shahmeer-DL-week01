explain analyze
select count(o.order_id) as orders,sum(oi.price) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
on oi.order_id=o.order_id
join olist_products_dataset p
on p.product_id=oi.product_id
where o.order_status='delivered'
group by(p.product_category_name,DATE_TRUNC('month', o.order_purchase_timestamp))

-- where filtering should always be before grouping as I did 
-- One change can be to use CTE for order_items to precalculate results
-- with item_revenue AS (
-- select order_id,product_id,SUM(price) as revenue
-- from olist_order_items_dataset
-- group by order_id, product_id
-- )
