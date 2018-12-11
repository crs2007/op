
-- =============================================
-- Author:		Sharon
-- Create date: 29/04/2013
-- Update date: 29/10/2015 Sand to DBA
-- Description:	Get Mail Recipiant By Procedure Name
-- =============================================
CREATE FUNCTION [Report].[ufn_Mail_GetMailRecipiantByProcedureName]
(
	@ProcedureName sysname
)
RETURNS VARCHAR(2000)
AS
BEGIN	
	DECLARE @MailRecipiant VARCHAR(2000) = '';

	SELECT	@MailRecipiant += CONCAT(MR.EMail,';')
	FROM	[Report].Mail_MailRecipiantProcedure CL
			INNER JOIN [Report].Mail_Procedure P ON P.ID = CL.ProcedureID
			INNER JOIN [Report].Mail_MailRecipiant MR ON MR.ID = CL.MailRecipiantID
	WHERE	P.ProcedureName = @ProcedureName;

	IF	@MailRecipiant IS NULL OR @MailRecipiant = ''
		SELECT	@MailRecipiant += CONCAT(MR.EMail,';')
		FROM	[Report].Mail_MailRecipiant MR
		WHERE	MR.Category LIKE '%' + @ProcedureName + '%'
				AND MR.EMail != '';

	IF	@MailRecipiant IS NULL OR @MailRecipiant = ''
		SELECT	@MailRecipiant += CONCAT(MR.EMail,';')
		FROM	[Report].Mail_MailRecipiant MR
		WHERE	MR.Category like '%DBA%'
				AND MR.EMail != '';
		 
	RETURN @MailRecipiant;
END