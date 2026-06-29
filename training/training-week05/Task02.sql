EXPLAIN ANALYZE

WITH Avg_payments as (

	SELECT payment_type,AVG(payment_value) as Average
	from olist_order_payments_dataset
	group by(payment_type)
)
,filtered_payments as(select p.order_id,p.payment_value,p.payment_type,a.Average 
from olist_order_payments_dataset p, Avg_payments a
where p.payment_type=a.payment_type
and p.payment_value<a.Average)

SELECT orders.order_id,orders.customer_id,p.payment_value,p.payment_type
from  olist_orders_dataset orders,filtered_payments p
where orders.order_id=p.order_id
