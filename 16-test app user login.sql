-- TEST APPLICATION USERS (MAHDI & ZAHRA)
USE CarManagementDB;
GO

PRINT '--- TESTING APP AUTHENTICATION FOR CUSTOMERS ---';

-- Test 1: Mahdi logs into the mobile app (Success)
PRINT 'SCENARIO 1: Mahdi tries to login with correct password';
EXEC dbo.sp_UserLogin @InputUsername = 'mahdi', @InputPassword = '123';

-- Test 2: Zahra logs into the mobile app (Success)
PRINT 'SCENARIO 2: Zahra tries to login with correct password';
EXEC dbo.sp_UserLogin @InputUsername = 'zahra', @InputPassword = '123';

-- Test 3: Hacker tries to guess Mahdi's password (Fails)
PRINT 'SCENARIO 3: Someone tries to login as mahdi with wrong password';
BEGIN TRY
    EXEC dbo.sp_UserLogin @InputUsername = 'mahdi', @InputPassword = 'wrongpassword';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [APP SECURITY: Login Blocked!];
END CATCH;
GO