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
--	10/15/2020 - TCW - UPDATE PORT and EXT Attr procs. Also completed ADD_Layout and DELETE_Layout Proc
--  10/16/2020 - TCW - ADDED Procedures for User and User Info table management csp_ADD_User
--  10/16/2020 - TCW - ADDED Procedures for User and User Info table management csp_UPD_User
--  10/17/2020 - TCW - ADDED Procedures for User and User Info table management csp_DELTE_User_ByEmail
--  10/17/2020 - TCW - ADDED Procedures for User and User Info table management csp_DELTE_User_ByUserID
--  10/17/2020 - TCW - ADDED Procedures for User and User Info table management csp_LOGON_User
--  10/17/2020 - TCW - ADDED Procedures for User and User Info table management csp_VRFY_User
--  10/17/2020 - TCW - ADDED Procedures for User and User Info table management csp_UPD_Password
--	10/25/2020 - TCW - UPDATE Renamed procedures to be consistent with csp_ADD, csp_DEL or csp_UPD
--
*/


--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

/** DROP PROCEDURES STATEMENTS (DEBUG USE)
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_DEVICE] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_DEVICE_EXT_ATTR] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_DEVICE_PORT_ATTR] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_DEVICEPORTCONFIG] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_LAYOUT] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADD_USER] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_ADJUST_DEVICEPORTS] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_DEL_DEVICE] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_DEL_DEVICEPORTCONFIG] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_DEL_LAYOUT] 
DROP PROCEDURE IF EXISTS [DBO].[csp_DEL_USER_BYEMAIL] 
DROP PROCEDURE IF EXISTS [DBO].[csp_DEL_USER_BYUSERID] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_LINK_PORTTODEVICE] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_LOGON_USER] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_UNDEL_LAYOUT] 
DROP PROCEDURE IF EXISTS [DBO].[CSP_UNDEL_DEVICE] 
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_DEVICE] 
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_DEVICE_EXT_ATTR] 
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_DEVICE_PORT_ATTR] 
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_LAYOUT] 
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_PASSWORD]
DROP PROCEDURE IF EXISTS [DBO].[csp_UPD_USER]
DROP PROCEDURE IF EXISTS [DBO].[CSP_VRFY_USER]
*/


SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

--======================================================
-- PROCEDURES RELATED TO USER EFFORTS
--======================================================
CREATE OR ALTER PROCEDURE [dbo].[csp_CheckLoginAvailable]
	@USER_INFO		varchar(60),		--USER EMAIL or USER_NAME (EITHER OR)
	@USER_INFO_TYPE	char(1),			--TYPE = 'E'=Email, 'U'=UserName
	@IGNORE_UID		varchar(60) = '',	
	@MSG_OUT		varchar(255) OUTPUT --MSG OUTPUT BACK TO CALLING FUNCTION (ONTOP OF RETURN VALUE),
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/17/2020
-- PURPOSE: Handles User (Logon Availability) By Email or Username
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_CheckLoginAvailable

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @RESULT as INT = 0

/*
RETURN: RESULT
	1 = If User Info Item is found (Email or Username, depending on @USER_INFO_TYPE)
	0 = User INFO is not in system.
*/

	IF (@USER_INFO_TYPE = 'E') BEGIN
		--EMAIL CHECK
		SET @RESULT = dbo.fnc_CheckEmailExist(@USER_INFO, @IGNORE_UID)
		IF (@RESULT = 1) 
			SET @MSG_OUT = 'Email address associated with another account...'
		else
			SET @MSG_OUT = ''
	END ELSE BEGIN
		--USER NAME CHECK
		SET @RESULT = dbo.fnc_CheckUserIDExist(@USER_INFO)
		IF (@RESULT = 1) 
			SET @MSG_OUT = 'Username is not available...'
		else
			SET @MSG_OUT = ''
	END

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_LOGON_User]
	@USER_NM		varchar(60),		--USER EMAIL or USER_NAME (EITHER OR)
	@USER_PWD		varchar(40),		--USER EMAIL
	@MSG_OUT		varchar(255) OUTPUT, --MSG OUTPUT BACK TO CALLING FUNCTION (ONTOP OF RETURN VALUE),
	@UID_OUT	varchar(60) OUTPUT
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/17/2020
-- PURPOSE: Handles User (Logon) By Email
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_LOGON_User

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT
DECLARE @USR as varchar(60) = null
DECLARE @INT_USER_ID as varchar(60) = NULL
DECLARE @INT_USER_EMAIL as varchar(60) = NULL
DECLARE @INT_USER_PWD as varchar(40) = NULL
DECLARE @INT_USER_LCK as BIT = 1
DECLARE @INT_USER_LCK_DT as DateTime = null
DECLARE @INT_USER_VRFY as BIT = 0
DECLARE @AD_MAX_FAILS as tinyint
DECLARE @AD_WAIT_TIME as tinyint

DECLARE @MIN_LEFT as tinyint
/*
RETURN: RESULT
	0 = Invalid Login or Password
	1 = Login Successful
	2 = Login Successful (Account need Verification)
	3 = Account Locked (Login Exists) but account has been locked
*/


	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()
		
		--SET DEFAULT VALUE
		SET @UID_OUT = ''

		--GET APPLICATION DEFAULTS FOR MAX FAIL ATTEMPTS BEFORE LOCKOUT AND MAX WAIT TIME FOR LOCKOUT RESET
		select @AD_MAX_FAILS = CAST(ISNULL(dbo.fnc_AppSettingValue('MAX_FAIL'),0) as tinyint)
		select @AD_WAIT_TIME = CAST(ISNULL(dbo.fnc_AppSettingValue('WAITTIME'),0) as tinyint)

		--IF KEY IS NOT FOUND AND VALUE IS SET TO 0 THEN HARDCODE A DEFAULT HERE
		IF (@AD_MAX_FAILS = 0)
			SET @AD_MAX_FAILS = 3   -- MAX FAILED ATTEMPTS BEFORE LOCKOUT OCCURS

		IF (@AD_WAIT_TIME = 0)
			SET @AD_WAIT_TIME = 15  -- MAX WAIT TIME BEFORE BEFORE A RE-LOGIN ATTEMPT CAN BE MADE

