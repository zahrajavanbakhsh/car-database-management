USE CarManagement_Final;
GO

-- 1. cant change a state of a car that being selled
CREATE TRIGGER trg_PreventResellingSoldCar 
ON Car 
AFTER UPDATE
AS 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted i 
        JOIN deleted d ON i.CarID = d.CarID 
        WHERE d.CurrentStatus = 'Sold' AND i.CurrentStatus != 'Sold'
    ) 
    BEGIN 
        RAISERROR ('Logical error: A sold vehicle is permanently removed from the fleet and its status cannot be changed.', 16, 1); 
        ROLLBACK TRAN; 
    END
END;
GO


-- 2. cant reserve a car under repairing
CREATE TRIGGER trg_AutoMaintenanceStatus 
ON Repair 
AFTER INSERT
AS 
BEGIN
    DECLARE @CarID INT; 
    
    SELECT @CarID = CarID 
    FROM inserted;
    
    UPDATE Car 
    SET CurrentStatus = 'Maintenance' 
    WHERE CarID = @CarID AND CurrentStatus != 'Sold';
END;
GO


-- 3. prevent of reservation of a sold car
CREATE TRIGGER trg_PreventInvalidReservations 
ON Reservation 
AFTER INSERT
AS 
BEGIN
    DECLARE @CarStatus NVARCHAR(20); 
    DECLARE @InsertedCarID INT;
    
    SELECT @InsertedCarID = CarID 
    FROM inserted; 
    
    SELECT @CarStatus = CurrentStatus 
    FROM Car 
    WHERE CarID = @InsertedCarID;
    
    IF @CarStatus IN ('Sold', 'Maintenance') 
    BEGIN 
        RAISERROR ('Logical error: This car has been sold or is under repair and cannot be reserved.', 16, 1); 
        ROLLBACK TRAN; 
    END
END;
GO


-- 4. update the state of a payment account of a customer after paying
CREATE TRIGGER trg_UpdateCustomerAccountStatus 
ON Payment 
AFTER INSERT
AS 
BEGIN
    -- Update based on Reservations
    UPDATE c 
    SET c.WalletBalance = c.WalletBalance + i.Amount 
    FROM Customer c 
    INNER JOIN Reservation r ON c.CustomerID = r.CustomerID 
    INNER JOIN inserted i ON r.ReservationID = i.ReservationID;
    
    -- Update based on Sales
    UPDATE c 
    SET c.WalletBalance = c.WalletBalance + i.Amount 
    FROM Customer c 
    INNER JOIN Sale s ON c.CustomerID = s.CustomerID 
    INNER JOIN inserted i ON s.SaleID = i.SaleID;
    
    -- Reactivate accounts if balance is sufficient
    UPDATE c 
    SET c.AccountStatus = 'Active' 
    FROM Customer c 
    WHERE c.WalletBalance >= 0 
      AND c.AccountStatus = 'Debt' 
      AND c.CustomerID IN (
          SELECT CustomerID FROM Reservation r INNER JOIN inserted i ON r.ReservationID = i.ReservationID 
          UNION 
          SELECT CustomerID FROM Sale s INNER JOIN inserted i ON s.SaleID = i.SaleID
      );
END;
GO


-- 5. auto update account status after wallet balance changes
CREATE TRIGGER trg_AutoUpdateAccountStatus 
ON Customer 
AFTER UPDATE
AS 
BEGIN
    IF UPDATE(WalletBalance) 
    BEGIN
        UPDATE c 
        SET c.AccountStatus = 
            CASE 
                WHEN i.WalletBalance < 0 THEN 'Suspended' 
                ELSE 'Active' 
            END 
        FROM Customer c 
        INNER JOIN inserted i ON c.CustomerID = i.CustomerID 
        INNER JOIN deleted d ON c.CustomerID = d.CustomerID 
        WHERE i.WalletBalance <> d.WalletBalance;
    END
END;
GO