-- 2-data.sql
USE CarManagement_Final;
GO

SET NOCOUNT ON;
PRINT '--- CLEANING UP EXISTING DATA ---';

-- پاکسازی جداول به ترتیب وابستگی (از فرزند به پدر) برای جلوگیری از خطای کلید خارجی
DELETE FROM AppUser;
DELETE FROM Payment;
DELETE FROM Repair;
DELETE FROM Sale;
DELETE FROM Reservation;
DELETE FROM Insurance;
DELETE FROM Car;
DELETE FROM Employee;
DELETE FROM Customer;
DELETE FROM Manufacturer;

PRINT '--- INSERTING NEW MOCK DATA ---';

-- =========================================
-- 1. Manufacturer
-- =========================================
SET IDENTITY_INSERT Manufacturer ON;
INSERT INTO Manufacturer (ManufacturerID, Name, Country) VALUES 
(5, 'Toyota', 'Japan'), 
(6, 'Hyundai', 'South Korea'), 
(7, 'Saipa', 'Iran'), 
(8, 'IranKhodro', 'Iran'), 
(9, 'BMW', 'Germany'),
(10, 'Mercedes-Benz', 'Germany'),
(11, 'Audi', 'Germany'),
(12, 'Kia', 'South Korea'),
(13, 'Ford', 'USA'),
(14, 'Honda', 'Japan');
SET IDENTITY_INSERT Manufacturer OFF;

-- =========================================
-- 2. Customer
-- =========================================
SET IDENTITY_INSERT Customer ON;
INSERT INTO Customer (CustomerID, NationalCode, FirstName, LastName, Phone, Address, WalletBalance, AccountStatus) VALUES 
-- داده های قبلی
(4, '1234567890', 'Mahdi', 'Kazemaini', '09134273052', NULL, -44500.00, 'Suspended'),
(5, '1234567899', 'Ali', 'Alipoor', '09130000000', NULL, -150.00, 'Debt'),
(6, '1234567898', 'Zahra', 'Javanbakhsh', '09130000003', NULL, 2000.00, 'Active'),
(7, '0000000001', 'Test', 'Testi', '09120000001', NULL, 0.00, 'Active'),
(8, '1111222233', 'Sample', 'User', '09100001122', NULL, 500.00, 'Active'),
-- داده های جدید
(9, '0987654321', 'Reza', 'Mohammadi', '09123456789', 'Tehran, Valiasr St', 15000.00, 'Active'),
(10, '1357924680', 'Sara', 'Ahmadi', '09151112233', 'Mashhad, Reza St', 300.00, 'Active'),
(11, '2468013579', 'Nima', 'Karimi', '09132223344', 'Isfahan, Chaharbagh', 0.00, 'Active'),
(12, '1122334455', 'Maryam', 'Hosseini', '09173334455', 'Shiraz, Zand St', -50.00, 'Debt'),
(13, '9988776655', 'Omid', 'Sadeghi', '09145556677', 'Tabriz, Shahrdari Sq', 8500.00, 'Active');
SET IDENTITY_INSERT Customer OFF;

-- =========================================
-- 3. Employee
-- =========================================
SET IDENTITY_INSERT Employee ON;
INSERT INTO Employee (EmployeeID, NationalCode, FirstName, LastName, Position, BaseSalary, CommissionRate) VALUES 
-- داده های قبلی
(1, '2222222222', 'Amir', 'Khorsandi', 'Sales Manager', 15000.00, 5.00),
(2, '3333333333', 'Mina', 'Amiri', 'Rental Agent', 12000.00, 2.50),
(3, '1111111111', 'Ali', 'Fanian', 'Sales Manager & Rental Agent', 25000.00, 7.00),
(4, '4444555566', 'Reza', 'Ahmadi', 'Support', 8000.00, 0.00),
(5, '7777888899', 'Sara', 'Kamali', 'Inspector', 9500.00, 0.00),
-- داده های جدید
(6, '1010101010', 'Hassan', 'Jalali', 'Sales Agent', 11000.00, 3.00),
(7, '2020202020', 'Neda', 'Rostami', 'Sales Agent', 11500.00, 3.50),
(8, '3030303030', 'Kamran', 'Nouri', 'Manager', 30000.00, 8.00),
(9, '4040404040', 'Elnaz', 'Safavi', 'Rental Agent', 12500.00, 2.00),
(10, '5050505050', 'Sina', 'Talebi', 'Technical Expert', 14000.00, 0.00);
SET IDENTITY_INSERT Employee OFF;

