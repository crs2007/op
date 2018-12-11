-- =============================================
-- Author:		Liran Vayman
-- Create date: 2016.08.16
-- Description:	Exec...INTO SP
-- Exec [dbo].[spGetTableFromSP] @Sp_Name = 'sp_who', @NewTable =  '##TempFor
--**** Please notice that SP that uses Temp tables in it - Can't be EXEC INTO!!!
-- =============================================
create PROCEDURE [dbo].[spGetTableFromProcedure]
(
	
	@Sp_Name nvarchar(max), --The SP name you want to execute 
	@DBName sysname = NULL, --The DB name you want to execute from.  default is NULL which will give current DB
	@SchemaName sysname = 'dbo', -- the SP schema. Default is 'dbo'
	@Parameters nvarchar (max) = NULL, -- the params the SP gets. Default is NULL
	@NewTable sysname = NULL --The table in which you want to insert the SP result set to. If regular temp table is set - it will be changed to a global temp table.
)
AS
BEGIN
	SET NOCOUNT ON;
	/*Set Current DB if no DBName was provided*/
	Select @DBName = ISNULL (@DBName, DB_NAME()), @Parameters = ISNULL(@Parameters, '')

	/*Remove brackets from SP name*/
	IF @Sp_Name like '%]' 
	BEGIN
		select @Sp_Name =  SUBSTRING(@Sp_Name, 2, LEN(@Sp_Name)-2)
	END

	/*Remove unnecessary characters in SP name*/
	Declare @Checksp varchar(max)  = '', @SPFullPath nvarchar(max) = ''

	if @Sp_Name like '% %'
	select @Checksp =  LEFT(@Sp_Name, CHARINDEX(' ', @Sp_Name) - 1)
	else 
	select @Checksp = @Sp_Name

	/*Create the full path for the SP (DB.Schema.Object)*/
	select @SPFullPath = @DBName + '.' + @SchemaName + '.' + @Checksp + ' ' + @Parameters
	
	/*Check if SP exists before starting*/
	Create table #CheckSPName (DBName sysname);

	select @Checksp = 'Select name from '+ @DBName + '.' + 'sys.procedures Where name = ''' + @Checksp + '''and SCHEMA_NAME(schema_id) = ''' + @SchemaName + ''''

	insert into #CheckSPName
	EXEC (@Checksp)

	select @Checksp = 'Select name from master.sys.sysobjects Where name = ''' + @Sp_Name + '''and xtype = ''P'''

	insert into #CheckSPName
	EXEC (@Checksp)

	IF NOT EXISTS (SELECT 1 FROM  #CheckSPName)
	RAISERROR ('SP does not exists.', -- Message text.
               16, -- Severity.
               1 -- State.
               );

	DROP TABLE #CheckSPName


	

	/*Check if table is  a Global Temp table. if not - change it to global*/
	Declare @TempTablecheck varchar (1000),
			@TableChangedMessage varchar (100) = ''

	if @NewTable is not null
	Begin

		if @NewTable like '#%' and @NewTable not like '##%'
		select @NewTable = '#' + @NewTable

		select @TempTablecheck = 'tempdb..' + @NewTable

		/*Check if Global Temp Table exists. If so - rename the new one*/
		IF OBJECT_ID(@TempTablecheck) IS NOT NULL
		begin 

			select @NewTable = @NewTable + right (newid(), 5)
			select @TableChangedMessage = '/*(Please notice that temp table name was changed)*/'

		end
	End

	Else if @NewTable is null
	Begin
		select @NewTable = '##Temp' + right (newid(), 5)
	End


	/*Create a temp table for SP schema*/
	declare @SQString nvarchar (max) = ''

	BEGIN TRY

		create table #TableTemplate
		(
		is_hidden	bit NOT NULL	,
		column_ordinal	int NOT NULL	,
		name	sysname NULL	,
		is_nullable	bit NOT NULL	,
		system_type_id	int NOT NULL	,
		system_type_name	nvarchar(256) NULL	,
		max_length	smallint NOT NULL	,
		precision	tinyint NOT NULL	,
		scale	tinyint NOT NULL	,
		collation_name	sysname NULL	,
		user_type_id	int NULL	,
		user_type_database	sysname NULL	,
		user_type_schema	sysname NULL	,
		user_type_name	sysname NULL	,
		assembly_qualified_type_name	nvarchar(4000)	,
		xml_collection_id	int NULL	,
		xml_collection_database	sysname NULL	,
		xml_collection_schema	sysname NULL	,
		xml_collection_name	sysname NULL	,
		is_xml_document	bit NOT NULL	,
		is_case_sensitive	bit NOT NULL	,
		is_fixed_length_clr_type	bit NOT NULL	,
		source_server	sysname NULL	,
		source_database	sysname	NULL,
		source_schema	sysname	NULL,
		source_table	sysname	NULL,
		source_column	sysname	NULL,
		is_identity_column	bit NULL	,
		is_part_of_unique_key	bit NULL	,
		is_updateable	bit NULL	,
		is_computed_column	bit NULL	,
		is_sparse_column_set	bit NULL	,
		ordinal_in_order_by_list	smallint NULL	,
		order_by_list_length	smallint NULL	,
		order_by_is_descending	smallint NULL	,
		tds_type_id	int NOT NULL	,
		tds_length	int NOT NULL	,
		tds_collation_id	int NULL	,
		tds_collation_sort_id	tinyint NULL	
		)

		/*Insert SP Result Set columns into temp table*/
		insert into #TableTemplate
		Exec sp_describe_first_result_set @tsql = @SPFullPath

		/*if SP does not return result set - return error*/
		if @@ROWCOUNT = 0 
		RAISERROR ('SP return no result set.', -- Message text.
            16, -- Severity.
            1 -- State.
            );


		select @SQString = @SQString+ name + ' ' + system_type_name + ' ' + case when is_nullable = 1 then 'NULL' else 'NOT NULL' END /*Null column definition*/+ ','
		from #TableTemplate

		select @SQString = 'CREATE TABLE ' + @NewTable + ' (' + @SQString 
		select @SQString = reverse(stuff(reverse(@SQString), 1, 1, '')) /*Remove extra comma at the end of the string*/
		select @SQString = @SQString + ')'
		print @SQString

		exec sp_executesql @SQString /*Creating the temp table*/

		Declare @SQLST nvarchar (max) = ''

		select @SQLST = 'Insert into ' + @NewTable + ' Exec ' + @SPFullPath

		exec sp_executesql @SQLST


		/*Prepare select command for the new temp table of the SP*/
		Declare @EndSt nvarchar (max) = ''

		select @EndSt = 'Select * from ' + @NewTable


		/*Prepare drop table command for the new temp table of the SP*/
		Declare @DropTable nvarchar (max) = ''

		select @DropTable = 'Drop Table ' + @NewTable


		/*The reult set containing the select + drop table commands for the user*/
		select 'Run This For Result Set: ' , @EndSt + ' ' + @TableChangedMessage
		
		select 'Dont Forget To Drop Table...', @DropTable

	

	END TRY

	BEGIN CATCH  

		Declare @ErrorMessage nvarchar (max)
		select @ErrorMessage = ERROR_MESSAGE()

		Declare @DropAfterErrorTable sysname = 'tempdb..' + @NewTable

		IF OBJECT_ID(@DropAfterErrorTable) IS NOT NULL OR OBJECT_ID(@NewTable) IS NOT NULL
		exec (@DropTable)

		RAISERROR (@ErrorMessage, -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );


	END CATCH; 

	drop table #TableTemplate

END