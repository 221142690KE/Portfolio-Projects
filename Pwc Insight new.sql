-- Keenan Peterson Data analytics project
-- Total Revenue made by the business 
SELECT SUM(Try_cast(price as float) * try_cast(quantity as float)) as total_revenue
  FROM [PortfolioProject].[dbo].[Transactions$]
  where [Feeback status] = 'approved' 
 
 -- Total customers
 Select
 count(distinct customerid) as total_customers
 from [PortfolioProject].[dbo].[Transactions$]
 where CustomerID is not null 

 -- Monthly revenue trends by approved product category 
 Select
 Format(try_cast(purchasedate as date) , 'yyyy-MM') as Month,
 Productcategory,
 SUM(Try_cast(price as float) * Try_cast (quantity as float)) as total_revenue
 from [PortfolioProject].[dbo].[Transactions$]
 where try_cast(PurchaseDate as date) is not null
 AND ProductCategory is not null
 AND [Feeback status] = 'Approved'
 Group by Format(try_cast(purchasedate as date) , 'yyyy-MM'), 
 ProductCategory
 Order by Month, ProductCategory

 -- What is total revenue by country 
 SELECT 
    Country,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS TotalRevenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE [Feeback status] = 'approved'
AND price is not null 
AND Quantity is not null 
GROUP BY Country
ORDER BY TotalRevenue DESC;

-- What is the customer age group revenue contribution 
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
AND [Feeback status] = 'approved'
GROUP BY 
    CASE 
        WHEN TRY_CAST(Age AS INT) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TRY_CAST(Age AS INT) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TRY_CAST(Age AS INT) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TRY_CAST(Age AS INT) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+'
    END;

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
        TRY_CAST(Age AS INT) IS NOT NULL AND
		[Feeback status] = 'approved'
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

-- Highest selling product per country 
SELECT 
    Country,
    ProductCategory,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
FROM [PortfolioProject].[dbo].[Transactions$]
WHERE Country is not null 
AND ProductCategory is not null
GROUP BY  Country, ProductCategory
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
		AND [Feeback status] = 'approved'
    GROUP BY Country, ProductCategory
)

SELECT 
    Country,
    ProductCategory,
    Revenue
FROM RankedProducts
WHERE Rank = 1
ORDER BY Revenue DESC;

-- What is the total number of declinced transactions
Select count('feeback status') as total_decline
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'declined'

-- What is the total number of failed transactions 
Select count('feeback status') as total_failed
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'failed'

-- What is the revenue lost during the failed transactions
Select count('feeback status') as total_failed,
sum(try_cast(price as float) * try_cast(quantity as float)) as total_loss
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'failed'

-- Total products sold
select 
sum(try_cast(quantity as float)) as total_Quantity
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'approved'

-- Total orders completed
select 
sum(try_cast(quantity as float)) as total_Quantity
from [PortfolioProject].[dbo].[Transactions$]
where [OrderStatus] = 'completed'

-- monthly sales growth rates
WITH MonthlySales AS (
    SELECT 
        FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM') AS Month,
        SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS Revenue
    FROM [PortfolioProject].[dbo].[Transactions$]
    WHERE TRY_CAST(PurchaseDate AS DATE) IS NOT NULL AND
	[Feeback status] = 'approved'
    GROUP BY FORMAT(TRY_CAST(PurchaseDate AS DATE), 'yyyy-MM')
)
SELECT 
    Month,
    Revenue,
    (Revenue - LAG(Revenue) OVER (ORDER BY Month)) * 100 / NULLIF(LAG(Revenue) OVER (ORDER BY Month), 0) AS GrowthRatePercent
FROM MonthlySales;

