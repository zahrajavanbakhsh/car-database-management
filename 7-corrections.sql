-- corrections
-- correction the method of buying a car
GO
ALTER PROCEDURE sp_RegisterCarSale
    @CustomerID INT,
    @CarID INT,
    @EmployeeID INT,
    @FinalPrice DECIMAL(18,2),
    @PaymentMethod NVARCHAR(50)
AS
BEGIN
    DECLARE @CarStatus NVARCHAR(20);
    DECLARE @NewSaleID INT;

    SELECT @CarStatus = CurrentStatus FROM Car WHERE CarID = @CarID;

    IF @CarStatus != 'Available'
    BEGIN
        RAISERROR ('This car is currently unavailable and cannot be sold..', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        
        INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate)
        VALUES (@CustomerID, @CarID, @EmployeeID, @FinalPrice, GETDATE());
        
        SET @NewSaleID = SCOPE_IDENTITY(); 

        INSERT INTO Payment (SaleID, Amount, PaymentDate, Method)
        VALUES (@NewSaleID, @FinalPrice, GETDATE(), @PaymentMethod);

        UPDATE Car SET CurrentStatus = 'Sold' WHERE CarID = @CarID;

    COMMIT TRAN;
    
    PRINT 'Succesfull with full payment';
END;
GO

-- correction of searching for a car
DROP PROCEDURE IF EXISTS sp_AdvancedCarSearch;
GO

CREATE FUNCTION fn_AdvancedCarSearch 
(
    @BrandName NVARCHAR(100) = NULL,
    @ModelName NVARCHAR(50) = NULL,
    @IsForRent BIT = 0,
    @IsForSale BIT = 0
)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        c.VIN,
        m.Name AS Brand,
        c.Model,
        c.BuildYear,
        c.Mileage,
        c.DailyRentPrice,
        c.BaseSalePrice,
        c.CurrentStatus
    FROM Car c
    JOIN Manufacturer m ON c.ManufacturerID = m.ManufacturerID
    WHERE 
        (@BrandName IS NULL OR m.Name LIKE '%' + @BrandName + '%')
        AND (@ModelName IS NULL OR c.Model LIKE '%' + @ModelName + '%')
        AND (@IsForRent = 0 OR c.DailyRentPrice > 0)
        AND (@IsForSale = 0 OR c.BaseSalePrice > 0)
        AND c.CurrentStatus IN ('Available', 'Rented')
);
GO

-- correction of the state of a car for customer
DROP PROCEDURE IF EXISTS sp_GetCarConditionReport;
GO

CREATE FUNCTION fn_GetCarConditionReport 
(
    @CarID INT
)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        c.VIN, 
        c.Model, 
        c.BuildYear, 
        c.Mileage AS CurrentMileage,
        c.CurrentStatus,
        r.RepairDate, 
        r.Description AS RepairDetails, 
        ISNULL(r.Cost, 0) AS RepairCost
    FROM Car c
    LEFT JOIN Repair r ON c.CarID = r.CarID
    WHERE c.CarID = @CarID
);
GO