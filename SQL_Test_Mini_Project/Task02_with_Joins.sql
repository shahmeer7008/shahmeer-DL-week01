EXPLAIN ANALYZE
WITH Avg_payments as (

	SELECT payment_type,AVG(payment_value) as Average
	from olist_order_payments_dataset
	group by(payment_type)
)
SELECT orders.order_id,orders.customer_id,p.payment_value,p.payment_type
from olist_orders_dataset orders
JOIN olist_order_payments_dataset p
ON p.order_id=orders.order_id
JOIN Avg_payments a
ON a.payment_type=p.payment_type
where 
p.payment_value < a.Average