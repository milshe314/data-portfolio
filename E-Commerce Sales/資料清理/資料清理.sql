-- ========================================
-- 1. 資料型別調整
-- ========================================

ALTER TABLE orders
ALTER COLUMN Discount DECIMAL(4, 2) NULL;

ALTER TABLE orders
ALTER COLUMN Quantity INT NULL;

ALTER TABLE customers
ALTER COLUMN Age INT NULL;


-- ========================================
-- 2. 建立 orders 分析用 View
-- ========================================

GO

CREATE OR ALTER VIEW dbo.vw_orders_clean AS
SELECT DISTINCT o.*
FROM dbo.orders AS o
WHERE
    (o.Quantity > 0 OR o.Quantity IS NULL)
    AND EXISTS (
        SELECT 1
        FROM dbo.customers AS c
        WHERE c.CustomerID = o.CustomerID
    );

GO

-- ========================================
-- 3. 建立 payments 分析用 View
-- ========================================

CREATE OR ALTER VIEW dbo.vw_payments_clean AS
SELECT p.*
FROM dbo.payments AS p
WHERE EXISTS (
    SELECT 1
    FROM dbo.vw_orders_clean AS o
    WHERE o.OrderID = p.OrderID
);

GO