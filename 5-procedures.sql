-- procedures
-- renting a car
GO
CREATE PROCEDURE sp_RegisterNewReservation
    @CustomerID INT,
    @CarID INT,
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    DECLARE @AccStatus NVARCHAR(20);
    DECLARE @IsAvailable BIT;
    DECLARE @TotalCost DECIMAL(18,2);

    SELECT @AccStatus = AccountStatus FROM Customer WHERE CustomerID = @CustomerID;
    IF @AccStatus = 'Debt' OR @AccStatus = 'Suspended'
    BEGIN
        RAISERROR ('Operation canceled: The customer has an outstanding debt or is suspended.', 16, 1);
        RETURN;
    END

    SET @IsAvailable = dbo.fn_CheckCarAvailability(@CarID, @StartDate, @EndDate);
    IF @IsAvailable = 0
    BEGIN
        RAISERROR ('Operation cancelled: The car is reserved on this date.', 16, 1);
        RETURN;
    END

    SET @TotalCost = dbo.fn_CalculateRentalCost(@CarID, DATEDIFF(DAY, @StartDate, @EndDate));

    BEGIN TRAN;
        INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, TotalAmount, Status)
        VALUES (@CustomerID, @CarID, @StartDate, @EndDate, @TotalCost, 'Active');

        UPDATE Car SET CurrentStatus = 'Rented' WHERE CarID = @CarID;
    COMMIT TRAN;
END;

-- buying a car
GO
CREATE PROCEDURE sp_RegisterCarSale
    @CustomerID INT,
    @CarID INT,
    @EmployeeID INT,
    @FinalPrice DECIMAL(18,2)
AS
BEGIN
    DECLARE @CarStatus NVARCHAR(20);
    SELECT @CarStatus = CurrentStatus FROM Car WHERE CarID = @CarID;

    IF @CarStatus = 'Rented'
    BEGIN
        RAISERROR ('You cannot sell a car that is being leased.', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate)
        VALUES (@CustomerID, @CarID, @EmployeeID, @FinalPrice, GETDATE());

        UPDATE Car SET CurrentStatus = 'Sold' WHERE CarID = @CarID;
    COMMIT TRAN;
END;

-- the complition of reservation
GO
CREATE PROCEDURE sp_CompleteReservation
    @ReservationID INT
AS
BEGIN
    DECLARE @CarID INT;
    SELECT @CarID = CarID FROM Reservation WHERE ReservationID = @ReservationID;

    BEGIN TRAN;
        UPDATE Reservation SET Status = 'Completed' WHERE ReservationID = @ReservationID;
        UPDATE Car SET CurrentStatus = 'Available' WHERE CarID = @CarID;
    COMMIT TRAN;
END;


-- full log of a history of a car
GO
CREATE PROCEDURE sp_GetCarHistoryTimeline
    @CarID INT
AS
BEGIN
    SELECT 
        'Reservation' AS ActivityType, 
        StartDate AS ActivityDate, 
        'Reserved by Customer ID: ' + CAST(CustomerID AS NVARCHAR) AS Description
    FROM Reservation WHERE CarID = @CarID
    
    UNION ALL
    
    SELECT 
        'Maintenance' AS ActivityType, 
        RepairDate AS ActivityDate, 
        Description
    FROM Repair WHERE CarID = @CarID
    
    ORDER BY ActivityDate DESC;
END;

-- dynamic filtering for customers
GO
CREATE PROCEDURE sp_AdvancedCarSearch
    @BrandName NVARCHAR(100) = NULL,
    @ModelName NVARCHAR(50) = NULL,
    @IsForRent BIT = 0,
    @IsForSale BIT = 0
AS
BEGIN
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
        AND c.CurrentStatus IN ('Available', 'Rented');
END;
GO

-- show the full state of all cars for customers
GO
CREATE PROCEDURE sp_GetCarConditionReport
    @CarID INT
AS
BEGIN
    SELECT 
        VIN, 
        Model, 
        BuildYear, 
        Mileage AS CurrentMileage,
        CurrentStatus
    FROM Car WHERE CarID = @CarID;

    SELECT 
        RepairDate, 
        Description AS RepairDetails, 
        Cost
    FROM Repair 
    WHERE CarID = @CarID
    ORDER BY RepairDate DESC;
END;
GO

-- automatic calculation of late fees
GO
CREATE PROCEDURE sp_ProcessCarReturnAndLateFees
    @ReservationID INT,
    @ActualReturnDate DATETIME
AS
BEGIN
    DECLARE @ExpectedEndDate DATETIME;
    DECLARE @CustomerID INT;
    DECLARE @CarID INT;
    DECLARE @DailyRentPrice DECIMAL(18,2);
    DECLARE @LateDays INT;
    DECLARE @LatePenaltyFee DECIMAL(18,2) = 0;

    SELECT 
        @ExpectedEndDate = r.EndDate, 
        @CustomerID = r.CustomerID, 
        @CarID = r.CarID,
        @DailyRentPrice = c.DailyRentPrice
    FROM Reservation r
    JOIN Car c ON r.CarID = c.CarID
    WHERE r.ReservationID = @ReservationID;

    BEGIN TRAN;
        IF @ActualReturnDate > @ExpectedEndDate
        BEGIN
            SET @LateDays = DATEDIFF(DAY, @ExpectedEndDate, @ActualReturnDate);
            SET @LatePenaltyFee = @LateDays * (@DailyRentPrice * 1.5);

            UPDATE Customer 
            SET WalletBalance = WalletBalance - @LatePenaltyFee 
            WHERE CustomerID = @CustomerID;

            UPDATE Customer 
            SET AccountStatus = 'Debt' 
            WHERE CustomerID = @CustomerID AND WalletBalance < 0;
            
            PRINT 'The late fee was calculated and credited to the customers account' + CAST(@LatePenaltyFee AS NVARCHAR);
        END

        UPDATE Reservation SET Status = 'Completed' WHERE ReservationID = @ReservationID;
        UPDATE Car SET CurrentStatus = 'Available' WHERE CarID = @CarID AND CurrentStatus != 'Sold';
    
    COMMIT TRAN;
END;
GO