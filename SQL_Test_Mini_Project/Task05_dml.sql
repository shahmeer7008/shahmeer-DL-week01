with preCalculated as (

select DATE_TRUNC('month', o.order_purchase_timestamp)as months,p.product_category_name as  product_category_name,
sum(oi.price) as total_revenue,count(o.order_id) as total_orders,
Avg(oi.freight_value) AS avg_freight
from olist_orders_dataset o
join olist_order_items_dataset oi
on oi.order_id=o.order_id
join olist_products_dataset p
on p.product_id=oi.product_id
where o.order_status='delivered'
and p.product_category_name is not null
group by(p.product_category_name,DATE_TRUNC('month', o.order_purchase_timestamp))
)

Merge into monthly_revenue as destination
using preCalculated as sources
on sources.months=destination.months
and 
sources.product_category_name=destination.product_category_name

when matched then 
update set

total_revenue = sources.total_revenue,
total_orders = sources.total_orders,
avg_freight = sources.avg_freight,
updated_at = current_timestamp
when not matched then
    insert (months, product_category_name, total_revenue, total_orders, avg_freight)
    values (sources.months, sources.product_category_name, sources.total_revenue, sources.total_orders, sources.avg_freight);
