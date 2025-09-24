/* Запрос находит десятку лучших продавцов по выручке*/
SELECT
	CONCAT(e.first_name || ' '|| e.last_name) as seller,
	COUNT(s.sales_id) as operations,
	FLOOR(SUM(p.price * s.quantity)) as income
FROM sales s
INNER JOIN employees e
	ON e.employee_id = s.sales_person_id
INNER JOIN products p
	ON p.product_id = s.product_id
GROUP BY CONCAT(e.first_name ||' '|| e.last_name)
ORDER BY income DESC
LIMIT 10;


/*Запрос находит продавцов, чья средняя выручка за сделку меньше средней выручки по всем продавцам*/
WITH tab AS (
	SELECT
		CONCAT(e.first_name ||' ' || e.last_name) as seller,
		FLOOR(AVG(p.price * s.quantity)) as average_income
	FROM sales AS s
	INNER JOIN products as p
		ON p.product_id = s.product_id
	INNER JOIN employees as e
		ON e.employee_id = s.sales_person_id
	GROUP BY CONCAT(e.first_name ||' '|| e.last_name)
	),
	
	tab2 AS (
	SELECT
		seller,
		average_income,
		FLOOR(average_income) - FLOOR(AVG(average_income) OVER ()) AS diff
	FROM tab)

SELECT 
	seller,
	average_income
FROM tab2
WHERE diff < 0
ORDER BY 2;


/*Запрос находит информацию о выручке по дням недели в разрезе продавцов*/
SELECT
	CONCAT(e.first_name ||' '|| e.last_name) as seller,
	TO_CHAR(sale_date, 'day') as day_of_week,
	FLOOR(SUM(p.price * s.quantity)) as income
FROM sales s
INNER JOIN employees e
	ON e.employee_id = s.sales_person_id
INNER JOIN products p
	ON p.product_id = s.product_id d
GROUP BY EXTRACT(isodow from sale_date), TO_CHAR(sale_date, 'day'), CONCAT(e.first_name ||' '|| e.last_name)
ORDER BY EXTRACT(isodow from sale_date), seller;


/*Запрос находит количество покупателей по трем возрастным категориям*/
WITH tab AS (
	SELECT
		age, 
		CASE
		WHEN age BETWEEN 16 AND 25 THEN '16-25'
		WHEN age BETWEEN 26 AND 40 THEN '26-40'
		WHEN age > 40 THEN '40+'
		END AS age_category
	FROM customers
	)

SELECT
	age_category,
	COUNT(*) as age_count
FROM tab
GROUP BY age_category
ORDER BY age_category;


/*Запрос показывает данные по количеству уникальных покупателей и выручке в разрезе месяца*/
SELECT
	SUBSTR(DATE_TRUNC ('month', sale_date)::text, 1, 7) as selling_month,
	COUNT(DISTINCT c.customer_id) as total_customers,
	FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN customers c
	ON c.customer_id = s.customer_id
INNER JOIN products p
	ON p.product_id = s.product_id
GROUP BY DATE_TRUNC ('month', sale_date)
ORDER BY DATE_TRUNC ('month', sale_date);


/*Запрос находит покупателей, совершивших первую покупку в ходе проведения акции (когда сумма товара была равна 0)*/
WITH tab AS (
	SELECT
		s.sales_id,
		c.customer_id,
		CONCAT(c.first_name ||' '|| c.last_name) as customer,
		s.sale_date,
		CONCAT(e.first_name ||' '|| e.last_name) as seller,
		s.quantity, 
		p.price
	FROM sales s
	INNER JOIN customers c
		ON c.customer_id = s.customer_id
	INNER JOIN employees e
		ON e.employee_id = s.sales_person_id 
	INNER JOIN products p
		ON p.product_id = s.product_id
	),
	
tab_2 as (
	SELECT 
		sales_id, 
		customer_id,
		customer, 
		sale_date, 
		seller, price,
		MIN(sale_date) OVER (PARTITION BY customer_id) as first_purchase
	FROM tab
	WHERE price = 0
	ORDER BY sale_date, sales_id)

SELECT 
	customer,
	MIN(sale_date) as sale_date,
	seller
FROM tab_2
WHERE sale_date = first_purchase
GROUP BY customer, seller
ORDER BY customer;
