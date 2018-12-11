﻿
CREATE PROCEDURE [dbo].[CPUSIMPLE]

AS

BEGIN

DECLARE

@n numeric(16,6) = 0,

@a DATETIME,

@b DATETIME

DECLARE

@f int

SET @f = 1

SET @a=CURRENT_TIMESTAMP

WHILE @f <= 10000000

BEGIN

SET @n = @n % 999999 + sqrt(@f)

SET @f = @f + 1

END

SET @b = CURRENT_TIMESTAMP

PRINT 'Timing = ' + ISNULL(CAST(DATEDIFF(MS, @a, @b)AS VARCHAR),'')

PRINT 'Res = ' + ISNULL(CAST(@n AS VARCHAR),'')

END