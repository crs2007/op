--LISTING 3: T-SQL Code That Creates a Function to Count the Number of Times a String 
--Appears in Another String
--http://sqlmag.com/t-sql/counting-instances-word-record
CREATE FUNCTION Utility.WordRepeatedNumTimes (@SourceString varchar(8000),@TargetWord varchar(8000))
RETURNS int
AS
BEGIN
DECLARE @NumTimesRepeated int
 	,@CurrentStringPosition int
	,@LengthOfString int
	,@PatternStartsAtPosition int
	,@LengthOfTargetWord int
	,@NewSourceString varchar(8000)

	SET @LengthOfTargetWord = len(@TargetWord)
	SET @LengthOfString = len(@SourceString)
	SET @NumTimesRepeated = 0
	SET @CurrentStringPosition = 0
	SET @PatternStartsAtPosition = 0
	SET @NewSourceString = @SourceString

	WHILE len(@NewSourceString) >= @LengthOfTargetWord
	BEGIN

		SET @PatternStartsAtPosition = CHARINDEX (@TargetWord,@NewSourceString)
	
		IF @PatternStartsAtPosition <> 0
		BEGIN
			SET @NumTimesRepeated = @NumTimesRepeated + 1

			SET @CurrentStringPosition = @CurrentStringPosition + @PatternStartsAtPosition + @LengthOfTargetWord;

			SET @NewSourceString = SUBSTRING(@NewSourceString, @PatternStartsAtPosition + @LengthOfTargetWord, @LengthOfString);

		END
		ELSE
		BEGIN
			SET @NewSourceString = ''
		END
	
	END
	
	RETURN @NumTimesRepeated

END