-- =========================================
-- 4. Car
-- =========================================
SET IDENTITY_INSERT Car ON;
INSERT INTO Car (CarID, VIN, ManufacturerID, Model, BuildYear, Color, Mileage, DailyRentPrice, BaseSalePrice, CurrentStatus) VALUES 
-- داده های قبلی
(8, 'VIN-TOYOTA-001', 5, 'Camry', 2022, 'White', 15000, 60.00, 25000.00, 'Available'),
(9, 'VIN-BMW-002', 9, 'X5', 2023, 'Black', 5000, 150.00, 65000.00, 'Maintenance'),
(10, 'VIN-HYUNDAI-003', 6, 'Elantra', 2021, 'Silver', 45000, 45.00, 18000.00, 'Sold'),
(11, 'VIN-TOYOTA-004', 5, 'Corolla', 2020, 'Red', 60000, 40.00, 15000.00, 'Sold'),
(12, 'VIN-SAIPA-005', 7, 'Peraid', 2002, 'White', 1000, 6.00, 25.00, 'Sold'),
(13, 'VIN-IRANKHODRO-006', 8, 'Pezho', 2005, 'White', 2000, 10.00, 40.00, 'Maintenance'),
(14, 'VIN-DEMO-ALI-007', 9, 'Demo Car', 2026, NULL, 0, 50.00, 30000.00, 'Sold'),
-- داده های جدید
(15, 'VIN-BENZ-008', 10, 'C-Class', 2024, 'Black', 1000, 120.00, 55000.00, 'Rented'),
(16, 'VIN-AUDI-009', 11, 'Q5', 2023, 'Blue', 8000, 110.00, 50000.00, 'Available'),
(17, 'VIN-KIA-010', 12, 'Optima', 2022, 'White', 25000, 55.00, 22000.00, 'Available'),
(18, 'VIN-FORD-011', 13, 'Mustang', 2023, 'Yellow', 5000, 130.00, 45000.00, 'Sold'),
(19, 'VIN-HONDA-012', 14, 'Civic', 2021, 'Gray', 30000, 45.00, 19000.00, 'Sold'),
(20, 'VIN-HYUNDAI-013', 6, 'Santa Fe', 2022, 'Black', 20000, 70.00, 32000.00, 'Sold'),
(21, 'VIN-IRANKHODRO-014', 8, '206', 2018, 'White', 85000, 15.00, 5000.00, 'Available'),
(22, 'VIN-SAIPA-015', 7, 'Tiba', 2020, 'Silver', 60000, 10.00, 3000.00, 'Sold');
SET IDENTITY_INSERT Car OFF;

-- =========================================
-- 5. Insurance
-- =========================================
INSERT INTO Insurance (PolicyNumber, CarID, Provider, CoverageType, ExpirationDate) VALUES 
-- داده های قبلی
('POL-1001', 8, 'Iran Insurance', 'Full-Body', '2027-05-01'),
('POL-1002', 9, 'Asia Insurance', 'Third-Party', '2027-12-01'),
('POL-1003', 10, 'Melat Insurance', 'Full-Body', '2027-11-01'),
('POL-1004', 11, 'Mihan Insurance', 'Third-Party', '2028-10-01'),
('POL-1005', 12, 'Sas Insurance', 'Third-Party', '2029-09-01'),
-- داده های جدید
('POL-1006', 15, 'Saman Insurance', 'Full-Body', '2027-01-15'),
('POL-1007', 16, 'Pasargad Insurance', 'Full-Body', '2027-03-20'),
('POL-1008', 17, 'Alborz Insurance', 'Third-Party', '2027-06-10'),
('POL-1009', 20, 'Asia Insurance', 'Full-Body', '2027-08-05'),
('POL-1010', 21, 'Iran Insurance', 'Third-Party', '2026-11-30');

-- =========================================
-- 6. Reservation
-- =========================================
SET IDENTITY_INSERT Reservation ON;
INSERT INTO Reservation (ReservationID, CustomerID, CarID, StartDate, EndDate, TotalAmount, Status) VALUES 
-- داده های قبلی
(1, 4, 8, '2026-05-20 10:00:00.000', '2026-05-25 10:00:00.000', 300.00, 'Completed'),
(2, 5, 9, '2026-05-26 14:00:00.000', '2026-05-30 14:00:00.000', 600.00, 'Active'),
(10, 4, 9, '2026-07-01 00:00:00.000', '2026-07-10 00:00:00.000', 1350.00, 'Completed'),
(11, 6, 13, '2026-08-01 00:00:00.000', '2026-08-05 00:00:00.000', 40.00, 'Completed'),
-- داده های جدید
(12, 9, 15, '2026-06-01 10:00:00.000', '2026-06-10 10:00:00.000', 1080.00, 'Active'),     -- دلیل Rented بودن ماشین 15
(13, 10, 16, '2026-04-10 09:00:00.000', '2026-04-15 09:00:00.000', 550.00, 'Completed'),
(14, 11, 17, '2026-05-01 12:00:00.000', '2026-05-05 12:00:00.000', 220.00, 'Completed'),
(15, 12, 21, '2026-02-15 08:00:00.000', '2026-02-20 08:00:00.000', 75.00, 'Completed'),
(16, 7, 8, '2026-06-15 10:00:00.000', '2026-06-20 10:00:00.000', 300.00, 'Cancelled');
SET IDENTITY_INSERT Reservation OFF;

-- =========================================
-- 7. Sale
-- =========================================
SET IDENTITY_INSERT Sale ON;
INSERT INTO Sale (SaleID, CustomerID, CarID, EmployeeID, FinalPrice, SaleDate) VALUES 
-- داده های قبلی
(1, 6, 10, 1, 14500.00, '2026-04-10 11:30:00.000'),
(6, 6, 12, 2, 2800.00, '2026-05-29 23:13:25.700'),
(8, 4, 14, 3, 35000.00, '2026-05-29 23:16:01.943'),
-- داده های جدید (تکمیل چرخه ماشین های فروخته شده)
(9, 5, 11, 2, 14000.00, '2026-03-15 10:00:00.000'), -- فروش کرولا
(10, 10, 18, 6, 44000.00, '2026-05-05 14:20:00.000'), -- فروش موستانگ
(11, 11, 19, 7, 18500.00, '2026-05-10 16:45:00.000'), -- فروش سیویک
(12, 12, 20, 8, 31000.00, '2026-06-02 09:15:00.000'), -- فروش سانتافه
(13, 13, 22, 1, 2900.00, '2026-06-12 11:10:00.000');  -- فروش تیبا
SET IDENTITY_INSERT Sale OFF;

-- =========================================
-- 8. Repair
-- =========================================
SET IDENTITY_INSERT Repair ON;
INSERT INTO Repair (RepairID, CarID, RepairDate, Description, Cost) VALUES 
-- داده های قبلی
(1, 11, '2026-05-25', 'Engine Oil Change and Brake Pads', 120.00),
(3, 9, '2026-07-11', 'Routine Maintenance & Oil Change', 150.00),
(4, 13, '2026-08-06', 'Gearbox Repair', 800.00),
(5, 8, '2026-01-15', 'Windshield replacement', 250.00),
(6, 8, '2026-03-22', 'Tire alignment', 80.00),
-- داده های جدید
(7, 16, '2026-04-16', 'Deep Cleaning', 30.00),
(8, 17, '2026-05-06', 'Battery Replacement', 100.00),
(9, 21, '2026-02-21', 'Clutch Repair', 180.00),
(10, 9, '2026-06-05', 'Cooling System Fix', 300.00);
SET IDENTITY_INSERT Repair OFF;

-- =========================================
-- 9. Payment
-- =========================================
SET IDENTITY_INSERT Payment ON;
INSERT INTO Payment (PaymentID, ReservationID, SaleID, Amount, PaymentDate, Method) VALUES 
-- داده های قبلی
(1, 1, NULL, 300.00, '2026-05-20 09:50:00.000', 'Credit Card'),
(2, NULL, 1, 14500.00, '2026-04-10 12:00:00.000', 'Bank Transfer'),
(12, NULL, 6, 2800.00, '2026-05-29 23:13:25.700', 'Credit Card'),
(13, 10, NULL, 1350.00, '2026-05-29 23:13:25.750', 'Cash'),
(14, 11, NULL, 40.00, '2026-05-29 23:13:25.753', 'Credit Card'),
(15, NULL, NULL, 45000.00, '2026-05-29 23:14:48.853', 'Bank Transfer'),
(16, NULL, 8, 35000.00, '2026-05-29 23:16:01.943', 'Bank Transfer'),
-- داده های جدید
(17, 12, NULL, 1080.00, '2026-06-01 09:55:00.000', 'Credit Card'),
(18, 13, NULL, 550.00, '2026-04-10 08:50:00.000', 'Cash'),
(19, 14, NULL, 220.00, '2026-05-01 11:55:00.000', 'Credit Card'),
(20, NULL, 9, 14000.00, '2026-03-15 10:00:00.000', 'Bank Transfer'),
(21, NULL, 10, 44000.00, '2026-05-05 14:20:00.000', 'Bank Transfer'),
(22, NULL, 11, 18500.00, '2026-05-10 16:45:00.000', 'Credit Card'),
(23, NULL, 12, 31000.00, '2026-06-02 09:15:00.000', 'Bank Transfer');
SET IDENTITY_INSERT Payment OFF;

-- =========================================
-- 10. AppUser
-- =========================================
SET IDENTITY_INSERT AppUser ON;
INSERT INTO AppUser (UserID, Username, Password, Role, EmployeeID, CustomerID) VALUES 
-- داده های قبلی
(1, 'admin', '123', 'Admin', 1, NULL),
(2, 'agent', '123', 'Employee', 2, NULL),
(3, 'mahdi', '123', 'Customer', NULL, 4),
(4, 'zahra', '123', 'Customer', NULL, 6),
-- داده های جدید
(5, 'reza_emp', '123', 'Employee', 4, NULL),
(6, 'kamran_mgr', '123', 'Admin', 8, NULL),
(7, 'reza_cust', '123', 'Customer', NULL, 9),
(8, 'sara_cust', '123', 'Customer', NULL, 10),
(9, 'nima_cust', '123', 'Customer', NULL, 11),
(10, 'maryam_cust', '123', 'Customer', NULL, 12);
SET IDENTITY_INSERT AppUser OFF;
GO

PRINT '--- DATA POPULATION COMPLETED SUCCESSFULLY ---';