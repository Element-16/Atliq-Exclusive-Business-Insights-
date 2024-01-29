SELECT 
    *
FROM
    dim_customer;
SELECT 
    *
FROM
    dim_product;
SELECT 
    *
FROM
    fact_gross_price;
SELECT 
    *
FROM
    fact_manufacturing_cost;
SELECT 
    *
FROM
    fact_pre_invoice_deductions;
SELECT 
    *
FROM
    fact_sales_monthly;

SELECT 
    *
FROM
    dim_customer;
/*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/
SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

with cte as(
Select distinct(p.product_code) as code,g.fiscal_year as year from dim_product as p
join fact_gross_price as g using(product_code) ),
cte2 as(
select count(code) as total_count,year from cte 
group by year),
cte3 as(
select (select total_count from cte2 where year='2020') as 'unique_products_2020',
(select total_count from cte2 where year='2021') as 'unique_products_2021' from cte2
limit 1)
select unique_products_2020,unique_products_2021,
concat(round((((unique_products_2021-unique_products_2020)*100)/unique_products_2020),2),'%') as percentage_chg
from cte3;

/* . Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count
*/
SELECT 
    COUNT(DISTINCT product_code) product_count, segment
FROM
    dim_product
GROUP BY segment
ORDER BY 1 DESC;

/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference  */
with cte as(
Select count(distinct(p.product_code)) as total_count,p.segment as 'segment',g.fiscal_year year from dim_product as p
join fact_gross_price as g using(product_code) group by p.segment,g.fiscal_year),
cte2 as(
select total_count,segment from cte where year ='2020'),
cte3 as
(
select total_count,segment from cte where year ='2021')
select segment,a.total_count as 'product_count_2020',b.total_count as 'product_count_2021',(b.total_count-a.total_count) as 'difference' from cte2 as a join cte3 as b using(segment)
order by 4 desc limit 1;

/*
5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/
with cte as
(
select m.product_code as 'product_code' ,m.manufacturing_cost as 'manufacturing_cost',p.product as 'product' from fact_manufacturing_cost as m left join dim_product as p using(product_code))

(select product_code,product,round(manufacturing_cost,2) manufacturing_cost  from cte
order by 3 desc limit 1)
union
(select product_code,product,round(manufacturing_cost,2) manufacturing_cost from cte
order by 3 asc limit 1);

/*
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/
with cte as(
select c.customer_code customer_code ,c.customer customer,c.market,d.fiscal_year,avg(d.pre_invoice_discount_pct) average_discount_percentage from dim_customer as c join fact_pre_invoice_deductions as d using(customer_code)
where market='India' and d.fiscal_year='2021'
group by c.customer_code,c.customer
)
select customer_code,customer,average_discount_percentage from cte 
order by 3 desc
limit 5;
/*
7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
Gross Sales Amount = gross_price * sold_quantity
*/

with cte as(
select (g.gross_price*s.sold_quantity) Gross_Sales_Amount,month(date) month,year(date) year,c.customer,c.customer_code from fact_gross_price as g join fact_sales_monthly as s using(product_code) 
join dim_customer as c using(customer_code))

select month,year,round(sum(Gross_Sales_Amount),2) Gross_Sales_Amount from cte where customer='Atliq Exclusive'
group by month,year;

/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/
with cte as(
select *,month(date_add(date, interval 4 month)) fiscal_month from fact_sales_monthly),

cte2 as(
select *,
case 
when fiscal_month in(1,2,3) then 'Q1'
when fiscal_month in(4,5,6) then 'Q2'
when fiscal_month in(7,8,9) then 'Q3'
when fiscal_month in(10,11,12) then 'Q4'
end as Quarter
from cte)
select sum(sold_quantity) total_sold_quantity,quarter from cte2
where fiscal_year='2020'
group by quarter
order by 1 desc;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
gross_sales_mln = gross_price * sold_quantity

*/
with cte as (
select round(sum(g.gross_price*s.sold_quantity),2) Gross_Sales_mln,c.channel
from fact_gross_price as g join fact_sales_monthly as s using(product_code) 
join dim_customer as c using(customer_code)
where s.fiscal_year='2021'
group by channel)

select channel,gross_sales_mln,
concat(round(((gross_sales_mln*100)/(select sum(gross_sales_mln) from cte)),2),'%') percentage
from cte;

/*
10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/
with cte as(
 select p.product_code,p.product,p.division divison,sum(s.sold_quantity) total_sold_quantity
 from dim_product as p join fact_sales_monthly as s using(product_code)
 where s.fiscal_year='2021'
 group by division,product,product_code),
 cte2 as
 (
 select *,dense_rank() over(partition by divison order by total_sold_quantity) rank_order from cte)
 
 select* from cte2 where rank_order<=3;
 









