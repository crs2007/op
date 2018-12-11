
CREATE FUNCTION [dbo].[ufn_Util_ConvertIntToDateTime](@id int, @it int)
RETURNS datetime
AS
BEGIN

    DECLARE @vt char(6), @d char(8), @dt datetime
    SELECT @d = convert(varchar, @id)
	SET @vt = convert(CHAR,@it)

    WHILE (len(@vt) < 6)
	BEGIN
		IF len(@vt) = 5 SET @vt = '0' + convert(char,@vt)
		ELSE
			SET @vt = RTRIM(@vt) + '0';
	END	

    SELECT @dt = left (@d,4) + '-' + substring(@d,5,2) + '-' + right(@d,2) + ' ' + left(@vt,2) + ':' + substring(@vt, 3,2)

    RETURN (@dt)
END