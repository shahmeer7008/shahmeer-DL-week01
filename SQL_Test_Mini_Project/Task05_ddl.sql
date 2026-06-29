Create table monthly_revenue (
    months DATE not null,product_category_name VARCHAR(255) not null,
	total_revenue NUMERIC(15, 2) not null,total_orders INT not null,
    avg_freight NUMERIC(10, 2) not null,updated_at TIMESTAMP default current_timestamp ,
    Constraint monthly_revenue_key primary key (months, product_category_name)
);

-- Create index on monthly_revenue (months, product_category_name);