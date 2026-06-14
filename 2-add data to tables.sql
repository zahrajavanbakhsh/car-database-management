USE CarManagementDB;
GO

-- add data to tables
--ALTER TABLE Manufacturer
--DROP CONSTRAINT UQ__Manufact__067B3009FC67FD67;

INSERT INTO Manufacturer (Name, Country) VALUES 
('Toyota', 'Japan'), 
('Hyundai', 'South Korea'),
('Saipa', 'Iran'),
('IranKhodro', 'Iran'),
('BMW', 'Germany');

INSERT INTO Customer (NationalCode, FirstName, LastName, Phone, WalletBalance, AccountStatus) VALUES 
('1234567890', 'Mahdi', 'Kazemaini', '09134273052', 500.00, 'Active'),
('1234567899', 'Ali', 'Alipoor', '09130000000', -150.00, 'Debt'),
('1234567898', 'Zahra', 'Javanbakhsh', '09130000003', 2000.00, 'Active');

INSERT INTO Employee (NationalCode, FirstName, LastName, Position, BaseSalary, CommissionRate) VALUES 
('2222222222', 'Amir', 'Khorsandi', 'Sales Manager', 15000.00, 5.00),
('3333333333', 'Mina', 'Amiri', 'Rental Agent', 12000.00, 2.50),
('1111111111', 'Ali', 'Fanian','Sales Manager & Rental Agent' , 25000.00, 7.00);

SELECT * FROM Manufacturer;

ALTER TABLE Car
ALTER COLUMN VIN NVARCHAR(50) NOT NULL;

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, Color, Mileage, DailyRentPrice, BaseSalePrice, CurrentStatus) VALUES 
('VIN-TOYOTA-001', 5, 'Camry', 2022, 'White', 15000, 60.00, 25000.00, 'Available'),
('VIN-BMW-002', 9, 'X5', 2023, 'Black', 5000, 150.00, 65000.00, 'Rented'),
('VIN-HYUNDAI-003', 6, 'Elantra', 2021, 'Silver', 45000, 45.00, 18000.00, 'Maintenance'),
('VIN-TOYOTA-004', 5, 'Corolla', 2020, 'Red', 60000, 40.00, 15000.00, 'Sold'),
('VIN-SAIPA-005', 7, 'Peraid', 2002, 'White', 1000, 6.00, 25.00, 'Available'),
('VIN-IRANKHODRO-006', 8, 'Pezho', 2005, 'White', 2000, 10.00, 40.00, 'Available');

SELECT * FROM Car;

INSERT INTO Insurance (PolicyNumber, CarID, Provider, CoverageType, ExpirationDate) VALUES 
('POL-1001', 8, 'Iran Insurance', 'Full-Body', '2027-05-01'),
('POL-1002', 9, 'Asia Insurance', 'Third-Party', '2027-12-01'),
('POL-1003', 10, 'Melat Insurance', 'Full-Body', '2027-11-01'),
('POL-1004', 11, 'Mihan Insurance', 'Third-Party', '2028-10-01'),
('POL-1005', 12, 'Sas Insurance', 'Third-Party', '2029-09-01');

SELECT * FROM Car;
SELECT * FROM Customer;
SELECT * FROM Employee;

INSERT INTO Reservation (CustomerID, CarID, StartDate, EndDate, TotalAmount, Status) VALUES 
(4, 8, '2026-05-20 10:00:00', '2026-05-25 10:00:00', 300.00, 'Completed'),
(5, 9, '2026-05-26 14:00:00', '2026-05-30 14:00:00', 600.00, 'Active');

INSERT INTO Sale (CustomerID, CarID, EmployeeID, FinalPrice, SaleDate) VALUES 
(6, 10, 1, 14500.00, '2026-04-10 11:30:00');

INSERT INTO Repair (CarID, RepairDate, Description, Cost) VALUES 
(11, '2026-05-25', 'Engine Oil Change and Brake Pads', 120.00);

SELECT * FROM Reservation;
SELECT * FROM Sale;

INSERT INTO Payment (ReservationID, SaleID, Amount, PaymentDate, Method) VALUES 
(1, NULL, 300.00, '2026-05-20 09:50:00', 'Credit Card'),
(NULL, 1, 14500.00, '2026-04-10 12:00:00', 'Bank Transfer');
GO