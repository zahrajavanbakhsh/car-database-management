-- functions
-- final rental cost 
GO
CREATE FUNCTION fn_CalculateRentalCost 
(
    @CarID INT,
    @Days INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @DailyPrice DECIMAL(18,2);
    DECLARE @TotalCost DECIMAL(18,2);
    
    SELECT @DailyPrice = DailyRentPrice FROM Car WHERE CarID = @CarID;
    
    SET @TotalCost = @DailyPrice * @Days;
    
    RETURN @TotalCost;
END;

-- availablity cars for triggers and procejures
GO
CREATE FUNCTION fn_CheckCarAvailability 
(
    @CarID INT,
    @RequestedStartDate DATETIME,
    @RequestedEndDate DATETIME
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsAvailable BIT = 1;
    
    IF EXISTS (
        SELECT 1 FROM Reservation 
        WHERE CarID = @CarID 
        AND Status IN ('Confirmed', 'Active')
        AND (StartDate < @RequestedEndDate AND EndDate > @RequestedStartDate)
    )
    BEGIN
        SET @IsAvailable = 0;
    END

    RETURN @IsAvailable;
END;


-- all reservation of a customer for discount
GO
CREATE FUNCTION fn_GetCustomerTotalReservations 
(
    @CustomerID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @ResCount INT;
    
    SELECT @ResCount = COUNT(ReservationID) 
    FROM Reservation 
    WHERE CustomerID = @CustomerID AND Status = 'Completed';
    
    RETURN ISNULL(@ResCount, 0);
END;
GO

