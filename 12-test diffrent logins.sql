-- tests with diffrent logins (FULLY DATA-AGNOSTIC & AUTOMATED)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

-- 0. PRE-CLEANUP (To guarantee a clean state if previous test failed)
DELETE FROM Payment WHERE ReservationID IN (SELECT ReservationID FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode IN ('MULTI-CUST', '0987654321')));
DELETE FROM Reservation WHERE CustomerID IN (SELECT CustomerID FROM Customer WHERE NationalCode IN ('MULTI-CUST', '0987654321'));
DELETE FROM Car WHERE VIN = 'VIN-MULTI-01';
DELETE FROM Manufacturer WHERE Name = 'MultiBrand';
DELETE FROM Customer WHERE NationalCode IN ('MULTI-CUST', '0987654321');

BEGIN TRAN MultiLoginTests;
PRINT '--- TRANSACTION STARTED: MULTI-ROLE SECURITY TESTS ---';

-- ==========================================
-- 1. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) VALUES ('MULTI-CUST', 'Multi', 'Cust', '09121212121');
DECLARE @TestCust INT = SCOPE_IDENTITY();

INSERT INTO Manufacturer (Name, Country) VALUES ('MultiBrand', 'MultiLand');
DECLARE @TestManuf INT = SCOPE_IDENTITY();

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-MULTI-01', @TestManuf, 'MultiCar', 2026, 50.00, 10000.00, 'Available');
DECLARE @TestCar INT = SCOPE_IDENTITY();

INSERT INTO Payment (Amount, PaymentDate, Method) VALUES (100.00, GETDATE(), 'Cash');
DECLARE @TestPayment INT = SCOPE_IDENTITY();
PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- ==========================================
-- BLOCK 1: MANAGER TESTS
-- ==========================================
PRINT '--- EXECUTING AS MANAGER ---';
EXECUTE AS LOGIN = 'CarManagerLogin';
PRINT 'TEST 1: Viewing Income Report (SUCCESS)';
SELECT TOP 1 * FROM dbo.vw_IncomeReportByBrand;
PRINT 'TEST 2: Viewing ROI Analysis (SUCCESS)';
SELECT TOP 1 * FROM dbo.vw_CarROI_Analysis;
REVERT;
PRINT '';

-- ==========================================
-- BLOCK 2: EMPLOYEE TESTS
-- ==========================================
PRINT '--- EXECUTING AS EMPLOYEE ---';
EXECUTE AS LOGIN = 'CarEmployeeLogin';
PRINT 'TEST 1: Insert new customer (SUCCESS)';
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) VALUES ('0987654321', 'Ali', 'Rezaei', '09129998877');

PRINT 'TEST 2: Register a reservation (SUCCESS)';
EXEC dbo.sp_RegisterNewReservation @CustomerID = @TestCust, @CarID = @TestCar, @StartDate = '2026-10-01', @EndDate = '2026-10-05', @PaymentMethod = 'Cash';

PRINT 'TEST 3: Try to view ROI Analysis (DENIED)';
BEGIN TRY SELECT * FROM dbo.vw_CarROI_Analysis; END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: View Denied for Employee]; END CATCH;

PRINT 'TEST 4: Try to delete payment (DENIED)';
BEGIN TRY DELETE FROM Payment WHERE PaymentID = @TestPayment; END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Delete Denied for Employee]; END CATCH;
REVERT;
PRINT '';

-- ==========================================
-- BLOCK 3: CUSTOMER TESTS
-- ==========================================
PRINT '--- EXECUTING AS CUSTOMER ---';
EXECUTE AS LOGIN = 'CarCustomerLogin';
PRINT 'TEST 1: View Available Cars (SUCCESS)';
SELECT TOP 1 * FROM dbo.vw_AvailableCars;

PRINT 'TEST 2: View Customer private data (DENIED)';
BEGIN TRY SELECT * FROM Customer; END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Customer Table Denied]; END CATCH;

PRINT 'TEST 3: View Payments (DENIED)';
BEGIN TRY SELECT * FROM Payment; END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Payment Table Denied]; END CATCH;
REVERT;
PRINT '';

ROLLBACK TRAN MultiLoginTests;
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO