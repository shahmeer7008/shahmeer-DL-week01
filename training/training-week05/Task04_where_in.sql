explain analyze 
SELECT p.payment_type,count(p.order_id)
from olist_order_payments_dataset p
join olist_orders_dataset o
on o.order_id=p.order_id
where payment_type in('credit_card','boleto')
and extract(year from (o.order_purchase_timestamp)) = '2018'
group by(p.payment_type)

