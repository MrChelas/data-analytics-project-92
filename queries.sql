/* Запрос находит десятку лучших продавцов по выручке*/
SELECT
    CONCAT(e.first_name || ' ' || e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY CONCAT(e.first_name || ' ' || e.last_name)
ORDER BY income DESC
LIMIT 10;

/*Запрос находит продавцов, чья средняя выручка за сделку меньше
средней выручки по всем продавцам*/
WITH tab AS (
    SELECT
        CONCAT(e.first_name || ' ' || e.last_name) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income,
        FLOOR(AVG(p.price * s.quantity))
        - FLOOR(
            SUM(SUM(p.price * s.quantity)) OVER ()
            / SUM(COUNT(p.price * s.quantity)) OVER ()
        ) AS diff
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    GROUP BY CONCAT(e.first_name || ' ' || e.last_name)
)

SELECT
    seller,
    average_income
FROM tab
WHERE diff < 0
ORDER BY average_income;


/*Запрос находит информацию о выручке по дням недели в разрезе продавцов*/
SELECT
    CONCAT(e.first_name || ' ' || e.last_name) AS seller,
    RTRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    EXTRACT(ISODOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'day'),
    CONCAT(e.first_name || ' ' || e.last_name)
ORDER BY EXTRACT(ISODOW FROM s.sale_date), seller;

/*Запрос находит количество покупателей по трем возрастным категориям*/
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END
    ) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category

/*Запрос показывает данные по количеству уникальных покупателей
и выручке в разрезе месяца*/
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN customers AS c
    ON s.customer_id = c.customer_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY selling_month
ORDER BY selling_month;


/*Запрос находит покупателей, совершивших первую покупку в ходе проведения акции
(когда сумма товара была равна 0)*/
WITH tab AS (
    SELECT
        s.sales_id,
        c.customer_id,
        s.sale_date,
        p.price,
        CONCAT(c.first_name || ' ' || c.last_name) AS customer,
        CONCAT(e.first_name || ' ' || e.last_name) AS seller,
        MIN(s.sale_date) OVER (PARTITION BY c.customer_id) AS first_purchase
    FROM sales AS s
    INNER JOIN customers AS c
        ON s.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
),

tab_2 AS (
    SELECT *
    FROM tab
    WHERE price = 0
    ORDER BY sale_date, sales_id
)

SELECT
    customer,
    seller,
    MIN(sale_date) AS sale_date
FROM tab_2
WHERE sale_date = first_purchase
GROUP BY customer, seller
ORDER BY customer;
