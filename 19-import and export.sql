USE master;
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

USE CarManagement_Final;
GO

EXEC xp_cmdshell 'bcp "SELECT ''CarID'', ''VIN'', ''Model'', ''TotalRentIncome'', ''TotalRepairCost'', ''NetProfit'' UNION ALL SELECT CAST(CarID AS NVARCHAR(250)), CAST(VIN AS NVARCHAR(250)), CAST(Model AS NVARCHAR(250)), CAST(TotalRentIncome AS NVARCHAR(250)), CAST(TotalRepairCost AS NVARCHAR(250)), CAST(NetProfit AS NVARCHAR(250)) FROM CarManagement_Final.dbo.vw_CarROI_Analysis" queryout "C:\Users\Mr Kazemayni\Desktop\phase 3\car-database-management\Manager_ROI.csv" -T -c -t,';

EXEC xp_cmdshell 'bcp "SELECT ''EmployeeID'', ''FullName'', ''Position'', ''TotalSalesContracts'', ''TotalSalesVolume'', ''EarnedCommission'' UNION ALL SELECT CAST(EmployeeID AS NVARCHAR(250)), CAST(FullName AS NVARCHAR(250)), CAST(Position AS NVARCHAR(250)), CAST(TotalSalesContracts AS NVARCHAR(250)), CAST(TotalSalesVolume AS NVARCHAR(250)), CAST(EarnedCommission AS NVARCHAR(250)) FROM CarManagement_Final.dbo.vw_EmployeeCommissionReport" queryout "C:\Users\Mr Kazemayni\Desktop\phase 3\car-database-management\Employee_Commission.csv" -T -c -t,';

EXEC xp_cmdshell 'bcp "SELECT * FROM CarManagement_Final.dbo.vw_AvailableCars FOR XML PATH(''Car''), ROOT(''AvailableCars'')" queryout "C:\Users\Mr Kazemayni\Desktop\phase 3\car-database-management\Customer_Cars.xml" -T -c';
GO

USE master;
GO
EXEC sp_configure 'xp_cmdshell', 0;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO