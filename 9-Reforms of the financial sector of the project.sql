-- Reforms of the financial sector of the project
USE CarManagementDB;
GO

DROP PROCEDURE IF EXISTS dbo.sp_RegisterCarSale;
GO
CREATE PROCEDURE dbo.sp_RegisterCarSale
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
        RAISERROR ('This car is currently unavailable and cannot be sold.', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
        UPDATE Customer 
        SET WalletBalance = WalletBalance - @FinalPrice 
        WHERE CustomerID = @CustomerID;

        INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate)
        VALUES (@CustomerID, @CarID, @EmployeeID, @FinalPrice, GETDATE());
        
        SET @NewSaleID = SCOPE_IDENTITY(); 

        INSERT INTO Payment (SaleID, Amount, PaymentDate, Method)
        VALUES (@NewSaleID, @FinalPrice, GETDATE(), @PaymentMethod);

        UPDATE Car SET CurrentStatus = 'Sold' WHERE CarID = @CarID;

    COMMIT TRAN;
    PRINT 'Sale successful: The customer paid the full amount instantly.';
END;
GO

DROP PROCEDURE IF EXISTS dbo.sp_RegisterNewReservation;
GO
CREATE PROCEDURE dbo.sp_RegisterNewReservation
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
        UPDATE Customer 
        SET WalletBalance = WalletBalance - @TotalCost 
        WHERE CustomerID = @CustomerID;

        INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, TotalAmount, Status)
        VALUES (@CustomerID, @CarID, @StartDate, @EndDate, @TotalCost, 'Active');

        SET @NewResID = SCOPE_IDENTITY(); 

        INSERT INTO Payment (ReservationID, Amount, PaymentDate, Method)
        VALUES (@NewResID, @TotalCost, GETDATE(), @PaymentMethod);

        UPDATE Car SET CurrentStatus = 'Rented' WHERE CarID = @CarID;

    COMMIT TRAN;
    PRINT 'Reservation successful: The rental fee was paid upfront.';
END;
GO

DROP TRIGGER IF EXISTS trg_UpdateCustomerAccountStatus;
GO
CREATE TRIGGER trg_UpdateCustomerAccountStatus
ON Payment
AFTER INSERT
AS
BEGIN
    UPDATE c
    SET c.WalletBalance = c.WalletBalance + i.Amount
    FROM Customer c
    INNER JOIN Reservation r ON c.CustomerID = r.CustomerID
    INNER JOIN inserted i ON r.ReservationID = i.ReservationID;

    UPDATE c
    SET c.WalletBalance = c.WalletBalance + i.Amount
    FROM Customer c
    INNER JOIN Sale s ON c.CustomerID = s.CustomerID
    INNER JOIN inserted i ON s.SaleID = i.SaleID;

    UPDATE c
    SET c.AccountStatus = 'Active'
    FROM Customer c
    WHERE c.WalletBalance >= 0 AND c.AccountStatus = 'Debt'
      AND c.CustomerID IN (
          SELECT CustomerID FROM Reservation r INNER JOIN inserted i ON r.ReservationID = i.ReservationID
          UNION
          SELECT CustomerID FROM Sale s INNER JOIN inserted i ON s.SaleID = i.SaleID
      );
END;
GO

DROP PROCEDURE IF EXISTS dbo.sp_PayPenaltyDebt;
GO
CREATE PROCEDURE dbo.sp_PayPenaltyDebt
    @ReservationID INT, 
    @Amount DECIMAL(18,2)
AS
BEGIN
    INSERT INTO Payment (ReservationID, Amount, PaymentDate, Method)
    VALUES (@ReservationID, @Amount, GETDATE(), 'Cash');
END;
GO