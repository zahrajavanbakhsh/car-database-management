USE [master];
GO

-- 1. SERVER LEVEL LOGINS

-- Drop existing logins to prevent errors during rebuild
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarManagerLogin') 
    DROP LOGIN CarManagerLogin;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarEmployeeLogin') 
    DROP LOGIN CarEmployeeLogin;

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'CarCustomerLogin') 
    DROP LOGIN CarCustomerLogin;
GO

-- Create SQL Logins for database-level access
CREATE LOGIN CarManagerLogin WITH PASSWORD = '123';
CREATE LOGIN CarEmployeeLogin WITH PASSWORD = '123';
CREATE LOGIN CarCustomerLogin WITH PASSWORD = '123';
GO


USE CarManagement_Final;
GO

-- 2. DATABASE USERS & ROLES

-- Drop existing database users
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ManagerUser') 
    DROP USER ManagerUser;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EmployeeUser') 
    DROP USER EmployeeUser;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CustomerUser') 
    DROP USER CustomerUser;

-- Drop existing database roles
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ManagerRole') 
    DROP ROLE ManagerRole;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'EmployeeRole') 
    DROP ROLE EmployeeRole;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'CustomerRole') 
    DROP ROLE CustomerRole;
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


-- 3. PERMISSIONS CONFIGURATION

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