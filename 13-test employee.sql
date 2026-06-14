-- TEST EMPLOYEE ROLE LIMITATIONS & CAPABILITIES
USE CarManagementDB;
GO
SET NOCOUNT ON;

BEGIN TRAN EmployeeTestTran;
PRINT '--- TRANSACTION STARTED: EMPLOYEE ROLE TESTS ---';

-- Get necessary IDs for the tests
DECLARE @TestCustID INT = (SELECT TOP 1 CustomerID FROM Customer WHERE NationalCode = '1234567890');
DECLARE @TestCarID INT = (SELECT TOP 1 CarID FROM Car WHERE CurrentStatus = 'Available');
DECLARE @TestEmpID INT = (SELECT TOP 1 EmployeeID FROM Employee WHERE NationalCode = '3333333333');

-- 1. Switch context to Employee
EXECUTE AS LOGIN = 'CarEmployeeLogin';
PRINT '>>> LOGGED IN AS: EMPLOYEE <<<';

PRINT '';
-- Scenario 1: Add a new customer (Should Succeed)
PRINT 'SCENARIO 1: Insert new customer -> EXPECTED: SUCCESS';
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) 
VALUES ('0000000001', 'Test', 'Testi', '09120000001');
PRINT 'Result: Customer inserted successfully.';

PRINT '';
-- Scenario 2: Register a new car reservation (Should Succeed)
PRINT 'SCENARIO 2: Register reservation -> EXPECTED: SUCCESS';
EXEC dbo.sp_RegisterNewReservation @CustomerID = @TestCustID, @CarID = @TestCarID, @StartDate = '2026-08-01', @EndDate = '2026-08-05', @PaymentMethod = 'Cash';
PRINT 'Result: Reservation registered successfully.';

PRINT '';
-- Scenario 3: Attempt to delete a payment record (Should Fail - Denied)
PRINT 'SCENARIO 3: Delete payment record -> EXPECTED: DENIED';
BEGIN TRY
    DELETE FROM Payment WHERE PaymentID = 1;
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
PRINT '--- TRANSACTION ROLLED BACK ---';
GO