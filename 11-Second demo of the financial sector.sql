-- Second demo of the financial sector
USE CarManagementDB;
GO
SET NOCOUNT ON;

BEGIN TRAN AdvancedFinTest;
PRINT '--- TRANSACTION STARTED: ADVANCED FINANCIAL TESTS ---';

DECLARE @MahdiID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1234567890');
DECLARE @Camry_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TOYOTA-001');
DECLARE @BMW_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-BMW-002');
DECLARE @AmirID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222222');
DECLARE @ResID INT;

-- Preparation: Creating a delay and putting Mahdi in debt (like the previous scenario)
EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @Camry_ID, @StartDate = '2026-05-30', @EndDate = '2026-06-03', @PaymentMethod = 'Credit Card';
SET @ResID = (SELECT TOP 1 ReservationID FROM Reservation WHERE CustomerID = @MahdiID ORDER BY ReservationID DESC);
EXEC dbo.sp_ProcessCarReturnAndLateFees @ReservationID = @ResID, @ActualReturnDate = '2026-06-09';

PRINT '';
PRINT '1. CURRENT STATE: Mahdi is in DEBT (-40 Wallet)';
SELECT WalletBalance AS [Mahdi Wallet (Debt)], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;

PRINT '';
PRINT '2. TEST: Clearing the Debt (Unblocking Customer)';
-- Mahdi pays the $40 penalty in cash to unblock his account
EXEC dbo.sp_PayPenaltyDebt @ReservationID = @ResID, @Amount = 40.00;
-- The trigger should reset the wallet to 0 and revert the account to Active
SELECT WalletBalance AS [Mahdi Wallet (Should be 0)], AccountStatus AS [Status (Should be ACTIVE)] FROM Customer WHERE CustomerID = @MahdiID;

PRINT '';
PRINT '3. TEST: Trying to sell a RENTED car';
-- The BMW is currently Rented. Let's see if an employee can sell it?
BEGIN TRY
    EXEC dbo.sp_RegisterCarSale @CustomerID = @MahdiID, @CarID = @BMW_ID, @EmployeeID = @AmirID, @FinalPrice = 65000.00, @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [BLOCKED: Cannot sell rented car!];
END CATCH;

PRINT '';
PRINT '4. TEST: Auto-Maintenance Trigger & Reservation Block';
-- Sending the Camry to the repair shop (The trigger should change the car's status to Maintenance)
INSERT INTO Repair (CarID, RepairDate, Description, Cost) VALUES (@Camry_ID, GETDATE(), 'Engine Check', 50.00);
SELECT CurrentStatus AS [Camry Status (Should be MAINTENANCE)] FROM Car WHERE CarID = @Camry_ID;

-- Now someone tries to rent the Camry that is in the repair shop!
BEGIN TRY
    EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @Camry_ID, @StartDate = '2026-06-20', @EndDate = '2026-06-25', @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [BLOCKED: Cannot rent car in maintenance!];
END CATCH;

ROLLBACK TRAN AdvancedFinTest;
PRINT '';
PRINT '--- TRANSACTION ROLLED BACK ---';
GO