#1. Duplicate & Integrity Checks

SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
#done

SELECT email,mobile, COUNT(*)
FROM customers
GROUP BY email,mobile
HAVING COUNT(*) > 1;
#done

SELECT asin, COUNT(*)
FROM products
GROUP BY asin
HAVING COUNT(*) > 1;
#done

#2. NULL & Missing Value Checks

select order_id,delivery_date,order_status
from orders
where order_date is null and order_status='Delivered';
#done

select order_id,delivery_date,order_status
from orders
where order_date is not null and order_status in('Cancelled','Pending');
#diff
select * from orders;

select transaction_id,bank_name,payment_method
from transactions
where bank_name is null and payment_method in ('Credit Card','debit Card');
#done

select transaction_id,bank_name,payment_method
from transactions
where upi_id is null and payment_method in ('upi');
#done

select return_id,refund_amount_inr,return_status
from returns
where refund_amount_inr=0 is null and return_status in ('Refunded');
#done

select product_id,stock_qty,is_prime
from products
where stock_qty=0 and is_prime='yes';
#done
select * from orders;

select order_id,order_total_inr,discount_inr,promo_applied
from orders
where discount_inr>0 and promo_applied is null;
#done

#3. Business Logic Inconsistencies

#Find orders where order_total_inr does not equal subtotal_inr + shipping_fee_inr + gst_inr − discount_inr

SELECT 
    order_id,
    order_total_inr,
    (subtotal_inr + shipping_fee_inr + gst_inr - discount_inr) AS expected_total
FROM orders
WHERE order_total_inr = (subtotal_inr + shipping_fee_inr + gst_inr - discount_inr);
#done

#Find orders where shipping_fee_inr > 0 but customer is Prime member

select o.order_id,o.customer_id,c.full_name,c.prime_member
from orders o join customers c 
on o.customer_id=c.customer_id
where o.shipping_fee_inr>0 and c.prime_member='prime';

#Find orders where gst_inr does not match expected subtotal_inr × gst_percent from products

select
    o.order_id,
    o.product_id,
    o.subtotal_inr,
    o.gst_inr as actual_gst,
    ROUND(o.subtotal_inr * p.gst_percent / 100, 2) as expected_gst
from orders o
join products p 
    on o.product_id = p.product_id
where  o.gst_inr != ROUND(o.subtotal_inr * p.gst_percent / 100, 2);
#done

#Find reviews where review_date is earlier than order_date

select o.order_id,o.order_date,r.review_id,r.review_date
from orders o join reviews r 
on o.order_id=r.order_id
where o.order_date > r.review_date;
#done

#Find returns where return_request_date is earlier than order_date

select o.order_id,o.order_date,r.return_id,r.return_request_date
from orders o join `returns` r 
on o.order_id=r.order_id
where o.order_date > r.return_request_date;
#done

#Find transactions where transaction_date is earlier than order_date
select o.order_id,o.order_date,t.transaction_id,t.transaction_date
from orders o join transactions t
on o.order_id=t.order_id
where o.order_date > t.transaction_date;
#done

#Find returns where days_to_return exceeds the product's return_window_days

SELECT 
    r.return_id,
    r.order_id,
    r.days_to_return,
    p.product_id,
    p.return_window_days
FROM returns r
JOIN products p
    ON r.product_id = p.product_id
WHERE r.days_to_return > p.return_window_days;
#diff

#Find orders where ship_date is earlier than order_date

select order_id,order_date,ship_date
from orders 
where order_date > ship_date;
#done

select * from orders;

#Find orders where delivery_date is earlier than ship_date

select order_id,order_date,ship_date,delivery_date
from orders 
where ship_date > delivery_date;
#done
select * from orders;

#4. Price & Financial Anomalies

#Find products where selling_price > mrp_inr
select product_name,mrp_inr,selling_price
from products
where mrp_inr < selling_price;
#done


#Find products where cost_price > selling_price

select product_name,cost_price,selling_price
from products
where cost_price > selling_price;
#diff

#Find products where discount_pct = 0 but selling_price < mrp_inr

select product_name,discount_pct,selling_price,mrp_inr
from products
where discount_pct=0 and selling_price < mrp_inr;
#diff

#Find orders where discount_inr > subtotal_inr

select order_id,subtotal_inr,discount_inr
from orders
where discount_inr > subtotal_inr;
#done

#Find returns where refund_amount_inr > order_total_inr

select o.order_id,o.order_total_inr,r.refund_amount_inr
from orders o join `returns` r 
on o.order_id=r.order_id
where refund_amount_inr > order_total_inr;
#done

#Find transactions where amount_inr does not match the linked order's order_total_inr

select o.order_id,t.transaction_id,o.order_total_inr,t.amount_inr
from orders o join transactions t
on o.order_id=t.order_id
where o.order_total_inr!=t.amount_inr;
#done

#Find orders with order_status = 'Returned' but no matching row in the returns table

select  o.order_id,r.return_id,o.order_status
from orders o left join `returns` r
on o.order_id=r.order_id
where o.order_status='Returned' and r.order_id is null;
#diff

#Find returns with return_status = 'Refunded' but linked transaction transaction_status ≠ 'Refunded'


select o.order_id,o.order_status,t.transaction_status
from orders o left join transactions t 
on o.order_id=t.order_id
where o.order_status='Refunded' and transaction_status!='Refunded';
#done

#Find transactions with is_refund = 'Yes' but no linked_return_id

select transaction_id,is_refund,linked_return_id
from  transactions
where is_refund='yes' and linked_return_id is null;
#diff

#Find reviews where verified_purchase = 'Yes' but the linked order status is 'Cancelled'

select r.review_id,o.order_id,r.verified_purchase,o.order_status
from orders o join reviews r 
on o.order_id=r.order_id
where r.verified_purchase='yes' and o.order_status='Cancelled';
#done

#Find sellers with account_health = 'Critical' but seller_rating > 4.5

select seller_id,account_health,seller_rating
from sellers
where account_health='Critical' and seller_rating>4.5;
#one

#6. Outlier & Range Validation

#Find customers where lifetime_spend_inr is extremely low (< 100) or suspiciously high

select customer_id,full_name,lifetime_spend_inr
from customers
where lifetime_spend_inr<100;
#done

#Find customers where total_orders = 0 but lifetime_spend_inr > 0

select customer_id,full_name,total_orders,lifetime_spend_inr
from customers
where total_orders=0 and lifetime_spend_inr>0;
#done

#Find sellers where return_rate_pct + defect_rate_pct > 15 but account_health = 'Healthy'

select  seller_id,seller_name,(return_rate_pct+defect_rate_pct) as total_rate_pct,account_health
from sellers
where (return_rate_pct+defect_rate_pct)>15 and account_health='Healthy';
#diff

#Find orders where quantity is unusually high (> 10)

select order_id,quantity
from orders
where quantity>10;
#done

#Find products where weight_kg is 0 or unrealistically high for the category

SELECT product_id,
       product_name,
       category,
       weight_kg
FROM products
WHERE weight_kg = 0
   OR weight_kg > 100;  -- generic high threshold
#done

#Find reviews where helpful_votes > total_votes

select review_id,helpful_votes,total_votes
from reviews
where helpful_votes>total_votes;
#done

#Find sellers where total_listings = 0 but total_sales_inr > 0

select seller_id,seller_name,total_listings,total_sales_inr
from sellers
where total_listings=0 and total_sales_inr>0;
#done

#7. Formatting & Standardisation

#Standardise gender values — check for anything outside 'M' / 'F'

select customer_id,full_name,gender
from customers
where gender not in ('m','f');
#done 

#Validate all mobile numbers follow the +91 XXXXXXXXXX format with exactly 10 digits

SELECT customer_id,
       full_name,
       mobile
FROM customers
WHERE mobile NOT REGEXP '^\\+91[0-9]{10}$';
#done

#Validate all pincode values are exactly 6 digits

select customer_id,full_name,pincode
from customers
where pincode not between 100000 and 999999;
#done

#Validate all email fields contain '@' and a valid domain

select customer_id,full_name,email
from customers
where  email not like '%@%';
#done

#Check account_created dates are not in the future relative to order_date

select c.customer_id,c.full_name,c.account_created,o.order_id,o.order_date
from orders o join customers c 
on c.customer_id=o.customer_id
where c.account_created>o.order_date;
#deff

#Check joined_date of sellers is not after any of their associated product launch_date

select s.seller_id,s.seller_name,s.joined_date,p.product_id,p.product_name,p.launch_date
from sellers s join products p
on s.seller_id=p.seller_id
where s.joined_date>p.launch_date;
#diff