RETRY_LOGIN:
		--THIS GOTO IS CALLED FROM THE RETRY AFTER LOCK OUT (REMOVED LOCK AND RESUMES HERE)
		SET @RESULT = 0	--RESET DEFAULT STATUS

		--ATTEMPT TO GET USER_ID BASED ON LOOKUP OF USER ID OR EMAIL 
		--(Gather Login Details as well, such as Verify status and if it is locked)
		Select 
			@INT_USER_ID = U.USER_ID
			,@INT_USER_PWD = CONVERT(varchar(40),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, U.USER_PWD))
			,@INT_USER_LCK = U.USER_ACCT_LCK
			,@INT_USER_VRFY = UI.USER_ACT_VRFY 
			,@INT_USER_EMAIL = CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, U.USER_EMAIL))
			,@INT_USER_LCK_DT = U.USER_LOGIN_FAIL_DT
		from 
			dbo.USERS U WITH (NOLOCK) 
			INNER JOIN dbo.USER_INFO UI WITH (NOLOCK)
			ON U.USER_ID = UI.USER_ID
		WHERE 
			(U.USER_ID = @USER_NM 
			OR UPPER(CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, U.USER_EMAIL))) = UPPER(@USER_NM))

		--SET RESULT RETURN VALUE AND DO ANY WORK NEEDED AND RETURN RESULT
		IF (@INT_USER_ID is not null) BEGIN
			--===================================
			--USER ID WAS FOUND
			--===================================
			SET @UID_OUT = @INT_USER_ID

			--USE COLLATE Latin1_General_CS_AS to make sure password comparison is Case Sensative
			IF (@INT_USER_PWD COLLATE Latin1_General_CS_AS = @USER_PWD AND @INT_USER_LCK = 0) BEGIN
				--===================================
				--GOOD PASSWORD (ACCOUNT NOT LOCKED)
				--===================================
				SET @RESULT = 1
				SET @MSG_OUT = 'Login Successful'
				
				--UPDATE LAST LOGIN DATE AND TIME AS WELL AS LAST UPDT RECORD TIMESTAMPS
				UPDATE dbo.USERS SET
					USER_LST_LOGIN_TS = GetDate()
					,USER_LOGIN_FAIL_CNT = 0
					,LST_UPDT_TS = GetDate()
					,LST_UPDT_USER_ID = ISNULL(@INT_USER_ID,@LST_UPDT_USER_ID)
				WHERE
					USER_ID = @INT_USER_ID

				IF (@INT_USER_VRFY = 0) BEGIN
					--===================================
					--ACCOUNT NEEDS TO BE VERIFIED
					--===================================
					SET @RESULT = 2
					SET @MSG_OUT = 'Login Successful (Account not Verified)'
				END

				--LOG SUCCESS IN ACTIVIT RECORD
				INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
				Select
					dbo.fnc_GetActivityID('AUTH_SUCCESS') as ACT_TYP_ID,
					null,
					RTRIM('<<AUTHENTICATION SUCCESS>>  -  [USER_ID] - ( ' + @INT_USER_ID + ' )') as ACT_DESC,
					isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID

			END ELSE IF (@INT_USER_LCK = 1) BEGIN
				--===================================
				--ACCOUNT LOCKED
				--===================================
				SET @RESULT = 3
				
				IF (DATEADD(minute,@AD_WAIT_TIME,@INT_USER_LCK_DT) >= GetDate()) BEGIN
					--NEED TO WAIT STILL
					
					--SET REMAINING MINUTES
					SELECT @MIN_LEFT = Case when DATEDIFF(minute,GetDate(),DATEADD(minute,@AD_WAIT_TIME,@INT_USER_LCK_DT)) < 0 then 0 else DATEDIFF(minute,GetDate(),DATEADD(minute,@AD_WAIT_TIME,@INT_USER_LCK_DT)) END

					IF (@MIN_LEFT > 0) BEGIN
						SET @MSG_OUT = 'Account locked. Please try again in ' + RTRIM(CAST(@MIN_LEFT as varchar(5))) + ' min(s).'
					END ELSE BEGIN
						SET @MIN_LEFT = 30
						SET @MSG_OUT = 'Account locked. Please try again in ' + RTRIM(CAST(@MIN_LEFT as varchar(5))) + ' sec(s).'
					END

				END ELSE BEGIN
					--WAIT COMPLETE, GOOD TO TRY AGAIN (REMOVE LOCK)
					UPDATE dbo.USERS SET
						USER_ACCT_LCK = 0
						,USER_LOGIN_FAIL_CNT = 0
						,LST_UPDT_TS = GetDate()
						,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
					WHERE
						[USER_ID] = @INT_USER_ID


					GOTO RETRY_LOGIN

				END
			END ELSE BEGIN
				--===================================
				--ACCOUNT FOUND - BUT FAILED LOGIN
				--===================================
				SET @MSG_OUT = 'Login Failed'

				--UPDATE LAST LOGIN DATE AND TIME AS WELL AS LAST UPDT RECORD TIMESTAMPS
				UPDATE dbo.USERS SET
					USER_LOGIN_FAIL_CNT = case when (ISNULL(USER_LOGIN_FAIL_CNT,0) + 1) >= CAST(@AD_MAX_FAILS as tinyint) THEN 5 ELSE ISNULL(USER_LOGIN_FAIL_CNT,0) + 1 END
					,USER_LOGIN_FAIL_DT = GetDate()
					,USER_ACCT_LCK = CASE WHEN ISNULL(USER_LOGIN_FAIL_CNT,0) >= CAST(@AD_MAX_FAILS as tinyint) THEN 1 ELSE 0 END
					,LST_UPDT_TS = GetDate()
					,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
				WHERE
					USER_ID = @INT_USER_ID

				UPDATE dbo.USERS SET
					USER_LOGIN_FAIL_CNT = 0
					,USER_ACCT_LCK = 0
				WHERE
					DATEADD(minute,@AD_WAIT_TIME,@INT_USER_LCK_DT) < GetDate()
					AND USER_ID = @INT_USER_ID  
					AND USER_LOGIN_FAIL_CNT >= 5

				IF EXISTS(SELECT USER_ACCT_LCK from dbo.USERS U WITH (NOLOCK) WHERE U.USER_ID = @INT_USER_ID AND U.USER_ACCT_LCK = 1) BEGIN
					SET @MSG_OUT = 'Login Failed (Account Locked). Try again Later'
					SET @MSG = 'Account has been locked ( USER_ID=' + @INT_USER_ID + ' )'
					RAISERROR (@MSG,15,1) 
				END

			END
		END ELSE BEGIN
			--============================================
			--IF USER DOES NOT EXISTS THROW AN EXCEPTION
			--============================================
			SET @MSG = 'Invalid Login and/or Bad Password! ( USER_LOGIN=' + @USER_NM + ' )'
			SET @MSG_OUT = 'Invalid Login!'
			RAISERROR (@MSG,15,1) 
		END
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('AUTH_FAILURE') as ACT_TYP_ID,
			null,
			RTRIM('<<AUTHENTICATION ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_DEL_User_ByEmail]
	@USER_EMAIL		varchar(60),		--USER TO REMOVE BY EMAIL
	@USR			VARCHAR(60)	= null	--USER MAKING CHANGE
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/17/2020
-- PURPOSE: Handles User (DELETE) By Email
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_UPD_User_ByEmail

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0
DECLARE @DEL_USER_ID as varchar(60) = null


BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()


		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = CAST(dbo.fnc_CheckEmailExist(@USER_EMAIL,'') as tinyint)
		 
		IF (@usrResult = 0) BEGIN 
			--IF USER DOES NOT EXISTS THRU AN EXCEPTION
			SET @MSG = 'User Email does not exist! ( USER_EMAIL=' + @USER_EMAIL + ' )'
			RAISERROR (@MSG,15,1) 
		END ELSE BEGIN
			--IF USER EXISTS BY EMAIL THEN GRAB HIS USER_ID, THIS IS FOR USER_INFO AND AUDIT REASONS ONLY (FOR THE MSG ENTRY INTO TABLE)
			SELECT @DEL_USER_ID = USER_ID from dbo.USERS U WITH (NOLOCK) WHERE UPPER(CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, U.USER_EMAIL))) = UPPER(@USER_EMAIL)
		END

	
		--UDPATE USER_INFO RECORD (FOR AUDIT REASONS)
		UPDATE dbo.USER_INFO SET
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			USER_ID = @DEL_USER_ID

		--UPDATE USERS RECORD (FOR AUDIT REASONS)
		UPDATE dbo.USERS SET
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			USER_ID = @DEL_USER_ID
			AND UPPER(CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_EMAIL))) = UPPER(@USER_EMAIL)

		--REMOVE USER_INFO AND USERS RECORD
		DELETE FROM dbo.USERS WHERE USER_ID = @DEL_USER_ID AND UPPER(CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_EMAIL))) = UPPER(@USER_EMAIL)
		DELETE FROM dbo.USER_INFO WHERE USER_ID = @DEL_USER_ID

		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_DEL') as ACT_TYP_ID,
			null,
			RTRIM('<<USER DELETE ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_DEL_User_ByUserID]
	@USER_ID		varchar(60),		--USER TO DELTETE BY USER ID
	@USR			VARCHAR(60) = null	--USER MAKING CHANGE
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/15/2020
-- PURPOSE: Handles User (DELETE) By User ID
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_DEL_User_ByUserID

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0


BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()


		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = CAST(dbo.fnc_CheckUserIDExist(@USER_ID) as tinyint)
		 
		IF (@usrResult = 0) BEGIN 
			--IF USER DOES NOT EXISTS THRU AN EXCEPTION
			SET @MSG = 'User ID does not exist! ( USER_ID=' + @USER_ID + ' )'
			RAISERROR (@MSG,15,1) 
		END
	
		--DELETE USER_INFO RECORD
		UPDATE dbo.USER_INFO SET
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			USER_ID = @USER_ID

		--DELETE USERS RECORD
		UPDATE dbo.USERS SET
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			USER_ID = @USER_ID

		--REMOVE USER_INFO AND USERS RECORD
		DELETE FROM dbo.USERS WHERE USER_ID = @USER_ID
		DELETE FROM dbo.USER_INFO WHERE USER_ID = @USER_ID

		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_DEL') as ACT_TYP_ID,
			null,
			RTRIM('<<USER DELETE ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_VRFY_User]
	@USER_ID		varchar(60),
	@USR			varchar(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/17/2020
-- PURPOSE: Handles User (Verification) - 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_VRFT_User------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0

BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()


		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = CAST(dbo.fnc_CheckUserIDExist(@USER_ID) as tinyint)
		 
		IF (@usrResult = 0) BEGIN 
			--IF USER DOES NOT EXISTS THRU AN EXCEPTION
			SET @MSG = 'User ID does not exist! ( USER_ID=' + @USER_ID + ' )'
			RAISERROR (@MSG,15,1) 
		END
	
		--UPDATE USER_INFO TO MARK ACCOUNT AS VERIFIED
		UPDATE dbo.USER_INFO SET
			USER_ACT_VRFY = 1
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			[USER_ID] = @USER_ID 
		
		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_ERR') as ACT_TYP_ID,
			null,
			RTRIM('<<USER UPDATE ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_Password]
	@USER_ID		varchar(60),
	@OLD_USER_PWD	varchar(40),
	@NEW_USER_PWD	varchar(40),
	@USR			varchar(60) = null,
	@MSG_OUT		varchar(255) OUTPUT
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/15/2020
-- PURPOSE: Handles User (UPDATE) - Password Only
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of csp_UPD_Password
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0


--OPEN KEY NOW SO THAT WE CAN ENCRYPTING DATA (GETS CLOSED AT THE END) IF NOT USING ENCRYPTION COMMENT OUT THESE 2 LINES
OPEN SYMMETRIC KEY SLOCDB_SymKey
   DECRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;

BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()


		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = CAST(dbo.fnc_CheckUserIDExist(@USER_ID) as tinyint)
		 
		IF (@usrResult = 0) BEGIN 
			--IF USER DOES NOT EXISTS THRU AN EXCEPTION
			SET @MSG = 'User ID does not exist! ( USER_ID=' + @USER_ID + ' )'
			RAISERROR (@MSG,15,1) 
		END
	
		IF NOT EXISTS(Select USER_ID from dbo.USERS WITH (NOLOCK) WHERE USER_ID=@USER_ID AND CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_PWD)) = @OLD_USER_PWD) BEGIN 
			--USER_ID AND PASSWORD COMBO INCORRECT UNABLE TO CONTINUE
			SET @MSG = 'Password entered is incorrect, password change aborted ( USER_ID=' + @USER_ID + ' )'
			SET @MSG_OUT = 'Current password is incorrect, Please try again.'
			RAISERROR (@MSG,15,1) 
		END

		--EXAMPLE OF HOW TO ENCYRPT COLUMN CONTENT TO VARBINARY(128)
		--EncryptByKey(Key_GUID('SLOCDB_SymKey'),'This is a Test String')

		--UPDATE USERS RECORD
		UPDATE dbo.USERS SET
			USER_PWD = EncryptByKey(Key_GUID('SLOCDB_SymKey'),@NEW_USER_PWD) 
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			[USER_ID] = @USER_ID 
			AND CONVERT(varchar(60),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_PWD)) = @OLD_USER_PWD
		
		SET @MSG_OUT = 'Password Updated Successfully'
		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_ERR') as ACT_TYP_ID,
			null,
			RTRIM('<<USER UPDATE ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

--CLOSE KEY NOW THAT WE ARE DONE ADDING AND ENCRYPTING DATA,  IF NOT USING ENCRYPTION COMMENT OUT THIS BELOW LINE
CLOSE SYMMETRIC KEY SLOCDB_SymKey

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_User]
	@USER_ID		varchar(60),
	@USER_EMAIL		varchar(60),
	@SEC_QID_1		TINYINT,
	@SEC_QID_2		TINYINT,
	@SEC_QID_3		TINYINT,
	@SEC_QANS_1		varchar(100),
	@SEC_QANS_2		varchar(100),
	@SEC_QANS_3		varchar(100),
	@USER_FNAME		varchar(30),
	@USER_LNAME		varchar(30),
	@USER_PHONE		varchar(10),
	@USER_VRFY_PREF_CD CHAR(1) = 'N',
	@USR			varchar(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/15/2020
-- PURPOSE: Handles User (UPDATE) - Not Password that is a different proc 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/15/2020 - TCW - Intial Creationg of csp_UPD_User

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0


--OPEN KEY NOW SO THAT WE CAN ENCRYPTING DATA (GETS CLOSED AT THE END) IF NOT USING ENCRYPTION COMMENT OUT THESE 2 LINES
OPEN SYMMETRIC KEY SLOCDB_SymKey
   DECRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;

BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @LST_UPDT_USER_ID = @USR
		else
			SET @LST_UPDT_USER_ID = USER_NAME()


		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = CAST(dbo.fnc_CheckUserIDExist(@USER_ID) as tinyint)
		 
		IF (@usrResult = 0) BEGIN 
			--IF USER DOES NOT EXISTS THRU AN EXCEPTION
			SET @MSG = 'User ID does not exist! ( USER_ID=' + @USER_ID + ' )'
			RAISERROR (@MSG,15,1) 
		END
	
		--EXAMPLE OF HOW TO ENCYRPT COLUMN CONTENT TO VARBINARY(128)
		--EncryptByKey(Key_GUID('SLOCDB_SymKey'),'This is a Test String')

		--UPDATE USER INFO RECORD (USER_ID is NOT UPDATEABLE BECAUSE IT IS THE KEY)
		UPDATE dbo.USER_INFO SET
			SEC_QID_1 = @SEC_QID_1
			,SEC_QID_2 = @SEC_QID_2
			,SEC_QID_3 = @SEC_QID_3
			,USER_FNAME = dbo.fnc_StripSpcChars(@USER_FNAME)
			,USER_LNAME = dbo.fnc_StripSpcChars(@USER_LNAME)
			,USER_PHONE = @USER_PHONE
			,USER_VRFY_PREF_CD = @USER_VRFY_PREF_CD
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			[USER_ID] = @USER_ID 


		--UPDATE USERS RECORD
		UPDATE dbo.USERS SET
			SEC_QID_1 = EncryptByKey(Key_GUID('SLOCDB_SymKey'),dbo.fnc_StripSpcChars(@SEC_QANS_1)) 
			,SEC_QID_2 = EncryptByKey(Key_GUID('SLOCDB_SymKey'),dbo.fnc_StripSpcChars(@SEC_QANS_2)) 
			,SEC_QID_3 = EncryptByKey(Key_GUID('SLOCDB_SymKey'),dbo.fnc_StripSpcChars(@SEC_QANS_3)) 
			,USER_EMAIL = EncryptByKey(Key_GUID('SLOCDB_SymKey'),@USER_EMAIL) 
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			[USER_ID] = @USER_ID 
		
		
		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_ERR') as ACT_TYP_ID,
			null,
			RTRIM('<<USER UPDATE ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

--CLOSE KEY NOW THAT WE ARE DONE ADDING AND ENCRYPTING DATA,  IF NOT USING ENCRYPTION COMMENT OUT THIS BELOW LINE
CLOSE SYMMETRIC KEY SLOCDB_SymKey

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_User]
	@USER_ID		varchar(60),
	@USER_PWD		varchar(40),
	@USER_EMAIL		varchar(60),
	@SEC_QID_1		TINYINT,
	@SEC_QID_2		TINYINT,
	@SEC_QID_3		TINYINT,
	@SEC_QANS_1		varchar(100),
	@SEC_QANS_2		varchar(100),
	@SEC_QANS_3		varchar(100),
	@USER_FNAME		varchar(30),
	@USER_LNAME		varchar(30),
	@USER_PHONE		varchar(10),
	@USER_VRFY_PREF_CD CHAR(1) = 'N',
	@USR			varchar(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/15/2020
-- PURPOSE: Handles User (Add) 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/15/2020 - TCW - Intial Creationg of csp_ADD_User

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0

--OPEN KEY NOW SO THAT WE CAN ENCRYPTING DATA (GETS CLOSED AT THE END) IF NOT USING ENCRYPTION COMMENT OUT THESE 2 LINES
OPEN SYMMETRIC KEY SLOCDB_SymKey
   DECRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;

BEGIN TRANSACTION 
	BEGIN TRY
		--SET USER ID FOR TRANSACTION
		IF (@USR is not null)
			SET @REC_CRTE_USER_ID = @USR
		else
			SET @REC_CRTE_USER_ID = USER_NAME()

		--CHECK TO SEE IF EMAIL OR USERNAME EXISTS IF IT DOES FAIL THE REQUEST
		Select @usrResult = (CAST(dbo.fnc_CheckEmailExist(@USER_EMAIL,@USER_ID) as tinyint) + CAST(dbo.fnc_CheckUserIDExist(@USER_ID) as tinyint))
		 
		IF (@usrResult > 0) BEGIN 
			SET @MSG = 'User ID or Email already exist! ( USER_ID=' + @USER_ID + '  -  USER_EMAIL=' + @USER_EMAIL + ' )'
			RAISERROR (@MSG,15,1) 
		END


		--EXAMPLE OF HOW TO ENCYRPT COLUMN CONTENT TO VARBINARY(128)
		--EncryptByKey(Key_GUID('SLOCDB_SymKey'),'This is a Test String')

		--BUILD USER_INFO RECORD
		INSERT INTO dbo.USER_INFO (USER_ID, SEC_QID_1, SEC_QID_2, SEC_QID_3, USER_FNAME, USER_LNAME, USER_PHONE, USER_VRFY_PREF_CD, REC_CRTE_USER_ID)
		SELECT @USER_ID, @SEC_QID_1, @SEC_QID_2, @SEC_QID_3, @USER_FNAME, @USER_LNAME, @USER_PHONE, @USER_VRFY_PREF_CD, @REC_CRTE_USER_ID

		 
		--BUILD USERS RECORD
		INSERT INTO dbo.USERS (USER_ID, SEC_QID_1, SEC_QID_2, SEC_QID_3, USER_PWD, USER_EMAIL, REC_CRTE_USER_ID)
		SELECT 
			@USER_ID, 
			EncryptByKey(Key_GUID('SLOCDB_SymKey'),@SEC_QANS_1), 
			EncryptByKey(Key_GUID('SLOCDB_SymKey'),@SEC_QANS_2), 
			EncryptByKey(Key_GUID('SLOCDB_SymKey'),@SEC_QANS_3), 
			EncryptByKey(Key_GUID('SLOCDB_SymKey'),@USER_PWD),  
			EncryptByKey(Key_GUID('SLOCDB_SymKey'),@USER_EMAIL),
			@REC_CRTE_USER_ID

		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('USER_ERR') as ACT_TYP_ID,
			null,
			RTRIM('<<USER INSERT ERROR>>  -  [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			@REC_CRTE_USER_ID as REC_CRTE_USER_ID
	END CATCH

--CLOSE KEY NOW THAT WE ARE DONE ADDING AND ENCRYPTING DATA,  IF NOT USING ENCRYPTION COMMENT OUT THIS BELOW LINE
CLOSE SYMMETRIC KEY SLOCDB_SymKey

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_GetSecQuestions]
	@IGNORE_QID1	INT = 0,
	@IGNORE_QID2	INT = 0
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/17/2020
-- PURPOSE: Handles User (Retrieving Security Questiosn) - 
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/17/2020 - TCW - Intial Creationg of [csp_GetSecQuestions]
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT = 0
DECLARE @usrResult as tinyint = 0

	--UPDATE USER_INFO TO MARK ACCOUNT AS VERIFIED
	Select 
		SQ.SEC_QUEST_ID
		,SQ.SEC_QUEST_TXT 
	FROM dbo.SECURITY_QUESTIONS SQ WITH (NOLOCK)
	WHERE (
			SQ.SEC_QUEST_ID <> @IGNORE_QID1
			AND SQ.SEC_QUEST_ID <> @IGNORE_QID2
		)
	ORDER BY SQ.SEC_QUEST_ID
GO


--======================================================
-- PROCEDURES RELATED TO LAYOUT EFFORTS
--======================================================
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
-- 10/18/2020 - TCW - Modified the way that Port attributes are created
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @MY_LO_ID as INT
DECLARE @RESULT as INT = 0
DECLARE @PRT_TYP_ID as tinyint
DECLARE @PRT_DIR_CD as CHAR(1)
DECLARE @PRT_TXT varchar(255)
DECLARE @PRT_CNT tinyint
DECLARE @ATTR_VALUE as varchar(255)
DECLARE @VALOUT as varchar(255)
DECLARE @COMM_TXT CHAR(8)
DECLARE @PDI as tinyint = null
DECLARE @ATTR_KEY_CD CHAR(8)
DECLARE @ICnt as tinyint = 0
DECLARE @PRT_CFG_ID INT

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@LO_DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@LO_DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@LO_DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END
	
		--BUILD DEVICE RECORD
		INSERT INTO dbo.LAYOUTS (LO_NAME, LO_DEV_ID, LO_NOTES, REC_CRTE_USER_ID)
		Select dbo.fnc_StripSpcChars(@LO_NAME), @LO_DEV_ID, dbo.fnc_StripSpcChars(@LO_NOTES), @USR
		SET @MY_LO_ID = SCOPE_IDENTITY()

		/*----------------------------------------------------------------------------------------------------------
		WITH THE NEW LAYOUT AND DEVICE ASSIGNMENT TO THE LAYOUT WE CAN NOW SETUP THE DEVICE_EXT_ATTR AND PORT_ATTR.
		LAYOUTS ALLOW FOR CUSTOMIZATION AS THEY ASSOCIATE ATTRIBUTES TO A DEVICE 
		(AS TO WHERE A DEVICE IS JUST A DEVICE). DEVICES CONTAIN NO OWNERSHIP OR CUSTOMIZATION IF NOT USED IN LAYOUT
		----------------------------------------------------------------------------------------------------------*/
		
		--================================================================================
		-- ADD ALL AVAILABLE ATTRIBUTES FOR DEVICE_EXT_ATTR (THESE ARE ALL NEEDED)
		--================================================================================
		INSERT INTO dbo.DEVICE_EXT_ATTR (DEV_ID, LO_ID, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_TS, REC_CRTE_USER_ID)
		Select	
			@LO_DEV_ID  DEV_ID
			,@MY_LO_ID as LO_ID
			,CC.COMM_CD as ATTR_KEY_CD
			,'' as ATTR_VALUE
			,GetDate() as REC_CRTE_TS
			,@REC_CRTE_USER_ID as REC_CRTE_USER_ID
		FROM 
			dbo.COMMON_CODES CC WITH (NOLOCK),
			dbo.DEVICES D WITH (NOLOCK)
		WHERE
			@LO_DEV_ID = D.DEV_ID
			AND CC.COMM_TYPE_CD ='DEV_ATTR'


		--================================================================================
		-- ADD ALL AVAILABLE ATTRIBUTES FOR DEVICE_PORT_ATTR (THESE ARE ALL NEEDED)
		--================================================================================
		INSERT INTO dbo.DEVICE_PORT_ATTR (LO_ID, PRT_CFG_ID, PRT_ID, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_USER_ID)
		Select 
			@MY_LO_ID as LO_ID
			,DP.PRT_CFG_ID
			,DP.PRT_ID
			,CC.COMM_CD as ATTR_KEY_CD
			,REPLACE(
				REPLACE(
					REPLACE(dbo.fnc_AppSettingValue(CC.COMM_CD),'@VAL',RTRIM(CAST(DP.PRT_ID as varchar(3))))
				,'@PT',RTRIM(dbo.fnc_PortToText(DPC.PRT_TYP_ID)))
			,'@CT',RTRIM(ISNULL(dbo.fnc_CommonCodeTXT(DPC.PRT_DIR_CD,'PORT_DIR'),''))) as ATTR_VALUE
			,@REC_CRTE_USER_ID as REC_CRTE_USER_ID
		FROM
			dbo.DEVICES D WITH (NOLOCK),
			dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK),
			dbo.DEVICE_PORTS DP WITH (NOLOCK),
			dbo.COMMON_CODES CC WITH (NOLOCK)
		WHERE
			D.DEV_ID = DPC.DEV_ID
			AND DPC.PRT_CFG_ID = DP.PRT_CFG_ID
			AND CC.COMM_TYPE_CD ='PRT_ATTR'
			AND @LO_DEV_ID = DPC.DEV_ID 

		SET @RESULT = 1

		COMMIT TRANSACTION 
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION 

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('LAYOUT_ERR') as ACT_TYP_ID,
			@LO_DEV_ID,
			RTRIM('<<LAYOUT INSERT ERROR>>  -  [LAYOUT_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH
return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_Layout]
	@LO_ID			INT = 0,
	@LO_NAME		VARCHAR(100),
	@LO_NOTES		VARCHAR(500) = null,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/14/2020
-- PURPOSE: Handles Updating the Layout
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/14/2020 - TCW - Intial Creationg of csp_UPD_Layout

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @IMAGE as varbinary(max) 
DECLARE @MSG as varchar(2048)
DECLARE @LO_DEV_ID as int
DECLARE @LST_UPDT_USER_ID as varchar(60)


BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END
		ELSE BEGIN
			Select @LO_DEV_ID = L.LO_DEV_ID FROM dbo.LAYOUTS L WITH (NOLOCK) WHERE L.LO_ID = @LO_ID
		END

		--UPDATE LAYOUTS TABLE
		UPDATE dbo.LAYOUTS SET
			LO_NAME = dbo.fnc_StripSpcChars(@LO_NAME)
			,LO_NOTES = dbo.fnc_StripSpcChars(@LO_NOTES)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE	
			LO_ID = @LO_ID
	

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('LAYOUT_ERR') as ACT_TYP_ID,
			@LO_DEV_ID,
			RTRIM('<<LAYOUT UPDATE ERROR>>  -  [LO_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_DEL_Layout]
	@LO_ID			INT = 0,
	@SOFT_DELETE	BIT = 0,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles delete layouts
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/14/2020 TCW - Intial Creationg of csp_DEL_Layout
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @LO_NAME as varchar(100) = null
DECLARE @LO_DEV_ID as int
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
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @LO_NAME = LO_NAME, @LO_DEV_ID=LO_DEV_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID
		END


		IF (@SOFT_DELETE = 0) BEGIN
			--DELETE  (FIRST DELETE ASSIGNMENTS THAT REFERENCE THIS LAYOUT)
			DELETE FROM dbo.DEVICE_PORT_ATTR WHERE LO_ID = @LO_ID


			--DELETE DEVICE (SECOND DELETE EXT ATTRIBUTES FOR LAYOUT)
			DELETE FROM dbo.DEVICE_EXT_ATTR WHERE LO_ID = @LO_ID


			--DELETE CLEANUP (LASTLY REMOVE LAYOUTS)
			--SO I CAN GET A USERNAME FOR THE ACTION
			UPDATE dbo.LAYOUTS SET LST_UPDT_USER_ID = @LST_UPDT_USER_ID WHERE LO_ID = @LO_ID 
			DELETE FROM dbo.LAYOUTS WHERE LO_ID = @LO_ID
		END ELSE BEGIN
			--SOFT DELETE OPTION SET
			UPDATE dbo.LAYOUTS SET 
				LO_SFT_DEL = 1 
				,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
				,LST_UPDT_TS = GetDate()
			WHERE 
				LO_ID = @LO_ID

		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('LAYOUT_ERR') as ACT_TYP_ID,
			@LO_DEV_ID,
			RTRIM('<<LAYOUT DELETE ERROR>>  -  [LO_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UnDEL_Layout]
	@LO_ID			INT = 0,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/14/2020
-- PURPOSE: Handles Undelete of Soft deleted layouts
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/14/2020 TCW - Intial Creationg of csp_UnDEL_Layout
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @LO_NAME as varchar(100) = null
DECLARE @LO_DEV_ID as INT
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
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @LO_NAME = LO_NAME, @LO_DEV_ID = LO_DEV_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID
		END


		--UNDELETE THE SOFT DELETE, SET IT BACK TO ZERO SO IT IS VISIBLE
		UPDATE dbo.LAYOUTS SET 
			LO_SFT_DEL = 0
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
			,LST_UPDT_TS = GetDate()
		WHERE 
			LO_ID = @LO_ID


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('LAYOUT_ERR') as ACT_TYP_ID,
			@LO_DEV_ID,
			RTRIM('<<LAYOUT UNDELETE ERROR>>  -  [LO_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO



--======================================================
-- PROCEDURES RELATED TO DEVICE EFFORTS
--======================================================
CREATE OR ALTER PROCEDURE [dbo].[csp_LINK_PortToDevice]
	@LO_ID				INT,	
	@PRT_CFG_ID			INT,
	@PRT_ID				INT,
	@ATTR_KEY_CD		CHAR(8),
	@LNK_PRT_CFG_ID		INT,
	@LNK_PRT_ID			INT,
	@LNK_DEV_ID			INT,
	@USR				VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/15/2020
-- PURPOSE: Handles Linking a port from a layout to another device
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/15/2020 - TCW - Intial Creationg of csp_LINK_PortToDevice

------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @RESULT as INT
DECLARE @ATTR_VALUE as varchar(255)
DECLARE @VALOUT as varchar(255)
DECLARE @COMM_TXT CHAR(8)
DECLARE @ATTR_KEY_CD1 CHAR(8) = 'PRT_ASSN' -- PRT_CFG_ID + '.' + PRT_ID (casted as string) = link
DECLARE @ATTR_KEY_CD2 CHAR(8) = 'PRTDEVID' -- Could be the LO_ID or DEV_ID (Still on the fence on this one)
DECLARE @LO_NAME VARCHAR(100) 
DECLARE @LO_DEV_ID INT

--IF A DEVICE IS LINKED FROM THIS DEVICE TO ANOTHER DEVICE, THAT DEVICE TOO SHOULD REFLECT THAT CONNECTION ON THE OPPOSITE AVENUE(ROUND ROBIN LINK)
--USED FOR CREATING THE RETURN LINK 
DECLARE @RET_LO_ID INT

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@LNK_DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@LNK_DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided for link. (LNK_DEV_ID=' + CAST(@LNK_DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END
	
		--CHECK FOR VALID LAYOUT ID
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided for link. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END
		ELSE BEGIN
			--GET LAYOUT NAME AND DEVILCE ASSOCIATED WITH "THIS" LAYOUT. 
			--THIS WILL BE USED TO CREATE THE ROUND ROBIN LINK BACK.
			Select @LO_NAME = LO_NAME, @LO_DEV_ID = LO_DEV_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID = @LO_ID
		END
		

		--PERFORM LINK 
		UPDATE dbo.DEVICE_PORT_ATTR SET 
			ATTR_VALUE = CASE 
							WHEN ATTR_KEY_CD =  @ATTR_KEY_CD1 THEN RTRIM(CAST(@PRT_CFG_ID as varchar(10))) + '.' + RTRIM(CAST(@PRT_ID as varchar(10)))
							WHEN ATTR_KEY_CD =  @ATTR_KEY_CD1 THEN CAST(@LNK_DEV_ID as varchar(10))
							ELSE ATTR_VALUE
						END 
		WHERE
			@LO_ID = LO_ID
			AND @PRT_CFG_ID = PRT_CFG_ID
			AND @PRT_ID = PRT_ID
			AND ATTR_KEY_CD  IN (@ATTR_KEY_CD1, @ATTR_KEY_CD2)

		--CREATE CIRCULAR LINK
		SELECT @RET_LO_ID = LO_ID from dbo.LAYOUTS L WITH (NOLOCK) INNER JOIN dbo.DEVICES D WITH (NOLOCK) ON L.LO_DEV_ID = D.DEV_ID AND L.LO_SFT_DEL = 0 AND D.DEV_SFT_DEL = 0 AND D.DEV_ID = @LNK_DEV_ID
		IF (@RET_LO_ID  is not null) BEGIN
			--IF There is a layout for the device being linked to, first lets make sure it is not soft deleted and that the device exists, if so grab the LO_ID of that device
			Select 1/1
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
			dbo.fnc_GetActivityID('DEV_LNK_ERR') as ACT_TYP_ID,
			RTRIM('<<DEVICE LINK ERROR>>  -  [LAYOUT_NAME] - (''' + ISNULL(@LO_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
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
	@CRTE_LAYOUT	BIT = 0,
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
DECLARE @DEV_ID		int = 0
DECLARE @IMAGE		varbinary(max) 
DECLARE @ERRMSG		varchar(2048)
DECLARE @MSG		varchar(2048)
DECLARE @REC_CRTE_USER_ID varchar(60)
DECLARE @ICnt		tinyint = 0
DECLARE @PRT_CFG_ID int 
DECLARE @PRT_TYP_ID tinyint
DECLARE @PRT_DIR_CD char(1)
DECLARE @PRT_CNT	tinyint
DECLARE @PRT_GNDR	char(1)
DECLARE @RESULT		int = 0
DECLARE @retResult  int = 0
DECLARE @TranCnt	int = @@TRANCOUNT
DECLARE @Temp		Table (
		ENTRY_ID	int identity(1,1) not null,
		PRT_TYP_ID	tinyint null,
		PRT_DIR_CD	char(1) null,
		PRT_CNT		tinyint null,
		PRT_GNDR	char(1) null
	)
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL

--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

IF (@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
END

IF (@DEBUG=1) BEGIN
	PRINT 'csp_ADD_Device'
	PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))
END

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
		IF ISJSON(@PRT_JSON) > 0 BEGIN
			--PARSE JSON DATA (IF IT IS VALID JSON) THEN LOAD IT INTO A @TEMP TABLE FOR PROCESSING
			INSERT INTO @Temp (PRT_TYP_ID, PRT_DIR_CD, PRT_CNT, PRT_GNDR) --, PRT_CHAN, PRT_DESC, PRT_GNDR, PRT_NAME)
			SELECT * FROM OPENJSON(@PRT_JSON)
				WITH ( 
					PRT_TYP_ID tinyint 'strict $.PRT_TYP_ID',
					PRT_DIR_CD CHAR(1) 'strict $.PRT_DIR_CD',
					PRT_CNT tinyint 'strict $.PRT_CNT',
					PRT_GNDR CHAR(1) 'strict $.PRT_GNDR'
					)
			
			--REMOVE PORTS WITH NO COUNT, THESE ARE NOT VALID 
			DELETE FROM @Temp WHERE PRT_CNT = 0

			--WE HAVE DATA FROM JSON LETS PROCESS IT
			IF (Select Count(*) from @Temp) > 0 BEGIN
				--SEEING WE HAVE PORT CONFIGURATIONS WE WILL WANT TO CREATE THE DEVICE_PORT ENTRIES
				WHILE EXISTS(SELECT PRT_TYP_ID FROM @Temp) BEGIN								
					Select TOP 1
						@PRT_TYP_ID = PRT_TYP_ID
						,@PRT_DIR_CD = PRT_DIR_CD
						,@PRT_CNT = PRT_CNT
						,@PRT_GNDR = PRT_GNDR
					FROM @Temp
					ORDER BY PRT_TYP_ID, PRT_DIR_CD

					IF (@DEBUG=1) 
						print 'CALLING: csp_ADD_DevicePortConfig (' + CAST(ISNULL(@DEV_ID,'') as varchar(10)) + ', ' + CAST(ISNULL(@PRT_TYP_ID,'') as varchar(10)) + ', ' + @PRT_DIR_CD + ', ' + CAST(ISNULL(@PRT_CNT,'') as varchar(3)) + ', ' + @PRT_GNDR + ', ''' + @REC_CRTE_USER_ID + ''')'

					exec @retResult = dbo.csp_ADD_DevicePortConfig @DEV_ID, @PRT_TYP_ID, @PRT_DIR_CD, @PRT_CNT, @PRT_GNDR, @REC_CRTE_USER_ID, @PRT_CFG_ID OUTPUT
					
					--CHECK FOR VALID DEVICE ID
					IF (@retResult = 0) BEGIN 
						SET @MSG = 'Unable to add Port Configuration! (DEV_ID=' + CAST(ISNULL(@DEV_ID,'') as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(ISNULL(@PRT_CFG_ID,'') as varchar(10)) + ')'
						RAISERROR (@MSG,15,1) 
					END

					--REMOVE LAST RECORD AND LOOP
					DELETE FROM @Temp WHERE @PRT_TYP_ID = PRT_TYP_ID AND @PRT_DIR_CD = PRT_DIR_CD AND @PRT_CNT = PRT_CNT
				END
			END
		END

		IF (@CRTE_LAYOUT = 1) 
			IF (@DEBUG=1) BEGIN
				print 'Calling csp_ADD_Layout (''' + ISNULL(@DEV_NAME,'null') + ''', ' + CAST(ISNULL(@DEV_ID,'null') as varchar(10)) + ', ''' + @REC_CRTE_USER_ID + ''')'
			END
			exec dbo.csp_ADD_Layout @LO_NAME = @DEV_NAME, @LO_DEV_ID = @DEV_ID, @USR=@REC_CRTE_USER_ID

		SET @RESULT = 1

	END TRY
	BEGIN CATCH
		--ERROR CATCH
		IF (@DEBUG=1) BEGIN
			print 'csp_ADD_Device (ERROR OCCURED)'
		END

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

IF (@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG = 1) 
		print 'Transaction Committed (csp_ADD_Device)'
END 
ELSE IF (@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG = 1)
		print 'Transaction RolledBack (csp_ADD_Device)'
END

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_Device]	
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
-- 10/07/2020 - TCW - Intial Creationg of csp_UPD_Device
-- 10/10/2020 - TCW - Added varbinary(max) for device image (Stored in Device Table)
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @IMAGE as varbinary(max) 
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @PRT_CFG_ID as INT
DECLARE @PRT_TYP_ID TINYINT
DECLARE @PRT_DIR_CD CHAR(1)
DECLARE @PRT_CNT as TINYINT
DECLARE @retRESULT as INT = 0
DECLARE @TranCnt as INT = @@TRANCOUNT	
DECLARE @RESULT AS INT = 0
DECLARE @CntDiff smallint = 0
DECLARE @PosStart tinyint = 0
DECLARE @ICnt as INT = 0 
DECLARE @PRT_GNDR as CHAR(1) = null

DECLARE @Temp as Table (
		ENTRY_ID int identity(1,1) not null,
		PRT_TYP_ID tinyint null,
		PRT_DIR_CD char(1) null,
		PRT_CNT tinyint null,
		PRT_GNDR char(1) null
	)
DECLARE @TempCFG as Table (
	PRT_CFG_ID int not null,
	CFG_ACTION CHAR(1) default('D') not null, --D (Delete) *Default*, Found = U (Update) not found = I (Insert), Found = S (Skipped) no update needed
	DEV_ID INT not null,
	PRT_TYP_ID tinyint not null,
	PRT_DIR_CD CHAR(1) not null,
	OLD_PRT_GNDR CHAR(1) null,
	NEW_PRT_GNDR char(1) null,
	OLD_PRT_CNT smallint not null,
	NEW_PRT_CNT smallint not null
)
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL

--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

IF (@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
END

IF (@DEBUG=1) BEGIN
	print 'Transaction Start (csp_UPD_Device)'
	PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))
END

	--=====================================================
	--SET DEFAULTS FOR DEVICE IMAGE AND USER INFO
	--=====================================================
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


	--=====================================================
	--LETS TRY TO DO THE UPDATES
	--=====================================================
	BEGIN TRY

		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
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
			INSERT INTO @Temp (PRT_TYP_ID, PRT_DIR_CD, PRT_CNT, PRT_GNDR) --, PRT_CHAN, PRT_DESC, PRT_GNDR, PRT_NAME)
			SELECT * FROM OPENJSON(@PRT_JSON)
				WITH ( 
					PRT_TYP_ID tinyint 'strict $.PRT_TYP_ID',
					PRT_DIR_CD CHAR(1) 'strict $.PRT_DIR_CD',
					PRT_CNT tinyint 'strict $.PRT_CNT',
					PRT_GNDR CHAR(1) 'strict $.PRT_GNDR'
					)
					--WE HAVE DATA FROM JSON LETS PROCESS IT

			--REMOVE PORTS WITH NO COUNT, THESE ARE NOT VALID 
			DELETE FROM @Temp WHERE PRT_CNT = 0

			--TAKE SNAPSHOT OF CURRENT CONFIG (USED FOR DRIVING UPDATE)
			INSERT INTO @TempCFG (PRT_CFG_ID,DEV_ID,PRT_TYP_ID, PRT_DIR_CD, OLD_PRT_CNT, NEW_PRT_CNT, OLD_PRT_GNDR, NEW_PRT_GNDR)
			SELECT DPC.PRT_CFG_ID, DPC.DEV_ID, DPC.PRT_TYP_ID, DPC.PRT_DIR_CD, DPC.PRT_CNT, DPC.PRT_CNT, DPC.PRT_GNDR, DPC.PRT_GNDR from dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK) WHERE DPC.DEV_ID = @DEV_ID


			--========================================================================
			--DETERMINE WHAT NEEDS TO BE UPDATED, DELETED OR INSERTED FOR PORTS
			--(NOTE: A DELETE CAN OCCUR IF ITS NOT PART OF THE CONFIGURATION ANYMORE)
			--=======================================================================
			UPDATE TC SET 
				--IF IT CHANGED MARK IT FOR 'U'PDATE OTHER WISE 'S'KIP IT
				TC.CFG_ACTION = CASE 
									WHEN T.PRT_CNT <> TC.OLD_PRT_CNT THEN 'U' 
									WHEN T.PRT_GNDR <> TC.OLD_PRT_GNDR THEN 'U' 
									ELSE 'S' 
								END
				,TC.NEW_PRT_CNT = T.PRT_CNT
				,TC.NEW_PRT_GNDR = T.PRT_GNDR
			FROM
				@TempCFG TC INNER JOIN @Temp T 
				ON
					TC.PRT_TYP_ID = T.PRT_TYP_ID
					AND TC.PRT_DIR_CD = T.PRT_DIR_CD
					AND TC.OLD_PRT_GNDR = T.PRT_GNDR	

			--ADD NEW ITEMS TO TABLE FOR PROCESSING AND MARK THEIR ACTIONS 'I'NSERT
			INSERT INTO @TempCFG (PRT_CFG_ID, CFG_ACTION, DEV_ID, PRT_TYP_ID, PRT_DIR_CD, OLD_PRT_CNT, NEW_PRT_CNT,OLD_PRT_GNDR,NEW_PRT_GNDR)
			SELECT
				0,'I',@DEV_ID, T.PRT_TYP_ID, T.PRT_DIR_CD, T.PRT_CNT, T.PRT_CNT, T.PRT_GNDR, T.PRT_GNDR
			FROM
				@TempCFG TC FULL OUTER JOIN @Temp T 
				ON
					TC.PRT_TYP_ID = T.PRT_TYP_ID
					AND TC.PRT_DIR_CD = T.PRT_DIR_CD	
					AND TC.OLD_PRT_GNDR = T.PRT_GNDR	
			WHERE
				TC.PRT_TYP_ID IS NULL 

			--ITEMS BEING SKIPPED (NOT UPDATED BUT IN CONFIG) CAN BE IGNORED, SO REMOVE THEM FROM THE DRIVING TABLE
			DELETE FROM @TempCFG WHERE CFG_ACTION = 'S'

			--===============================================================================================
			--*** AT THIS POINT WE HAVE A DRIVING TABLE THAT CONTAINS DELTAS FOR OUR PORT UPDATE PROCESS. ***
			--===============================================================================================

			--DISPLAY LIST OF ITEMS BEING CHANGED (DEBUG ONLY)
			IF (@DEBUG=1)
				SELECT * FROM @TempCFG

			--=====================================================
			--DELETE ENTRIES FROM THE DEVICE_PORT_CONFIG TABLE
			--=====================================================
			WHILE EXISTS(SELECT PRT_CFG_ID FROM @TempCFG WHERE CFG_ACTION='D') BEGIN
				--REMOVE ITEMS THAT WERE NOT LONGER PART OF THE CONFIG (DELETES)
				Select TOP 1 @PRT_CFG_ID = PRT_CFG_ID FROM @TempCFG WHERE CFG_ACTION = 'D' ORDER BY PRT_CFG_ID ASC
				
				IF (@DEBUG=1) 
						print 'CALLING: csp_DEL_DevicePortConfig (' + CAST(ISNULL(@DEV_ID,'') as varchar(10)) + ', ' + CAST(ISNULL(@PRT_CFG_ID,'') as varchar(10)) +  ', ''' + @LST_UPDT_USER_ID + ''')'

				exec @retRESULT = csp_DEL_DevicePortConfig @DEV_ID, @PRT_CFG_ID, @LST_UPDT_USER_ID

				--CHECK FOR VALID DEVICE ID
				IF (@retRESULT = 0) BEGIN 
					SET @MSG = 'Unable to remove Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				DELETE FROM @TempCFG WHERE CFG_ACTION = 'D' AND @PRT_CFG_ID = PRT_CFG_ID
			END 

			
			--=====================================================
			--INSERT NEW ENTRIES INTO THE DEVICE_PORT_CONFIG TABLE
			--=====================================================
			WHILE EXISTS(SELECT PRT_CFG_ID FROM @TempCFG WHERE CFG_ACTION='I') BEGIN
				Select TOP 1
					@PRT_TYP_ID = PRT_TYP_ID
					,@PRT_DIR_CD = PRT_DIR_CD
					,@PRT_CNT = OLD_PRT_CNT
					,@PRT_GNDR = OLD_PRT_GNDR
				FROM @TempCFG 
				WHERE CFG_ACTION = 'I' AND PRT_CFG_ID=0 
				ORDER BY PRT_CFG_ID ASC
				
				IF (@DEBUG=1) 
						print 'CALLING: csp_ADD_DevicePortConfig (' + CAST(ISNULL(@DEV_ID,'') as varchar(10)) + ', ' + CAST(ISNULL(@PRT_TYP_ID,'') as varchar(10)) + ', ' + @PRT_DIR_CD + ', ' + CAST(ISNULL(@PRT_CNT,'') as varchar(3)) + ', ' + @PRT_GNDR + ', ''' + @LST_UPDT_USER_ID + ''')'

				exec @retRESULT = csp_ADD_DevicePortConfig @DEV_ID, @PRT_TYP_ID, @PRT_DIR_CD, @PRT_CNT, @PRT_GNDR, @LST_UPDT_USER_ID, @PRT_CFG_ID OUTPUT

				--CHECK FOR VALID DEVICE ID
				IF (@retRESULT = 0) BEGIN 
					SET @MSG = 'Unable to remove Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(ISNULL(@PRT_CFG_ID,'--null--') as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				-- WE ARE NOT ADJUSTING BUT ADDING APORT (SET PRT_CNT TO 0 AND LET IT SYNC)
				exec @retRESULT = dbo.csp_ADJUST_DevicePorts @DEV_ID, @PRT_CFG_ID, 'A', 0, @LST_UPDT_USER_ID

				--CHECK Return Results
				IF (@retRESULT = 0) BEGIN 
					SET @MSG = 'Error adjusting Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				DELETE FROM @TempCFG WHERE CFG_ACTION = 'I' AND @PRT_TYP_ID = PRT_TYP_ID AND @PRT_DIR_CD = PRT_DIR_CD AND @PRT_CNT = OLD_PRT_CNT AND @PRT_GNDR = OLD_PRT_GNDR
			END 

			--=====================================================
			--UDPATE ENTRIES IN THE DEVICE_PORT_CONFIG TABLE
			--=====================================================
			WHILE EXISTS(Select PRT_CFG_ID FROM @TempCFG) BEGIN
				Select TOP 1
					@PRT_CFG_ID = TC.PRT_CFG_ID
					,@PRT_TYP_ID = TC.PRT_TYP_ID
					,@PRT_DIR_CD = TC.PRT_DIR_CD
					,@CntDiff = (TC.NEW_PRT_CNT - TC.OLD_PRT_CNT)
					,@PRT_CNT = TC.NEW_PRT_CNT
					,@PRT_GNDR = TC.NEW_PRT_GNDR
				From	
					@TempCFG TC
				WHERE
					TC.CFG_ACTION = 'U'
				ORDER BY PRT_CFG_ID ASC


				IF (@DEBUG=1) 
						print 'CALLING: csp_UPD_DevicePortConfig (' + CAST(ISNULL(@DEV_ID,'') as varchar(10)) + ', ' + CAST(ISNULL(@PRT_TYP_ID,'') as varchar(10)) + ', ' + @PRT_DIR_CD + ', ' + CAST(ISNULL(@PRT_CNT,'') as varchar(3)) + ', ' + @PRT_GNDR + ', ''' + @LST_UPDT_USER_ID + ''')'

				--UPDATE DPC RECORD FIRST
				exec @retRESULT = dbo.csp_UPD_DevicePortConfig @DEV_ID, @PRT_CFG_ID, @PRT_CNT, @PRT_GNDR, @LST_UPDT_USER_ID

				--CHECK FOR VALID DEVICE ID
				IF (@retRESULT = 0) BEGIN 
					SET @MSG = 'Unable to update Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(ISNULL(@PRT_CFG_ID,'--null--') as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				--THEN MAKE ADJUSTMENTS TO THE DEVICE PORTS AND DEVICE PORT ATTRIBUTES TABLES
				IF (@CntDiff < 0) Begin
					--REMOVE PORTS
					Select @CntDiff = ABS(@CntDiff)
					exec @retRESULT = dbo.csp_ADJUST_DevicePorts @DEV_ID, @PRT_CFG_ID, 'S', @CntDiff, @LST_UPDT_USER_ID
				END ELSE BEGIN
					--ADD PORTS
					Select @CntDiff = ABS(@CntDiff)
					exec @retRESULT = dbo.csp_ADJUST_DevicePorts @DEV_ID, @PRT_CFG_ID, 'A', @CntDiff, @LST_UPDT_USER_ID
				END

				--set @retRESULT = 1
				--CHECK Return Results
				IF (@retRESULT = 0) BEGIN 
					SET @MSG = 'Error adjusting Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				--REMOVE LAST RECORD AND LOOP
				DELETE FROM @TempCFG WHERE @DEV_ID = DEV_ID AND @PRT_CFG_ID = PRT_CFG_ID 
			END
		END
		SET @RESULT = 1

	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		IF (@DEBUG = 1)
			print 'csp_UPD_Device (ERROR OCCURED)'

		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH


IF (@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG = 1) 
		print 'Transaction Committed (csp_UPD_Device)'
END 
ELSE IF (@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG = 1)
		print 'Transaction Rolledback (csp_UPD_Device)'
END

return(@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_DevicePortConfig]
	@DEV_ID			INT,
	@PRT_CFG_ID		INT,
	@PRT_CNT		TINYINT, 
	@PRT_GNDR		CHAR(1) = 'F',
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/18/2020
-- PURPOSE: Handles (Updating Device Port Configurations)
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/25/2020 - TCW - Intial Creationg of csp_UPD_DevicePortConfig
------------------------------------------------------------------------------------------------------------------

DECLARE @ERRMSG varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID varchar(60)
DECLARE @ICnt tinyint = 0
DECLARE @RESULT INT = 0
DECLARE @DEV_NAME varchar(100)
DECLARE @TranCnt int = @@TRANCOUNT
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL

--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

--Dont add to the transaction pool unless we need to.
IF (@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
	IF (@DEBUG = 1) BEGIN
		print 'Transaction Start (csp_UPD_DevicePortConfig)'
		PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))
	END
END

IF (@DEBUG=1)
	PRINT 'csp_UPD_DevicePortConfig (' + CAST(@DEV_ID as varchar(10)) + ',' + CAST(@PRT_CFG_ID as varchar(10)) + ',' + CAST(@PRT_CNT as varchar(10)) + ',' + @PRT_GNDR +  ',''' + ISNULL(@USR,'dbo') + ''')'

	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END
	
		--========================================================
		-- UPDATE DEVICE_PORT_CONFIG TABLE (UPDATES PRT_CNT ONLY)
		--========================================================
		UPDATE dbo.DEVICE_PORT_CONFIG SET
			PRT_CNT = CASE WHEN @PRT_CNT <> PRT_CNT THEN @PRT_CNT ELSE PRT_CNT END
			,PRT_GNDR = CASE WHEN @PRT_GNDR <> PRT_GNDR THEN @PRT_GNDR ELSE PRT_GNDR END
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			@DEV_ID = DEV_ID
			AND @PRT_CFG_ID = PRT_CFG_ID
			AND (
				@PRT_CNT <> PRT_CNT
				OR @PRT_GNDR <> PRT_GNDR
				)
		


		SET @RESULT=1
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		IF (@DEBUG=1) 
			print 'Failed in (csp_UPD_DevicePortsConfig)'

		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

IF (@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG = 1) 
		print 'Transaction Committed (csp_UPD_DevicePortConfig)'
END 
ELSE IF (@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG = 1)
		print 'Transaction RolledBack (csp_UPD_DevicePortConfig)'
END

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_DevicePortConfig]
	@DEV_ID			INT,
	@PRT_TYP_ID		TINYINT,
	@PRT_DIR_CD		CHAR(1) = null,
	@PRT_CNT		TINYINT, 
	@PRT_GNDR		CHAR(1) = null,
	@USR			VARCHAR(60) = null,
	@PRT_CFG_ID		INT OUTPUT  
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/18/2020
-- PURPOSE: Handles (Adding Device Port Configurations)
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/18/2020 - TCW - Intial Creationg of csp_ADD_DevicePortConfig
------------------------------------------------------------------------------------------------------------------

DECLARE @ERRMSG varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID varchar(60)
DECLARE @ICnt tinyint = 0
DECLARE @RESULT INT = 0
DECLARE @DEV_NAME varchar(100)
DECLARE @TranCnt int = @@TRANCOUNT
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL


--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

--Dont add to the transaction pool unless we need to.
IF (@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
	IF (@DEBUG = 1) BEGIN
		print 'Transaction Start (csp_ADD_DevicePortConfig)'
		PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))	
	END
END 

IF (@DEBUG = 1)
	PRINT 'csp_ADD_DevicePortConfig (' + CAST(@DEV_ID as varchar(10)) + ',' + CAST(@PRT_TYP_ID as varchar(10)) + ',''' + @PRT_DIR_CD + ''',' + CAST(@PRT_CNT as varchar(10)) + ',''' + @PRT_GNDR + ''',''' + ISNULL(@USR,'dbo') + ''')'

	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()


	BEGIN TRY

		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END
		
		--WALK THRU ALL THE PORT TYPE CONNECTIONS AND CREATE A DEVICE_PORT ENTRY
		SET @ICnt = 0 
	
		INSERT INTO dbo.DEVICE_PORT_CONFIG (DEV_ID, PRT_TYP_ID, PRT_DIR_CD, PRT_CNT, PRT_GNDR, REC_CRTE_USER_ID)
		Select @DEV_ID, @PRT_TYP_ID, @PRT_DIR_CD, @PRT_CNT, @PRT_GNDR, @REC_CRTE_USER_ID
		SET @PRT_CFG_ID = SCOPE_IDENTITY()

		WHILE (@ICnt < @PRT_CNT) BEGIN
			--CREATE A DEVICE PORT FOR ALL PRT_CNTS OF A PARTICULAR PORT CONFIGURATION
			INSERT INTO dbo.DEVICE_PORTS (PRT_CFG_ID, PRT_ID, REC_CRTE_USER_ID)
			Select @PRT_CFG_ID, @ICnt + 1 PRT_ID, @REC_CRTE_USER_ID
			SET @ICnt += 1
		END

		SET @RESULT=1
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		IF (@DEBUG = 1) 
			print 'Failed in (csp_ADD_DevicePortsConfig)'

		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH


IF (@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG = 1) 
		print 'Transaction Committed (csp_ADD_DevicePortConfig)'
END 
ELSE IF (@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG = 1)
			print 'Transaction RolledBack (csp_ADD_DevicePortConfig)'
END

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_DEL_DevicePortConfig]
	@DEV_ID			INT = 0,
	@PRT_CFG_ID		INT = 0,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/18/2020
-- PURPOSE: Handles (Device Port Configurations)
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/18/2020 TCW - Intial Creationg of csp_DEL_DevicePortConfig
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @DEV_NAME as varchar(100) = null
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @PRT_LNK as varchar(255)
DECLARE @RESULT INT = 0
DECLARE @TranCnt int = @@TRANCOUNT
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL

--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

--Dont add to the transaction pool unless we need to.
IF(@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
	IF (@DEBUG = 1) BEGIN
		print 'Transaction Start (csp_DEL_DevicePortConfig)'
		PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))
	END
END

IF (@DEBUG = 1)
	PRINT 'csp_DEL_DevicePortConfig (' + CAST(@DEV_ID as varchar(10)) + ',' + CAST(@PRT_CFG_ID as varchar(10)) + ',''' + ISNULL(@USR,'dbo') + ''')'

	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE_PORT_CONFIG ID
		IF (@PRT_CFG_ID = 0) OR NOT EXISTS(SELECT PRT_CFG_ID from dbo.DEVICE_PORT_CONFIG WITH (NOLOCK) WHERE PRT_CFG_ID=@PRT_CFG_ID) BEGIN 
			SET @MSG = 'Invalid Port Configuration ID Provided. (PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END


		--UNASSIGN ANY INSTRUMENT LINKED TO THIS INSTRUMENTS DEVICE_PORTS SEEING THIS PRT_CFG_ID IS BEING REMOVED
		--(UNASSOCIATES IT WITH THIS DEVICE)

		--GET PORT LNK SO IT CAN BE REMOVED FROM REFERRING DEVICES
		Select @PRT_LNK = RTRIM(CAST(DPC.PRT_CFG_ID as VARCHAR(10))) + '.'
		FROM dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
		WHERE DPC.DEV_ID = @DEV_ID AND DPC.PRT_CFG_ID = @PRT_CFG_ID
		
		--REMOVE ASSOCIATION
		UPDATE dbo.DEVICE_PORT_ATTR SET
			ATTR_VALUE = 0
		WHERE
			@PRT_CFG_ID = PRT_CFG_ID
			AND RTRIM(CAST(PRT_CFG_ID as VARCHAR(10))) + '.' = @PRT_LNK --NOTE: PRT_CFG_ID WILL BE UNIQUE TO EACH TYPE OF PORT TYPE... 
			AND ATTR_KEY_CD IN ('LOD_ASSN','PRT_ASSN')

		--FOR AUDIT REASONS (PRIOR TO DELETE)
		UPDATE DPA SET 
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
			,LST_UPDT_TS = GetDate()
		FROM
			dbo.DEVICE_PORT_CONFIG DPC INNER JOIN dbo.DEVICE_PORT_ATTR DPA
			ON 
				DPC.PRT_CFG_ID = DPA.PRT_CFG_ID
				AND DPC.DEV_ID = @DEV_ID
				AND DPC.PRT_CFG_ID = @PRT_CFG_ID	
		
		--DELETE FROM DEVICE_PORT_ATTR
		DELETE FROM DPA 
		FROM
			dbo.DEVICE_PORT_CONFIG DPC INNER JOIN dbo.DEVICE_PORT_ATTR DPA
			ON 
				DPC.PRT_CFG_ID = DPA.PRT_CFG_ID
				AND DPC.DEV_ID = @DEV_ID
				AND DPC.PRT_CFG_ID = @PRT_CFG_ID

		--FOR AUDIT REASONS (PRIOR TO DELETE)
		UPDATE DP SET 
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
			,LST_UPDT_TS = GetDate()
		FROM
			dbo.DEVICE_PORT_CONFIG DPC INNER JOIN dbo.DEVICE_PORTS DP
			ON 
				DPC.PRT_CFG_ID = DP.PRT_CFG_ID
				AND DPC.DEV_ID = @DEV_ID
				AND DPC.PRT_CFG_ID = @PRT_CFG_ID

		--DELETE FROM DEVICE_PORTS
		DELETE FROM DP
		FROM
			dbo.DEVICE_PORT_CONFIG DPC INNER JOIN dbo.DEVICE_PORTS DP
			ON 
				DPC.PRT_CFG_ID = DP.PRT_CFG_ID
				AND DPC.DEV_ID = @DEV_ID
				AND DPC.PRT_CFG_ID = @PRT_CFG_ID


		--FOR AUDIT REASONS (PRIOR TO DELETE)
		UPDATE dbo.DEVICE_PORT_CONFIG SET 
			LST_UPDT_USER_ID = @LST_UPDT_USER_ID
			,LST_UPDT_TS = GetDate()
		WHERE DEV_ID = @DEV_ID AND PRT_CFG_ID = @PRT_CFG_ID

		--DELETE FROM DEVICE_PORT_CONFIG
		DELETE FROM dbo.DEVICE_PORT_CONFIG WHERE DEV_ID = @DEV_ID AND PRT_CFG_ID = @PRT_CFG_ID
		
		SET @RESULT = 1
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		IF (@DEBUG = 1) 
			print 'Failed in (csp_DEL_DevicePortsConfig)'

		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE DELETE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

IF (@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG = 1) 
		print 'Transaction Committed (csp_DEL_DevicePortConfig)'
END 
ELSE IF (@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG = 1)
		print 'Transaction RolledBack (csp_DEL_DevicePortConfig)'
END

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_ADJUST_DevicePorts]
	@DEV_ID			INT,
	@PRT_CFG_ID		INT,
	@PRT_ACT		CHAR(1),  -- 'S' for Subtract, 'A' for Add
	@PRT_CNT		smallint,  -- Number of ports to remove or add
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/18/2020
-- PURPOSE: Handles (Adjusting Device Port Configurations)
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/18/2020 - TCW - Intial Creationg of [csp_ADJUST_DevicePorts]
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID varchar(60)
DECLARE @RESULT INT = 0
DECLARE @ICnt int = 0
DECLARE @POS_START int = 0
DECLARE @DEV_NAME varchar(100)
DECLARE @TranCnt int = @@TRANCOUNT
DECLARE @MISMATCHED bit = 0
DECLARE @MATHGOOD BIT = 0
DECLARE @DEBUG BIT = 0			--USED TO CONTROL DEBUG MESSAGES (1=On/0=Off) -SEE APP_DEFAULTS TABLE KEY=DEBUGSQL

--SET DEBUG PREFERENCE (SETS DEBUG FLAG/BIT to 0 or 1)
SELECT @DEBUG = CASE WHEN CAST(ISNULL(APD.APP_VALUE,'0') as varchar(3)) > 0 THEN 1 ELSE 0 END from dbo.APP_DEFAULTS APD WITH (NOLOCK) WHERE APD.APP_KEY = 'DEBUGSQL'

--Dont add to the transaction pool unless we need to.
IF (@TranCnt = 0) BEGIN
	BEGIN TRANSACTION 
	IF (@DEBUG = 1) BEGIN
		print 'Transaction Start (csp_ADJUST_DevicePorts)'
		PRINT 'TRAN COUNT: ' + CAST(@@TRANCOUNT as varchar(3))
	END
END

IF (@DEBUG=1)
	PRINT 'csp_ADJUST_DevicePorts (' + CAST(@DEV_ID as varchar(10)) + ',' + CAST(@PRT_CFG_ID as varchar(10)) + ',''' + @PRT_ACT + ''',' + CAST(@PRT_CNT as varchar(10)) + ',''' + ISNULL(@USR,'dbo') + ''')'

	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE_PORT_CONFIG ID
		IF (@PRT_CFG_ID = 0) OR NOT EXISTS(SELECT PRT_CFG_ID from dbo.DEVICE_PORT_CONFIG WITH (NOLOCK) WHERE PRT_CFG_ID=@PRT_CFG_ID) BEGIN 
			SET @MSG = 'Invalid Port Configuration ID Provided. (PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END

		--GATHER ANALYSIS DATA TO CHECK FOR MISMATCHED PORT_CONFIGURATIONS (IF SO FIX THEM)
		Select 
			@POS_START = MAX(DP.PRT_ID)
			,@MISMATCHED = CASE WHEN COUNT(DP.PRT_ID) = MAX(DP.PRT_ID)  THEN 0 ELSE 1 END
			,@MATHGOOD = CASE 
							WHEN DPC.PRT_CNT = CASE 
								WHEN @PRT_ACT = 'S' THEN COUNT(DP.PRT_ID) - @PRT_CNT  
								WHEN @PRT_ACT = 'N' THEN COUNT(DP.PRT_ID)  
								ELSE COUNT(DP.PRT_ID) + @PRT_CNT 
							END THEN 1 ELSE 0 
						END
		from 
			dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
			INNER JOIN dbo.DEVICE_PORTS DP WITH (NOLOCK) 
			ON	DPC.PRT_CFG_ID = DP.PRT_CFG_ID
				AND @DEV_ID = DPC.DEV_ID
				AND @PRT_CFG_ID = DPC.PRT_CFG_ID
		GROUP BY DPC.PRT_CNT
		

		IF (@MISMATCHED = 1 OR @MATHGOOD = 0) BEGIN
			-- THIS SHOULD NEVER HAPPEN, BUT IF IT DOES ATTEMPT TO CORRECT IT
			IF (@DEBUG = 1) 
				PRINT 'PORT MUST BE REBUILT - THERE IS A MISMATCH'

				--REMOVE DEVICE_PORTS 
					
				--REMOVE DEVICE_PORT_ATTR

				--RE-ADD DEVICE_PORTS 

				--RE-ADD 
		END

		IF (@MISMATCHED = 0 AND @MATHGOOD = 1) BEGIN
			-- THIS SHOULD NEVER HAPPEN, BUT IF IT DOES ATTEMPT TO CORRECT IT
			IF (@DEBUG = 1) 
				PRINT 'ACTION TO ''' + CASE WHEN @PRT_ACT = 'S' THEN 'REMOVE' ELSE 'ADD' END + ''' PORTS PASSED VALIDATION.'

			SET @ICnt = @POS_START
			
			IF (@PRT_ACT = 'S') BEGIN
				if (@DEBUG = 1) 
					print 'SUBTRACTING PORT INFO FOR PRT_CFG_ID: ' + CAST(@PRT_CFG_ID as varchar(10)) + " (" + CAST(@PRT_CNT as varchar(3)) + ")"
				--UPDATE DEVICE_PORTS (FOR AUDIT REASONS)
				UPDATE DP SET
					LST_UPDT_TS = GetDate()
					,LST_UPDT_USER_ID = @REC_CRTE_USER_ID
				FROM 
					dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
					INNER JOIN dbo.DEVICE_PORTS DP
					ON
						DPC.PRT_CFG_ID = DP.PRT_CFG_ID
						AND @DEV_ID = DPC.DEV_ID
						AND @PRT_CFG_ID = DPC.PRT_CFG_ID
						AND (@POS_START-@PRT_CNT ) < DP.PRT_ID

				--UPDATE DEVICE_PORT_ATTR (FOR AUDIT REASONS)
				UPDATE DPA SET
					LST_UPDT_TS = GetDate()
					,LST_UPDT_USER_ID = @REC_CRTE_USER_ID
				FROM 
					dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
					INNER JOIN dbo.DEVICE_PORTS DP WITH (NOLOCK)
					ON
						DPC.PRT_CFG_ID = DP.PRT_CFG_ID
						AND @DEV_ID = DPC.DEV_ID
						AND @PRT_CFG_ID = DPC.PRT_CFG_ID
						AND (@POS_START-@PRT_CNT ) < DP.PRT_ID
					INNER JOIN dbo.DEVICE_PORT_ATTR DPA 
					ON
						DPC.PRT_CFG_ID = DPA.PRT_CFG_ID
						AND DP.PRT_ID = DPA.PRT_ID
				
				--REMOVE EXCESS PORTS FOR DEVICE_PORT_ATTR
				DELETE FROM DPA
				FROM 
					dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
					INNER JOIN dbo.DEVICE_PORTS DP WITH (NOLOCK)
					ON
						DPC.PRT_CFG_ID = DP.PRT_CFG_ID
						AND @DEV_ID = DPC.DEV_ID
						AND @PRT_CFG_ID = DPC.PRT_CFG_ID
						AND (@POS_START-@PRT_CNT ) < DP.PRT_ID
					INNER JOIN dbo.DEVICE_PORT_ATTR DPA 
					ON
						DPC.PRT_CFG_ID = DPA.PRT_CFG_ID
						AND DP.PRT_ID = DPA.PRT_ID

				--REMOVE EXCESS PORTS FOR DEVICE_PORTS
				DELETE FROM DP
				FROM 
					dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
					INNER JOIN dbo.DEVICE_PORTS DP
					ON
						DPC.PRT_CFG_ID = DP.PRT_CFG_ID
						AND @DEV_ID = DPC.DEV_ID
						AND @PRT_CFG_ID = DPC.PRT_CFG_ID
						AND (@POS_START-@PRT_CNT ) < DP.PRT_ID
			END
			ELSE IF (@PRT_ACT = 'A') BEGIN
				if (@DEBUG = 1) 
					print 'ADDING PORT INFO FOR PRT_CFG_ID: ' + CAST(@PRT_CFG_ID as varchar(10)) + " (" + CAST(@PRT_CNT as varchar(3)) + ")"
				
				WHILE (@ICnt < (@POS_START + @PRT_CNT)) BEGIN
					--INSERT PRT_ID INTO DEVICE_PORTS TABLE
					INSERT INTO dbo.DEVICE_PORTS (PRT_CFG_ID, PRT_ID, REC_CRTE_USER_ID)
					Select @PRT_CFG_ID, @ICnt+1, @REC_CRTE_USER_ID

					SET @ICnt += 1
				END
			END
			IF (@PRT_ACT IN ('A','N')) BEGIN
				--HANDLE THE MISSING PORT ATTRIBUTE ENTRIES IN BULK FOR EACH LAYOUT
				INSERT INTO dbo.DEVICE_PORT_ATTR (LO_ID, PRT_CFG_ID, PRT_ID, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_USER_ID)
				Select 
					L.LO_ID
					,DRV.PRT_CFG_ID
					,DRV.PRT_ID
					,CC.COMM_CD as ATTR_KEY_CD
					,REPLACE(
						REPLACE(
							REPLACE(dbo.fnc_AppSettingValue(CC.COMM_CD),'@VAL',RTRIM(CAST(DRV.PRT_ID as varchar(3))))
						,'@PT',RTRIM(dbo.fnc_PortToText(DRV.PRT_TYP_ID)))
					,'@CT',RTRIM(ISNULL(dbo.fnc_CommonCodeTXT(DRV.PRT_DIR_CD,'PORT_DIR'),''))) as ATTR_VALUE
					,DRV.REC_CRTE_USER_ID
				FROM (
					Select
						DPC.DEV_ID
						,DPC.PRT_TYP_ID
						,DPC.PRT_DIR_CD
						,DP.PRT_CFG_ID, DP.PRT_ID, 1 LO_ID, DP.REC_CRTE_TS, DP.REC_CRTE_USER_ID, DP.LST_UPDT_TS, DP.LST_UPDT_USER_ID
					FROM
						dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
						INNER JOIN dbo.DEVICE_PORTS DP WITH (NOLOCK)
						ON
							DPC.PRT_CFG_ID = DP.PRT_CFG_ID
							AND @DEV_ID = DPC.DEV_ID 
							AND @PRT_CFG_ID = DPC.PRT_CFG_ID
						FULL OUTER JOIN
						dbo.DEVICE_PORT_ATTR DPA 
						ON
							DPC.PRT_CFG_ID = DPA.PRT_CFG_ID
							AND DP.PRT_ID = DPA.PRT_ID
					WHERE 
						DP.PRT_ID IS NOT NULL
						AND DPA.PRT_ID IS NULL
				) DRV,
				dbo.COMMON_CODES CC WITH (NOLOCK),
				dbo.LAYOUTS L WITH (NOLOCK)
				WHERE
					L.LO_DEV_ID = DRV.DEV_ID
					AND CC.COMM_TYPE_CD ='PRT_ATTR'

			END
		END
		
		SET @RESULT=1

	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ISNULL(ERROR_NUMBER(),'') as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		IF (@DEBUG=1)
			print 'Failed in (csp_ADJUST_DevicePorts)'

		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('PORT_ATTR_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE PORT ATTR ADJUSTMENT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + '''), [PRT_CFG_ID] - ( ' + CAST(@PRT_CFG_ID as varchar(10)) + ' )    [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

IF	(@TranCnt = 0) AND (@RESULT = 1) BEGIN
	COMMIT TRANSACTION
	IF (@DEBUG=1)
		print 'Transaction committed (csp_ADJUST_DevicePorts)'
END 
ELSE IF	(@TranCnt = 0) AND (@RESULT = 0) BEGIN
	ROLLBACK TRANSACTION
	IF (@DEBUG=1)
		print 'Transaction rolledback (csp_ADJUST_DevicePorts)'
END
return (@RESULT)
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
DECLARE @ERRMSG  varchar(2048)
DECLARE @DEV_NAME varchar(100) = null
DECLARE @MSG varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @PRT_CFG_ID INT = 0
DECLARE @retResult INT = 0
DECLARE @RESULT int = 0
DECLARE @TempCFG TABLE (
	PRT_CFG_ID int NOT NULL
)

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()


	BEGIN TRY
		--CHECK FOR VALID DEVICE ID
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END


		IF (@SOFT_DELETE = 0) BEGIN
			
			INSERT INTO @TempCFG
			Select PRT_CFG_ID FROM dbo.DEVICE_PORT_CONFIG WITH (NOLOCK) WHERE @DEV_ID = DEV_ID

			WHILE EXISTS(SELECT PRT_CFG_ID FROM @TempCFG) BEGIN
				--GET FIRST ID
				Select TOP 1 @PRT_CFG_ID = PRT_CFG_ID FROM @TempCFG ORDER BY PRT_CFG_ID ASC

				--FIRST REMOVE PORT CONFIGURATIONS AND ATTRIBUTES (PLUS UNASSOCIATE ANY DEVICES LINKED TO THIS DEVICE)
				exec @retResult = dbo.csp_DEL_DevicePortConfig @DEV_ID,@PRT_CFG_ID, @LST_UPDT_USER_ID

				--CHECK FOR VALID DEVICE ID
				IF (@retResult = 0) BEGIN 
					SET @MSG = 'Unable to remove Port Configuration! (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + '), ' + '(PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ')'
					RAISERROR (@MSG,15,1) 
				END

				DELETE FROM @TempCFG WHERE  @PRT_CFG_ID = PRT_CFG_ID
			END

			--SECOND REMOVE LAYOUTS FOR DEVICE
			DELETE FROM dbo.LAYOUTS WHERE LO_DEV_ID = @DEV_ID

			--LASTLY DELETE DEVICE
			--SO I CAN GET A USERNAME FOR THE ACTION IN THE TRIGGER (Ahh.. Eh.. Eh...Smart Huh!)
			UPDATE dbo.DEVICES SET LST_UPDT_USER_ID = @LST_UPDT_USER_ID WHERE DEV_ID = @DEV_ID 
			DELETE FROM dbo.DEVICES WHERE DEV_ID = @DEV_ID

			--FOR CLEANUP PURPOSES (REMOVES ANY LAYOUT THAT USES A DEVICE THAT DOESN'T EXIST)
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
		SET @RESULT = 1

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE DELETE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return (@RESULT)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UnDEL_Device]
	@DEV_ID			INT = 0,
	@USR			VARCHAR(60) = null
AS
SET NOCOUNT ON
------------------------------------------------------------------------------------------------------------------
-- AUTHOR : Thomas Wallace		   DATE: 10/07/2020
-- PURPOSE: Handles Undelete a Soft deleted Device
------------------------------------------------------------------------------------------------------------------
-- UPDATES:	
-- 10/14/2020 TCW - Intial Creationg of csp_UnDel_Device
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
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END

		--UNDELETE THE SOFTDELTE SET IT BACK TO ZERO SO IT IS VISIBLE
		UPDATE dbo.DEVICES SET 
			DEV_SFT_DEL = 0 
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
			,LST_UPDT_TS = GetDate()
		WHERE 
			DEV_ID = @DEV_ID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE UNDELETE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
	END CATCH

return
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_Device_Port_Attr]
	@PRT_CFG_ID		INT,
	@PRT_ID			INT,
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
-- 10/07/2020 - TCW - Intial Creationg of csp_UPD_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @LST_UPDT_USER_ID as varchar(60)
DECLARE @DEV_ID INT
DECLARE @DEV_NAME varchar(100)
DECLARE @RESULTS INT = 1

BEGIN TRANSACTION 
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @LST_UPDT_USER_ID = @USR
	else
		SET @LST_UPDT_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID PORT CONFIG ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@PRT_CFG_ID = 0) OR NOT EXISTS(SELECT PRT_CFG_ID from dbo.DEVICES_PORT_CONFIG WITH (NOLOCK) WHERE PRT_CFG_ID=@PRT_CFG_ID) BEGIN 
			SET @MSG = 'Invalid Port Config ID Provided. (PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME & ID OF DEVICE (FOR AUDIT REASONS)
			SELECT 
				@DEV_NAME = D.DEV_NAME 
				,@DEV_ID = D.DEV_ID
			from 
				dbo.DEVICES D WITH (NOLOCK) 
				INNER JOIN dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
				ON 
					D.DEV_ID = DPC.DEV_ID
					AND DPC.PRT_CFG_ID = @PRT_CFG_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		--BUILD DEVICE PORT ATTR RECORD
		UPDATE dbo.DEVICE_PORT_ATTR SET 
			ATTR_VALUE = dbo.fnc_StripSpcChars(@ATTR_VALUE)
			,LST_UPDT_TS = GetDate()
			,LST_UPDT_USER_ID = @LST_UPDT_USER_ID
		WHERE
			@PRT_CFG_ID = PRT_CFG_ID
			AND @PRT_ID = PRT_ID
			AND @LO_ID = LO_ID
			AND @ATTR_KEY_CD = ATTR_KEY_CD


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		--ERROR CATCH
		ROLLBACK TRANSACTION

		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('PORT_ATTR_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE PORT ATTR UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID

		SET @RESULTS = 0
	END CATCH

return (@RESULTS)
GO


CREATE OR ALTER PROCEDURE [dbo].[csp_UPD_Device_EXT_Attr]
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
-- 10/07/2020 - TCW - Intial Creationg of csp_UPD_Device_Port_Attr
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
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
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
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ATTR_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE EXT ATTR UPDATE ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@LST_UPDT_USER_ID,user_name()) as REC_CRTE_USER_ID
		
		SET @RESULTS = 0

	END CATCH

return(@RESULTS)
GO


/** csp_ADD_Device_Port_Attr (NOT USED CURRENTLY)
CREATE OR ALTER PROCEDURE [dbo].[csp_ADD_Device_Port_Attr]
	@PRT_CFG_ID		INT,
	@PRT_ID			INT,
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
-- 10/07/2020 - TCW - Intial Creationg of csp_ADD_Device_Port_Attr
------------------------------------------------------------------------------------------------------------------
DECLARE @ERRMSG as varchar(2048)
DECLARE @MSG as varchar(2048)
DECLARE @REC_CRTE_USER_ID as varchar(60)
DECLARE @DEV_ID int
DECLARE @DEV_NAME varchar(100)
DECLARE @TranCnt int = @@TRANCOUNT
DECLARE @RESULT INT = 0

IF	(@TranCnt = 0) 
	BEGIN TRANSACTION 
	
	--SET USER ID FOR TRANSACTION
	IF (@USR is not null)
		SET @REC_CRTE_USER_ID = @USR
	else
		SET @REC_CRTE_USER_ID = USER_NAME()

	BEGIN TRY
		--CHECK FOR VALID PORT CONFIG ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@PRT_CFG_ID = 0) OR NOT EXISTS(SELECT PRT_CFG_ID from dbo.DEVICES_PORT_CONFIG WITH (NOLOCK) WHERE PRT_CFG_ID=@PRT_CFG_ID) BEGIN 
			SET @MSG = 'Invalid Port Config ID Provided. (PRT_CFG_ID=' + CAST(@PRT_CFG_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME & ID OF DEVICE (FOR AUDIT REASONS)
			SELECT 
				@DEV_NAME = D.DEV_NAME 
				,@DEV_ID = D.DEV_ID
			from 
				dbo.DEVICES D WITH (NOLOCK) 
				INNER JOIN dbo.DEVICE_PORT_CONFIG DPC WITH (NOLOCK)
				ON 
					D.DEV_ID = DPC.DEV_ID
					AND DPC.PRT_CFG_ID = @PRT_CFG_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
			SET @MSG = 'Invalid Layout ID Provided. (LO_ID=' + CAST(@LO_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END

		
		--BUILD DEVICE PORT ATTR RECORD
		INSERT INTO dbo.DEVICE_PORT_ATTR (PRT_CFG_ID, PRT_ID, LO_ID, ATTR_KEY_CD, ATTR_VALUE, REC_CRTE_USER_ID)
		Select @PRT_CFG_ID, @PRT_ID, @LO_ID, @ATTR_KEY_CD, dbo.fnc_StripSpcChars(@ATTR_VALUE), @REC_CRTE_USER_ID 


		SET @RESULT = 1

	END TRY
	BEGIN CATCH
		--ERROR CATCH
		SET @ERRMSG = '(' + CAST(ERROR_NUMBER() as VARCHAR(10)) + ' - ' + ERROR_MESSAGE() + ')'
		
		--LOG ERROR IN ACTIVIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE PORT ATTR INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID
		
	END CATCH

	IF	(@TranCnt = 0) 
		IF (@RESULT = 1) BEGIN
			--COMMIT TRANSACTION
			print 'Transaction committed (csp_ADJUST_DevicePorts)'
		END ELSE BEGIN
			--ROLLBACK TRANSACTION
			print 'Transaction rolledback (csp_ADJUST_DevicePorts)'
		END

return (@RESULT)
*/
GO


/** csp_ADD_Device_EXT_Attr  (NOT USED CURRENTLY)
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
		IF (@DEV_ID = 0) OR NOT EXISTS(SELECT DEV_ID from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID) BEGIN 
			SET @MSG = 'Invalid Device ID Provided. (DEV_ID=' + CAST(@DEV_ID as varchar(10)) + ' - NOT VALID!)'
			RAISERROR (@MSG,15,1) 
		END 
		ELSE BEGIN
			--IF DEVICE EXISTS THEN GET NAME OF DEVICE (FOR AUDIT REASONS)
			SELECT @DEV_NAME = DEV_NAME from dbo.DEVICES WITH (NOLOCK) WHERE DEV_ID=@DEV_ID
		END

		--CHECK FOR VALID LAYOUT ID (SHOULD NEVER HAPPEN BUT SAFEGAURD CHECK)
		IF (@LO_ID = 0) OR NOT EXISTS(SELECT LO_ID from dbo.LAYOUTS WITH (NOLOCK) WHERE LO_ID=@LO_ID) BEGIN 
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
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DEV_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_ERR') as ACT_TYP_ID,
			@DEV_ID,
			RTRIM('<<DEVICE EXT ATTR INSERT ERROR>>  -  [DEV_NAME] - (''' + ISNULL(@DEV_NAME,'--null--') + ''')     [ERROR] - ' + 
			'(' + ISNULL(ERROR_PROCEDURE(),'') + ') - ' + @ERRMSG
			) as ACT_DESC,
			isnull(@REC_CRTE_USER_ID,user_name()) as REC_CRTE_USER_ID

		SET @RESULTS = 0
	END CATCH

return(@RESULTS)
*/
GO


--======================================================
-- GRANT EXECUTIONS FOR PROCEDURES SECION (IF NEEDED)
--======================================================
/* EXAMPLE BELOW:
	GRANT EXECUTE ON [dbo].[csp_ADD_Device] TO [db_executor] AS [dbo]
	GO
*/
