-- Script Name:     PrintMax
-- Description:     The stored procedure created by this script prints a text of any size, even if the size is greater than 8,000 bytes,
--                  which is the limit of the regular PRINT statement. It splits the large text into chunks of up to 4,000 bytes,
--                  and then uses the regular PRINT statement. It searches for line breaks in the text,
--                  and prefers the split to occur where there are line breaks, so that the output is more readbale.
-- Author:          Guy Glantser, Madeira
-- Last Updated On: 10/12/2011
-- Fixed By Rimer Sharon On 10/7/12 : add CASE ON @intLineBreakIndex
CREATE PROCEDURE [dbo].[PrintMax] 
(
       @inLargeText AS NVARCHAR(MAX)
)
AS
BEGIN 
	-- Declare the variables
	DECLARE
			@nvcReversedData    NVARCHAR(MAX) ,
			@intLineBreakIndex  INT ,
			@intSearchLength    INT    = 4000;


	-- Print chunks of up to 4,000 bytes

	WHILE LEN (@inLargeText) > @intSearchLength
	BEGIN
			-- Find the last line break in the current chunk, if such exists

			SET @nvcReversedData       = LEFT (@inLargeText , @intSearchLength);
			SET @nvcReversedData       = REVERSE (@nvcReversedData);
			SET @intLineBreakIndex     = CHARINDEX (CHAR(10) + CHAR(13) , @nvcReversedData);

			-- Print the current chunk up to the last line break (or the whole chunk, if there is no line break)
			PRINT LEFT (@inLargeText , @intSearchLength - (CASE WHEN @intLineBreakIndex = 0 THEN 0 ELSE @intLineBreakIndex + 1 END));

			-- Trim the printed chunk
			SET @inLargeText = RIGHT (@inLargeText , LEN (@inLargeText) - @intSearchLength + (CASE WHEN @intLineBreakIndex = 0 THEN 0 ELSE @intLineBreakIndex - 1 END));

	END;

	-- Print the last chunk
	IF LEN (@inLargeText) > 0
			PRINT @inLargeText;
END