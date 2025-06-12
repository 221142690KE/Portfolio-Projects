/* Keenan Peterson PwC transaction project
The purpose of the project is the identity and uncover hidden insight into the transcational data in order to provide
recommendations to inform their future strategy to drive growth and revenue in their product categorie */ 

-- total revenue
select sum(try_cast(price as float) * try_cast(quantity as float)) as total_revenue
from [PortfolioProject].[dbo].[Transactions$]

--Total customers
select 
count(distinct customerid) as total_Customers
from [PortfolioProject].[dbo].[Transactions$]
where CustomerID is not null

-- What is the Monthly Revenue trends by product category?
SELECT 
    FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM') AS Month,
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE TRY_CAST(PurchaseDate AS DATE) IS NOT NULL
And ProductCategory is not null 
GROUP BY FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM'), ProductCategory
ORDER BY Month, ProductCategory;

-- What is the total revenue per product category
SELECT
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE TRY_CAST(Price AS FLOAT) IS NOT NULL AND TRY_CAST(Quantity AS FLOAT) IS NOT NULL
And ProductCategory is not null 
GROUP BY ProductCategory
ORDER BY Revenue DESC;

-- What is the Total revenue by country?
SELECT 
    Country,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- What is the Customer Age group revenue contribution?
SELECT 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS AgeGroup,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE TRY_CAST(Age AS INT) IS NOT NULL
GROUP BY 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END;

-- Lowest growth product that contributes to the drop in growth from august 
WITH MonthlyRevenue AS (
    SELECT 
        ProductCategory,
        FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM') AS Month,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND 
        TRY_CAST(Quantity AS FLOAT) IS NOT NULL AND 
        TRY_CAST(PurchaseDate AS DATE) IS NOT NULL AND
        ProductCategory IS NOT NULL AND
        FORMAT(TRY_CAST(PurchaseDate AS DATE), 'MM') BETWEEN '07' AND '12'
    GROUP BY 
        ProductCategory,
        FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM')
),

RevenueWithGrowth AS (
    SELECT 
        ProductCategory,
        Month,
        Revenue,
        LAG(Revenue) OVER (PARTITION BY ProductCategory ORDER BY Month) AS PrevMonthRevenue
    FROM MonthlyRevenue
),

GrowthStats AS (
    SELECT 
        ProductCategory,
        Month,
        Revenue,
        PrevMonthRevenue,
        CASE 
            WHEN PrevMonthRevenue IS NOT NULL AND PrevMonthRevenue > 0 
            THEN ROUND(((Revenue - PrevMonthRevenue) / PrevMonthRevenue) * 100, 2)
            ELSE NULL
        END AS MoM_Growth
    FROM RevenueWithGrowth
),

NegativeGrowth AS (
    SELECT 
        ProductCategory,
        AVG(Revenue) AS AvgRevenue,
        COUNT(*) AS NegativeGrowthMonths
    FROM GrowthStats
    WHERE MoM_Growth < 0
    GROUP BY ProductCategory
)

SELECT TOP 3 
    ProductCategory,
    ROUND(AvgRevenue, 2) AS AvgRevenue,
    NegativeGrowthMonths
FROM NegativeGrowth
ORDER BY AvgRevenue ASC;

-- Worst performing product category all year round 
SELECT 
    ProductCategory,
    ROUND(SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)), 2) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    ProductCategory IS NOT NULL AND
    TRY_CAST(Price AS FLOAT) IS NOT NULL AND
    TRY_CAST(Quantity AS FLOAT) IS NOT NULL
GROUP BY ProductCategory
ORDER BY TotalRevenue ASC;



-- What is the most purchased product category per age segment by revenue
WITH AgeRevenue AS (
    SELECT 
        CASE 
            WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
            WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
            WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
            WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
            ELSE '60+'
        END AS AgeGroup,
        ProductCategory,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalRevenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        ProductCategory IS NOT NULL AND 
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND 
        TRY_CAST(Quantity AS FLOAT) IS NOT NULL AND 
        TRY_CAST(Age AS INT) IS NOT NULL
    GROUP BY 
        CASE 
            WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
            WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
            WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
            WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
            ELSE '60+'
        END,
        ProductCategory
),

RankedCategories AS (
    SELECT *,
           RANK() OVER (PARTITION BY AgeGroup ORDER BY TotalRevenue DESC) AS rnk
    FROM AgeRevenue
)

SELECT 
    AgeGroup,
    ProductCategory,
    ROUND(TotalRevenue, 2) AS TotalRevenue
FROM RankedCategories
WHERE rnk = 1
ORDER BY AgeGroup;


-- What is the Gender-based revenue performance?
SELECT 
    Gender,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE Gender IS NOT NULL
GROUP BY Gender; 

