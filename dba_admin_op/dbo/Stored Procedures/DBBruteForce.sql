-- =============================================
-- Author:		John Imel
-- Create date: 2016/05/02
-- Update date: 
-- Description:	http://www.sqlservercentral.com/scripts/bruteforce/140542/
-- =============================================
CREATE PROCEDURE [dbo].[DBBruteForce]
	@searchvalue varchar(4000),
	@type varchar(200),
	@fuzzy BIT,
	@fuzzyoperator VARCHAR(200)
AS
BEGIN
	SET NOCOUNT ON;
	--build up helper table for types used later to limit rows we will query
	DECLARE @typelist TABLE(rowid INT IDENTITY, TYPE VARCHAR(255), typename varchar(255) PRIMARY KEY(type,typename));
	--feel free to add more in here if you need currently this only supports number, string and date
	INSERT INTO @typelist(type,typename)
	VALUES 
	('number','decimal'),
	('number','numeric'),
	('string','char'),
	('number','smallint'),
	('string','varchar'),
	('date','datetime'),
	('string','nvarchar'),
	('string','text'),
	('string','ntext'),
	('number','int'),
	('number','bigint'),
	('date','smalldatetime'),
	('number','float'),
	('number','money');
	--now remove the temp tbles if they already exists

	IF OBJECT_ID('tempdb..#TempCols') IS NOT NULL
	DROP TABLE #TempCols;
	
	IF OBJECT_ID('tempdb..#TempBruteForce') IS NOT NULL
	DROP TABLE #TempBruteForce;
	
	--create the temp table needed for the search
	CREATE TABLE #TempCols(id INT IDENTITY PRIMARY KEY, tbl VARCHAR(255) NOT null, col VARCHAR(255) NOT null, TYPE varchar(255));
	CREATE TABLE #TempBruteForce(id INT IDENTITY PRIMARY KEY, tbl VARCHAR(255) NOT null, tblqry Nvarchar(max), cnt INT DEFAULT (0),processed BIT DEFAULT(0),sqltxt Nvarchar(max),errortxt NVARCHAR(max));
	
	--there shouldnt be a huge need to a index here so im skipping that
	
	--now we have 2 seperate ways to deal with this, one for strings and one for the rest
	IF(@type = 'string')
	BEGIN
		INSERT INTO #TempCols(tbl,col,type)	
		SELECT DISTINCT '[' + ss.name + '].[' + t.name + ']' AS tblname, c.name AS colname, st.name AS coltype
		FROM sys.tables t
		INNER JOIN sys.columns c ON c.object_id = t.object_id
		INNER JOIN sys.types st ON st.system_type_id = c.system_type_id AND st.name != 'sysname'
		INNER JOIN sys.schemas ss ON ss.schema_id = t.schema_id 
		WHERE EXISTS (SELECT 1 FROM @typelist WHERE type = @type AND typename = st.name)
		AND (st.name IN ('ntext','text') OR c.max_length >= LEN(@searchvalue))
		
		--now lets combine these to lessen the load on the server dependent on what was requested by grouping these by table
		--then combining all the columns into one where clause, this will reduce the number of searches to the number of tables with qualifying columns in them
		--changing it a little to work with all the differnt options available
		IF(@fuzzy = 1 AND @fuzzyoperator = 'beginswith')
		BEGIN
			--begins with search
			INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)
			SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('[' + tt.col + '] LIKE '''+@searchvalue+'%''')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
		END
		ELSE IF(@fuzzy = 1 AND @fuzzyoperator = 'endswith')
		BEGIN
			--ends with search
			INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)
			SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('[' + tt.col + '] LIKE ''%'+@searchvalue+'''')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
		END
		ELSE IF(@fuzzy = 0)
		BEGIN
			--string exact match, using like to work around text and ntext columns but with no wildcards
			INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)
			SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('[' + tt.col + '] LIKE '''+@searchvalue+'''')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
		END
		ELSE
		BEGIN
			--default to contains
			INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)
			SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('charindex('''+@searchvalue+''',[' + tt.col + '], 1) > 0')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
		end
		
	END 
	ELSE IF(@type = 'number')
	BEGIN
		--build up the columns for number search
		INSERT INTO #TempCols(tbl,col,type)	
		SELECT DISTINCT '[' + ss.name + '].[' + t.name + ']' AS tblname, c.name AS colname, st.name AS coltype
		FROM sys.tables t
		INNER JOIN sys.columns c ON c.object_id = t.object_id
		INNER JOIN sys.types st ON st.system_type_id = c.system_type_id AND st.name != 'sysname'
		INNER JOIN sys.schemas ss ON ss.schema_id = t.schema_id 
		WHERE EXISTS (SELECT 1 FROM @typelist WHERE type = @type AND typename = st.name)
		
		--build up query texts
		INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)	
		SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('[' + tt.col + '] = '+@searchvalue+'')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
	END 
	ELSE IF(@type = 'date')
	BEGIN
		--build up TABLE AND col list OF datetime columns
		INSERT INTO #TempCols(tbl,col,type)	
		SELECT DISTINCT '[' + ss.name + '].[' + t.name + ']' AS tblname, c.name AS colname, st.name AS coltype
		FROM sys.tables t
		INNER JOIN sys.columns c ON c.object_id = t.object_id
		INNER JOIN sys.types st ON st.system_type_id = c.system_type_id AND st.name != 'sysname'
		INNER JOIN sys.schemas ss ON ss.schema_id = t.schema_id 
		WHERE EXISTS (SELECT 1 FROM @typelist WHERE type = @type AND typename = st.name)
		--in this case we cast datetimes as daes to do a simple comparison, mainly to avoid a 2 millisec difference causing a non match.  
		--Its better to error on the side of more rows idenified then less.
		INSERT INTO #TempBruteForce(tbl,tblqry,cnt,processed,sqltxt,errortxt)	
		SELECT t.tbl,'select count(1) from ' + tbl + ' where 1 = 1 and ('+REPLACE(x.csvvalue,'|',' or ')+')',0,0,NULL,null
			FROM #TempCols t
			 OUTER APPLY ( SELECT    STUFF(( SELECT  '|' + ('cast([' + tt.col + '] as date) = cast('''+@searchvalue+''' as date)')
													FROM    #TempCols tt
													WHERE   tt.tbl = t.tbl
												  FOR
													XML PATH(''), TYPE ).value('.[1]', 'nvarchar(max)'
												  ), 1, 1, '') AS csvvalue
								) x
			GROUP BY tbl,x.csvvalue
	END 
	ELSE
	BEGIN
		--if the type cant be determined just error the process out
		RAISERROR ('Unknown type encountered! string, number, and date are the only accepted types', 0, 20) WITH NOWAIT;
	END 
	
	--declarations
	DECLARE @rowcnt INT; 
	DECLARE @operator VARCHAR(200);
	DECLARE @where varchar(200);
	DECLARE @sqltxt NVARCHAR(max);
	DECLARE @SQL NVARCHAR(max);
	DECLARE @SQL_cnt NVARCHAR(max);
	DECLARE @ParmDefinition nVARCHAR(500);
	DECLARE @I  INT;
	DECLARE @id INT;
	DECLARE @tbl varchar(255);
	DECLARE @col VARCHAR(255);
	DECLARE @fldtype VARCHAR(255); 
	DECLARE @counter INT;
	
	DECLARE dbnames CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR 
	SELECT id,tbl,tblqry FROM #TempBruteForce
	
	OPEN dbnames
	FETCH NEXT FROM dbnames INTO @id,@tbl,@sqltxt
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @SQL_cnt = 'SELECT @IOUT = ('+@sqltxt+');';
		SELECT @SQL =  @sqltxt;
		SET @ParmDefinition = N'@IOUT INT OUTPUT';
		
		BEGIN TRY
			EXEC sp_executesql 
			@SQL_cnt, 
			@ParmDefinition,
			@IOUT=@I OUTPUT;
			
			--get count results and update the temptable, mark as processed
			UPDATE #TempBruteForce SET cnt = @I, sqltxt = @sql, processed = 1 WHERE id = @id;
			
			--if @i is greater than 0 than lets print the query to the messages, allows a preview of data found before it finishes, 
			--it can take an hour on large databases with large tables and lots of rows.  so sometimes i dont like to wait.
			IF(@I > 0)
			BEGIN
				RAISERROR (@SQL, 0, 1) WITH NOWAIT;
			END
			ELSE
			BEGIN
				--i like to at least print the table out for ones nothing was found in, mainly to tell where its at in the process
				DECLARE @temptxt VARCHAR(255);
				SET @temptxt = @tbl + ': [no data found]'
				RAISERROR (@temptxt, 0, 1) WITH NOWAIT;
			end
			
		END TRY
		BEGIN CATCH
			--in this case i am interested in what errors so lets just record that one back in the temp table as an error
			PRINT('Error occurred in table: '+@tbl+'');
			UPDATE t SET processed = 1,errortxt = @sqltxt
			FROM #TempBruteForce t
			where t.id = @id;
		END CATCH
	
	
		FETCH NEXT FROM dbnames INTO @id,@tbl,@sqltxt
	END
	
	CLOSE dbnames
	DEALLOCATE dbnames
	
	SELECT 'Search Results';
	SELECT * FROM #TempBruteForce WHERE cnt > 0 ORDER BY cnt DESC;
	SELECT 'Errors Encountered';
	SELECT * FROM #TempBruteForce WHERE LEN(errortxt) > 0;

	SET NOCOUNT OFF;
	
END