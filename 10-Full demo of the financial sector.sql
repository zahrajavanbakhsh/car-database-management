-- Full demo of the financial sector
USE CarManagementDB;
GO

SET NOCOUNT ON; 

BEGIN TRAN FullTestTransaction;

-- vars
DECLARE @MahdiID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1234567890');
DECLARE @ZahraID INT = (SELECT CustomerID FROM Customer WHERE NationalCode = '1234567898');
DECLARE @AmirID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222222');

DECLARE @Camry_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-TOYOTA-001');   
DECLARE @Saipa_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-SAIPA-005');    
DECLARE @Pezho_ID INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-IRANKHODRO-006'); 

DECLARE @MahdiResID INT;


-- SCENARIO 1: SUCCESSFUL RENTAL (UPFRONT PAYMENT)
SELECT WalletBalance AS [1-BEFORE: Mahdi Wallet], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [1-BEFORE: Camry Status] FROM Car WHERE CarID = @Camry_ID;

-- Mahdi rents the car for 4 days (4 days * 60 = 240 cash payment)
EXEC dbo.sp_RegisterNewReservation
    @CustomerID = @MahdiID,
    @CarID = @Camry_ID,
    @StartDate = '2026-05-30',
    @EndDate = '2026-06-03',
    @PaymentMethod = 'Credit Card';

SELECT WalletBalance AS [1-AFTER: Mahdi Wallet (Should be SAME)], AccountStatus FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [1-AFTER: Camry Status (Should be RENTED)] FROM Car WHERE CarID = @Camry_ID;


-- SCENARIO 2: SUCCESSFUL SALE (UPFRONT PAYMENT)
SELECT WalletBalance AS [2-BEFORE: Zahra Wallet] FROM Customer WHERE CustomerID = @ZahraID;
SELECT CurrentStatus AS [2-BEFORE: Saipa Status] FROM Car WHERE CarID = @Saipa_ID;

-- Zahra buys the Pride ($25 cash payment)
EXEC dbo.sp_RegisterCarSale
    @CustomerID = @ZahraID,
    @CarID = @Saipa_ID,
    @EmployeeID = @AmirID,
    @FinalPrice = 25.00,
    @PaymentMethod = 'Bank Transfer';

SELECT WalletBalance AS [2-AFTER: Zahra Wallet (Should be SAME)] FROM Customer WHERE CustomerID = @ZahraID;
SELECT CurrentStatus AS [2-AFTER: Saipa Status (Should be SOLD)] FROM Car WHERE CarID = @Saipa_ID;


-- SCENARIO 3: LATE RETURN & HEAVY PENALTY (CREATING DEBT)
SET @MahdiResID = (SELECT TOP 1 ReservationID FROM Reservation WHERE CustomerID = @MahdiID ORDER BY ReservationID DESC);

-- Return date was supposed to be June 3, Mahdi returns it on June 9 (6 days delay)
EXEC dbo.sp_ProcessCarReturnAndLateFees
    @ReservationID = @MahdiResID,
    @ActualReturnDate = '2026-06-09';

-- Mahdi's wallet should go from 500 to -40!
SELECT WalletBalance AS [3-AFTER: Mahdi Wallet (Should drop by 540)], AccountStatus AS [3-AFTER: Mahdi Status (Should be DEBT)] FROM Customer WHERE CustomerID = @MahdiID;
SELECT CurrentStatus AS [3-AFTER: Camry Status (Should be AVAILABLE)] FROM Car WHERE CarID = @Camry_ID;


-- SCENARIO 4: BLOCKED RENTAL DUE TO DEBT
BEGIN TRY
    -- Mahdi (in debt) tries to rent the Peugeot
    EXEC dbo.sp_RegisterNewReservation
        @CustomerID = @MahdiID,
        @CarID = @Pezho_ID,
        @StartDate = '2026-06-10',
        @EndDate = '2026-06-12',
        @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [4-SYSTEM BLOCK LOG (Debt Protection Worked!)];
END CATCH;

-- Confirming the Peugeot is still Available and was not rented to Mahdi
SELECT CurrentStatus AS [4-AFTER: Pezho Status (Should remain AVAILABLE)] FROM Car WHERE CarID = @Pezho_ID;


-- SCENARIO 5: BLOCKED SALE OF ALREADY SOLD CAR
BEGIN TRY
    -- Mahdi tries to buy the Pride that was already sold
    EXEC dbo.sp_RegisterCarSale
        @CustomerID = @MahdiID,
        @CarID = @Saipa_ID,
        @EmployeeID = @AmirID,
        @FinalPrice = 25.00,
        @PaymentMethod = 'Cash';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [5-SYSTEM BLOCK LOG (Double-Sale Protection Worked!)];
END CATCH;

ROLLBACK TRAN FullTestTransaction;
GO