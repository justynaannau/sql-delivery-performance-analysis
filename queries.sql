USE DeliveryPerformance;

-- =========================================
-- 1. Data Quality Check: Duplicate Order IDs
-- Objective: Check whether order_id values are unique
-- =========================================

SELECT
    order_id,
    COUNT(*) AS DuplicateCount
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- =========================================
-- 2. Monthly Orders Trend
-- Objective: Analyze monthly order volume
-- =========================================

SELECT
    DATETRUNC(MONTH, order_purchase_timestamp) AS OrderMonth,
    COUNT(*) AS OrdersCount
FROM orders
GROUP BY DATETRUNC(MONTH, order_purchase_timestamp)
ORDER BY 1;


-- =========================================
-- 3. Orders by Order Status
-- Objective: Analyze distribution of technical order statuses
-- =========================================

SELECT
    order_status,
    COUNT(*) AS OrdersCount
FROM orders
GROUP BY order_status
ORDER BY OrdersCount DESC;


-- =========================================
-- 4. Average Delivery Time
-- Objective: Calculate average delivery time in days
-- =========================================

SELECT
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS AvgDeliveryDays
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- =========================================
-- 5. Delivery Status Categories
-- Objective: Classify orders as On Time, Delayed or No Delivery Date
-- =========================================

SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN 'No Delivery Date'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Delayed'
        ELSE 'On Time'
    END AS DeliveryStatus,

    COUNT(*) AS OrdersCount

FROM orders

GROUP BY
    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN 'No Delivery Date'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Delayed'
        ELSE 'On Time'
    END

ORDER BY OrdersCount DESC;


-- =========================================
-- 6. Monthly Delay Rate
-- Objective: Calculate delay rate by purchase month
-- =========================================

SELECT
    DATETRUNC(MONTH, order_purchase_timestamp) AS OrderMonth,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END
    ) AS DelayedOrders,

    CAST(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS DelayRatePercent

FROM orders

WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL

GROUP BY DATETRUNC(MONTH, order_purchase_timestamp)

ORDER BY OrderMonth;


-- =========================================
-- 7. Top 5 Months with Highest Delay Rate
-- Objective: Identify months with the highest operational delay risk
-- Note: Months with fewer than 100 orders are excluded
-- =========================================

SELECT TOP 5
    DATETRUNC(MONTH, order_purchase_timestamp) AS OrderMonth,

    COUNT(*) AS TotalOrders,

    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END
    ) AS DelayedOrders,

    CAST(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS DelayRatePercent

FROM orders

WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL

GROUP BY DATETRUNC(MONTH, order_purchase_timestamp)

HAVING COUNT(*) > 100

ORDER BY DelayRatePercent DESC;


-- =========================================
-- 8. Missing Delivery Date Analysis
-- Objective: Measure completeness of delivery date data
-- =========================================

SELECT
    COUNT(*) AS TotalOrders,

    SUM(
        CASE
            WHEN order_delivered_customer_date IS NULL
                THEN 1
            ELSE 0
        END
    ) AS MissingDeliveryDate,

    CAST(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date IS NULL
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(10,2)
    ) AS MissingDeliveryDatePercent

FROM orders;


-- =========================================
-- 9. Average Delay Days
-- Objective: Calculate average number of days delayed for delayed orders only
-- =========================================

SELECT
    AVG(DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date)) AS AvgDelayDays
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;


-- =========================================
-- 10. Average Delivery Time by Order Status
-- Objective: Compare delivery duration across order statuses
-- =========================================

SELECT
    order_status,

    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS AvgDeliveryDays

FROM orders

WHERE order_delivered_customer_date IS NOT NULL

GROUP BY order_status

ORDER BY AvgDeliveryDays DESC;


-- =========================================
-- 11. Monthly Order Growth
-- Objective: Calculate month-over-month order growth
-- =========================================

WITH MonthlyOrders AS (
    SELECT
        DATETRUNC(MONTH, order_purchase_timestamp) AS OrderMonth,
        COUNT(*) AS TotalOrders
    FROM orders
    GROUP BY DATETRUNC(MONTH, order_purchase_timestamp)
)

SELECT
    OrderMonth,

    TotalOrders,

    LAG(TotalOrders) OVER (ORDER BY OrderMonth) AS PreviousMonthOrders,

    CAST(
        100.0 * (TotalOrders - LAG(TotalOrders) OVER (ORDER BY OrderMonth))
        / NULLIF(LAG(TotalOrders) OVER (ORDER BY OrderMonth), 0)
        AS DECIMAL(10,2)
    ) AS MonthlyGrowthPercent

FROM MonthlyOrders

ORDER BY OrderMonth;
