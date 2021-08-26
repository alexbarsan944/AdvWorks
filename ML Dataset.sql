
--MONTHLY SPENDINGS BY CustomerID 
ALTER VIEW vMonthlySpendings AS 
Select CustomerID,  (CAST(TotalDue AS int) / (SELECT COUNT(
	DISTINCT FORMAT (OrderDate, 'MM-yyyy')
	) from Sales.SalesOrderHeader)) as "MonthlySpendings"
FROM Sales.SalesOrderHeader soh
group by CustomerID, TotalDue
order by CustomerID OFFSET 0 ROWS;

--AVG MONTHLY SPENDINGS BY CustomerID 
ALTER VIEW vAvgMonthlySpendings AS 
select CustomerID, AVG(MonthlySpendings) as AvgMonthlySpendings
from vMonthlySpendings
WHERE MonthlySpendings > 10
group by CustomerID
order by CustomerID OFFSET 0 ROWS;

select * from vAvgMonthlySpendings;
 

-- Create BikeBuyers view
ALTER VIEW BikeBuyers
AS
select DISTINCT fis.CustomerKey, 1 as Buyer from AdventureWorksDW2019.dbo.FactInternetSales fis  
JOIN AdventureWorksDW2019.dbo.DimProduct dp on dp.ProductKey = fis.ProductKey
WHERE dp.ProductSubcategoryKey IN (1,2,3)
GROUP BY fis.CustomerKey;


-- Create NonBikeBuyers view
ALTER VIEW NonBikeBuyers
AS
WITH CustomerIDList (CustomerID)  
AS  
(  
    select bb.CustomerKey from BikeBuyers bb 
)
SELECT DISTINCT fis.CustomerKey as CustomerKey, 0 as Buyer from dbo.FactInternetSales fis
where fis.CustomerKey not in (Select * from CustomerIDList)
ORDER BY 1 OFFSET 0 ROWS;  

-- Create Bikers view (merged)
Create VIEW temp
AS
select * from BikeBuyers bb2
UNION 
select * from NonBikeBuyers nbb2 
ORDER BY CUSTOMERKEY OFFSET 0 ROWS;

ALTER VIEW Bikers
AS
select * from temp order by CustomerKey OFFSET 0 ROWS;


SELECT * from Bikers b ;



-- Procedure that returns the age from datetime
ALTER FUNCTION dbo.get_age(@t DATETIME) RETURNS INT
BEGIN	
	DECLARE @return_value INT;
	BEGIN
		IF DATEDIFF(mm, @t, getdate()) /12 = 0
			SET @return_value = 0
		ELSE
			SET @return_value = DATEDIFF(mm, @t ,getdate())/12
			RETURN @return_value
	END
END;

SELECT dbo.get_age('05/10/1999') AS Age;


-- Months by bike sales qty
ALTER VIEW Months_by_qty 
AS
select FORMAT (OrderDate, 'MM ') as OrderDate, count(CustomerID) BikeSalesQty
from AdventureWorks2016_EXT.Sales.SalesOrderHeader soh 
inner join BikeBuyers bb on bb.CustomerKey = soh.CustomerID 
where bb.Buyer = 1
group by OrderDate
order by 2 desc OFFSET 0 ROWS;

ALTER VIEW All_months_by_qty 
AS
select OrderDate, count(BikeSalesQty) BikeSalesQty from Months_by_qty
group by OrderDate
order by BikeSalesQty desc
OFFSET 0 ROWS;
 
select * from dbo.All_months_by_qty;

 
-- Last order date for CustomerID 
ALTER VIEW LastOrder
AS
SELECT  CustomerID, OrderDate  
FROM
( 
SELECT CustomerID, OrderDate, ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate desc) AS IndexNo  
	FROM AdventureWorks2016_EXT.Sales.SalesOrderHeader soh) as temp
WHERE IndexNo = 1;


-- Create customer data
ALTER view CustomerData
as
select 
	DISTINCT dc.CustomerKey,
	vd.IncomeGroup,
	bb.Buyer AS BikeBuyer,
	dc.GeographyKey,
	dc.FirstName + ' ' + dc.LastName as FullName, 
	dbo.get_age(dc.BirthDate) AS Age,
	dc.Gender,
	dc.YearlyIncome,
	dc.TotalChildren,
	dc.NumberChildrenAtHome,
	dc.EnglishEducation,
	dc.EnglishOccupation,
	dc.HouseOwnerFlag,
	dc.MaritalStatus,
	dc.NumberCarsOwned,
	DATEDIFF(mm, lo.OrderDate, '1.01.2016') AS MonthsSinceLastPurchase,
	dc.CommuteDistance
from DimCustomer dc 
INNER JOIN dbo.LastOrder lo on lo.CustomerID = dc.CustomerKey
INNER JOIN dbo.Bikers bb on bb.CustomerKey = dc.CustomerKey
INNER JOIN AdventureWorksDW2019.dbo.vDMPrep vd on bb.CustomerKey = vd.CustomerKey 
order by CustomerKey OFFSET 0 ROWS;

select * from CustomerData;







