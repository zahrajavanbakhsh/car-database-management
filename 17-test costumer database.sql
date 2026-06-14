-- AUTOMATED ROLE TEST FOR CUSTOMER (USING IMPERSONATION)
USE CarManagementDB;
GO
SET NOCOUNT ON;

PRINT '==================================================';
PRINT '--- AUTOMATED TEST: CUSTOMER ROLE LIMITATIONS ---';
PRINT '==================================================';

-- Put on the Customer mask
EXECUTE AS LOGIN = 'CarCustomerLogin';
PRINT '>>> SYSTEM CONTEXT SWITCHED TO: CUSTOMER <<<';

PRINT '';
-- 1. Allowed Action: Customers can see which cars are available
PRINT 'SCENARIO 1: View available cars -> EXPECTED: SUCCESS';
SELECT * FROM dbo.vw_AvailableCars;

PRINT '';
-- 2. Denied Action: Customers CANNOT see other customers' private data
PRINT 'SCENARIO 2: View Customer Table -> EXPECTED: DENIED';
BEGIN TRY
    SELECT * FROM Customer;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Access to Customer table is denied];
END CATCH;

PRINT '';
-- 3. Denied Action: Customers CANNOT register reservations directly in DB
PRINT 'SCENARIO 3: Direct Reservation Execution -> EXPECTED: DENIED';
BEGIN TRY
    EXEC dbo.sp_RegisterNewReservation @CustomerID = 1, @CarID = 1, @StartDate = '2026-06-01', @EndDate = '2026-06-05', @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Execute Permission Denied];
END CATCH;

-- Take off the mask
REVERT;
PRINT '>>> SYSTEM CONTEXT REVERTED TO: ADMIN <<<';
GO