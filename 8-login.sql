-- login

USE [master];
GO

-- Drop existing logins to prevent errors during rebuild
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarManagerLogin') DROP LOGIN CarManagerLogin;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarEmployeeLogin') DROP LOGIN CarEmployeeLogin;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarCustomerLogin') DROP LOGIN CarCustomerLogin;
GO

-- Create SQL Logins for database-level access
CREATE LOGIN CarManagerLogin WITH PASSWORD = '123';
CREATE LOGIN CarEmployeeLogin WITH PASSWORD = '123';
CREATE LOGIN CarCustomerLogin WITH PASSWORD = '123';
GO

USE CarManagementDB;
GO

-- Drop existing database users and roles
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ManagerUser') DROP USER ManagerUser;
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EmployeeUser') DROP USER EmployeeUser;
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CustomerUser') DROP USER CustomerUser;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ManagerRole') DROP ROLE ManagerRole;
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EmployeeRole') DROP ROLE EmployeeRole;
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CustomerRole') DROP ROLE CustomerRole;
GO

-- Create Database Users mapped to the SQL Logins
CREATE USER ManagerUser FOR LOGIN CarManagerLogin;
CREATE USER EmployeeUser FOR LOGIN CarEmployeeLogin;
CREATE USER CustomerUser FOR LOGIN CarCustomerLogin;

-- Create Database Roles for modular permission management
CREATE ROLE ManagerRole;
CREATE ROLE EmployeeRole;
CREATE ROLE CustomerRole;
GO

-- Assign Users to their respective Roles
ALTER ROLE ManagerRole ADD MEMBER ManagerUser;
ALTER ROLE EmployeeRole ADD MEMBER EmployeeUser;
ALTER ROLE CustomerRole ADD MEMBER CustomerUser;
GO

-- Recreate AppUser table for Application-Level Authentication
DROP PROCEDURE IF EXISTS sp_UserLogin;
DROP TABLE IF EXISTS AppUser;
GO

CREATE TABLE AppUser (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(256) NOT NULL,
    Role NVARCHAR(20) NOT NULL CHECK (Role IN ('Admin', 'Employee', 'Customer')),
    EmployeeID INT NULL FOREIGN KEY REFERENCES Employee(EmployeeID),
    CustomerID INT NULL FOREIGN KEY REFERENCES Customer(CustomerID)
);
GO

-- Insert initial application users
INSERT INTO AppUser (Username, Password, Role, EmployeeID) 
VALUES ('admin', '123', 'Admin', (SELECT EmployeeID FROM Employee WHERE NationalCode = '2222222222'));

INSERT INTO AppUser (Username, Password, Role, EmployeeID) 
VALUES ('agent', '123', 'Employee', (SELECT EmployeeID FROM Employee WHERE NationalCode = '3333333333'));

INSERT INTO AppUser (Username, Password, Role, CustomerID) 
VALUES ('mahdi', '123', 'Customer', (SELECT CustomerID FROM Customer WHERE NationalCode = '1234567890'));

INSERT INTO AppUser (Username, Password, Role, CustomerID) 
VALUES ('zahra', '123', 'Customer', (SELECT CustomerID FROM Customer WHERE NationalCode = '1234567898'));
GO

-- Stored Procedure for verifying user credentials from the application
CREATE PROCEDURE sp_UserLogin
    @InputUsername NVARCHAR(50),
    @InputPassword NVARCHAR(256)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM AppUser WHERE Username = @InputUsername AND Password = @InputPassword)
    BEGIN
        SELECT 
            Username, 
            Role, 
            ISNULL(CAST(CustomerID AS NVARCHAR), 'N/A') AS CustomerID, 
            ISNULL(CAST(EmployeeID AS NVARCHAR), 'N/A') AS EmployeeID,
            'Login Successful' AS StatusMessage
        FROM AppUser 
        WHERE Username = @InputUsername AND Password = @InputPassword;
    END
    ELSE
    BEGIN
        RAISERROR ('Invalid Username or Password!', 16, 1);
    END
END;
GO

-- Permissions for Manager Role (Full Operational Access)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO ManagerRole;
GRANT EXECUTE TO ManagerRole;

-- Permissions for Employee Role (Restricted Access)
GRANT SELECT ON SCHEMA::dbo TO EmployeeRole;
GRANT INSERT, UPDATE ON Customer TO EmployeeRole;
GRANT INSERT, UPDATE ON Reservation TO EmployeeRole;
GRANT INSERT, UPDATE ON Payment TO EmployeeRole;
GRANT INSERT, UPDATE ON Repair TO EmployeeRole;
GRANT INSERT, UPDATE ON Sale TO EmployeeRole;

-- Deny sensitive actions for Employee
DENY DELETE ON SCHEMA::dbo TO EmployeeRole;
DENY UPDATE ON Employee TO EmployeeRole;
DENY INSERT, UPDATE ON AppUser TO EmployeeRole;
DENY SELECT ON dbo.vw_CarROI_Analysis TO EmployeeRole;
DENY SELECT ON dbo.vw_IncomeReportByBrand TO EmployeeRole;

-- Execute permissions for Employee (Allowed procedures only)
GRANT SELECT ON dbo.fn_AdvancedCarSearch TO EmployeeRole;
GRANT EXECUTE ON dbo.sp_UserLogin TO EmployeeRole;
GRANT EXECUTE ON dbo.sp_RegisterNewReservation TO EmployeeRole;
GRANT EXECUTE ON dbo.sp_RegisterCarSale TO EmployeeRole;
GRANT EXECUTE ON dbo.sp_ProcessCarReturnAndLateFees TO EmployeeRole;
GRANT EXECUTE ON dbo.sp_PayPenaltyDebt TO EmployeeRole;

-- Permissions for Customer Role (Minimal Access)
GRANT SELECT ON dbo.vw_AvailableCars TO CustomerRole;
GRANT EXECUTE ON dbo.sp_UserLogin TO CustomerRole;

-- Strict Denials for Customer
DENY SELECT ON Customer TO CustomerRole;
DENY SELECT ON Employee TO CustomerRole;
DENY SELECT ON Reservation TO CustomerRole;
DENY EXECUTE ON dbo.sp_RegisterNewReservation TO CustomerRole;
DENY EXECUTE ON dbo.sp_RegisterCarSale TO CustomerRole;
GO


-- server permissions
--USE [master];
--GO

-- Allow the System Admin (sa) to impersonate these logins for testing purposes
--GRANT IMPERSONATE ON LOGIN::CarCustomerLogin TO [sa];
--GRANT IMPERSONATE ON LOGIN::CarEmployeeLogin TO [sa];
--GRANT IMPERSONATE ON LOGIN::CarManagerLogin TO [sa];
--GO