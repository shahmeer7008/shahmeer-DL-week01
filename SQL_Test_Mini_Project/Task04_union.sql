explain analyze 
SELECT p.payment_type,count(p.order_id)
from olist_order_payments_dataset p
join olist_orders_dataset o
on o.order_id=p.order_id
where payment_type='credit_card'
and extract(year from (o.order_purchase_timestamp)) = '2018'
group by(p.payment_type)

union

SELECT p.payment_type,count(p.order_id)
from olist_order_payments_dataset p
join olist_orders_dataset o
on o.order_id=p.order_id
where payment_type='boleto'
and extract (year from (o.order_purchase_timestamp)) = '2018'
group by(p.payment_type)


-- Union all appends the results of two or more queries and Keeps duplicate rows
-- but union does not allow duplicate rows
-- filter outside union is useless because Union combines results of both tables 
-- and then applies filter
--Union is useful when we need unique records
--Union all can be useful in cases where duplication is not a problem
--like in data pipelines duplicate rows generated in later stage