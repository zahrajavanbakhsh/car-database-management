USE CarManagement_Final;
GO

-- functions
-- final rental cost 
CREATE FUNCTION fn_CalculateRentalCost 
(
    @CarID INT,
    @Days INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @DailyPrice DECIMAL(18,2);
    DECLARE @TotalCost DECIMAL(18,2);
    
    SELECT @DailyPrice = DailyRentPrice FROM Car WHERE CarID = @CarID;
    SET @TotalCost = @DailyPrice * @Days;
    
    RETURN @TotalCost;
END;
GO

-- availablity cars for triggers and procejures
CREATE FUNCTION fn_CheckCarAvailability 
(
    @CarID INT,
    @RequestedStartDate DATETIME,
    @RequestedEndDate DATETIME
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAvailable BIT = 1;
    
    IF EXISTS (
        SELECT 1 FROM Reservation 
        WHERE CarID = @CarID 
        AND Status IN ('Confirmed', 'Active')
        AND (StartDate < @RequestedEndDate AND EndDate > @RequestedStartDate)
    )
    BEGIN
        SET @IsAvailable = 0;
    END

    RETURN @IsAvailable;
END;
GO

-- all reservation of a customer for discount
CREATE FUNCTION fn_GetCustomerTotalReservations 
(
    @CustomerID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @ResCount INT;
    
    SELECT @ResCount = COUNT(ReservationID) 
    FROM Reservation 
    WHERE CustomerID = @CustomerID AND Status = 'Completed';
    
    RETURN ISNULL(@ResCount, 0);
END;
GO

-- correction of searching for a car
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