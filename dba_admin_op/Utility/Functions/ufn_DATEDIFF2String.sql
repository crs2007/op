
-- =============================================
-- Author:                      Sharon
-- Create date: 19/05/2016
-- Update date: 
-- Description:   DATEDIFF to String
-- =============================================
CREATE FUNCTION [Utility].[ufn_DATEDIFF2String]
    (
      @Start DATETIME ,
      @End DATETIME
    )
RETURNS VARCHAR(MAX)
AS
BEGIN
            DECLARE @S VARCHAR(max);
            IF DATEDIFF(DAY,@Start,ISNULL(@End,GETDATE())) = 0
            BEGIN
                        SET @S = 'ToDay';
                RETURN @S;
            END
    SELECT         @S = CASE WHEN [Y].[Years] IS NULL THEN 'Never Been Activated ***' ELSE 
                                                CASE WHEN [Y].[Years] > 0 THEN CAST([Y].[Years] AS varchar(4)) +' Year' + IIF([Y].[Years] = 1,' ' , 's ') ELSE '' END +
                                                CASE WHEN [M].[Months] > 0 THEN CAST([M].[Months] AS varchar(2)) +' Month' + IIF([M].[Months] = 1,' ' , 's ') ELSE '' END +
                                                CASE WHEN [D].[Days] > 0 THEN CAST([D].[Days] AS varchar(2)) +' Day' + IIF([D].[Days] = 1,' ' , 's ')  ELSE '' END
                                    
                                    END 
    FROM           (SELECT            ISNULL(@End,DATEADD(s, 86399, CONVERT(DATETIME,CONVERT(DATE,GETDATE()))))CurrentDay,@Start [FromDate])CD
                                    CROSS APPLY (SELECT YEAR(CD.CurrentDay) - YEAR(CD.FromDate) - (CASE WHEN MONTH(CD.CurrentDay) - MONTH(CD.FromDate) < 0 THEN 1 ELSE 0 END) [Years])Y
                                    CROSS APPLY (SELECT DATEDIFF(MONTH,DATEADD(YEAR,Y.Years,CD.FromDate),CD.CurrentDay) - (CASE WHEN DAY(CD.CurrentDay) - DAY(CD.FromDate) < 0 THEN 1 ELSE 0 END) [Months])M
                                    CROSS APPLY (SELECT DATEDIFF(DAY,DATEADD(MONTH,M.Months,DATEADD(YEAR,Y.Years,CD.FromDate)),CD.CurrentDay)[Days])D
    RETURN @S;
END;