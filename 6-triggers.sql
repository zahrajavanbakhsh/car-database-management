-- triggers
-- cant change a state of a car that being selled
GO
CREATE TRIGGER trg_PreventResellingSoldCar
ON Car
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.CarID = d.CarID
        WHERE d.CurrentStatus = 'Sold' AND i.CurrentStatus != 'Sold'
    )
    BEGIN
        RAISERROR ('Logical error: A sold vehicle is permanently removed from the fleet and its status cannot be changed.', 16, 1);
        ROLLBACK TRAN;
    END
END;

-- cant reserve a car under repairing
GO
CREATE TRIGGER trg_AutoMaintenanceStatus
ON Repair
AFTER INSERT
AS
BEGIN
    DECLARE @CarID INT;
    SELECT @CarID = CarID FROM inserted;

    UPDATE Car 
    SET CurrentStatus = 'Maintenance' 
    WHERE CarID = @CarID AND CurrentStatus != 'Sold';
END;

-- update the state of a payment acoount of a customer after paying
GO
CREATE TRIGGER trg_UpdateCustomerAccountStatus
ON Payment
AFTER INSERT
AS
BEGIN
    DECLARE @ResID INT, @SaleID INT, @Amount DECIMAL(18,2), @CustID INT;
    
    SELECT @ResID = ReservationID, @SaleID = SaleID, @Amount = Amount FROM inserted;

    IF @ResID IS NOT NULL
        SELECT @CustID = CustomerID FROM Reservation WHERE ReservationID = @ResID;
    ELSE IF @SaleID IS NOT NULL
        SELECT @CustID = CustomerID FROM Sale WHERE SaleID = @SaleID;

    IF @CustID IS NOT NULL
    BEGIN
        UPDATE Customer 
        SET WalletBalance = WalletBalance + @Amount
        WHERE CustomerID = @CustID;

        UPDATE Customer
        SET AccountStatus = 'Active'
        WHERE CustomerID = @CustID AND WalletBalance >= 0;
    END
END;

-- prevent of reservation of a sold car
GO
CREATE TRIGGER trg_PreventInvalidReservations
ON Reservation
AFTER INSERT
AS
BEGIN
    DECLARE @CarStatus NVARCHAR(20);
    DECLARE @InsertedCarID INT;

    SELECT @InsertedCarID = CarID FROM inserted;
    SELECT @CarStatus = CurrentStatus FROM Car WHERE CarID = @InsertedCarID;

    IF @CarStatus IN ('Sold', 'Maintenance')
    BEGIN
        RAISERROR ('Logical error: This car has been sold or is under repair and cannot be reserved.', 16, 1);
        ROLLBACK TRAN;
    END
END;
GO