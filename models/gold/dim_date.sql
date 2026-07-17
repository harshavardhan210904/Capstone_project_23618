{{ config(materialized='table') }}

with date_spine as (

    select
        dateadd(day, seq4(), '2024-04-01'::date) as full_date
    from table(generator(rowcount => 180))

)

select

    to_number(to_char(full_date,'YYYYMMDD')) as date_key,

    full_date,

    year(full_date) as year,

    quarter(full_date) as quarter,

    month(full_date) as month,

    monthname(full_date) as month_name,

    week(full_date) as week,

    day(full_date) as day,

    dayofweek(full_date) as day_of_week,

    dayname(full_date) as day_name,

    case
        when month(full_date) in (12,1,2) then 'Winter'
        when month(full_date) in (3,4,5) then 'Spring'
        when month(full_date) in (6,7,8) then 'Summer'
        else 'Fall'
    end as season,

    case
        when dayofweek(full_date) in (1,7) then true
        else false
    end as is_weekend,

    false as holiday_flag

from date_spine
where full_date <= '2024-09-27'