use sakila;
-- create cosine_similarity table
create table customer_similarity (
	user_A smallint,
    user_B smallint,
    similarity_score float
);

alter table  sakila.customer_similarity
add primary key (user_A, user_b);

insert into customer_similarity (
	user_A,
    user_B,
    similarity_score
)
-- all customers and all movies (fact)
with all_customers_all_movies as (
	select distinct
		c.customer_id,
		i.film_id
	from customer c
    join rental r
    on c.customer_id = r.customer_id
    join inventory i
    on r.inventory_id = i.inventory_id
),

-- all customers and total count of movies (statistic)
all_customers_total_movies as (
	select 
		customer_id,
		count(*) as movies_rented
	from all_customers_all_movies
	group by customer_id
),

-- combination of all customers and shared movies (statistic)
two_customers_shared_movies as (
	select
		a.customer_id as user_A,
		b.customer_id as user_B,
		count(*) as same_movies_rented
	from all_customers_all_movies a
    join all_customers_all_movies b
    on a.film_id = b.film_id
    where a.customer_id != b.customer_id
    group by a.customer_id, b.customer_id
),
-- sanity check: user 1 and 2 have 1 movie in common. use the following query to make sure that this CTE works correctly:
-- select film_id, count(*) from all_customers_all_movies where customer_id in (1,2) group by film_id order by count(*) desc;

-- combination of all customers, shared movies, total movies, and similarity score
two_customers_similarity_score as (
	select
		a.user_A,
        a.user_B,
        a.same_movies_rented,
        b.movies_rented as user_A_movies_rented,
        c.movies_rented as user_B_movies_rented,
        round(a.same_movies_rented / SQRT(b.movies_rented * c.movies_rented), 4) as similarity_score
	from two_customers_shared_movies a
    join all_customers_total_movies b
    on a.user_A = b.customer_id
    join all_customers_total_movies c
    on a.user_B = c.customer_id
    order by user_A, user_B
)
select user_A, user_B, similarity_score from two_customers_similarity_score;