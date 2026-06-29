EXPLAIN ANALYZE

WITH Avg_payments as (

	SELECT order_id,payment_value,payment_type,AVG(payment_value)
	OVER(PARTITION BY(payment_type))
	as Average
	from olist_order_payments_dataset
)

SELECT orders.order_id,orders.customer_id,p.payment_value,p.payment_type
from  olist_orders_dataset orders JOIN Avg_payments p
ON orders.order_id=p.order_id
where p.payment_value<Average
