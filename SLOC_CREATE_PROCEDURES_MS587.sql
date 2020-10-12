/**
--CLASS: MS587
--NAME: Thomas Wallace
--PROJECT: FINAL PROJECT
--DESC: 
--		This is the SQL for Creating and managing Procedures 
--=========================================================================================================
--	Change Date -INIT- Description of Change
--=========================================================================================================
--	10/11/2020 - TCW - INITIAL CREATION OF PROCEDURE SCRIPT
--
*/


--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

--SET 
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_Layout]
	@LO_NAME		varchar(100),
	@LO_DEV_ID		INT,
	@LO_NOTES		varchar(500) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/11/2020
-- PURPOSE: Handles Layouts (Add) 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/11/2020 - TCW - Intial Creationg of csp_ADD_Layout

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @MY_LO_ID as INT
DECLARE @RESULT as INT
DECLARE @ATTR_KEY_CD CHAR(8)

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@LO_DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@LO_DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@LO_DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END
	
		--BUILD DEVICE RECORD
		INSERT INTO dbo.LAYOUTS (LO_NAME, LO_DEV_ID, LO_NOTES)
		Select dbo.fnc_StripSpcChars(@LO_NAME), @LO_DEV_ID, dbo.fnc_StripSpcChars(@LO_NOTES)
		SET @MY_LO_ID = SCOPE_IDENTITY()

		/*----------------------------------------------------------------------------------------------------------
		WITH THE NEW LAYOUT AND DEVICE ASSIGNMENT TO THE LAYOUT WE CAN NOW SETUP THE DEVICE_EXT_ATTR AND PORT_ATTR.
		LAYOUTS ALLOW FOR CUSTOMIZATION AS THEY ASSOCIATE ATTRIBUTES TO A DEVICE 
		(AS TO WHERE A DEVICE IS JUST A DEVICE). DEVICES CONTAIN NO OWNERSHIP OR CUSTOMIZATION IF NOT USED IN LAYOUT
		----------------------------------------------------------------------------------------------------------*/
		--LOCAL TEMP TABLE FOR LOOP TO EXECUTE QUERY
		CREATE TABLE #ATTR_TEMP (
			ATTR_KEY_CD CHAR(8) NOT NULL,
			ATTR_VALUE VARCHAR(255) NULL,
			COMM_TYPE_CD CHAR(8) NOT NULL,
		)
		
		--INSERT INTO LOCAL TEMP TABLE (BOTH SETS OF ATTRIBUTES)
		INSERT INTO #ATTR_TEMP 
		Select COMM_CD, null AS ATTR_VALUE, COMM_TYPE_CD from dbo.COMMON_CODES CC WITH (NOLOCK) WHERE CC.COMM_TYPE_CD IN ('DEV_ATTR','PRT_ATTR') ORDER BY COMM_TYPE_CD, COMM_CD 

		--WALK THRU ALL AVAILALBE ATTR_KEY_CDS AND ADD THEM TO THE DEVICE_EXT_ATTR TABLE
		WHILE EXISTS(SELECT ATTR_KEY_CD from #ATTR_TEMP WHERE COMM_TYPE_CD = 'DEV_ATTR') BEGIN
			--GET KEY
			SELECT @ATTR_KEY_CD = ATTR_KEY_CD FROM #ATTR_TEMP WHERE COMM_TYPE_CD = 'DEV_ATTR'
			--ADD KEY INFO
			EXEC @RESULT = dbo.csp_ADD_Device_EXT_Attr @DEV_ID = @LO_DEV_ID, @LO_ID = @MY_LO_ID, @ATTR_KEY_CD = @ATTR_KEY_CD, @ATTR_VALUE = null, @USR = @REC_CRTE_USER_ID
			
			--CHECK RESULTS
			IF (@RESULT = 0) BEGIN
				SET @MSG = 'Error occured adding device attribute. (LO_ID=' + CAST(@My_LO_ID as varchar(10)) + '  -  ATTRIBUTE: ''' + @ATTR_KEY_CD + ''' )'
				RAISERROR (@MSG,15,1) 
			END

			--DELETE KEY FROM PROCESS TEMP TABLE
			DELETE FROM #ATTR_TEMP WHERE ATTR_KEY_CD = @ATTR_KEY_CD AND COMM_TYPE_CD = 'DEV_ATTR'
		END

		--Select * from dbo.DEVICE_PORTS



		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('LAYOUT_ERR') as ACT_TYP_ID,
			RTRIM('<<LAYOUT INSERT ERROR>>  -  [LAYOUT_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_Device]
	@DEV_TYP_ID		SMALLINT,
	@DEV_NAME		VARCHAR(100),
	@DEV_IMG		VARBINARY(MAX) = null,
	@DEV_MFG		VARCHAR(100) = null,
	@DEV_MODEL		VARCHAR(100) = null, 
	@DEV_SERIAL		VARCHAR(100) = null,
	@DEV_FW			VARCHAR(30) = null,
	@DEV_OS			VARCHAR(30) = null,
	@USR			VARCHAR(60) = null,
	@PRT_JSON		NVARCHAR(max)
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_ADD_Device
-- 10/10/2020 - TCW - Added varbinary(max) for device image (Stored in Device Table)
------------------------------------------------------------------------------------------------------------------
DECLARE @DEV_ID as int = 0
DECLARE @IMAGE as varbinary(max) 
DECLARE @ERRMSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @Temp as Table (
		ENTRY_ID int identity(1,1) not null,
		--ATTR_TYP char(1) not null,
		PRT_TYP_ID tinyint null,
		PRT_DIR_CD char(1) null,
		PRT_CNT tinyint null
	)


BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	--SET DEFAULT IMAGE TO NO IMAGE (IMAGE) FOR A NON DEFINED DEVICE IMAGE
	IF (@DEV_IMG IS NOT NULL)
		SET @IMAGE = @DEV_IMG
	ELSE
		SELECT @IMAGE = AD.APP_BIN_VALUE FROM DBO.APP_DEFAULTS AD WITH (NOLOCK) WHERE AD.APP_KEY = 'NO_IMAGE'


	BEGIN TRY
		--BUILD DEVICE RECORD
		INSERT INTO dbo.DEVICES (DEV_TYP_ID, DEV_NAME, DEV_IMG, DEV_MFG, DEV_MODEL, DEV_SERIAL, DEV_FW, DEV_OS, REC_CRTE_USER_ID)
		Select @DEV_TYP_ID, dbo.fnc_StripSpcChars(@DEV_NAME), @IMAGE, dbo.fnc_StripSpcChars(@DEV_MFG), dbo.fnc_StripSpcChars(@DEV_MODEL), dbo.fnc_StripSpcChars(@DEV_SERIAL), dbo.fnc_StripSpcChars(@DEV_FW), dbo.fnc_StripSpcChars(@DEV_OS), @REC_CRTE_USER_ID 
	
		--GETS THE INSERTED DEV_ID IDENTITY VALUE FROM THE RECENT STATEMENT
		SET @DEV_ID = SCOPE_IDENTITY() 
		
		--CHECK AND PROCESS JSON DATA	
		IF ISJSON(@PRT_JSON) > 0 
		BEGIN
			--PARSE JSON DATA (IF IT IS VALID JSON) THEN LOAD IT INTO A @TEMP TABLE FOR PROCESSING
			INSERT INTO @Temp (PRT_TYP_ID, PRT_DIR_CD, PRT_CNT) --, PRT_CHAN, PRT_DESC, PRT_GNDR, PRT_NAME)
			SELECT * FROM OPENJSON(@PRT_JSON)
				WITH ( 
					--ATTR_TYP CHAR(1) 'strict $.ATTR_TYP',
					PRT_TYP_ID tinyint 'strict $.PRT_TYP_ID',
					PRT_DIR_CD CHAR(1) 'strict $.PRT_DIR_CD',
					PRT_CNT tinyint 'strict $.PRT_CNT'
					--PRT_CHAN varchar(255) 'strict $.PRT_CHAN',
					--PRT_DESC varchar(255) 'strict $.PRT_DESC',
					--PRT_GNDR varchar(255) 'strict $.PRT_GNDR',
					--PRT_NAME varchar(255) 'strict $.PRT_NAME')
					)
					--WE HAVE DATA FROM JSON LETS PROCESS IT
			IF (Select Count(*) from @Temp) > 0 BEGIN
				INSERT INTO dbo.DEVICE_PORTS (DEV_ID, PRT_TYP_ID, PRT_DIR_CD, PRT_CNT, REC_CRTE_USER_ID)
				SELECT @DEV_ID, PRT_TYP_ID, PRT_DIR_CD, PRT_CNT, @REC_CRTE_USER_ID FROM @TEMP
			END
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPDATE_Device]
	@DEV_ID			INT = 0,
	@DEV_TYP_ID		SMALLINT,
	@DEV_NAME		VARCHAR(100),
	@DEV_IMG		VARBINARY(MAX) = null,
	@DEV_MFG		VARCHAR(100) = null,
	@DEV_MODEL		VARCHAR(100) = null, 
	@DEV_SERIAL		VARCHAR(100) = null,
	@DEV_FW			VARCHAR(30) = null,
	@DEV_OS			VARCHAR(30) = null,
	@USR			VARCHAR(60) = null,
	@PRT_JSON		NVARCHAR(max)
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_UPDATE_Device
-- 10/10/2020 - TCW - Added varbinary(max) for device image (Stored in Device Table)
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @IMAGE as varbinary(max) 
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @Temp as Table (
		ENTRY_ID int identity(1,1) not null,
		--ATTR_TYP char(1) not null,
		PRT_TYP_ID tinyint null,
		PRT_DIR_CD char(1) null,
		PRT_CNT tinyint null
	)


BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	--SET DEFAULT IMAGE TO NO IMAGE (IMAGE) FOR A NON DEFINED DEVICE IMAGE
	IF (@DEV_IMG IS NOT NULL)
		SET @IMAGE = @DEV_IMG
	ELSE
		SELECT @IMAGE = AD.APP_BIN_VALUE FROM DBO.APP_DEFAULTS AD WITH (NOLOCK) WHERE AD.APP_KEY = 'NO_IMAGE'


	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--UPDATE DEVICE TABLE
		UPDATE dbo.DEVICES SET
			DEV_TYP_ID = @DEV_TYP_ID
			,DEV_NAME = dbo.fnc_StripSpcChars(@DEV_NAME)
			,DEV_IMG = @IMAGE
			,DEV_MFG = dbo.fnc_StripSpcChars(@DEV_MFG)
			,DEV_MODEL = dbo.fnc_StripSpcChars(@DEV_MODEL)
			,DEV_SERIAL = dbo.fnc_StripSpcChars(@DEV_SERIAL)
			,DEV_FW = dbo.fnc_StripSpcChars(@DEV_FW)
			,DEV_OS = dbo.fnc_StripSpcChars(@DEV_OS)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE	
			DEV_ID = @DEV_ID
	
		
		--CHECK AND PROCESS JSON DATA	
		IF ISJSON(@PRT_JSON) > 0 
		BEGIN
			--PARSE JSON DATA (IF IT IS VALID JSON) THEN LOAD IT INTO A @TEMP TABLE FOR PROCESSING
			INSERT INTO @Temp (PRT_TYP_ID, PRT_DIR_CD, PRT_CNT) --, PRT_CHAN, PRT_DESC, PRT_GNDR, PRT_NAME)
			SELECT * FROM OPENJSON(@PRT_JSON)
				WITH ( 
					--ATTR_TYP CHAR(1) 'strict $.ATTR_TYP',
					PRT_TYP_ID tinyint 'strict $.PRT_TYP_ID',
					PRT_DIR_CD CHAR(1) 'strict $.PRT_DIR_CD',
					PRT_CNT tinyint 'strict $.PRT_CNT'
					--PRT_CHAN varchar(255) 'strict $.PRT_CHAN',
					--PRT_DESC varchar(255) 'strict $.PRT_DESC',
					--PRT_GNDR varchar(255) 'strict $.PRT_GNDR',
					--PRT_NAME varchar(255) 'strict $.PRT_NAME')
					)
					--WE HAVE DATA FROM JSON LETS PROCESS IT
			IF (Select Count(*) from @Temp) > 0 BEGIN
				--UPDATE PORT COUNTS
				UPDATE DS SET
					PRT_CNT = T.PRT_CNT
					,LST_UPDT_TS = GetDate()
					,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
				FROM dbo.DEVICE_PORTS DS 
				INNER JOIN @Temp T 
				ON 
					DS.DEV_ID = @DEV_ID
					AND DS.PRT_DIR_CD = T.PRT_DIR_CD 
					AND DS.PRT_TYP_ID = T.PRT_TYP_ID
					AND DS.PRT_CNT <> T.PRT_CNT
				

			END
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_DEL_Device]
	@DEV_ID			INT = 0,
	@SOFT_DELETE	BIT = 0,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 TCW - Intial Creationg of csp_DEL_Device
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @DEV_NAME as varchar(100) = null
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)


BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END


		IF (@SOFT_DELETE = 0) BEGIN
			--DELETE DEVICE (FIRST DELETE ASSIGNMENTS THAT REFERENCE THIS DEVICE (Linked Devices))
			DELETE FROM dbo.DEVICE_PORT_ATTR WHERE DEV_ID = @DEV_ID

			UPDATE dbo.DEVICE_PORT_ATTR SET 
				ATTR_VALUE = '-1' 
			WHERE 
				DEV_ID <> @DEV_ID 
				AND (
					ATTR_KEY_CD = 'PRTDEVID' 
					AND RTRIM(ATTR_VALUE) = RTRIM(CAST(@DEV_ID as varchar(10)))
				)

			--DELETE DEVICE (SECOND DELETE EXT ATTRIBUTES)
			DELETE FROM dbo.DEVICE_EXT_ATTR WHERE DEV_ID = @DEV_ID

			--DELETE DEVICE (THIRD DELETE DEVICE PORTS)
			DELETE FROM dbo.DEVICE_PORTS WHERE DEV_ID = @DEV_ID

			--DELETE CLEANUP (FOURTH REMOVE LAYOUTS FOR DEVICE)
			DELETE FROM dbo.LAYOUTS WHERE LO_DEV_ID = @DEV_ID

			--DELETE DEVICE (LAST DELETE DEVICE)
				--SO I CAN GET A USERNAME FOR THE ACTION
				UPDATE dbo.DEVICES SET LST_UPDT_USER_ID = @LST_UPDT_USER_ID WHERE DEV_ID = @DEV_ID 
			DELETE FROM dbo.DEVICES WHERE DEV_ID = @DEV_ID

			--CLEANUP (REMOVES ANY LAYOUT THAT USES A DEVICE THAT DOESN'T EXIST)
			DELETE FROM LO 
			FROM
				dbo.LAYOUTS LO FULL OUTER JOIN dbo.DEVICES D WITH (NOLOCK)
				ON 
					LO.LO_DEV_ID = D.DEV_ID
			WHERE 
				D.DEV_ID IS NULL
		END ELSE BEGIN

			--SOFT DELETE OPTION SET
			UPDATE dbo.DEVICES SET 
				DEV_SFT_DEL = 1 
				,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
				,LST_UPDT_TS = GetDate()
			WHERE 
				DEV_ID = @DEV_ID

		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE DELETE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_Device_Port_Attr]
	@DEV_ID			INT,
	@LO_ID			INT,
	@PRT_TYP_ID		TINYINT = null,
	@PRT_DIR_CD		CHAR(1) = null,
	@ATTR_KEY_CD	CHAR(8) = null, 
	@ATTR_VALUE     VARCHAR(255) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_ADD_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @DEV_NAME varchar(100)

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--BUILD DEVICE PORT ATTR RECORD
		INSERT INTO dbo.DEVICE_PORT_ATTR (DEV_ID, LO_ID, PRT_TYP_ID, PRT_DIR_CD, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_USER_ID)
		Select @DEV_ID, @LO_ID, @PRT_TYP_ID, @PRT_DIR_CD, @ATTR_KEY_CD, dbo.fnc_StripSpcChars(@ATTR_VALUE), @REC_CRTE_USER_ID 


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE PORT ATTR INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPDATE_Device_Port_Attr]
	@DEV_ID			INT,
	@LO_ID			INT,
	@PRT_TYP_ID		TINYINT = null,
	@PRT_DIR_CD		CHAR(1) = null,
	@ATTR_KEY_CD	CHAR(8) = null, 
	@ATTR_VALUE     VARCHAR(255) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_UPDATE_ALL_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @DEV_NAME varchar(100)

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--BUILD DEVICE PORT ATTR RECORD
		UPDATE dbo.DEVICE_PORT_ATTR SET 
			ATTR_VALUE = dbo.fnc_StripSpcChars(@ATTR_VALUE)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			@LO_ID = LO_ID
			AND @DEV_ID = DEV_ID
			AND @PRT_TYP_ID = PRT_TYP_ID
			AND @PRT_DIR_CD = PRT_DIR_CD
			AND @ATTR_KEY_CD = ATTR_KEY_CD


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE PORT ATTR UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPDATE_Device_Port_Attr_ByAttrID]
	@ATTR_ID		INT,
	@ATTR_KEY_CD	CHAR(8) = null, 
	@ATTR_VALUE     VARCHAR(255) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_UPDATE_ALL_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @DEV_ID as int = 0
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @DEV_NAME varchar(100)

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()

	BEGIN TRY
		Select @DEV_ID = DEV_ID from dbo.DEVICE_PORT_ATTR WHERE ATTR_ID = @ATTR_ID

		--CHECK FOR VALID DEVICE ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END


		--BUILD DEVICE PORT ATTR RECORD
		UPDATE dbo.DEVICE_PORT_ATTR SET 
			ATTR_VALUE = dbo.fnc_StripSpcChars(@ATTR_VALUE)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			@DEV_ID = DEV_ID
			AND @ATTR_ID = ATTR_ID
			AND @ATTR_KEY_CD = ATTR_KEY_CD


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE PORT ATTR UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_Device_EXT_Attr]
	@DEV_ID			INT,
	@LO_ID			INT,
	@ATTR_KEY_CD	CHAR(8) = null, 
	@ATTR_VALUE     VARCHAR(255) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_ADD_Device_EXT_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @DEV_NAME varchar(100)
DECLARE @RESULTS INT = 1

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--BUILD DEVICE EXT ATTR RECORD
		INSERT INTO dbo.DEVICE_EXT_ATTR (DEV_ID, LO_ID, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_USER_ID)
		Select @DEV_ID, @LO_ID, @ATTR_KEY_CD, dbo.fnc_StripSpcChars(@ATTR_VALUE), @REC_CRTE_USER_ID 


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE EXT ATTR INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID

		SET @RESULTS = 0
	END CATCH

return(@RESULTS)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPDATE_Device_EXT_Attr]
	@DEV_ID			INT,
	@LO_ID			INT,
	@ATTR_KEY_CD	CHAR(8) = null, 
	@ATTR_VALUE     VARCHAR(255) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/07/2020 - TCW - Intial Creationg of csp_UPDATE_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @DEV_NAME varchar(100)
DECLARE @RESULTS int = 1

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--BUILD DEVICE EXT ATTR RECORD
		UPDATE dbo.DEVICE_EXT_ATTR SET 
			ATTR_VALUE = dbo.fnc_StripSpcChars(@ATTR_VALUE)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			@LO_ID = LO_ID
			AND @DEV_ID = DEV_ID
			AND @ATTR_KEY_CD = ATTR_KEY_CD


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE EXT ATTR UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + @ERRMSG) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
		
		SET @RESULTS = 0

	END CATCH

return(@RESULTS)
GO


--GRANT EXECUTION OF THE PROCEDURE 
--GRANT EXECUTE ON [dbo].[csp_ADD_Device] TO [db_executor] AS [dbo]
--GO
