-- 1. View sample records
SELECT *
FROM walmart_clean_data
LIMIT 10;

-- 2. Count total records
SELECT COUNT(*) AS total_records
FROM walmart_clean_data;

-- 3. Count transactions by payment method
SELECT
    payment_method,
    COUNT(*) AS no_payments
FROM walmart_clean_data
GROUP BY payment_method;

-- 4. Count distinct branches
SELECT COUNT(DISTINCT branch) AS total_branches
FROM walmart_clean_data;

-- 5. Find minimum quantity sold
SELECT MIN(quantity) AS minimum_quantity
FROM walmart_clean_data;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_clean_data
GROUP BY payment_method;

-- Q2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating

WITH category_ratings AS (
    SELECT
        branch,
        category,
        AVG(rating) AS avg_rating
    FROM walmart_clean_data
    GROUP BY branch, category
),
ranked_categories AS (
    SELECT
        branch,
        category,
        avg_rating,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY avg_rating DESC
        ) AS category_rank
    FROM category_ratings
)
SELECT
    branch,
    category,
    avg_rating
FROM ranked_categories
WHERE category_rank = 1
ORDER BY branch;


-- Q3: Find the busiest day for each branch

SELECT
    branch,
    DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
    COUNT(*) AS no_transactions
FROM walmart_clean_data
GROUP BY
    branch,
    DAYNAME(STR_TO_DATE(date, '%d/%m/%Y'))
ORDER BY
    branch,
    no_transactions DESC;
    

-- Q4: Calculate the total quantity of items sold per payment method

SELECT
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart_clean_data
GROUP BY payment_method;


-- Q5: Calculate the average, minimum, and maximum
-- rating of each category for every city

SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart_clean_data
GROUP BY city, category
ORDER BY city, category;


-- Q6: Calculate the total profit for each category

SELECT
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart_clean_data
GROUP BY category
ORDER BY total_profit DESC;



-- Q7: Find the most common payment method for each branch

WITH payment_counts AS (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS total_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(*) DESC
        ) AS payment_rank
    FROM walmart_clean_data
    GROUP BY branch, payment_method
)
SELECT
    branch,
    payment_method AS preferred_payment_method,
    total_transactions
FROM payment_counts
WHERE payment_rank = 1
ORDER BY branch;


-- Q8: Categorize sales into shifts

SELECT
    branch,
    CASE
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart_clean_data
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;


-- Q9: Find the top 5 branches with the largest
-- revenue decrease from 2022 to 2023

WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart_clean_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart_clean_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(
        ((r2022.revenue - r2023.revenue)
        / r2022.revenue) * 100,
        2
    ) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023
    ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;

