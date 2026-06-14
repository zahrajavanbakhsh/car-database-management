-- create database and tables
CREATE DATABASE CarManagementDB;
GO
USE CarManagementDB;
GO

CREATE TABLE Manufacturer (
    ManufacturerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Country NVARCHAR(50) NOT NULL
);

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    NationalCode NVARCHAR(10) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Phone NVARCHAR(20) NOT NULL UNIQUE,
    Address NVARCHAR(255),
    WalletBalance DECIMAL(18,2) DEFAULT 0.00,
    AccountStatus NVARCHAR(20) DEFAULT 'Active' CHECK (AccountStatus IN ('Active', 'Suspended', 'Debt'))
);

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    NationalCode NVARCHAR(10) NOT NULL UNIQUE,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Position NVARCHAR(50),
    BaseSalary DECIMAL(18,2),
    CommissionRate DECIMAL(5,2) DEFAULT 0.00
);

CREATE TABLE Car (
    CarID INT IDENTITY(1,1) PRIMARY KEY,
    VIN NVARCHAR(17) NOT NULL UNIQUE,
    ManufacturerID INT FOREIGN KEY REFERENCES Manufacturer(ManufacturerID),
    Model NVARCHAR(50) NOT NULL,
    BuildYear INT,
    Color NVARCHAR(30),
    Mileage INT DEFAULT 0,
    DailyRentPrice DECIMAL(18,2) NOT NULL,
    BaseSalePrice DECIMAL(18,2) NOT NULL,
    CurrentStatus NVARCHAR(20) DEFAULT 'Available' CHECK (CurrentStatus IN ('Available', 'Rented', 'Sold', 'Maintenance'))
);

CREATE TABLE Insurance (
    PolicyNumber NVARCHAR(50) PRIMARY KEY,
    CarID INT FOREIGN KEY REFERENCES Car(CarID),
    Provider NVARCHAR(100) NOT NULL,
    CoverageType NVARCHAR(50) CHECK (CoverageType IN ('Third-Party', 'Full-Body')),
    ExpirationDate DATE NOT NULL
);

CREATE TABLE Reservation (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    CarID INT FOREIGN KEY REFERENCES Car(CarID),
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    TotalAmount DECIMAL(18,2),
    Status NVARCHAR(20) DEFAULT 'Confirmed' CHECK (Status IN ('Confirmed', 'Active', 'Completed', 'Cancelled'))
);

CREATE TABLE Sale (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    CarID INT UNIQUE FOREIGN KEY REFERENCES Car(CarID),
    EmployeeID INT FOREIGN KEY REFERENCES Employee(EmployeeID),
    FinalPrice DECIMAL(18,2) NOT NULL,
    SaleDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Repair (
    RepairID INT IDENTITY(1,1) PRIMARY KEY,
    CarID INT FOREIGN KEY REFERENCES Car(CarID),
    RepairDate DATE DEFAULT GETDATE(),
    Description NVARCHAR(255),
    Cost DECIMAL(18,2) NOT NULL
);

CREATE TABLE Payment (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NULL FOREIGN KEY REFERENCES Reservation(ReservationID),
    SaleID INT NULL FOREIGN KEY REFERENCES Sale(SaleID),
    Amount DECIMAL(18,2) NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    Method NVARCHAR(50) CHECK (Method IN ('Cash', 'Credit Card', 'Bank Transfer'))
);
GO

SELECT * FROM Car