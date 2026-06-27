-- TEST SCRIPT FOR ALL TRIGGERS (DATA-AGNOSTIC APPROACH)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

PRINT '======================================================';
PRINT '--- 1. ISOLATED MOCK DATA SETUP FOR TRIGGERS ---';
PRINT '======================================================';

-- PRE-CLEANUP
DELETE FROM Payment WHERE ReservationID IN (SELECT ReservationID FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode LIKE 'TRIG-%'));
DELETE FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode LIKE 'TRIG-%');
DELETE FROM Repair WHERE CarID IN (SELECT CarID FROM Car WHERE VIN LIKE 'VIN-TRIG-%');
DELETE FROM Car WHERE VIN LIKE 'VIN-TRIG-%';
DELETE FROM Customer WHERE NationalCode LIKE 'TRIG-%';
DELETE FROM Manufacturer WHERE Name = 'TrigBrand';

-- INSERT MOCK DATA
INSERT INTO Manufacturer (Name, Country) VALUES ('TrigBrand', 'TestLand');
DECLARE @ManufID INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'TrigBrand');

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-TRIG-01', @ManufID, 'SoldCar', 2020, 50.00, 20000.00, 'Sold'),
       ('VIN-TRIG-02', @ManufID, 'RepairCar', 2021, 60.00, 25000.00, 'Maintenance'),
       ('VIN-TRIG-03', @ManufID, 'NormalCar', 2022, 70.00, 30000.00, 'Available'),
       ('VIN-TRIG-04', @ManufID, 'PayCar', 2022, 70.00, 30000.00, 'Available'); -- ADDED FOR TEST 4
       
DECLARE @SoldCar INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TRIG-01');
DECLARE @RepairCar INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TRIG-02');
DECLARE @NormalCar INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TRIG-03');
DECLARE @PayCar INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TRIG-04');

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus)
VALUES ('TRIG-C1', 'Tom', 'Debt', '09400000001', -100.00, 'Debt'),
       ('TRIG-C2', 'Bob', 'Active', '09400000002', 500.00, 'Active');
DECLARE @DebtCust INT = (SELECT CustomerID FROM Customer WHERE NationalCode = 'TRIG-C1');
DECLARE @ActiveCust INT = (SELECT CustomerID FROM Customer WHERE NationalCode = 'TRIG-C2');

PRINT '>>> MOCK DATA READY <<<';
PRINT '';

PRINT '======================================================';
PRINT '--- 2. EXECUTING TRIGGER TESTS ---';
PRINT '======================================================';

PRINT 'TEST 1: trg_PreventResellingSoldCar';
BEGIN TRY
    UPDATE Car SET CurrentStatus = 'Available' WHERE CarID = @SoldCar;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [TRIGGER SHIELD: Prevent Reselling Sold Car];
END CATCH;
PRINT '';

PRINT 'TEST 2: trg_PreventInvalidReservations';
BEGIN TRY
    INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, Status)
    VALUES (@ActiveCust, @RepairCar, '2026-10-01', '2026-10-05', 'Active');
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [TRIGGER SHIELD: Prevent Invalid Reservation];
END CATCH;
PRINT '';

PRINT 'TEST 3: trg_AutoMaintenanceStatus';
INSERT INTO Repair (CarID, RepairDate, Description, Cost) VALUES (@NormalCar, GETDATE(), 'Engine Check', 50.00);
SELECT CurrentStatus AS [Car Status (Should automatically become MAINTENANCE)] FROM Car WHERE CarID = @NormalCar;
PRINT '';

PRINT 'TEST 4: trg_UpdateCustomerAccountStatus';
INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, Status) VALUES (@DebtCust, @PayCar, GETDATE(), GETDATE(), 'Completed');
DECLARE @FakeRes INT = (SELECT TOP 1 ReservationID FROM Reservation WHERE CustomerID = @DebtCust ORDER BY ReservationID DESC);
INSERT INTO Payment (ReservationID, Amount, PaymentDate, Method) VALUES (@FakeRes, 200.00, GETDATE(), 'Cash');
SELECT WalletBalance AS [Wallet (Should be 100.00)], AccountStatus AS [Status (Should auto-switch to ACTIVE)] FROM Customer WHERE CustomerID = @DebtCust;
PRINT '';

PRINT 'TEST 5: trg_AutoUpdateAccountStatus';
UPDATE Customer SET WalletBalance = -50.00 WHERE CustomerID = @ActiveCust;
SELECT AccountStatus AS [Status (Should auto-switch to SUSPENDED)] FROM Customer WHERE CustomerID = @ActiveCust;
PRINT '';

PRINT '======================================================';
PRINT '--- 3. CLEANUP MOCK DATA (Database restored) ---';
PRINT '======================================================';
-- POST-CLEANUP
DELETE FROM Payment WHERE ReservationID IN (SELECT ReservationID FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode LIKE 'TRIG-%'));
DELETE FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode LIKE 'TRIG-%');
DELETE FROM Repair WHERE CarID IN (SELECT CarID FROM Car WHERE VIN LIKE 'VIN-TRIG-%');
DELETE FROM Car WHERE VIN LIKE 'VIN-TRIG-%';
DELETE FROM Customer WHERE NationalCode LIKE 'TRIG-%';
DELETE FROM Manufacturer WHERE Name = 'TrigBrand';
GO