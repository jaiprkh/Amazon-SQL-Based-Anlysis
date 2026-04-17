#1 Sales & Revenue

#KPI
#total_revenue,total_orders,avg_order_value
select sum(order_total_inr) as total_revenue,count(*) as total_orders,round(avg(order_total_inr),2) as avg_order_value
from orders;
#done

#Monthly revenue trend
select date_format(order_date,'%y-%m') as month,
sum(order_total_inr) as total_revenue
from orders
group by date_format(order_date,'%y-%m')
order by month;

#Revenue by category

select p.category,sum(o.order_total_inr) as Revenue
from orders  o join products p
on	 p.product_id=o.product_id
group by p.category
order by Revenue desc;

#Top 10 best-selling products

select p.product_id,
p.product_name,
p.selling_price,
sum(quantity) as total_quantity_sold,
sum(o.order_total_inr) as total_revenue
from orders o join products p
on o.product_id=p.product_id
group by p.product_id,p.product_name,p.selling_price
order by total_revenue desc
limit 10;

#2. Customer Behaviour

#Prime vs Non-Prime spending

select prime_member,
count(*) as Total_Mamber
,sum(order_total_inr) as Total_Spending
from customers c join orders o
on c.customer_id=o.customer_id
group by c.prime_member;

#Top 10 customers by spend

select c.customer_id,c.full_name,count(*) as Total_orders,sum(o.order_total_inr) as Total_spending
from customers c join orders o
where c.customer_id=o.customer_id
group by c.customer_id,c.full_name
order by Total_spending desc
limit 10;

#Customer city-wise distribution

select city,count(*) as Total_orders,sum(o.order_total_inr) as Total_spending
from customers c join orders o
where c.customer_id=o.customer_id
group by c.customer_id,c.full_name
order by Total_spending desc
limit 10;

#Repeat vs one-time buyer

select
case
when order_count=1 then 'one-time buyers'
else 'Repeat buyers'
end as buyer_type,
count(*) as total_customers
from(
select customer_id,count(*) order_count
from orders
group by customer_id) a
group by buyer_type;

#3. Product Performance

#Average rating by category

select category,round(avg(rating),2)as avg_rating
from products
group by category;

#Profit margin by product

select product_name,selling_price,cost_price,(selling_price-cost_price) as profit_margin
from products
order by profit_margin desc;

#Out-of-stock Prime products

-- select product_name,is_prime,stock_qty
-- from products
-- where is_prime='yes' and stock_qty<=0;


#Low rated but high orders

select p.product_name,p.rating,count(*) as total_orders
from orders o join products p
on o.product_id=p.product_id
group by p.product_name,p.rating
order by p.rating asc,total_orders desc
limit 10;

#4. Returns & Refunds

#Return rate by category 

SELECT 
    p.category,
    concat(round((COUNT(DISTINCT r.order_id) * 1.0 / COUNT(DISTINCT o.order_id)*100),2),'%') AS return_rate
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id
LEFT JOIN returns r 
    ON o.order_id = r.order_id
GROUP BY p.category
ORDER BY return_rate DESC;

#Top return reasons
select return_reason,count(*) as total_used
from returns
group by return_reason
order by total_used desc;

#Total refund amount by month

select date_format(return_request_date,'%y-%m') as month,
sum(refund_amount_inr) as total_refund
from returns
group by date_format(return_request_date,'%y-%m')
order by month;

#Customers with most returns

select c.full_name,count(*) as total_returns
from customers c
join returns r
on c.customer_id=r.customer_id
group by full_name
order by total_returns desc;


#Seller Performance

#Top 10 sellers by revenue

select s.seller_name,p.product_name,sum(o.quantity) as total_sold_quantity,sum(o.order_total_inr) as total_revenue
from sellers s join products p
on s.seller_id=p.seller_id
join orders o
on p.product_id=o.product_id
group by  s.seller_name,p.product_name
order by total_revenue desc
limit 10;

#Seller health vs return rate

select seller_name,account_health,return_rate_pct
from sellers;

#FBA vs FBM vs Easy Ship
#Sellers with 0 listings active

select s.seller_id,s.seller_name,count(*) as total_listing_active
from sellers s join products p
on s.seller_id=p.seller_id
group by s.seller_id,s.seller_name
having count(*)<1;

#Payment & Orders

#Payment method distribution

select t.payment_method,sum(o.order_total_inr) as total_revenue
from transactions t join orders o
on t.order_id=o.order_id
group by t.payment_method
order by total_revenue desc;

#Order status breakdown

select order_status,count(*) total_orders
from orders
group by order_status
order by total_orders desc;

#Average delivery time
select shipping_type,round(avg(datediff(delivery_date,order_date)),2) as Average_delivery_time
from orders
group by shipping_type;

#COD orders by city

select c.city,sum(o.order_total_inr) as total_COD_revenue
from customers c join orders o 
on c.customer_id=o.customer_id
where payment_method='Cash on Delivery'
group by c.city
order by total_COD_revenue desc;
