USE CarManagement_Final;
GO

-- 1. renting a car (Register New Reservation)
DROP PROCEDURE IF EXISTS sp_RegisterNewReservation;
GO
CREATE PROCEDURE sp_RegisterNewReservation
    @CustomerID INT,
    @CarID INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @PaymentMethod NVARCHAR(50) 
AS
BEGIN
    DECLARE @AccStatus NVARCHAR(20);
    DECLARE @IsAvailable BIT;
    DECLARE @TotalCost DECIMAL(18,2);
    DECLARE @NewResID INT;

    SELECT @AccStatus = AccountStatus 
    FROM Customer 
    WHERE CustomerID = @CustomerID;
    
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
        
        UPDATE Customer 
        SET WalletBalance = WalletBalance - @TotalCost 
        WHERE CustomerID = @CustomerID;

        INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, TotalAmount, Status)
        VALUES (@CustomerID, @CarID, @StartDate, @EndDate, @TotalCost, 'Active');

        SET @NewResID = SCOPE_IDENTITY(); 

        INSERT INTO Payment (ReservationID, Amount, PaymentDate, Method)
        VALUES (@NewResID, @TotalCost, GETDATE(), @PaymentMethod);

        UPDATE Car 
        SET CurrentStatus = 'Rented' 
        WHERE CarID = @CarID;

    COMMIT TRAN;
    
    PRINT 'Reservation successful: The rental fee was paid upfront.';
END;
GO


-- 2. buying a car (Register Car Sale)
DROP PROCEDURE IF EXISTS sp_RegisterCarSale;
GO
CREATE PROCEDURE sp_RegisterCarSale
    @CustomerID INT,
    @CarID INT,
    @EmployeeID INT,
    @FinalPrice DECIMAL(18,2),
    @PaymentMethod NVARCHAR(50)
AS
BEGIN
    DECLARE @CarStatus NVARCHAR(20);
    DECLARE @NewSaleID INT;

    SELECT @CarStatus = CurrentStatus 
    FROM Car 
    WHERE CarID = @CarID;

    IF @CarStatus != 'Available'
    BEGIN
        RAISERROR ('This car is currently unavailable and cannot be sold.', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        
        UPDATE Customer 
        SET WalletBalance = WalletBalance - @FinalPrice 
        WHERE CustomerID = @CustomerID;

        UPDATE Customer 
        SET AccountStatus = CASE WHEN WalletBalance < 0 THEN 'Suspended' ELSE 'Active' END
        WHERE CustomerID = @CustomerID;

        INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate)
        VALUES (@CustomerID, @CarID, @EmployeeID, @FinalPrice, GETDATE());
        
        SET @NewSaleID = SCOPE_IDENTITY(); 

        INSERT INTO Payment (SaleID, Amount, PaymentDate, Method)
        VALUES (@NewSaleID, @FinalPrice, GETDATE(), @PaymentMethod);

        UPDATE Car 
        SET CurrentStatus = 'Sold' 
        WHERE CarID = @CarID;

    COMMIT TRAN;
    
    PRINT 'Sale successful: The customer paid the full amount instantly.';
END;
GO


-- 3. the completion of reservation
DROP PROCEDURE IF EXISTS sp_CompleteReservation;
GO
CREATE PROCEDURE sp_CompleteReservation
    @ReservationID INT
AS
BEGIN
    DECLARE @CarID INT;
    
    SELECT @CarID = CarID 
    FROM Reservation 
    WHERE ReservationID = @ReservationID;

    BEGIN TRAN;
        
        UPDATE Reservation 
        SET Status = 'Completed' 
        WHERE ReservationID = @ReservationID;
        
        UPDATE Car 
        SET CurrentStatus = 'Available' 
        WHERE CarID = @CarID;
        
    COMMIT TRAN;
END;
GO


-- 4. automatic calculation of late fees
DROP PROCEDURE IF EXISTS sp_ProcessCarReturnAndLateFees;
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
            
            PRINT 'The late fee was calculated and credited to the customers account: ' + CAST(@LatePenaltyFee AS NVARCHAR);
        END

        UPDATE Reservation 
        SET Status = 'Completed' 
        WHERE ReservationID = @ReservationID;
        
        UPDATE Car 
        SET CurrentStatus = 'Available' 
        WHERE CarID = @CarID AND CurrentStatus != 'Sold';

    COMMIT TRAN;
END;
GO


-- 5. pay penalty debt
DROP PROCEDURE IF EXISTS sp_PayPenaltyDebt;
GO
CREATE PROCEDURE sp_PayPenaltyDebt
    @ReservationID INT, 
    @Amount DECIMAL(18,2)
AS
BEGIN
    INSERT INTO Payment (ReservationID, Amount, PaymentDate, Method)
    VALUES (@ReservationID, @Amount, GETDATE(), 'Cash');
    
    PRINT 'Penalty payment recorded successfully.';
END;
GO


-- 6. full log of a history of a car
DROP PROCEDURE IF EXISTS sp_GetCarHistoryTimeline;
GO
CREATE PROCEDURE sp_GetCarHistoryTimeline
    @CarID INT
AS
BEGIN
    SELECT 
        'Reservation' AS ActivityType, 
        StartDate AS ActivityDate, 
        'Reserved by Customer ID: ' + CAST(CustomerID AS NVARCHAR) AS Description 
    FROM Reservation 
    WHERE CarID = @CarID
    
    UNION ALL
    
    SELECT 
        'Maintenance' AS ActivityType, 
        RepairDate AS ActivityDate, 
        Description 
    FROM Repair 
    WHERE CarID = @CarID 
    
    ORDER BY ActivityDate DESC;
END;
GO


-- 7. Stored Procedure for verifying user credentials from the application
DROP PROCEDURE IF EXISTS sp_UserLogin;
GO
CREATE PROCEDURE sp_UserLogin
    @InputUsername NVARCHAR(50),
    @InputPassword NVARCHAR(256)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM AppUser WHERE Username = @InputUsername AND Password = @InputPassword)
    BEGIN
        SELECT 
            Username, 
            Role, 
            ISNULL(CAST(CustomerID AS NVARCHAR), 'N/A') AS CustomerID, 
            ISNULL(CAST(EmployeeID AS NVARCHAR), 'N/A') AS EmployeeID, 
            'Login Successful' AS StatusMessage
        FROM AppUser 
        WHERE Username = @InputUsername AND Password = @InputPassword;
    END
    ELSE
    BEGIN
        RAISERROR ('Invalid Username or Password!', 16, 1);
    END
END;
GO