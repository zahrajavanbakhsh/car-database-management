-- Second demo of the financial sector
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN AdvancedFinTest;
PRINT '--- TRANSACTION STARTED: ADVANCED FINANCIAL TESTS ---';

-- ==========================================
-- 0. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';
INSERT INTO Manufacturer (Name, Country) VALUES ('MockBrand', 'MockLand');
DECLARE @Manuf INT = (SELECT TOP 1 ManufacturerID FROM Manufacturer ORDER BY ManufacturerID DESC);

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-MOCK-CAMRY2', @Manuf, 'Camry', 2022, 60.00, 25000.00, 'Available'),
       ('VIN-MOCK-BMW2', @Manuf, 'BMW', 2023, 150.00, 65000.00, 'Available');
DECLARE @Camry_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-MOCK-CAMRY2');
DECLARE @BMW_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-MOCK-BMW2');

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus)
VALUES ('1111111110', 'Mahdi', 'K', '09111111110', 500.00, 'Active'),
       ('9999999999', 'Other', 'User', '09999999999', 5000.00, 'Active');
DECLARE @MahdiID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1111111110');
DECLARE @OtherCustID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '9999999999');

INSERT INTO Employee (NationalCode, FirstName, LastName, Position)
VALUES ('2222222220', 'Amir', 'Kh', 'Sales');
DECLARE @AmirID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222220');

-- Rent BMW to another customer so it's realistically in 'Rented' status for Test 3
EXEC dbo.sp_RegisterNewReservation @CustomerID = @OtherCustID, @CarID = @BMW_ID, @StartDate = '2026-06-01', @EndDate = '2026-06-10', @PaymentMethod = 'Credit Card';

DECLARE @ResID INT;
PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- ==========================================
-- PREPARATION: Creating a delay and putting Mahdi in debt
-- ==========================================
EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @Camry_ID, @StartDate = '2026-05-30', @EndDate = '2026-06-03', @PaymentMethod = 'Credit Card';
SET @ResID = (SELECT TOP 1 ReservationID FROM Reservation WHERE CustomerID = @MahdiID ORDER BY ReservationID DESC);
EXEC dbo.sp_ProcessCarReturnAndLateFees @ReservationID = @ResID, @ActualReturnDate = '2026-06-09';


-- ==========================================
-- 1. CURRENT STATE
-- ==========================================
PRINT '';
PRINT '1. CURRENT STATE: Mahdi is in DEBT (-280 Wallet)';
SELECT WalletBalance AS [Mahdi Wallet (Debt)], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;


-- ==========================================
-- 2. CLEARING THE DEBT
-- ==========================================
PRINT '';
PRINT '2. TEST: Clearing the Debt (Unblocking Customer)';
-- Mahdi pays the exactly $280 penalty in cash to unblock his account
EXEC dbo.sp_PayPenaltyDebt @ReservationID = @ResID, @Amount = 280.00;

-- The trigger should reset the wallet to 0 and revert the account to Active
SELECT WalletBalance AS [Mahdi Wallet (Should be 0)], AccountStatus AS [Status (Should be ACTIVE)] FROM Customer WHERE CustomerID = @MahdiID;


-- ==========================================
-- 3. SELLING RENTED CAR
-- ==========================================
PRINT '';
PRINT '3. TEST: Trying to sell a RENTED car';
-- The BMW is currently Rented by OtherCust. Let's see if an employee can sell it?
BEGIN TRY
    EXEC dbo.sp_RegisterCarSale @CustomerID = @MahdiID, @CarID = @BMW_ID, @EmployeeID = @AmirID, @FinalPrice = 65000.00, @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [BLOCKED: Cannot sell rented car!];
END CATCH;


-- ==========================================
-- 4. AUTO-MAINTENANCE TRIGGER
-- ==========================================
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
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO