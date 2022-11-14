--1.What is the total amount each customer spent at the restaurant?
--SOLUTION
SELECT s.customer_id,SUM(m.price) AS total_spent
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id

--2.How many days has each customer visited the restaurant?
--SOLUTION
SELECT customer_id,COUNT(DISTINCT order_date)AS no_of_visit
FROM sales
GROUP BY customer_id

--3.What was the first item from the menu purchased by each customer?
--SOLUTION

WITH ordered_table AS(
SELECT x.*,m.product_name 
FROM
(SELECT customer_id,product_id,row_number() OVER (PARTITION BY customer_id ORDER BY order_date)AS row_num
FROM sales)x
INNER JOIN menu m
ON x.product_id = m.product_id)

SELECT customer_id,product_name FROM ordered_table
WHERE row_num =1

--4.What is the most purchased item on the menu and how many times was it purchased by all customers?
--SOLUTION

SELECT m.product_name,COUNT(m.product_name)as most_freq_order
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY most_freq_order DESC
OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY

--5.Which item was the most popular for each customer?
--SOLUTION

WITH order_rnk as (
SELECT *,DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_freq DESC)AS rnk FROM( 
SELECT customer_id,product_id,COUNT(*)AS order_freq FROM sales
GROUP BY customer_id,product_id)x),

popular_prod_id as(
SELECT customer_id,product_id FROM order_rnk 
WHERE rnk  = 1)

SELECT p.customer_id,m.product_name
FROM popular_prod_id p
INNER JOIN menu m
ON p.product_id = m.product_id


--6.Which item was purchased first by the customer after they became a member?
--SOLUTION
SELECT x.customer_id,x.order_date,me.product_name
FROM menu me
INNER JOIN(
SELECT s.*,m.join_date,DATEDIFF(day,m.join_date,s.order_date)as date_diff,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY DATEDIFF(day,m.join_date,s.order_date)) AS rnk
FROM sales s
FULL OUTER JOIN members m
ON s.customer_id = m.customer_id
WHERE order_date >= join_date)x
ON x.product_id = me.product_id
WHERE x.rnk = 1

--7 Which item was purchased just before the customer became a member?
--SOLUTION
SELECT x.customer_id,x.order_date,me.product_name
FROM menu me
INNER JOIN(
SELECT s.*,m.join_date,DATEDIFF(day,s.order_date,m.join_date)as date_diff,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY DATEDIFF(day,m.join_date,s.order_date)DESC) AS rnk
FROM sales s
FULL OUTER JOIN members m
ON s.customer_id = m.customer_id
WHERE order_date < join_date)x
ON x.product_id = me.product_id
WHERE x.rnk = 1

--8.What is the total items and amount spent for each member before they became a member?
--SOLUTION
with temp as(
SELECT s.*,m.join_date
FROM sales s
FULL OUTER JOIN members m
ON s.customer_id = m.customer_id
WHERE order_date < join_date),

final_table as(
SELECT temp.customer_id,m.product_name,m.price
FROM temp
INNER JOIN menu m
ON temp.product_id = m.product_id)

SELECT customer_id,COUNT(DISTINCT product_name) AS unique_product,SUM(price) AS total_sales
FROM final_table
GROUP BY customer_id

/*9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier then 
how many points would each customer have?*/
--SOLUTION 
SELECT s.customer_id,
SUM(CASE WHEN product_name = 'sushi' THEN price * 20
	 WHEN product_name = 'curry' THEN price * 10
	 WHEN product_name = 'ramen' THEN price * 10
	 END) AS total_points
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id

/*10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi - how many points do customer A and B have at the end of January?*/
--SOLUTION
WITH date_diff_table as (
SELECT s.*,m.join_date,DATEDIFF(day,join_date,order_date) AS date_diff
FROM sales s
FULL OUTER JOIN members m
ON s.customer_id = m.customer_id
WHERE MONTH(order_date) = 1),

multiplier as(
SELECT *,CASE WHEN date_diff BETWEEN 0 AND 7 THEN 2 ELSE 1 
		 END AS multiplier
FROM date_diff_table),

points as(
SELECT m.customer_id,m.multiplier,me.product_name,me.price,(multiplier * price * 10)AS points
FROM multiplier m
INNER JOIN menu me
ON m.product_id = me.product_id)

SELECT customer_id,SUM(points)AS total_points
FROM points
GROUP BY customer_id




















