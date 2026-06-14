-- populate database
USE CarManagementDB;
GO
SET NOCOUNT ON;

-- Get Customer IDs
DECLARE @MahdiID INT = (SELECT TOP 1 CustomerID FROM Customer WHERE NationalCode = '1234567890');
DECLARE @ZahraID INT = (SELECT TOP 1 CustomerID FROM Customer WHERE NationalCode = '1234567898');

-- Employee IDs
DECLARE @MinaID INT = 2; -- Mina Amiri
DECLARE @AliID INT = 3;  -- Ali Fanian

-- Car IDs
DECLARE @BMW_ID INT = 9;
DECLARE @Peraid_ID INT = 12;
DECLARE @Pezho_ID INT = 13;

DECLARE @ResBMW INT;
DECLARE @ResPezho INT;


-- Mina sells the Peraid to Zahra
EXEC dbo.sp_RegisterCarSale 
    @CustomerID = @ZahraID, 
    @CarID = @Peraid_ID, 
    @EmployeeID = @MinaID, 
    @FinalPrice = 2800.00, 
    @PaymentMethod = 'Credit Card';

-- Insert a brand new demo car for Ali to sell (Avoids duplicate sale conflicts)
DECLARE @ManufID INT = (SELECT TOP 1 ManufacturerID FROM Manufacturer);

INSERT INTO Car (VIN, ManufacturerID, Model, BuildYear, DailyRentPrice, BaseSalePrice, CurrentStatus)
VALUES ('VIN-DEMO-ALI-007', @ManufID, 'Demo Car', 2026, 50.00, 30000.00, 'Available');

DECLARE @NewCarID INT = SCOPE_IDENTITY();

-- Ali sells the newly added car to Mahdi
EXEC dbo.sp_RegisterCarSale 
    @CustomerID = @MahdiID, 
    @CarID = @NewCarID, 
    @EmployeeID = @AliID, 
    @FinalPrice = 35000.00, 
    @PaymentMethod = 'Bank Transfer';

-- Mahdi rents the BMW
EXEC dbo.sp_RegisterNewReservation 
    @CustomerID = @MahdiID, @CarID = @BMW_ID, 
    @StartDate = '2026-07-01', @EndDate = '2026-07-10', @PaymentMethod = 'Cash';

-- Get the ReservationID for the BMW
SET @ResBMW = (SELECT TOP 1 ReservationID FROM Reservation WHERE CarID = @BMW_ID ORDER BY ReservationID DESC);

-- Mahdi returns the BMW on time
EXEC dbo.sp_ProcessCarReturnAndLateFees 
    @ReservationID = @ResBMW, @ActualReturnDate = '2026-07-10';

-- Add repair costs to the BMW
INSERT INTO Repair (CarID, RepairDate, Description, Cost) 
VALUES (@BMW_ID, '2026-07-11', 'Routine Maintenance & Oil Change', 150.00);


-- Zahra rents the Pezho
EXEC dbo.sp_RegisterNewReservation 
    @CustomerID = @ZahraID, @CarID = @Pezho_ID, 
    @StartDate = '2026-08-01', @EndDate = '2026-08-05', @PaymentMethod = 'Credit Card';

-- Get the ReservationID for the Pezho
SET @ResPezho = (SELECT TOP 1 ReservationID FROM Reservation WHERE CarID = @Pezho_ID ORDER BY ReservationID DESC);

-- Zahra returns the Pezho
EXEC dbo.sp_ProcessCarReturnAndLateFees 
    @ReservationID = @ResPezho, @ActualReturnDate = '2026-08-05';

-- Pezho needs a heavy repair
INSERT INTO Repair (CarID, RepairDate, Description, Cost) 
VALUES (@Pezho_ID, '2026-08-06', 'Gearbox Repair', 800.00);
GO