-- ========================================
-- 1. 每月營收、訂單量與銷售量的趨勢如何?
-- ========================================
SELECT
    CONVERT (CHAR (7), o.OrderDate, 126) AS 年月,
    ROUND(
        SUM(p.UnitPrice * (1 - o.Discount) * o.Quantity),
        2
    ) AS 每月營收,
    COUNT(DISTINCT o.orderID) AS 訂單量,
    SUM(o.Quantity) AS 銷售量
FROM
    vw_orders_clean AS o
    INNER JOIN products AS p ON o.ProductID = p.ProductID
WHERE
    o.Quantity IS NOT NULL
    AND o.OrderDate IS NOT NULL
    AND o.Discount IS NOT NULL
    AND o.Status = 'Completed'
GROUP BY
    CONVERT (CHAR (7), o.OrderDate, 126)
ORDER BY
    年月;

-- ========================================
-- 2.不同折扣幅度下，訂單數與平均購買數量是否有差異?
-- ========================================
SELECT
    Discount AS 折扣幅度,
    COUNT(DISTINCT OrderID) AS 訂單數,
    CAST(AVG(Quantity * 1.0) AS DECIMAL(5, 2)) AS 平均購買數量
from
    vw_orders_clean
WHERE
    Discount IS NOT NULL
    AND Quantity IS NOT NULL
    AND Status = 'Completed'
GROUP BY
    Discount
ORDER BY
    Discount;

