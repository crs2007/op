

/*
This procedures starts a server side trace for the blocking report event.

Parameters:
@FilePath - The location of the trace file.  If you don't send any value it will use the path d:\trace.  Make
sure that you have this path or always send the needed path.  You can also modify the code to have a different default path.

@maxfilesize - As the name implies the trace file's maxsimum size

@DurationInMinutes - How many minutes the trace will run until it will stop running aotumaticly

*/

CREATE PROCEDURE [Utility].[usp_PerformanceTuning_SetQureTrace]
    (
      @FilePath NVARCHAR(150) = NULL ,
      @maxfilesize BIGINT = 50 ,
      @DurationInMinutes INT = 120,
	  @HostName sysname = NULL
    )
AS
BEGIN
	SET NOCOUNT ON;
    DECLARE @rc INT;
    DECLARE @TraceID INT;
    DECLARE @StopTime DATETIME = GETDATE();

    BEGIN TRY
        IF @FilePath IS NULL
            SELECT  @FilePath = N'H:\Temp\Qure' + N'\Qure_'
                    + CONVERT(VARCHAR(20), GETUTCDATE(), 112) + '_'
                    + REPLACE(CONVERT(VARCHAR(20), GETUTCDATE(), 108), ':', '');

        IF ISNULL(@maxfilesize, 0) <= 0
            SET @maxfilesize = 50;

        SET @StopTime = DATEADD(MINUTE, @DurationInMinutes, @StopTime);

        EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, @FilePath, @maxfilesize,
            @StopTime; 
        IF ( @rc != 0 )
            RAISERROR('could not create trace',16,1);

	

		-- Set the events
        DECLARE @on BIT;
        SET @on = 1;
		EXEC sp_trace_setevent @TraceID, 10, 1, @on;
		EXEC sp_trace_setevent @TraceID, 10, 10, @on;
		EXEC sp_trace_setevent @TraceID, 10, 6, @on;
		EXEC sp_trace_setevent @TraceID, 10, 8, @on;
		EXEC sp_trace_setevent @TraceID, 10, 11, @on;
		EXEC sp_trace_setevent @TraceID, 10, 12, @on;
		EXEC sp_trace_setevent @TraceID, 10, 13, @on;
		EXEC sp_trace_setevent @TraceID, 10, 14, @on;
		EXEC sp_trace_setevent @TraceID, 10, 15, @on;
		EXEC sp_trace_setevent @TraceID, 10, 16, @on;
		EXEC sp_trace_setevent @TraceID, 10, 17, @on;
		EXEC sp_trace_setevent @TraceID, 10, 18, @on;
		EXEC sp_trace_setevent @TraceID, 10, 26, @on;
		EXEC sp_trace_setevent @TraceID, 10, 31, @on;
		EXEC sp_trace_setevent @TraceID, 10, 35, @on;
		EXEC sp_trace_setevent @TraceID, 10, 48, @on;
		EXEC sp_trace_setevent @TraceID, 10, 60, @on;
		EXEC sp_trace_setevent @TraceID, 12, 1, @on;
		EXEC sp_trace_setevent @TraceID, 12, 11, @on;
		EXEC sp_trace_setevent @TraceID, 12, 6, @on;
		EXEC sp_trace_setevent @TraceID, 12, 8, @on;
		EXEC sp_trace_setevent @TraceID, 12, 10, @on;
		EXEC sp_trace_setevent @TraceID, 12, 12, @on;
		EXEC sp_trace_setevent @TraceID, 12, 13, @on;
		EXEC sp_trace_setevent @TraceID, 12, 14, @on;
		EXEC sp_trace_setevent @TraceID, 12, 15, @on;
		EXEC sp_trace_setevent @TraceID, 12, 16, @on;
		EXEC sp_trace_setevent @TraceID, 12, 17, @on;
		EXEC sp_trace_setevent @TraceID, 12, 18, @on;
		EXEC sp_trace_setevent @TraceID, 12, 26, @on;
		EXEC sp_trace_setevent @TraceID, 12, 31, @on;
		EXEC sp_trace_setevent @TraceID, 12, 35, @on;
		EXEC sp_trace_setevent @TraceID, 12, 48, @on;
		EXEC sp_trace_setevent @TraceID, 12, 60, @on;


	-- Set the Filters
        DECLARE @intfilter INT;
        DECLARE @bigintfilter BIGINT;
		IF @HostName IS NOT NULL
			EXEC sp_trace_setfilter @TraceID, 8, 0, 6, @HostName;-- N'SPIDER2'
	-- Set the trace status to start
        EXEC sp_trace_setstatus @TraceID, 1;

	-- display trace id for future references
	--select TraceID=@TraceID

        RETURN(0);
    END TRY
    BEGIN CATCH
        THROW;
        RETURN (-1);
    END CATCH;
END