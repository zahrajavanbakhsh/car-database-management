-- TEST MANAGER ROLE PRIVILEGES
USE CarManagementDB;
GO
SET NOCOUNT ON;

BEGIN TRAN ManagerTestTran;
PRINT '--- TRANSACTION STARTED: MANAGER ROLE TESTS ---';

-- 1. Switch context to Manager
EXECUTE AS LOGIN = 'CarManagerLogin';
PRINT '>>> LOGGED IN AS: MANAGER <<<';

PRINT '';
-- Scenario 1: View sensitive Income Report (Should Succeed)
PRINT 'SCENARIO 1: View Income Report By Brand -> EXPECTED: SUCCESS';
SELECT * FROM dbo.vw_IncomeReportByBrand;

PRINT '';
-- Scenario 2: View sensitive ROI Analysis (Should Succeed)
PRINT 'SCENARIO 2: View ROI Analysis -> EXPECTED: SUCCESS';
SELECT * FROM dbo.vw_CarROI_Analysis;

PRINT '';
-- Scenario 3: Update employee commission rate (Should Succeed)
PRINT 'SCENARIO 3: Update Employee Commission -> EXPECTED: SUCCESS';
UPDATE Employee SET CommissionRate = 10.00 WHERE NationalCode = '3333333333';
PRINT 'Result: Commission rate updated successfully by Manager.';

PRINT '';
-- Scenario 4: Delete an old cancelled reservation (Should Succeed)
PRINT 'SCENARIO 4: Delete a reservation record -> EXPECTED: SUCCESS';
-- Manager has the right to delete records if needed
DELETE FROM Reservation WHERE Status = 'Cancelled';
PRINT 'Result: Deletion query executed successfully.';

-- Revert to original admin context
REVERT;
PRINT '>>> REVERTED TO ADMIN <<<';

ROLLBACK TRAN ManagerTestTran;
PRINT '--- TRANSACTION ROLLED BACK ---';
GO