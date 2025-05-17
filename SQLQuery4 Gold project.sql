/* SQL DATA ANALYTICS PROJECT BY KEENAN PETERSON */ 

--Query 1 (TREND ANALYSIS) ANALYSE CHANGE OVER TIME
select 
Datetrunc(month, order_date) as order_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantity 
from [portfolioproject].[dbo].[gold.fact_sales]
where order_date is not null
group by Datetrunc(month, order_date)
order by Datetrunc(month, order_date)

Select
Year(order_date) as order_year,
Month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantity 
from [portfolioproject].[dbo].[gold.fact_sales]
where order_date is not null
group by Year(order_date), Month(order_date)
order by Year(order_date), Month(order_date)

Select 
Format(order_date, 'yyyy-MMM') as order_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers, 
sum(quantity) as total_quantity 
from [portfolioproject].[dbo].[gold.fact_sales]
where order_date is not null
group by Format(order_date, 'yyyy-MMM')
order by Format(order_date, 'yyyy-MMM')

--HOW MANY NEW CUSTOMERS WERE ADDED EACH YEAR
Select 
datetrunc(year, create_date) as create_year,
Count(customer_key) as total_customer
from [portfolioproject].[dbo].[gold.dim_customers]
Group by datetrunc(year, create_date)
order by datetrunc(year, create_date)

-- Query 2(CUMULATIVE ANALYSIS) UNDERSTAND WHETHER THE FIRM IS GROWING OR DECLINING OVERTIME 
-- Calculate the total sales per month and the running total of sales over time 

Select 
order_date,
total_sales,
Sum(total_sales) over (partition by order_date order by order_date) as running_total_sales
from 
(
Select 
Datetrunc(month, order_date) as order_date,
Sum(sales_amount) as total_sales
from [portfolioproject].[dbo].[gold.fact_sales]
where order_date is not null
group by Datetrunc(month, order_date)
) t 

-- Calculate the moving average price yearly
Select 
order_date,
total_sales,
Sum(total_sales) over (order by order_date) as running_total_sales,
AVG(avg_price) over (order by order_date) as moving_average_price
from 
(
Select 
Datetrunc(year, order_date) as order_date,
Sum(sales_amount) as total_sales,
Avg(price) as avg_price
from [portfolioproject].[dbo].[gold.fact_sales]
where order_date is not null
group by Datetrunc(year, order_date)
) t 

-- Query 3 (PERFORMANCE ANALYSIS) COMPARE THE CURRENT VALUE TO A THE TARGET VALUE
-- Analyse the yearly performance of products by comparing each product's sale to both it's avg_sales_performance and the previous year's sale
WITH yearly_product_sales AS(
Select
Year(f.order_date) as order_year,
p.product_name,
Sum(f.sales_amount) as current_sales
from [portfolioProject].[dbo].[gold.fact_sales]f
Left join [PortfolioProject].[dbo].[gold.dim_products]p
on f.product_key = p.product_key
where f.order_date is not null
group by Year(f.order_date), p.product_name
)

Select order_year, product_name, current_sales,
Avg(current_sales) over (partition by product_name) avg_sales,
current_sales - Avg(current_sales) over (partition by product_name) as diff_avg,
CASE WHEN current_sales - Avg(current_sales) over (partition by product_name) > 0 then 'above Avg'
     WHEN current_sales - Avg(current_sales) over (partition by product_name) < 0 then 'below Avg'
	 Else 'Avg'
	 End avg_change,
Lag(current_sales) over (partition by product_name order by order_year) py_sales,
current_sales - Lag(current_sales) over (partition by product_name order by order_year) as diff_py,
CASE WHEN current_sales - Lag(current_sales) over (partition by product_name order by order_year) > 0 then 'Increase'
     WHEN current_sales - Lag(current_sales) over (partition by product_name order by order_year) < 0 then 'decrease'
	 Else 'No change'
	 End avg_change
from yearly_product_sales
order by product_name, order_year

--Query 4 (PART-TO-WHOLE ANALYSIS) ANALYSE HOW AN INDIVIDUAL PART IS PERFORMING COMPARED TO THE OVERALL
-- WHICH CATEGORIES CONTRIBUTE THE MOST TO OVERALL SALES
WITH category_sales as (
Select
category,
sum(sales_amount) total_sales
from [portfolioProject].[dbo].[gold.fact_sales]f
Left join [PortfolioProject].[dbo].[gold.dim_products]p
on p.product_key = f.product_key
group by category )

Select 
category,
total_sales,
SUM(total_sales) over () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) over ()) *100,2),'%') as percentage_of_total
from category_sales 
Order by total_sales desc 

