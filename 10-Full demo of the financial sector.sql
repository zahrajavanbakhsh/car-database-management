-- Full demo of the financial sector
USE CarManagement_Final;
GO
SET NOCOUNT ON; 

BEGIN TRAN FullTestTransaction;
PRINT '--- TRANSACTION STARTED: FULL FINANCIAL DEMO ---';

-- ==========================================
-- 0. SETUP MOCK DATA (Data-Agnostic Approach)
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA <<<';
INSERT INTO Manufacturer (Name, Country) VALUES ('MockToyota', 'Japan'), ('MockSaipa', 'Iran');
DECLARE @Manuf1 INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'MockToyota');
DECLARE @Manuf2 INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'MockSaipa');

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-MOCK-CAMRY', @Manuf1, 'Camry', 2022, 60.00, 25000.00, 'Available'),
       ('VIN-MOCK-SAIPA', @Manuf2, 'Pride', 2002, 6.00, 25.00, 'Available'),
       ('VIN-MOCK-PEZHO', @Manuf2, 'Pezho', 2005, 10.00, 40.00, 'Available');
DECLARE @Camry_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-MOCK-CAMRY');
DECLARE @Saipa_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-MOCK-SAIPA');
DECLARE @Pezho_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-MOCK-PEZHO');

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus)
VALUES ('1111111110', 'Mahdi', 'K', '09111111110', 500.00, 'Active'),
       ('1111111111', 'Zahra', 'J', '09111111111', 2000.00, 'Active');
DECLARE @MahdiID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1111111110');
DECLARE @ZahraID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1111111111');

INSERT INTO Employee (NationalCode, FirstName, LastName, Position)
VALUES ('2222222220', 'Amir', 'Kh', 'Sales');
DECLARE @AmirID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222220');

DECLARE @MahdiResID INT;
PRINT '>>> MOCK DATA READY <<<';
PRINT '';

-- ==========================================
-- SCENARIO 1: SUCCESSFUL RENTAL (UPFRONT PAYMENT)
-- ==========================================
SELECT WalletBalance AS [1-BEFORE: Mahdi Wallet], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [1-BEFORE: Camry Status] FROM Car WHERE CarID = @Camry_ID;

-- Mahdi rents the car for 4 days (4 days * 60 = 240 cash payment. Wallet should drop by 240)
EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @Camry_ID, @StartDate = '2026-05-30', @EndDate = '2026-06-03', @PaymentMethod = 'Credit Card';

SELECT WalletBalance AS [1-AFTER: Mahdi Wallet (Dropped by 240)], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [1-AFTER: Camry Status (Should be RENTED)] FROM Car WHERE CarID = @Camry_ID;


-- ==========================================
-- SCENARIO 2: SUCCESSFUL SALE (UPFRONT PAYMENT)
-- ==========================================
SELECT WalletBalance AS [2-BEFORE: Zahra Wallet] FROM Customer WHERE CustomerID = @ZahraID;
SELECT CurrentStatus AS [2-BEFORE: Saipa Status] FROM Car WHERE CarID = @Saipa_ID;

-- Zahra buys the Pride ($25 cash payment)
EXEC dbo.sp_RegisterCarSale @CustomerID = @ZahraID, @CarID = @Saipa_ID, @EmployeeID = @AmirID, @FinalPrice = 25.00, @PaymentMethod = 'Bank Transfer';

SELECT WalletBalance AS [2-AFTER: Zahra Wallet (Dropped by 25)] FROM Customer WHERE CustomerID = @ZahraID;
SELECT CurrentStatus AS [2-AFTER: Saipa Status (Should be SOLD)] FROM Car WHERE CarID = @Saipa_ID;


-- ==========================================
-- SCENARIO 3: LATE RETURN & HEAVY PENALTY (CREATING DEBT)
-- ==========================================
SET @MahdiResID = (SELECT TOP 1 ReservationID FROM Reservation WHERE CustomerID = @MahdiID ORDER BY ReservationID DESC);

-- Return date was supposed to be June 3, Mahdi returns it on June 9 (6 days delay)
-- Penalty: 6 days * (60 * 1.5) = 540. Mahdi's current wallet is 260. 260 - 540 = -280 (DEBT!)
EXEC dbo.sp_ProcessCarReturnAndLateFees @ReservationID = @MahdiResID, @ActualReturnDate = '2026-06-09';

SELECT WalletBalance AS [3-AFTER: Mahdi Wallet (Should be -280)], AccountStatus AS [3-AFTER: Mahdi Status (Should be DEBT)] FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [3-AFTER: Camry Status (Should be AVAILABLE)] FROM Car WHERE CarID = @Camry_ID;


-- ==========================================
-- SCENARIO 4: BLOCKED RENTAL DUE TO DEBT
-- ==========================================
BEGIN TRY
    -- Mahdi (in debt) tries to rent the Peugeot
    EXEC dbo.sp_RegisterNewReservation @CustomerID = @MahdiID, @CarID = @Pezho_ID, @StartDate = '2026-06-10', @EndDate = '2026-06-12', @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [4-SYSTEM BLOCK LOG (Debt Protection Worked!)];
END CATCH;

-- Confirming the Peugeot is still Available and was not rented to Mahdi
SELECT CurrentStatus AS [4-AFTER: Pezho Status (Should remain AVAILABLE)] FROM Car WHERE CarID = @Pezho_ID;


-- ==========================================
-- SCENARIO 5: BLOCKED SALE OF ALREADY SOLD CAR
-- ==========================================
BEGIN TRY
    -- Mahdi tries to buy the Pride that was already sold to Zahra in Scenario 2
    EXEC dbo.sp_RegisterCarSale @CustomerID = @MahdiID, @CarID = @Saipa_ID, @EmployeeID = @AmirID, @FinalPrice = 25.00, @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [5-SYSTEM BLOCK LOG (Double-Sale Protection Worked!)];
END CATCH;

ROLLBACK TRAN FullTestTransaction;
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO