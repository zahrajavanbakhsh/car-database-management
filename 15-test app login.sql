-- TEST APPLICATION LOGIN & AUTHENTICATION
USE CarManagementDB;
GO
SET NOCOUNT ON;

PRINT '--- APPLICATION AUTHENTICATION TESTS ---';
PRINT '';

-- Scenario 1: Valid Admin Login
PRINT 'SCENARIO 1: Admin Login -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'admin', @InputPassword = '123';

-- Scenario 2: Valid Employee Login
PRINT 'SCENARIO 2: Employee Login -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'agent', @InputPassword = '123';

-- Scenario 3: Valid Customer Login (Mahdi)
PRINT 'SCENARIO 3: Customer Login (Mahdi) -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'mahdi', @InputPassword = '123';

-- Scenario 4: Valid Customer Login (Zahra)
PRINT 'SCENARIO 4: Customer Login (Zahra) -> EXPECTED: SUCCESS';
EXEC dbo.sp_UserLogin @InputUsername = 'zahra', @InputPassword = '123';

-- Scenario 5: Invalid Password Attempt
PRINT 'SCENARIO 5: Wrong Password -> EXPECTED: FAIL (APP BLOCK)';
BEGIN TRY
    EXEC dbo.sp_UserLogin @InputUsername = 'admin', @InputPassword = 'wrong_password!';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [AUTH FAILED: Invalid Password];
END CATCH;

-- Scenario 6: Non-existent Username Attempt
PRINT 'SCENARIO 6: Unknown Username -> EXPECTED: FAIL (APP BLOCK)';
BEGIN TRY
    EXEC dbo.sp_UserLogin @InputUsername = 'hacker_user', @InputPassword = '123';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [AUTH FAILED: User Not Found];
END CATCH;
GO