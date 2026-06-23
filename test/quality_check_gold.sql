-- Duplicate customer IDs in Gold dimension
SELECT customer_key, COUNT(*) AS duplicate_count
FROM Gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Invalid gender values
SELECT DISTINCT gender
FROM Gold.dim_customers
WHERE gender NOT IN ('Male','Female','N/A');

-- Out-of-range birthdays
SELECT customer_key, birthday
FROM Gold.dim_customers
WHERE birthday < '1924-01-01' OR birthday > GETDATE();

-- 1. Duplicate product_numbers
SELECT product_key, COUNT(*) AS duplicate_count
FROM Gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- 2. Products with missing category references
SELECT product_key, category_id
FROM Gold.dim_products
WHERE category IS NULL;

-- 3. Products with invalid (negative) costs
SELECT product_key, product_cost
FROM Gold.dim_products
WHERE product_cost < 0;

-- Orphaned customer references (fact pointing to non-existent customer)
SELECT order_number, customer_key
FROM Gold.fact_sales
WHERE customer_key NOT IN (SELECT customer_key FROM Gold.dim_customers);

-- Orphaned product references (fact pointing to non-existent product)
SELECT order_number, product_key
FROM Gold.fact_sales
WHERE product_key NOT IN (SELECT product_key FROM Gold.dim_products);

-- Invalid sales calculation (sales_amount ≠ quantity * unit_price)
SELECT order_number, sales_amount, quantity, unit_price
FROM Gold.fact_sales
WHERE sales_amount != quantity * ABS(unit_price);
