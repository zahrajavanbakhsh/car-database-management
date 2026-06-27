-- TEST SCRIPT FOR ALL FUNCTIONS (DATA-AGNOSTIC APPROACH)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN FunctionTestsTran;
PRINT '======================================================';
PRINT '--- 1. ISOLATED MOCK DATA SETUP FOR FUNCTIONS ---';
PRINT '======================================================';

-- 1. Mock Manufacturer
INSERT INTO Manufacturer (Name, Country) VALUES ('FuncBrand', 'TestLand');
DECLARE @ManufID INT = SCOPE_IDENTITY();

-- 2. Mock Cars
INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-FUNC-01', @ManufID, 'FuncModel_A', 2022, 100.00, 20000.00, 'Available'),
       ('VIN-FUNC-02', @ManufID, 'FuncModel_B', 2020, 50.00, 15000.00, 'Available');
DECLARE @Car1 INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-FUNC-01');
DECLARE @Car2 INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-FUNC-02');

-- 3. Mock Customer
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone)
VALUES ('FUNC-CUST', 'Func', 'User', '09200000000');
DECLARE @CustID INT = SCOPE_IDENTITY();

-- 4. Mock Reservations (1 Active for checking availability, 2 Completed for counting)
-- Active reservation for Car1 (Oct 1 to Oct 10)
INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, Status)
VALUES (@CustID, @Car1, '2026-10-01', '2026-10-10', 'Active');

-- Completed reservations for Car2
INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, Status)
VALUES (@CustID, @Car2, '2026-01-01', '2026-01-05', 'Completed'),
       (@CustID, @Car2, '2026-02-01', '2026-02-05', 'Completed');

-- 5. Mock Repair (For Car1 Condition Report)
INSERT INTO Repair (CarID, RepairDate, Description, Cost)
VALUES (@Car1, '2026-05-01', 'Brake Pad Replacement', 120.00);

PRINT '>>> MOCK DATA READY <<<';
PRINT '';


PRINT '======================================================';
PRINT '--- 2. EXECUTING FUNCTION TESTS ---';
PRINT '======================================================';

PRINT 'TEST 1: fn_CalculateRentalCost';
PRINT 'Scenario: Renting Car1 (100/day) for 5 days. EXPECTED: 500.00';
SELECT dbo.fn_CalculateRentalCost(@Car1, 5) AS [Calculated Rental Cost];
PRINT '';


PRINT 'TEST 2: fn_CheckCarAvailability';
PRINT 'Scenario A: Try to rent Car1 from Oct 5 to Oct 15 (Overlaps with active reservation). EXPECTED: 0 (False)';
SELECT dbo.fn_CheckCarAvailability(@Car1, '2026-10-05', '2026-10-15') AS [Is Available (Overlapping)];

PRINT 'Scenario B: Try to rent Car2 from Oct 5 to Oct 15 (No active reservations). EXPECTED: 1 (True)';
SELECT dbo.fn_CheckCarAvailability(@Car2, '2026-10-05', '2026-10-15') AS [Is Available (Free)];
PRINT '';


PRINT 'TEST 3: fn_GetCustomerTotalReservations';
PRINT 'Scenario: Count completed reservations for our mock customer. EXPECTED: 2';
SELECT dbo.fn_GetCustomerTotalReservations(@CustID) AS [Total Completed Reservations];
PRINT '';


PRINT 'TEST 4: fn_AdvancedCarSearch';
PRINT 'Scenario: Search for ''FuncBrand'' and ''FuncModel_A'' that are for rent.';
SELECT * FROM dbo.fn_AdvancedCarSearch('FuncBrand', 'FuncModel_A', 1, 0);
PRINT '';


PRINT 'TEST 5: fn_GetCarConditionReport';
PRINT 'Scenario: Get condition and repair history for Car1.';
SELECT * FROM dbo.fn_GetCarConditionReport(@Car1);
PRINT '';


ROLLBACK TRAN FunctionTestsTran;
PRINT '======================================================';
PRINT '--- 3. CLEANUP COMPLETE (Database remains untouched) ---';
PRINT '======================================================';
GO