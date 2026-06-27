-- populate database (ISOLATED DEMO)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN PopulateDemoTran;
PRINT '--- TRANSACTION STARTED: POPULATE & PROCESS DATA ---';

-- ==========================================
-- 0. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';
INSERT INTO Manufacturer (Name, Country) VALUES ('MockBrand1', 'Germany'), ('MockBrand2', 'Iran');
DECLARE @Manuf1 INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'MockBrand1');
DECLARE @Manuf2 INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'MockBrand2');

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus)
VALUES ('1111111110', 'Mahdi', 'K', '09111111110', 50000.00, 'Active'),
       ('1111111111', 'Zahra', 'J', '09111111111', 50000.00, 'Active');
DECLARE @MahdiID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1111111110');
DECLARE @ZahraID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1111111111');

INSERT INTO Employee (NationalCode, FirstName, LastName, Position)
VALUES ('2222222220', 'Mina', 'A', 'Agent'),
       ('2222222221', 'Ali', 'F', 'Manager');
DECLARE @MinaID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222220');
DECLARE @AliID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222221');

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-POP-BMW', @Manuf1, 'BMW', 2023, 150.00, 65000.00, 'Available'),
       ('VIN-POP-PERAID', @Manuf2, 'Peraid', 2002, 6.00, 2800.00, 'Available'),
       ('VIN-POP-PEZHO', @Manuf2, 'Pezho', 2005, 10.00, 4000.00, 'Available');
DECLARE @BMW_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-POP-BMW');
DECLARE @Peraid_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-POP-PERAID');
DECLARE @Pezho_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-POP-PEZHO');
PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- ==========================================
-- 1. RUNNING TRANSACTIONS
-- ==========================================
PRINT 'SCENARIO 1: Mina sells the Peraid to Zahra';
EXEC dbo.sp_RegisterCarSale @CustomerID = @ZahraID, @CarID = @Peraid_ID, @EmployeeID = @MinaID, @FinalPrice = 2800.00, @PaymentMethod = 'Credit Card';

PRINT 'SCENARIO 2: Insert a brand new demo car and Ali sells it to Mahdi';
INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-DEMO-ALI-007', @Manuf1, 'Demo Car', 2026, 50.00, 30000.00, 'Available');
DECLARE @NewCarID INT = SCOPE_IDENTITY();
EXEC dbo.sp_RegisterCarSale @CustomerID = @MahdiID, @CarID = @NewCarID, @EmployeeID = @AliID, @FinalPrice = 35000.00, @PaymentMethod = 'Bank Transfer';

PRINT 'SCENARIO 3: Mahdi rents the BMW, returns it, and car goes to repair';
EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @BMW_ID, @StartDate = '2026-07-01', @EndDate = '2026-07-10', @PaymentMethod = 'Cash';
DECLARE @ResBMW INT = (SELECT TOP 1 ReservationID FROM Reservation WHERE CarID = @BMW_ID ORDER BY ReservationID DESC);
EXEC dbo.sp_ProcessCarReturnAndLateFees @ReservationID = @ResBMW, @ActualReturnDate = '2026-07-10';
INSERT INTO Repair (CarID, RepairDate, Description, Cost) VALUES (@BMW_ID, '2026-07-11', 'Routine Maintenance & Oil Change', 150.00);

PRINT 'SCENARIO 4: Zahra rents the Pezho, returns it, and car needs gearbox repair';
EXEC dbo.sp_RegisterNewReservation @CustomerID = @ZahraID, @CarID = @Pezho_ID, @StartDate = '2026-08-01', @EndDate = '2026-08-05', @PaymentMethod = 'Credit Card';
DECLARE @ResPezho INT = (SELECT TOP 1 ReservationID FROM Reservation WHERE CarID = @Pezho_ID ORDER BY ReservationID DESC);
EXEC dbo.sp_ProcessCarReturnAndLateFees @ReservationID = @ResPezho, @ActualReturnDate = '2026-08-05';
INSERT INTO Repair (CarID, RepairDate, Description, Cost) VALUES (@Pezho_ID, '2026-08-06', 'Gearbox Repair', 800.00);

ROLLBACK TRAN PopulateDemoTran;
PRINT '';
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO