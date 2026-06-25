-- 2-data.sql
USE CarManagement_Final;
GO

SET IDENTITY_INSERT Manufacturer ON;
INSERT INTO Manufacturer (ManufacturerID, Name, Country) VALUES 
(5, 'Toyota', 'Japan'), (6, 'Hyundai', 'South Korea'), (7, 'Saipa', 'Iran'), 
(8, 'IranKhodro', 'Iran'), (9, 'BMW', 'Germany');
SET IDENTITY_INSERT Manufacturer OFF;

SET IDENTITY_INSERT Customer ON;
INSERT INTO Customer (CustomerID, NationalCode, FirstName, LastName, Phone, Address, WalletBalance, AccountStatus) VALUES 
(4, '1234567890', 'Mahdi', 'Kazemaini', '09134273052', NULL, -44500.00, 'Suspended'),
(5, '1234567899', 'Ali', 'Alipoor', '09130000000', NULL, -150.00, 'Debt'),
(6, '1234567898', 'Zahra', 'Javanbakhsh', '09130000003', NULL, 2000.00, 'Active'),
(7, '0000000001', 'Test', 'Testi', '09120000001', NULL, 0.00, 'Active'),
(8, '1111222233', 'Sample', 'User', '09100001122', NULL, 500.00, 'Active');
SET IDENTITY_INSERT Customer OFF;

SET IDENTITY_INSERT Employee ON;
INSERT INTO Employee (EmployeeID, NationalCode, FirstName, LastName, Position, BaseSalary, CommissionRate) VALUES 
(1, '2222222222', 'Amir', 'Khorsandi', 'Sales Manager', 15000.00, 5.00),
(2, '3333333333', 'Mina', 'Amiri', 'Rental Agent', 12000.00, 2.50),
(3, '1111111111', 'Ali', 'Fanian', 'Sales Manager & Rental Agent', 25000.00, 7.00),
(4, '4444555566', 'Reza', 'Ahmadi', 'Support', 8000.00, 0.00),
(5, '7777888899', 'Sara', 'Kamali', 'Inspector', 9500.00, 0.00);
SET IDENTITY_INSERT Employee OFF;

SET IDENTITY_INSERT Car ON;
INSERT INTO Car (CarID, VIN, ManufacturerID, Model, BuildYear, Color, Mileage, DailyRentPrice, BaseSalePrice, CurrentStatus) VALUES 
(8, 'VIN-TOYOTA-001', 5, 'Camry', 2022, 'White', 15000, 60.00, 25000.00, 'Available'),
(9, 'VIN-BMW-002', 9, 'X5', 2023, 'Black', 5000, 150.00, 65000.00, 'Maintenance'),
(10, 'VIN-HYUNDAI-003', 6, 'Elantra', 2021, 'Silver', 45000, 45.00, 18000.00, 'Sold'),
(11, 'VIN-TOYOTA-004', 5, 'Corolla', 2020, 'Red', 60000, 40.00, 15000.00, 'Sold'),
(12, 'VIN-SAIPA-005', 7, 'Peraid', 2002, 'White', 1000, 6.00, 25.00, 'Sold'),
(13, 'VIN-IRANKHODRO-006', 8, 'Pezho', 2005, 'White', 2000, 10.00, 40.00, 'Maintenance'),
(14, 'VIN-DEMO-ALI-007', 9, 'Demo Car', 2026, NULL, 0, 50.00, 30000.00, 'Sold');
SET IDENTITY_INSERT Car OFF;

INSERT INTO Insurance (PolicyNumber, CarID, Provider, CoverageType, ExpirationDate) VALUES 
('POL-1001', 8, 'Iran Insurance', 'Full-Body', '2027-05-01'),
('POL-1002', 9, 'Asia Insurance', 'Third-Party', '2027-12-01'),
('POL-1003', 10, 'Melat Insurance', 'Full-Body', '2027-11-01'),
('POL-1004', 11, 'Mihan Insurance', 'Third-Party', '2028-10-01'),
('POL-1005', 12, 'Sas Insurance', 'Third-Party', '2029-09-01');

SET IDENTITY_INSERT Reservation ON;
INSERT INTO Reservation (ReservationID, CustomerID, CarID, StartDate, EndDate, TotalAmount, Status) VALUES 
(1, 4, 8, '2026-05-20 10:00:00.000', '2026-05-25 10:00:00.000', 300.00, 'Completed'),
(2, 5, 9, '2026-05-26 14:00:00.000', '2026-05-30 14:00:00.000', 600.00, 'Active'),
(10, 4, 9, '2026-07-01 00:00:00.000', '2026-07-10 00:00:00.000', 1350.00, 'Completed'),
(11, 6, 13, '2026-08-01 00:00:00.000', '2026-08-05 00:00:00.000', 40.00, 'Completed');
SET IDENTITY_INSERT Reservation OFF;

SET IDENTITY_INSERT Sale ON;
INSERT INTO Sale (SaleID, CustomerID, CarID, EmployeeID, FinalPrice, SaleDate) VALUES 
(1, 6, 10, 1, 14500.00, '2026-04-10 11:30:00.000'),
(6, 6, 12, 2, 2800.00, '2026-05-29 23:13:25.700'),
(8, 4, 14, 3, 35000.00, '2026-05-29 23:16:01.943');
SET IDENTITY_INSERT Sale OFF;

SET IDENTITY_INSERT Repair ON;
INSERT INTO Repair (RepairID, CarID, RepairDate, Description, Cost) VALUES 
(1, 11, '2026-05-25', 'Engine Oil Change and Brake Pads', 120.00),
(3, 9, '2026-07-11', 'Routine Maintenance & Oil Change', 150.00),
(4, 13, '2026-08-06', 'Gearbox Repair', 800.00),
(5, 8, '2026-01-15', 'Windshield replacement', 250.00),
(6, 8, '2026-03-22', 'Tire alignment', 80.00);
SET IDENTITY_INSERT Repair OFF;

SET IDENTITY_INSERT Payment ON;
INSERT INTO Payment (PaymentID, ReservationID, SaleID, Amount, PaymentDate, Method) VALUES 
(1, 1, NULL, 300.00, '2026-05-20 09:50:00.000', 'Credit Card'),
(2, NULL, 1, 14500.00, '2026-04-10 12:00:00.000', 'Bank Transfer'),
(12, NULL, 6, 2800.00, '2026-05-29 23:13:25.700', 'Credit Card'),
(13, 10, NULL, 1350.00, '2026-05-29 23:13:25.750', 'Cash'),
(14, 11, NULL, 40.00, '2026-05-29 23:13:25.753', 'Credit Card'),
(15, NULL, NULL, 45000.00, '2026-05-29 23:14:48.853', 'Bank Transfer'),
(16, NULL, 8, 35000.00, '2026-05-29 23:16:01.943', 'Bank Transfer');
SET IDENTITY_INSERT Payment OFF;

SET IDENTITY_INSERT AppUser ON;
INSERT INTO AppUser (UserID, Username, Password, Role, EmployeeID, CustomerID) VALUES 
(1, 'admin', '123', 'Admin', 1, NULL),
(2, 'agent', '123', 'Employee', 2, NULL),
(3, 'mahdi', '123', 'Customer', NULL, 4),
(4, 'zahra', '123', 'Customer', NULL, 6);
SET IDENTITY_INSERT AppUser OFF;
GO