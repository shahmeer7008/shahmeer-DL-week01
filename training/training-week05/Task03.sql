WITH previous as (
	select orders.order_id,orders.customer_id,customer.customer_state,CAST(orders.order_purchase_timestamp as DATE),CAST(orders.order_delivered_timestamp AS DATE)as del_date,
	Round(Extract(Epoch from (orders.order_delivered_timestamp - orders.order_purchase_timestamp)) / 86400) AS timetaken
	from olist_orders_dataset orders
	JOIN olist_order_customer_dataset customer
	on orders.customer_id=customer.customer_id
	where orders.order_delivered_timestamp is not NULL
)

SELECT *,coalesce(timetaken>LAG(timetaken)OVER(PARTITION BY(customer_state,del_date)order by(del_date)),false)as results
from previous