-- Questions asked from client
/*What is the overall success rate of transcations (approved vs total) and how does it compare to the rates of declined and failed transactions?*/
SELECT
    COUNT(transactionid) AS total_transactions,
    SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE 0 END) AS approved_transactions,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS approval_rate_percentage,
    SUM(CASE WHEN [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS declined_transactions,
    TRY_CAST(SUM(CASE WHEN [feeback status] = 'Declined' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS decline_rate_percentage,
    SUM(CASE WHEN [feeback status] = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS failure_rate_percentage
FROM
  [PortfolioProject].[dbo].[Transactions$]



  /* Which payment method has the highest rates of decline or failure and what is their impact on total potential revenue */
  SELECT
    paymentmethod,
    COUNT(transactionid) AS total_transactions,
    SUM(TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) AS total_amount,
    SUM(CASE WHEN  [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS declined_count,
    SUM(CASE WHEN  [Feeback status] = 'Declined' THEN (TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) ELSE 0 END) AS declined_amount,
    TRY_CAST(SUM(CASE WHEN  [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS decline_rate_percentage,
    SUM(CASE WHEN  [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS failed_count,
    SUM(CASE WHEN  [Feeback status] = 'Failed' THEN (TRY_CAST(Price AS FLOAT) * TRY_CAST(Quantity AS FLOAT)) ELSE 0 END) AS failed_amount,
    TRY_CAST(SUM(CASE WHEN  [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS failure_rate_percentage
FROM
   [PortfolioProject].[dbo].[Transactions$]
WHERE PaymentMethod  is not null 
GROUP BY
    paymentmethod
ORDER BY
    decline_rate_percentage DESC, failure_rate_percentage DESC;
    

/*What are the top countries by transaction volume, and how do their approval rates compare*/
SELECT TOP 5
    country,
    COUNT(transactionid) AS total_transactions,
    SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE ''END) AS approved_transactions,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE '' END) AS FLOAT) * 100 / COUNT(transactionid) AS approval_rate_percentage
FROM
   [PortfolioProject].[dbo].[Transactions$]
 Where 'approved' is not null   
GROUP BY
    country
ORDER BY
    approval_rate_percentage DESC

/* What are the lowest countries by transaction volume, and how do their failed rates compare*/
	SELECT TOP 5
    country,
    COUNT(transactionid) AS total_transactions,
    SUM(CASE WHEN [Feeback status] = 'failed' THEN 1 ELSE ''END) AS failed_transactions,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'failed' THEN 1 ELSE '' END) AS FLOAT) * 100 / COUNT(transactionid) AS failed_rate_percentage
FROM
   [PortfolioProject].[dbo].[Transactions$]
 Where 'approved' is not null   
GROUP BY
    country
ORDER BY
    failed_rate_percentage DESC

/* Is there a correlation between the device type used for transactions and the likelihood of a transaction being declined or failed*/

SELECT
    PaymentMethod,
    COUNT(transactionid) AS total_transactions,
    SUM(CASE WHEN [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS declined_count,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS decline_rate_percentage,
    SUM(CASE WHEN [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS failed_count,
    TRY_CAST(SUM(CASE WHEN [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(transactionid) AS failure_rate_percentage
FROM
     [PortfolioProject].[dbo].[Transactions$]
Where PaymentMethod is not null 	 
GROUP BY
    PaymentMethod
ORDER BY
    decline_rate_percentage DESC, failure_rate_percentage DESC;


--Total revenue loss from declined and failed transactions
select 
sum(try_cast(price as float) * try_cast(quantity as float)) as total_revenue_loss
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'declined' or [Feeback status] = 'failed'


select count([Feeback status]) as total_approved
from [PortfolioProject].[dbo].[Transactions$]
where [Feeback status] = 'approved'

-- Identity the amount of system erros and timeouts associated to the transaction gateway

SELECT
    SUM(CASE WHEN feedback LIKE '%System error%' THEN 1 ELSE 0 END) AS System_error,
    SUM(CASE WHEN feedback LIKE '%timeout%' THEN 1 ELSE 0 END) AS System_timeout

FROM
    [PortfolioProject].[dbo].[Transactions$]
WHERE
    feedback LIKE '%System error%' OR feedback LIKE '%timeout%'
	
-- If not system error or timeout error then customer related errors 
SELECT
    COUNT(transactionid) AS customer_related_errors_count
FROM
     [PortfolioProject].[dbo].[Transactions$]
WHERE
    feedback IS NOT NULL
    AND feedback NOT LIKE '%System error%'
    AND feedback NOT LIKE '%timeout%'
	AND Feedback NOT LIKE '%Approved%'

-- Approved vs failed and declined transactions
	SELECT 
    PaymentMethod,
    SUM(CASE 
            WHEN [Feeback Status] = 'Approved' THEN 1 
            ELSE 0 
        END) AS ApprovedCount,
    SUM(CASE 
            WHEN [Feeback Status] IN ('Failed', 'Declined') THEN 1 
            ELSE 0 
        END) AS Transaction_Fail
FROM [PortfolioProject].[dbo].[Transactions$]
Where PaymentMethod is not null 
GROUP BY PaymentMethod;

--Product category with the highest declined and failure rates
SELECT 
    ProductCategory,
    SUM(CASE 
            WHEN [Feeback status] IN ('Failed', 'Declined') THEN 1 
            ELSE 0 
        END) AS FailedOrDeclined,
    CAST(SUM(CASE WHEN [Feeback status] IN ('Failed', 'Declined') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS FailureRatePercent
FROM [PortfolioProject].[dbo].[Transactions$]
Where ProductCategory is not null 
GROUP BY ProductCategory
ORDER BY FailureRatePercent DESC;

--Top 5 countries with highest approval rates 
SELECT TOP 5
    Country,
    COUNT(*) AS TotalTransactions,
    SUM(CASE 
            WHEN [Feeback status] = 'Approved' THEN 1 
            ELSE 0 
        END) AS ApprovedTransactions,
    SUM(TRY_CAST(Price AS FLOAT)) AS TotalAmount,
    SUM(CASE 
            WHEN [Feeback status] = 'Approved' THEN TRY_CAST(Price AS FLOAT) 
            ELSE 0 
        END) AS ApprovedAmount,
    CAST(SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ApprovalRate
FROM 
[PortfolioProject].[dbo].[Transactions$]
GROUP BY Country
ORDER BY ApprovalRate DESC;


-- monthly approved vs decline rates
SELECT 
  Format(try_cast(purchasedate as date) , 'yyyy-MM') as Month,
    SUM(CASE WHEN [Feeback status] = 'Approved' THEN 1 ELSE 0 END) AS Approved,
    SUM(CASE WHEN [Feeback status] = 'Declined' THEN 1 ELSE 0 END) AS Declined,
    SUM(CASE WHEN [Feeback status] = 'Failed' THEN 1 ELSE 0 END) AS Failed
FROM [PortfolioProject].[dbo].[Transactions$]
where PurchaseDate is not null 
GROUP BY Format(try_cast(purchasedate as date) , 'yyyy-MM')
ORDER BY Month

--Identity the types of errors affecting transactions from payment, customer, issuer, system error, timeout
SELECT
  ErrorType,
  SUM(CASE WHEN [Feeback status] = 'approved' THEN 1 ELSE 0 END) AS Approved,
  SUM(CASE WHEN [Feeback status] = 'declined' THEN 1 ELSE 0 END) AS Declined,
  SUM(CASE WHEN [Feeback status] = 'failed' THEN 1 ELSE 0 END) AS Failed,
  COUNT(*) AS Total
FROM (
  SELECT *,
    CASE 
      WHEN Feedback IS NULL THEN 'Unknown'
      WHEN LOWER(Feedback) LIKE '%timeout%' THEN 'System Timeout'
      WHEN LOWER(Feedback) LIKE '%system%' OR LOWER(Feedback) LIKE '%internal%' THEN 'System Error'
      WHEN LOWER(Feedback) LIKE '%card%' OR LOWER(Feedback) LIKE '%invalid%' OR LOWER(Feedback) LIKE '%expired%' THEN 'Payment Error'
      WHEN LOWER(Feedback) LIKE '%do not honor%' THEN 'Issuer Rejection'
      ELSE 'Customer Error'
    END AS ErrorType
  FROM [PortfolioProject].[dbo].[Transactions$]
) AS Categorized
GROUP BY ErrorType
ORDER BY Total DESC;
