-- TEST SCRIPT FOR ALL VIEWS (DATA-AGNOSTIC APPROACH)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN ViewTestsTran;
PRINT '======================================================';
PRINT '--- 1. ISOLATED MOCK DATA SETUP FOR VIEWS ---';
PRINT '======================================================';

-- 1. Mock Manufacturers
INSERT INTO Manufacturer (Name, Country) VALUES ('ViewBrand_A', 'Germany'), ('ViewBrand_B', 'Japan');
DECLARE @ManufA INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'ViewBrand_A');
DECLARE @ManufB INT = (SELECT ManufacturerID FROM Manufacturer WHERE Name = 'ViewBrand_B');

-- 2. Mock Cars
INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-VIEW-01', @ManufA, 'Model_A1', 2020, 50.00, 20000.00, 'Available'),
       ('VIN-VIEW-02', @ManufB, 'Model_B1', 2021, 60.00, 25000.00, 'Rented'),
       ('VIN-VIEW-03', @ManufA, 'Model_A2', 2022, 0.00, 30000.00, 'Sold');
DECLARE @Car1 INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-VIEW-01');
DECLARE @Car2 INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-VIEW-02');
DECLARE @Car3 INT = (SELECT CarID FROM Car WHERE VIN = 'VIN-VIEW-03');

-- 3. Mock Customers (VIP, Normal, Debtor, Rent-Only, Buy-Only)
INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus)
VALUES ('VIEW-C1', 'John', 'RentOnly', '09100000001', 500.00, 'Active'),    -- Normal
       ('VIEW-C2', 'Jane', 'BuyOnly', '09100000002', 1500.00, 'Active'),     -- VIP
       ('VIEW-C3', 'Jack', 'Debtor', '09100000003', -200.00, 'Debt');        -- Debtor
DECLARE @CustRentOnly INT = (SELECT CustomerID FROM Customer WHERE NationalCode = 'VIEW-C1');
DECLARE @CustBuyOnly INT = (SELECT CustomerID FROM Customer WHERE NationalCode = 'VIEW-C2');
DECLARE @CustDebtor INT = (SELECT CustomerID FROM Customer WHERE NationalCode = 'VIEW-C3');

-- 4. Mock Employee (For Commission Report)
INSERT INTO Employee (NationalCode, FirstName, LastName, Position, CommissionRate)
VALUES ('VIEW-E1', 'Agent', 'Smith', 'Sales', 10.00);
DECLARE @EmpID INT = (SELECT EmployeeID FROM Employee WHERE NationalCode = 'VIEW-E1');

-- 5. Mock Reservations & Repairs (For ROI and Income Reports)
INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, TotalAmount, Status)
VALUES (@CustRentOnly, @Car1, '2026-01-01', '2026-01-05', 200.00, 'Completed'),
       (@CustDebtor, @Car2, '2026-02-01', '2026-02-10', 540.00, 'Completed');
DECLARE @Res1 INT = (SELECT ReservationID FROM Reservation WHERE CustomerID = @CustRentOnly);
DECLARE @Res2 INT = (SELECT ReservationID FROM Reservation WHERE CustomerID = @CustDebtor);

INSERT INTO Repair (CarID, RepairDate, Description, Cost)
VALUES (@Car1, '2026-01-06', 'Oil Change', 50.00);

-- 6. Mock Sales (For Pivot, Cube, and Commission Reports)
INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate)
VALUES (@CustBuyOnly, @Car3, @EmpID, 30000.00, '2026-03-01');
DECLARE @Sale1 INT = (SELECT SaleID FROM Sale WHERE CustomerID = @CustBuyOnly);

-- 7. Mock Payments (For Rollup and Pivot Reports)
INSERT INTO Payment (ReservationID, SaleID, Amount, Method)
VALUES (@Res1, NULL, 200.00, 'Cash'),
       (@Res2, NULL, 540.00, 'Credit Card'),
       (NULL, @Sale1, 30000.00, 'Bank Transfer');

PRINT '>>> MOCK DATA READY <<<';
PRINT '';


PRINT '======================================================';
PRINT '--- 2. EXECUTING VIEW TESTS ---';
PRINT '======================================================';

PRINT 'TEST 1: vw_AvailableCars (Should only show Model_A1 as Available)';
SELECT * FROM dbo.vw_AvailableCars WHERE VIN LIKE 'VIN-VIEW%';
PRINT '';

PRINT 'TEST 2: vw_CarROI_Analysis (Checking Profit = RentIncome - RepairCost)';
SELECT * FROM dbo.vw_CarROI_Analysis WHERE VIN LIKE 'VIN-VIEW%';
PRINT '';

PRINT 'TEST 3: vw_CustomerFinancialStatus (Checking Customer Balances)';
SELECT * FROM dbo.vw_CustomerFinancialStatus WHERE NationalCode LIKE 'VIEW-C%';
PRINT '';

PRINT 'TEST 4: vw_CustomerRanking (Checking VIP, Normal, and Debtor Logic)';
SELECT * FROM dbo.vw_CustomerRanking WHERE FullName LIKE '%Only' OR FullName LIKE '%Debtor';
PRINT '';

PRINT 'TEST 5: vw_IncomeReportByBrand (Checking ROLLUP Totals for Rent Payments)';
SELECT * FROM dbo.vw_IncomeReportByBrand WHERE BrandName LIKE 'ViewBrand%' OR BrandName = '--- Grand Total ---';
PRINT '';

PRINT 'TEST 6: vw_EmployeeCommissionReport (Checking 10% Commission on 30000 Sale)';
SELECT * FROM dbo.vw_EmployeeCommissionReport WHERE FullName = 'Agent Smith';
PRINT '';

PRINT 'TEST 7: vw_Pivot_Sales_By_PaymentMethod (Checking Pivot Logic for Bank Transfer)';
SELECT * FROM dbo.vw_Pivot_Sales_By_PaymentMethod WHERE Brand LIKE 'ViewBrand%';
PRINT '';

PRINT 'TEST 8: vw_Cube_RevenueAnalysis (Checking CUBE multidimensional aggregations)';
SELECT * FROM dbo.vw_Cube_RevenueAnalysis WHERE Brand LIKE 'ViewBrand%' OR Brand = '--- All Brands ---';
PRINT '';

PRINT 'TEST 9: vw_RentOnlyCustomers (Checking EXCEPT operator - Should only show John RentOnly)';
SELECT * FROM dbo.vw_RentOnlyCustomers WHERE NationalCode LIKE 'VIEW-C%';
PRINT '';


ROLLBACK TRAN ViewTestsTran;
PRINT '======================================================';
PRINT '--- 3. CLEANUP COMPLETE (Database remains untouched) ---';
PRINT '======================================================';
GO