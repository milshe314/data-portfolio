-- ========================================
-- 1. 重複資料與主鍵唯一性確認
-- ========================================

-- 完全重複列
SELECT
    OrderID,
    CustomerID,
    OrderDate,
    ProductID,
    Quantity,
    Discount,
    PaymentMethod,
    Status,
    COUNT(*) AS DuplicateCount
FROM dbo.orders
GROUP BY
    OrderID,
    CustomerID,
    OrderDate,
    ProductID,
    Quantity,
    Discount,
    PaymentMethod,
    Status
HAVING COUNT(*) > 1
ORDER BY OrderID;


-- OrderID 是否重複
SELECT
    OrderID,
    COUNT(*) AS OrderCount
FROM dbo.orders
GROUP BY OrderID
HAVING COUNT(*) > 1
ORDER BY OrderID;
-- ========================================
-- 2. NULL 確認
-- ========================================

WITH orders_dedup AS (
    SELECT DISTINCT *
    FROM orders
)
SELECT
    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS Null_OrderID,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Null_ProductID,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS Null_OrderDate,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Null_Quantity,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Null_Discount,
    SUM(CASE WHEN PaymentMethod IS NULL THEN 1 ELSE 0 END) AS Null_PaymentMethod,
    SUM(CASE WHEN Status IS NULL THEN 1 ELSE 0 END) AS Null_Status
FROM orders_dedup;
SELECT 
    SUM(CASE WHEN PaymentID IS NULL THEN 1 ELSE 0 END) AS Null_PaymentID,
    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS Null_OrderID,
    SUM(CASE WHEN PaymentDate IS NULL THEN 1 ELSE 0 END) AS Null_PaymentDate,
    SUM(CASE WHEN PaymentStatus IS NULL THEN 1 ELSE 0 END) AS Null_PaymentStatus
FROM payments;
SELECT 
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Null_ProductID,
    SUM(CASE WHEN ProductName IS NULL THEN 1 ELSE 0 END) AS Null_ProductName,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Null_Category,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS Null_UnitPrice
FROM products;
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN SignupDate IS NULL THEN 1 ELSE 0 END) AS Null_SignupDate,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Null_Age,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS Null_City,
    SUM(CASE WHEN CustomerSegment IS NULL THEN 1 ELSE 0 END) AS Null_CustomerSegment
FROM customers;
-- ========================================
-- 3. 數值範圍與類別值確認
-- ========================================

SELECT DISTINCT *
FROM orders
WHERE Discount < 0
   OR Discount > 1;

SELECT DISTINCT *
FROM orders
WHERE Quantity <= 0;

SELECT *
FROM products
WHERE UnitPrice <= 0;

SELECT Age
FROM customers
WHERE Age < 0
   OR Age > 120;

SELECT DISTINCT Status
FROM orders;

SELECT DISTINCT PaymentMethod
FROM orders;

SELECT DISTINCT PaymentStatus
FROM payments;

SELECT DISTINCT CustomerSegment
FROM customers;

SELECT DISTINCT Category
FROM products;
-- ========================================
-- 4. 關聯完整性確認
-- ========================================

SELECT DISTINCT o.*
FROM orders AS o
LEFT JOIN customers AS c
    ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

SELECT DISTINCT o.*
FROM orders AS o
LEFT JOIN products AS p
    ON o.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

SELECT p.*
FROM payments AS p
LEFT JOIN orders AS o
    ON p.OrderID = o.OrderID
WHERE o.OrderID IS NULL;