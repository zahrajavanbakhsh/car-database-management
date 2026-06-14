-- tests with diffrent logins

-- BLOCK 1: Run this AFTER physically logging in as 'CarManagerLogin'
USE CarManagementDB;
GO
PRINT '--- EXECUTING AS MANAGER ---';

-- Manager has FULL access to sensitive financial views
PRINT 'TEST 1: Viewing Income Report (SUCCESS)';
SELECT * FROM dbo.vw_IncomeReportByBrand;

PRINT 'TEST 2: Viewing ROI Analysis (SUCCESS)';
SELECT * FROM dbo.vw_CarROI_Analysis;
GO


-- BLOCK 2: Run this AFTER physically logging in as 'CarEmployeeLogin'
USE CarManagementDB;
GO
PRINT '--- EXECUTING AS EMPLOYEE ---';

-- Using a transaction so we don't save duplicate data and cause errors
BEGIN TRAN EmployeeManualTest;

    -- Employee CAN insert data and do daily tasks
    PRINT 'TEST 1: Insert new customer (SUCCESS)';
    INSERT INTO Customer (NationalCode, FirstName, LastName, Phone) 
    VALUES ('0987654321', 'Ali', 'Rezaei', '09129998877');

    PRINT 'TEST 2: Register a reservation (SUCCESS)';
    DECLARE @NewCustID INT = SCOPE_IDENTITY();
    DECLARE @AvailableCar INT = (SELECT TOP 1 CarID FROM Car WHERE CurrentStatus = 'Available');
    EXEC dbo.sp_RegisterNewReservation @CustomerID = @NewCustID, @CarID = @AvailableCar, @StartDate = '2026-10-01', @EndDate = '2026-10-05', @PaymentMethod = 'Cash';

    -- Employee CANNOT view Manager's financial reports
    PRINT 'TEST 3: Try to view ROI Analysis (DENIED)';
    BEGIN TRY
        SELECT * FROM dbo.vw_CarROI_Analysis;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: View Denied for Employee];
    END CATCH;

    -- Employee CANNOT delete payment history
    PRINT 'TEST 4: Try to delete payment (DENIED)';
    BEGIN TRY
        DELETE FROM Payment WHERE PaymentID = 1;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Delete Denied for Employee];
    END CATCH;

ROLLBACK TRAN EmployeeManualTest;
PRINT '--- Test finished and changes rolled back safely ---';
GO


-- BLOCK 3: Run this AFTER physically logging in as 'CarCustomerLogin'
USE CarManagementDB;
GO
PRINT '--- EXECUTING AS CUSTOMER ---';

-- Customer CAN only view allowed public views (like available cars)
PRINT 'TEST 1: View Available Cars (SUCCESS)';
SELECT * FROM dbo.vw_AvailableCars;

-- Customer CANNOT spy on other customers
PRINT 'TEST 2: View Customer private data (DENIED)';
BEGIN TRY
    SELECT * FROM Customer;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Customer Table Denied];
END CATCH;

-- Customer CANNOT view financial data
PRINT 'TEST 3: View Payments (DENIED)';
BEGIN TRY
    SELECT * FROM Payment;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [SECURITY BLOCK: Payment Table Denied];
END CATCH;
GO