EXPLAIN ANALYZE
SELECT o.order_id, o.customer_id, p.payment_value, p.payment_type
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE p.payment_value > (
SELECT AVG(p2.payment_value)
FROM olist_order_payments_dataset p2
WHERE p2.payment_type = p.payment_type
)