-- 1. Display the number of films in each category, sorted in descending order
SELECT c.name AS category, 
COUNT(f.film_id) AS film_count
FROM category c
LEFT JOIN film_category fc ON c.category_id = fc.category_id
LEFT JOIN film f ON f.film_id = fc.film_id
GROUP BY c.name
ORDER BY film_count DESC;

-- 2. Display the top 10 actors whose films were rented the most, sorted in descending order
SELECT a.actor_id, 
a.first_name, 
a.last_name, 
COUNT(r.rental_id) AS rental_count
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id = fa.actor_id
LEFT JOIN film f ON fa.film_id = f.film_id
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY rental_count DESC
LIMIT 10;

-- 3. Display the category of films that generated the highest revenue
SELECT c.name AS category, 
SUM(p.amount) AS total_revenue
FROM category c
LEFT JOIN film_category fc ON c.category_id = fc.category_id
LEFT JOIN film f ON fc.film_id = f.film_id
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
LEFT JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY total_revenue DESC
LIMIT 1;

-- 4. Display the titles of films not present in the inventory (WITHOUT using IN operator)
SELECT f.title
FROM film f
LEFT LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL;

-- 5. Display the top 3 actors who appeared the most in films within the "Children" category (include ties)
WITH actor_counts AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(*) AS film_count
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film_category fc ON fa.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Children'
    GROUP BY a.actor_id, a.first_name, a.last_name
),
ranked AS (
    SELECT 
        actor_id,
        first_name,
        last_name,
        film_count,
        DENSE_RANK() OVER (ORDER BY film_count DESC) AS rnk
    FROM actor_counts
)
SELECT actor_id, 
       first_name, 
       last_name, 
       film_count
FROM ranked
WHERE rnk <= 3
ORDER BY film_count DESC;

-- 6. Display cities with the count of active and inactive customers (sort by inactive DESC)
SELECT ci.city,
       SUM(CASE WHEN cu.active = 1 THEN 1 ELSE 0 END) AS active_customers,
       SUM(CASE WHEN cu.active = 0 THEN 1 ELSE 0 END) AS inactive_customers
FROM city ci
LEFT JOIN address a ON ci.city_id = a.city_id
LEFT JOIN customer cu ON a.address_id = cu.address_id
GROUP BY ci.city
ORDER BY inactive_customers DESC;

-- 7. Display the film category with the highest total rental hours in cities 
-- where customer.address_id belongs to that city and starts with the letter "a". 
-- Do the same for cities containing the symbol "-". Write this in a single query.

WITH rental_hours AS (
    SELECT ci.city, 
    c.name AS category, 
    SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600) AS total_hours
    FROM category c
    LEFT JOIN film_category fc ON c.category_id = fc.category_id
    LEFT JOIN film f ON fc.film_id = f.film_id
    LEFT JOIN inventory i ON f.film_id = i.film_id
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id
    LEFT JOIN customer cu ON r.customer_id = cu.customer_id
    LEFT JOIN address a ON cu.address_id = a.address_id
    LEFT JOIN city ci ON a.city_id = ci.city_id
    WHERE ci.city ILIKE 'a%' OR ci.city LIKE '%-%'
    GROUP BY ci.city, c.name
),
ranked AS (
    SELECT city, category, total_hours,
           RANK() OVER (PARTITION BY city ORDER BY total_hours DESC) AS rnk
    FROM rental_hours
)
SELECT city, category, total_hours
FROM ranked
WHERE rnk = 1;