-- Query 5 (DATA SEGMENTATION) GROUP THE DATA BASED ON SPECIFIC RANGE 
-- SEGMENT PRODUCTS INTO COST RANGES AND COUNT HOW MANY PRODUCTS FALL INTO EACH SEGMENT 
WITH product_segment AS(
Select 
product_key,
product_name,
cost,
CASE WHEN cost < 100 then 'below 100'
     WHEN cost between 100 and 500 then '100-500'
	 WHEN cost between 500 and 1000 then '500-1000'
	 Else 'above 1000'
	 End cost_range 
from [PortfolioProject].[dbo].[gold.dim_products])

Select cost_range,
count(product_key) as total_products
from product_segment
group by cost_range
order by total_products desc 

/* GROUP CUSTOMERS INTO THREE SEGMENTS BASED ON THEIR SPENDING BEHAVIOR
-- VIP: AT LEAST 12 MONTHS OF HISTORY AND SPENDING MORE THAN 5000
-- REGULAR: AT LEAST 12 MONTHS OF HISTORY BUT SPENDING 5000 OR LESS
-- NEW: LIFESPAN LESS THAN 12 MONTHS 
AND FIND THE TOTAL NUMBER OF CUSTOMERS BY EACH GROUP 
*/ 

WITH Customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) as total_spending, 
MIN(order_date) as first_order,
MAX(order_date) as last_order,
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
from [portfolioProject].[dbo].[gold.fact_sales]f
Left join [PortfolioProject].[dbo].[gold.dim_customers]c
on f.customer_key = c.customer_key
Group by c.customer_key
)
SELECT
Customer_segment,
Count(customer_key) as total_customers
From(
Select 
customer_key,
total_spending,
lifespan,
CASE WHEN Lifespan >= 12 and total_spending >5000 then 'VIP'
     WHEN Lifespan >= 12 and total_spending <=5000 then 'Regualar'
	 Else 'New'
	 End customer_segment
from Customer_spending) t 
Group by customer_segment
order by total_customers desc 

/* Build customer report 
-----------------------------------------------------------------------------------
Customer report
-----------------------------------------------------------------------------------
Purpose:
       - This report consolidates key customer metrics and behaviours

Highlights:
	   1. Gathers essential fields such as names, ages, and transaction details
	   2. Segments customer into categories (VIP, Regular, New) and age groups
	   3. Aggregates customer-level metrics:
	   - Total orders
	   - Total sales
	   - Total quantity purchased
	   - Total products
	   - Lifespan
	   4. Calculates valubale KPIs:
	   - recency (months since last order)
	   - avergae order vale
	   - average monthly spend
-------------------------------------------------------------------------------------
*/ 

--1 Base Query: Retrivies core columns from table
CREATE VIEW report AS
WITH base_query AS (
Select 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ' , c.last_name) as customer_name,
c.birthdate,
DATEDIFF(year, c.birthdate, GETDATE()) Age
from [portfolioProject].[dbo].[gold.fact_sales]f
Left join [PortfolioProject].[dbo].[gold.dim_customers]c
on f.customer_key = c.customer_key
where order_date is not null 
)
--Query 2 Customer Aggregations: Summarise key metrics at the customer level
, customer_aggregation AS(
SELECT
customer_key,
customer_number,
customer_name,
Age,
Count(DISTINCT order_number) as Total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) as Total_quantity,
Max(order_date) as last_order_date, 
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
FROM base_query 
Group by 
customer_key,
customer_number,
customer_name,
Age
)
Select
customer_key,
customer_number,
customer_name,
Age,
CASE WHEN age <20 Then 'Under 20'
WHEN age between 20 and 29 then '20-29' 
WHEN age between 30 and 39 then '30-39'
WHEN age between 40 and 49 then '40-49'
ELSE '50 and above'
END AS age_group,
CASE WHEN Lifespan >= 12 and total_sales >5000 then 'VIP'
     WHEN Lifespan >= 12 and total_sales <=5000 then 'Regualar'
	 Else 'New'
	 End as customer_segment,
	 last_order_date,
	 DATEDIFF(month, last_order_date, GETDATE()) as recency, 
total_orders,
total_sales,
total_quantity, 
lifespan,
--Compuate avg order value (AVO)
CASE WHEN total_sales = 0 THEN 0
ELSE Total_sales / Total_orders
END AS avg_order_value,
--Compuate avg monthly spend
CASE WHEN lifespan = 0 THEN total_sales
ELSE total_sales/lifespan
END AS avg_monthly_spend
From customer_aggregation

select *
from report 