-- ========================================
-- 3.不同年齡層的支付方式使用比例有何差異?
-- ========================================
WITH 年齡層 AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 0
            AND 10 THEN '0-10 歲'
            WHEN c.Age BETWEEN 11
            AND 20 THEN '11-20 歲'
            WHEN c.Age BETWEEN 21
            AND 30 THEN '21-30 歲'
            WHEN c.Age BETWEEN 31
            AND 40 THEN '31-40 歲'
            WHEN c.Age BETWEEN 41
            AND 50 THEN '41-50 歲'
            WHEN c.Age BETWEEN 51
            AND 60 THEN '51-60 歲'
            WHEN c.Age > 60 THEN '60+ 歲'
            ELSE NULL
        END AS 年齡層,
        o.PaymentMethod AS 支付方式
    FROM
        vw_orders_clean o
        JOIN customers c ON o.CustomerID = c.CustomerID
)
SELECT
    年齡層,
    COUNT(*) AS 訂單數,
    CAST(
        SUM(
            CASE
                WHEN 支付方式 = 'CardToCard' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 卡片轉帳,
    CAST(
        SUM(
            CASE
                WHEN 支付方式 = 'Cash' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 現金,
    CAST(
        SUM(
            CASE
                WHEN 支付方式 = 'Gateway' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 第三方支付,
    CAST(
        SUM(
            CASE
                WHEN 支付方式 = 'Wallet' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 電子錢包
FROM
    年齡層
WHERE
    年齡層 IS NOT NULL
    AND 支付方式 IS NOT NULL
GROUP BY
    年齡層
ORDER BY
    年齡層;

-- ========================================
-- 4. 各月份營收最高的 Top 5 商品，其年度營收排名為何?
-- ========================================
WITH 基礎銷售資料 AS (
    SELECT
        CONVERT(CHAR(4), o.OrderDate, 126) AS 年,
        CONVERT(CHAR(7), o.OrderDate, 126) AS 年月,
        o.ProductID AS 商品編號,
        p.ProductName AS 商品名稱,
        p.UnitPrice * (1 - o.Discount) * o.Quantity AS 營收
    FROM
        vw_orders_clean AS o
        INNER JOIN products AS p ON o.ProductID = p.ProductID
    WHERE
        o.Quantity IS NOT NULL
        AND o.OrderDate IS NOT NULL
        AND o.Discount IS NOT NULL
        AND o.Status = 'Completed'
),
年商品營收排名 AS (
    SELECT
        年,
        商品編號,
        商品名稱,
        ROUND(SUM(營收), 2) AS 每年營收,
        RANK() OVER(
            PARTITION BY 年
            ORDER BY
                SUM(營收) DESC
        ) AS 各年營收排名
    FROM
        基礎銷售資料
    GROUP BY
        年,
        商品編號,
        商品名稱
),
月商品營收排名 AS (
    SELECT
        年,
        年月,
        商品編號,
        商品名稱,
        ROUND(SUM(營收), 2) AS 每月營收,
        RANK() OVER (
            PARTITION BY 年月
            ORDER BY
                SUM(營收) DESC
        ) AS 各月營收排名
    FROM
        基礎銷售資料
    GROUP BY
        年,
        年月,
        商品編號,
        商品名稱
)
SELECT
    m.*,
    y.每年營收,
    y.各年營收排名
FROM
    年商品營收排名 y
    JOIN 月商品營收排名 m ON y.年 = m.年
    AND y.商品編號 = m.商品編號
WHERE
    各月營收排名 <= 5
ORDER BY
    年月,
    各月營收排名;

-- ========================================
-- 5.不同客戶分類的營收、訂單量與平均訂單金額有何差異?
-- ========================================
SELECT
    c.CustomerSegment,
    CAST(
        SUM(p.UnitPrice * (1 - o.Discount) * o.Quantity) AS DECIMAL(18, 2)
    ) AS 總營收,
    COUNT(DISTINCT o.OrderID) AS 訂單量,
    CAST(
        AVG(p.UnitPrice * (1 - o.Discount) * o.Quantity) AS DECIMAL(18, 2)
    ) AS 平均訂單金額
FROM
    vw_orders_clean o
    JOIN customers c ON o.CustomerID = c.CustomerID
    JOIN products p ON o.ProductID = p.ProductID
WHERE
    o.Quantity IS NOT NULL
    AND o.Discount IS NOT NULL
    AND o.Status = 'Completed'
GROUP BY
    c.CustomerSegment
ORDER BY
    總營收 DESC;

-- ========================================
-- 6.不同商品類別的完成、取消與退貨訂單比例有何差異?
-- ========================================
SELECT
    p.Category,
    CAST(
        COUNT(
            DISTINCT CASE
                WHEN o.Status = 'Completed' THEN o.OrderID
            END
        ) * 100.0 / COUNT(DISTINCT o.OrderID) AS DECIMAL(5, 2)
    ) AS 完成百分比,
    CAST(
        COUNT(
            DISTINCT CASE
                WHEN o.Status = 'Cancelled' THEN o.OrderID
            END
        ) * 100.0 / COUNT(DISTINCT o.OrderID) AS DECIMAL(5, 2)
    ) AS 取消百分比,
    CAST(
        COUNT(
            DISTINCT CASE
                WHEN o.Status = 'Returned' THEN o.OrderID
            END
        ) * 100.0 / COUNT(DISTINCT o.OrderID) AS DECIMAL(5, 2)
    ) AS 退貨百分比
FROM
    vw_orders_clean o
    JOIN products p ON o.ProductID = p.ProductID
GROUP BY
    p.Category;

-- ========================================
-- 7. 各商品的平均購買年齡為何?
-- ========================================
SELECT
    p.ProductID,
    p.ProductName,
    CAST(AVG(c.Age * 1.0) AS DECIMAL(5, 1)) AS 平均購買年齡
FROM
    vw_orders_clean AS o
    INNER JOIN customers AS c ON o.CustomerID = c.CustomerID
    INNER JOIN products AS p ON o.ProductID = p.ProductID
WHERE
    o.Quantity IS NOT NULL
GROUP BY
    p.ProductID,
    p.ProductName;

-- ========================================
-- 8. 不同支付方式的付款成功、失敗與退款比例是否有差異?
-- ========================================
SELECT
    o.PaymentMethod AS 付款方式,
    COUNT(*) AS 訂單數,
    CAST(
        SUM(
            CASE
                WHEN p.PaymentStatus = 'Paid' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 付款成功率,
    CAST(
        SUM(
            CASE
                WHEN p.PaymentStatus = 'Failed' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 付款失敗率,
    CAST(
        SUM(
            CASE
                WHEN p.PaymentStatus = 'Refunded' THEN 1.0
                ELSE 0
            END
        ) / COUNT(*) * 100 AS DECIMAL(5, 2)
    ) AS 退款率
FROM
    vw_orders_clean o
    JOIN vw_payments_clean p ON o.OrderID = p.OrderID
WHERE
    o.PaymentMethod IS NOT NULL
GROUP BY
    o.PaymentMethod
ORDER BY
    訂單數 DESC