-- What is the Average order by value by country?
SELECT 
    Country,
    AVG(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS AvgOrderValue
FROM [PortfolioProject].[dbo].[Transactions$]
GROUP BY Country
ORDER BY AvgOrderValue DESC;

-- How many repeating or returning buyers?
SELECT 
    CustomerID,
    COUNT(*) AS PurchaseCount,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalSpent
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY PurchaseCount DESC;

-- What is the Top selling products by country?
SELECT 
    Country,
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE Country is not null 
AND ProductCategory is not null
GROUP BY Country, ProductCategory
ORDER BY Country, Revenue DESC;

-- Highest selling product category per country
WITH RankedProducts AS (
    SELECT 
        Country,
        ProductCategory,
        ROUND(SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)), 2) AS Revenue,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY 
            SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) DESC) AS Rank
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        Country IS NOT NULL 
        AND ProductCategory IS NOT NULL
        AND TRY_CAST(Price AS FLOAT) IS NOT NULL
        AND TRY_CAST(Quantity AS FLOAT) IS NOT NULL
    GROUP BY Country, ProductCategory
)

SELECT 
    Country,
    ProductCategory,
    Revenue
FROM RankedProducts
WHERE Rank = 1
ORDER BY Revenue DESC;

-- What are the Monthly sales growth rates?
WITH MonthlySales AS (
    SELECT 
        FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM') AS Month,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE TRY_CAST(PurchaseDate AS DATE) IS NOT NULL
    GROUP BY FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM')
)
SELECT 
    Month,
    Revenue,
    (Revenue - LAG(Revenue) OVER (ORDER BY Month)) * 100.0 / NULLIF(LAG(Revenue) OVER (ORDER BY Month), 0) AS GrowthRatePercent
FROM MonthlySales;

-- Product category profitability by country 
SELECT 
    Country,
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE Country is not null 
And ProductCategory is not null 
GROUP BY Country, ProductCategory
ORDER BY Country, Revenue DESC;

-- Average expenditure per Age segment
SELECT 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS AgeGroup,
    AVG(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS AvgSpend
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE TRY_CAST(Age AS INT) IS NOT NULL
GROUP BY 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END;

-- Average quantity purchased per product
SELECT 
    ProductCategory, 
    AVG(TRY_CAST(Quantity AS FLOAT)) AS AvgQuantity
FROM [PortfolioProject].[dbo].[Transactions$]
Where ProductCategory is not null 
GROUP BY ProductCategory
ORDER BY AvgQuantity DESC;

-- What was the peak purchase days?
SELECT 
    DATENAME(WEEKDAY, TRY_CAST(PurchaseDate AS DATE)) AS DayOfWeek,
    COUNT(*) AS Orders
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE TRY_CAST(PurchaseDate AS DATE) IS NOT NULL
GROUP BY DATENAME(WEEKDAY, TRY_CAST(PurchaseDate AS DATE))
ORDER BY Orders DESC;

-- What was the total revenue by productcategory and gender?
SELECT 
    ProductCategory,
    Gender,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE Gender IS NOT NULL
AND ProductCategory is not null 
GROUP BY ProductCategory, Gender
ORDER BY ProductCategory, Revenue DESC;

-- what payment method is used by the various age groups and genders?
--first gender
-- second age

SELECT 
    Gender,
    PaymentMethod,
    COUNT(DISTINCT CustomerID) AS TotalUsers
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Gender IS NOT NULL 
    AND PaymentMethod IS NOT NULL
GROUP BY Gender, PaymentMethod
ORDER BY Gender, TotalUsers DESC;

SELECT 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS AgeGroup,
    PaymentMethod,
    COUNT(DISTINCT CustomerID) AS TotalUsers
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    TRY_CAST(Age AS INT) IS NOT NULL 
    AND PaymentMethod IS NOT NULL
GROUP BY 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END,
    PaymentMethod
ORDER BY AgeGroup, TotalUsers DESC;

-- Most used payment method per age group
WITH RankedMethods AS (
    SELECT 
        CASE 
            WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
            WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
            WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
            WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
            ELSE '60+'
        END AS AgeGroup,
        PaymentMethod,
        COUNT(DISTINCT CustomerID) AS TotalUsers,
        ROW_NUMBER() OVER (
            PARTITION BY 
                CASE 
                    WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
                    WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
                    WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
                    WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
                    ELSE '60+'
                END 
            ORDER BY COUNT(DISTINCT CustomerID) DESC
        ) AS RankInGroup
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        TRY_CAST(Age AS INT) IS NOT NULL 
        AND PaymentMethod IS NOT NULL
    GROUP BY 
        CASE 
            WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
            WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
            WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
            WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
            ELSE '60+'
        END,
        PaymentMethod
)

SELECT 
    AgeGroup,
    PaymentMethod,
    TotalUsers
FROM RankedMethods
WHERE RankInGroup = 1
ORDER BY AgeGroup;

-- highest vs lowest performing product in every country 
WITH CategoryRevenue AS (
    SELECT 
        Country,
        ProductCategory,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalRevenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        Country IS NOT NULL AND
        ProductCategory IS NOT NULL AND
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND
        TRY_CAST(Quantity AS FLOAT) IS NOT NULL
    GROUP BY Country, ProductCategory
),

RankedHigh AS (
    SELECT 
        Country,
        ProductCategory AS HighestSellingCategory,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalRevenue DESC) AS RankHigh
    FROM CategoryRevenue
),

