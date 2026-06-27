-- TEST EMPLOYEE ROLE LIMITATIONS & CAPABILITIES
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN EmployeeTestTran;
PRINT '--- TRANSACTION STARTED: EMPLOYEE ROLE TESTS ---';

-- ==========================================
-- 0. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) VALUES ('1313131313', 'EmpTest', 'Cust', '09131313131');
DECLARE @TestCustID INT = SCOPE_IDENTITY();

INSERT INTO Manufacturer (Name, Country) VALUES ('EmpBrand', 'EmpLand');
DECLARE @ManufID INT = SCOPE_IDENTITY();

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-EMP-TEST', @ManufID, 'EmpModel', 2026, 50.00, 15000.00, 'Available');
DECLARE @TestCarID INT = SCOPE_IDENTITY();

INSERT INTO Employee (NationalCode, FirstName, LastName, Position, BaseSalary)
VALUES ('3131313131', 'Test', 'Emp', 'Agent', 10000.00);
DECLARE @TestEmpID INT = SCOPE_IDENTITY();

-- Create a mock payment to test delete restriction
INSERT INTO Payment (Amount, PaymentDate, Method) VALUES (100.00, GETDATE(), 'Cash');
DECLARE @TestPayID INT = SCOPE_IDENTITY();

PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- ==========================================
-- 1. SWITCH CONTEXT TO EMPLOYEE
-- ==========================================
EXECUTE AS LOGIN = 'CarEmployeeLogin';
PRINT '>>> LOGGED IN AS: EMPLOYEE <<<';

PRINT '';
-- Scenario 1: Add a new customer (Should Succeed)
PRINT 'SCENARIO 1: Insert new customer -> EXPECTED: SUCCESS';
BEGIN TRY
    INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) 
    VALUES ('0000000001', 'Test', 'Testi', '09120000001');
    PRINT 'Result: Customer inserted successfully.';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [UNEXPECTED ERROR: Insert Failed];
END CATCH;

PRINT '';
-- Scenario 2: Register a new car reservation (Should Succeed)
PRINT 'SCENARIO 2: Register reservation -> EXPECTED: SUCCESS';
BEGIN TRY
    EXEC dbo.sp_RegisterNewReservation @CustomerID = @TestCustID, @CarID = @TestCarID, @StartDate = '2026-08-01', @EndDate = '2026-08-05', @PaymentMethod = 'Cash';
    PRINT 'Result: Reservation registered successfully.';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [UNEXPECTED ERROR: Reservation Failed];
END CATCH;

PRINT '';
-- Scenario 3: Attempt to delete a payment record (Should Fail - Denied)
PRINT 'SCENARIO 3: Delete payment record -> EXPECTED: DENIED';
BEGIN TRY
    DELETE FROM Payment WHERE PaymentID = @TestPayID;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Delete Denied];
END CATCH;

PRINT '';
-- Scenario 4: Attempt to view Manager's ROI view (Should Fail - Denied)
PRINT 'SCENARIO 4: View ROI Analysis -> EXPECTED: DENIED';
BEGIN TRY
    SELECT * FROM dbo.vw_CarROI_Analysis;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: ROI View Denied];
END CATCH;

PRINT '';
-- Scenario 5: Attempt to modify Employee Salaries (Should Fail - Denied)
PRINT 'SCENARIO 5: Update Employee Salary -> EXPECTED: DENIED';
BEGIN TRY
    UPDATE Employee SET BaseSalary = 50000.00 WHERE EmployeeID = @TestEmpID;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Salary Update Denied];
END CATCH;

-- Revert to original admin context
REVERT;
PRINT '>>> REVERTED TO ADMIN <<<';

ROLLBACK TRAN EmployeeTestTran;
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO