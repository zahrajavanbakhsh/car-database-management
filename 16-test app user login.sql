-- TEST APPLICATION USERS (MAHDI & ZAHRA)
USE CarManagement_Final;
GO
SET NOCOUNT ON;

BEGIN TRAN AppCustomerAuthTest;

-- ==========================================
-- 0. SETUP MOCK DATA
-- ==========================================
PRINT '>>> SETTING UP ISOLATED MOCK DATA (CUSTOMER USERS) <<<';
INSERT INTO AppUser (Username, Password, Role) VALUES 
('mahdi1', '123', 'Customer'),
('zahra1', '123', 'Customer');
PRINT '>>> MOCK USERS CREATED IN MEMORY <<<';
PRINT '';

PRINT '--- TESTING APP AUTHENTICATION FOR CUSTOMERS ---';
PRINT '';

-- Test 1: Mahdi logs into the mobile app (Success)
PRINT 'SCENARIO 1: Mahdi tries to login with correct password -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'mahdi', @InputPassword = '123';

-- Test 2: Zahra logs into the mobile app (Success)
PRINT 'SCENARIO 2: Zahra tries to login with correct password -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'zahra', @InputPassword = '123';

-- Test 3: Hacker tries to guess Mahdi's password (Fails)
PRINT 'SCENARIO 3: Someone tries to login as mahdi with wrong password -> EXPECTED: FAIL (BLOCKED)';
BEGIN TRY
    EXEC dbo.sp_UserLogin @InputUsername = 'mahdi', @InputPassword = 'wrongpassword';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [APP SECURITY: Login Blocked!];
END CATCH;

ROLLBACK TRAN AppCustomerAuthTest;
PRINT '';
PRINT '--- TRANSACTION ROLLED BACK (Database remains untouched) ---';
GO