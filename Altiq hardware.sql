1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

select distinct market from dim_customer where customer="Atliq Exclusive" and region="Apac"

2.2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

with cte1 as
 ( select count(distinct product_code) as unique_product_2020 from fact_sales_monthly 
    where fiscal_year=2020 ),
 cte2 as(
 select count(distinct product_code) as unique_product_2021 from fact_sales_monthly  
 where fiscal_year=2021 )
 select cte1.unique_product_2020,cte2.unique_product_2021,
		((cte2.unique_product_2021-cte1.unique_product_2020)/cte1.unique_product_2020 *100) as 
        perc_change
 from cte1
 join cte2
 
 3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count

select segment, count(distinct product_code) as product_count from dim_product group by 1 order by 2 desc

4.. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

	with cte as(select product_code, fiscal_year as year, sum(sold_quantity) as total_quantity
				from fact_sales_monthly group by 1,2)
	select p.segment, 
		   count(case when cte.	year=2020 then p.product_code end) as unique_product_2020,
		   count(case when cte.	year=2021 then p.product_code end) as unique_product_2021,
		   count(case when cte.	year=2021 then p.product_code end)
		   -count(case when cte.	year=2020 then p.product_code end) as difference
	 from cte
	 join dim_product p on p.product_code=cte.product_code
	 group by segment
     
 5. ###Get the products that have the highest and lowest manufacturing costs.
 
(select p.product_code,p.product, max_cost.manufacturing_cost
from dim_product p
join
(select mc.product_code, max(mc.manufacturing_cost) as manufacturing_cost from fact_manufacturing_cost mc	
group by product_code) as max_cost
on p.product_code=max_cost.product_code
order by manufacturing_cost desc limit 1)
Union
(select p.product_code,p.product,min_cost.manufacturing_cost
from dim_product p
join	
(select mc.product_code,min(mc.manufacturing_cost) as manufacturing_cost from fact_manufacturing_cost mc
group by product_code) as min_cost
on p.product_code=min_cost.product_code
order by manufacturing_cost limit 1)    

6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

Select c.customer_code,c.customer,c.market,b.Average_Discount from `dim_customer` c
join
(select customer_code,round(avg(pre_invoice_discount_pct)*100,2) as Average_Discount from `fact_pre_invoice_deductions` 
where fiscal_year=2021 group by 1) as b
on c.customer_code=b.customer_code
where c.market="India"
order by Average_Discount desc limit  5

7..Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount---

SELECT 
    MONTHNAME(fsm.date) as Month,
    YEAR(fsm.date) as Year,
    ROUND(SUM(fg.gross_price*fsm.sold_quantity), 2) as 'Gross sales Amount'
FROM fact_sales_monthly fsm
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
JOIN fact_gross_price fg ON fg.product_code = fsm.product_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(fsm.date), YEAR(fsm.date)
ORDER BY YEAR(fsm.date) ASC, MONTH(fsm.date) ASC

8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

select date,
	case 
		when month(date) between "1" and "3" then "Q2"
        when month(date) between "3" and "6" then "Q3"
        when month(date) between "6" and "9" then "Q4"
        when month(date) between "9" and "12" then "Q1"
     end as "Quarter",
     sum(sold_quantity) as Total_Sold_Quantity
	from `fact_sales_monthly`
    where fiscal_year=2020
    group by quarter
    order by Total_Sold_Quantity Desc
    limit 1
    
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage


SELECT c.channel, (SUM(fsm.sold_quantity * fgp.gross_price) ) AS gross_sales_mln,
       ROUND(SUM(fsm.sold_quantity * fgp.gross_price) / (SELECT SUM(sold_quantity * gross_price) FROM fact_sales_monthly fsm2 JOIN fact_gross_price fgp2 ON fsm2.product_code = fgp2.product_code WHERE YEAR(fsm2.date) = 2021) * 100, 2) AS percentage
FROM fact_sales_monthly fsm
JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
JOIN dim_customer c ON fsm.customer_code = c.customer_code
WHERE YEAR(fsm.date) = 2021
GROUP BY c.channel
ORDER BY gross_sales_mln DESC;

10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code---

  
WITH total as
(SELECT dp.division, dp.product_code, dp.product, SUM(fsm.sold_quantity) As total_sold_quantity
FROM dim_product as dp
JOIN fact_sales_monthly AS fsm
ON dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dp.division,dp.product_code, dp.product
ORDER BY total_sold_quantity DESC),
rk as
(SELECT *, DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
FROM total)
SELECT * from rk
WHERE rank_order <= 3;
    