RankedLow AS (
    SELECT 
        Country,
        ProductCategory AS LowestSellingCategory,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY TotalRevenue ASC) AS RankLow
    FROM CategoryRevenue
),

Highest AS (
    SELECT Country, HighestSellingCategory
    FROM RankedHigh
    WHERE RankHigh = 1
),

Lowest AS (
    SELECT Country, LowestSellingCategory
    FROM RankedLow
    WHERE RankLow = 1
)

SELECT 
    h.Country,
    h.HighestSellingCategory,
    l.LowestSellingCategory
FROM Highest h
JOIN Lowest l ON h.Country = l.Country
ORDER BY h.Country;


/* The client wants me to dive into specific data regarding the performance of South Africa, in order to gain 
an understand of the market to develop innovative product and marketing strategies*/

-- Total revenue of products in South Africa
SELECT 
    ProductCategory,
    ROUND(SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)), 2) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Country = 'South Africa' AND
    TRY_CAST(Price AS FLOAT) IS NOT NULL AND
    TRY_CAST(Quantity AS FLOAT) IS NOT NULL
GROUP BY ProductCategory
ORDER BY TotalRevenue DESC;

-- Monthly revenue in South Africa
SELECT 
    FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM') AS Month,
    ROUND(SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)), 2) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Country = 'South Africa' AND
    TRY_CAST(PurchaseDate AS DATE) IS NOT NULL
GROUP BY FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM')
ORDER BY Month;

-- What age group segment purchases the most products
SELECT 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END AS AgeGroup,
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS INT)) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Age IS NOT NULL AND
	Country = 'South Africa'AND
    ProductCategory IS NOT NULL AND
    TRY_CAST(Price AS FLOAT) IS NOT NULL AND
    TRY_CAST(Quantity AS INT) IS NOT NULL
GROUP BY 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END,
    ProductCategory
ORDER BY AgeGroup, TotalRevenue DESC;

-- highest selling product per month
WITH MonthlyRevenue AS (
    SELECT 
        DATENAME(MONTH, TRY_CAST(PurchaseDate AS DATE)) AS MonthName,
        MONTH(TRY_CAST(PurchaseDate AS DATE)) AS MonthNumber,
        ProductCategory,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS INT)) AS Revenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        TRY_CAST(PurchaseDate AS DATE) IS NOT NULL AND
		Country = 'South Africa' AND
        ProductCategory IS NOT NULL AND
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND
        TRY_CAST(Quantity AS INT) IS NOT NULL
    GROUP BY 
        DATENAME(MONTH, TRY_CAST(PurchaseDate AS DATE)),
        MONTH(TRY_CAST(PurchaseDate AS DATE)),
        ProductCategory
),
Ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY MonthNumber ORDER BY Revenue DESC) AS Rank
    FROM MonthlyRevenue
)
SELECT 
    MonthName,
    ProductCategory,
    Revenue
FROM Ranked
WHERE Rank = 1
ORDER BY MonthNumber;


-- Prefered payment method for each age segment
SELECT 
    PaymentMethod,
    COUNT(DISTINCT CustomerID) AS UserCount
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Country = 'South Africa' AND
    PaymentMethod IS NOT NULL
GROUP BY PaymentMethod
ORDER BY UserCount DESC;

-- Gender spending
SELECT 
    Gender,
    ROUND(SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)), 2) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE 
    Country = 'South Africa' AND
    Gender IS NOT NULL
GROUP BY Gender
ORDER BY Revenue DESC;

--What gender purchases the most products
WITH GenderRevenue AS (
    SELECT
        Gender,
        ProductCategory,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS INT)) AS Revenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        Gender IS NOT NULL AND 
		Country = 'South Africa' AND
        ProductCategory IS NOT NULL AND
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND
        TRY_CAST(Quantity AS INT) IS NOT NULL
    GROUP BY Gender, ProductCategory
),
RankedProducts AS (
    SELECT *,
        RANK() OVER (PARTITION BY Gender ORDER BY Revenue DESC) AS ProductRank
    FROM GenderRevenue
),
TotalGenderRevenue AS (
    SELECT
        Gender,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS INT)) AS TotalRevenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE 
        Gender IS NOT NULL AND
		Country = 'South Africa' AND
        TRY_CAST(Price AS FLOAT) IS NOT NULL AND
        TRY_CAST(Quantity AS INT) IS NOT NULL
    GROUP BY Gender
)
SELECT 
    r.Gender,
    t.TotalRevenue,
    r.ProductCategory AS MostPurchasedProduct
FROM RankedProducts r
JOIN TotalGenderRevenue t ON r.Gender = t.Gender
WHERE r.ProductRank = 1
ORDER BY t.TotalRevenue DESC;


--- Project complete for client