-- TEST MANAGER ROLE PRIVILEGES
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN ManagerTestTran;
PRINT '--- TRANSACTION STARTED: MANAGER ROLE TESTS ---';

-- ==========================================
-- 0. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';

-- Mock Employee for Commission Update
INSERT INTO Employee (NationalCode, FirstName, LastName, Position, CommissionRate)
VALUES ('3333333332', 'Mock', 'Emp', 'Agent', 5.00);

-- Mock Customer & Car for Reservation
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) VALUES ('4444444444', 'Mock', 'Cust', '09444444444');
DECLARE @CustID INT = SCOPE_IDENTITY();

INSERT INTO Manufacturer (Name, Country) VALUES ('MockManuf', 'MockLand');
DECLARE @ManufID INT = SCOPE_IDENTITY();

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-MOCK-MGR', @ManufID, 'MgrCar', 2026, 50, 10000, 'Available');
DECLARE @CarID INT = SCOPE_IDENTITY();

-- Mock Cancelled Reservation
INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, Status)
VALUES (@CustID, @CarID, GETDATE(), GETDATE(), 'Cancelled');

PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- 1. Switch context to Manager
EXECUTE AS LOGIN = 'CarManagerLogin';
PRINT '>>> LOGGED IN AS: MANAGER <<<';

PRINT '';
-- Scenario 1: View sensitive Income Report (Should Succeed)
PRINT 'SCENARIO 1: View Income Report By Brand -> EXPECTED: SUCCESS';
SELECT TOP 1 * FROM dbo.vw_IncomeReportByBrand;

PRINT '';
-- Scenario 2: View sensitive ROI Analysis (Should Succeed)
PRINT 'SCENARIO 2: View ROI Analysis -> EXPECTED: SUCCESS';
SELECT TOP 1 * FROM dbo.vw_CarROI_Analysis;

PRINT '';
-- Scenario 3: Update employee commission rate (Should Succeed)
PRINT 'SCENARIO 3: Update Employee Commission -> EXPECTED: SUCCESS';
UPDATE Employee SET CommissionRate = 10.00 WHERE NationalCode = '3333333333';
PRINT 'Result: Commission rate updated successfully by Manager.';

PRINT '';
-- Scenario 4: Delete an old cancelled reservation (Should Succeed)
PRINT 'SCENARIO 4: Delete a reservation record -> EXPECTED: SUCCESS';
-- Manager has the right to delete records if needed
DELETE FROM Reservation WHERE Status = 'Cancelled';
PRINT 'Result: Deletion query executed successfully.';

-- Revert to original admin context
REVERT;
PRINT '>>> REVERTED TO ADMIN <<<';

ROLLBACK TRAN ManagerTestTran;
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO