use namastesql;
select * from dbo.credit_card_transcations;
-- basic Analysis
select min(transaction_date),max(transaction_date)  --2013-10-04,2015-05-26
from
credit_card_transcations;

select distinct card_type
from
credit_card_transcations;  -- Silver Signature Gold Platinum

select distinct exp_type
from
credit_card_transcations;  -- Entertainment Food Bills Fuel Travel Grocery

-- 1.top 5 cities with highest spends and their percentage contribution of total credit card spends 
with city_spends as
    (select top 5 city,sum(amount) as spends
    from credit_card_transcations
    group by city
    order by spends desc
    ),
total_spends as 
    (select sum(cast(amount as bigint)) as total_amt from credit_card_transcations
    )
select city_spends.*,cast(round(spends*1.0/total_amt*100,3) as decimal(5,2)) as percet_by_spends
from city_spends,total_spends;


-- 2.highest spend month and amount spent in that month for each card type

with cte1 as
(
    select card_type,DATEPART(YEAR,transaction_date) year,DATEPART(MONTH,transaction_date) month,
    sum(amount) as spent
    from
    credit_card_transcations
    group by card_type,DATEPART(YEAR,transaction_date),DATEPART(MONTH,transaction_date)
)
select * from
    (select *,
    rank() over (partition by card_type order by spent desc) as rnk
    from cte1) a
    where rnk=1;

-- 3.print the transaction details(all columns from the table) for each card type when it reaches
--  a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte1 as (
    select *,
    sum(amount) over(partition by card_type order by transaction_date,transaction_id) as cum_sum
from credit_card_transcations
),
cte2 as 
    (select *,rank() over (partition by card_type order by cum_sum asc) as rnk
    from cte1
    where cum_sum>=1000000
    )
select * from cte2 where rnk=1;

-- 4.find city which had lowest percentage spend for gold card type
with cte1 as 
    (
    select city,card_type,sum(amount)as total_spent,
    sum(
    case when card_type='Gold' then amount  end) as
    gold_amt
    from

    credit_card_transcations
    group by city,card_type
    )
select top 1 city,
    sum(gold_amt)*1.0/sum(total_spent)*100 as gold_perc
    from cte1
    group by city
    having sum(gold_amt) is not null
    order by gold_perc;
  
-- 5.city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as
    (
    select city,exp_type,sum(amount) as total_expense
    from credit_card_transcations
    group by city,exp_type

    ),cte2 as(
select *,
       rank() over(partition by city order by total_expense desc) as highest_expense,
       rank() over(partition by city order by total_expense ) as lowest_expense
from 
cte1
)
select city,
      max(case when lowest_expense=1 then exp_type end) as lowest_expense,
      max(case when highest_expense=1 then exp_type end) as highest_expense
from cte2
group by city;

-- 6-  find percentage contribution of spends by females for each expense type
with cte1 as 
    (select exp_type,
           sum(amount) as total_expens,
           sum(case when gender='F' then amount end) as fem_perc
    from credit_card_transcations
    group by exp_type
)
select *,
       fem_perc*1.0/total_expens*100 as contribution
from cte1
order by contribution desc;

--  7-which card and expense type combination saw highest month over month growth in Jan-2014
with cte1 as
    (select card_type,exp_type,FORMAT(transaction_date,'yyy-MM') as year_month,
      sum(amount) as total_expense
    from credit_card_transcations
    group  by card_type,exp_type,FORMAT(transaction_date,'yyy-MM')
    ),
cte2 as
    (
    select *,lag(total_expense) over(partition by card_type,exp_type order by year_month) as prev
    from cte1
    ),
cte3 as 
    (
    select *,(total_expense-prev)*1.0/prev*100 as growth
    from cte2
    )
select top 1 card_type,exp_type
from cte3 
where prev is not null and year_month='2014-01'
order by growth desc
;

-- 8.during weekends which city has highest total spend to total no of transcations ratio 

with cte1 as
    (select *,
    DATENAME(WEEKDAY,transaction_date) as week_day
    from credit_card_transcations
    )
select top 1 city,sum(amount)/count(1) as total_ratio
from cte1
where week_day='Sunday' or week_day='Saturday'
group by city
order by total_ratio desc;

-- 9- which city took least number of days to reach
-- its 500th transaction after the first transaction in that city
with cte1 as
    (
    select * ,row_number() over(partition by city  order by transaction_date) as rnk
    from credit_card_transcations
    ),
cte2 as
    (
    select * from cte1
    where rnk=1 or rnk=500
    )
select top 1 city,
   case when count(1)>1 then datediff(DAY,min(transaction_date),max(transaction_date)) end as date_dif
from cte2
group by city 
having count(1)>1
order by date_dif asc

;

select * from credit_card_transcations;


-- C:\Users\tandr\Source\Repos\credit_card_trans_project1.sql