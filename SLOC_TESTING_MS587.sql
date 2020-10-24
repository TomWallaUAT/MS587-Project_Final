--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

--TRUNCATE USERS AND AUDIT TABLES
TRUNCATE TABLE dbo.AUDIT_ACTIVITY
TRUNCATE TABLE dbo.USERS
TRUNCATE TABLE dbo.USER_INFO


--USER SETUP AND MANIPULATION TEST
exec dbo.csp_ADD_User 'AdminTom','D3m0P@55w0rd','tcw8915@q.com',1,2,3,'Pemberton','East Valley','Jaws','Tom','Wallace','4802629115','S', null

exec dbo.csp_ADD_User 'TBAZ74','D3m0P@55w0rd','TBAZ74@yahoo.com',1,2,3,'Pemberton','Red Mountain','Jaws','Thomas','Wallace','4802629115','S', 'AdminTom'
exec dbo.csp_ADD_User 'TommyBoyAZ','D3m0P@55w0rd1!2@','slmtommy@yahoo.com',1,2,3,'Wallace','Mountain View','Jeo','Tiger','King','6232153602','S', 'AdminTom'

exec dbo.csp_UPDATE_User 'TBAZ74','TBAZ74@yahoo.com',1,2,3,'Hart','Dobson','Cricket','Moose','Finbar','4805551212','N', 'AdminTom' 
exec dbo.csp_UPDATE_User 'TommyBoyAZ','slmtommy@yahoo.com',1,2,3,'Johnson','Mountain View','Jeo','Doctor','BraveStone','4805551313','N','AdminTom'

exec dbo.csp_UPDATE_User 'TBAZ74','TBAZ74@yahoo.com',1,2,3,'Pemberton','Red Mountain','Jaws','Thomas','Wallace','4802629115','S', 'AdminTom'
exec dbo.csp_UPDATE_User 'TommyBoyAZ','slmtommy@yahoo.com',1,2,3,'Wallace','Mountain View','Jeo','Tiger','King','6232153602','S', 'AdminTom'

exec dbo.csp_DELETE_User_ByEmail 'slmtommy@yahoo.com','AdminTom'
exec dbo.csp_DELETE_User_ByUserID 'TommyBoyAZ','AdminTom'
exec dbo.csp_DELETE_User_ByUserID 'TBAZ74','AdminTom'

--PASSWORD UPDATE (REQUIRED OLD AND NEW PASSWORD TO WORK - HAS OUTPUT)
DECLARE @P_OUTPUT VARCHAR(255)
--exec dbo.csp_UPDATE_Password 'AdminTom','D3m0P@55w0rd','C@tL0v3r123','AdminTom', @P_OUTPUT OUTPUT
exec dbo.csp_UPDATE_Password 'AdminTom','C@tL0v3r123','D3m0P@55w0rd','AdminTom', @P_OUTPUT OUTPUT
PRINT @P_OUTPUT
Select * from dbo.V_USER_INFO_ALL 


--TEST ACCOUNT LOCKOUT PERIOD (IF ACCOUNT IS LOGGED IN MULTIPLE TIMES INCORRECTLY IT IS LOCKED OUT FOR A DURATION OF TIME)
DECLARE @P_OUTPUT as varchar(255)
DECLARE @P_RESULT as tinyint

exec  @P_RESULT = dbo.csp_LOGON_User 'tcw8915@q.com','D3m0P@55w0rd1', @P_OUTPUT output
PRINT CAST(@P_RESULT as varchar(1)) + ' - ' + @P_OUTPUT
Select * from dbo.V_USER_INFO_ALL 

/** ENCRYPTION DATA TEST WITH VIEW
--SHOWS DENCRYPTED DATA
Select * from dbo.V_USER_INFO_ALL 

--SHOWS ENCRYPTED DATA
Select 
	UI.USER_ID
	,UI.USER_FNAME
	,UI.USER_LNAME 
	,UI.USER_PHONE 
	,U.USER_EMAIL
	,U.USER_PWD
	,UI.SEC_QID_1
	,dbo.fnc_GetSecurityQuestion(UI.SEC_QID_1) as SEC_QUESTION_1_TXT
	,U.SEC_QID_1 as SEC_QUEST_ANS_1
	,UI.SEC_QID_2
	,dbo.fnc_GetSecurityQuestion(UI.SEC_QID_2) as SEC_QUESTION_2_TXT
	,U.SEC_QID_2 as SEC_QUEST_ANS_2
	,UI.SEC_QID_3
	,dbo.fnc_GetSecurityQuestion(UI.SEC_QID_3) as SEC_QUESTION_3_TXT
	,U.SEC_QID_3 as SEC_QUEST_ANS_3
	,dbo.fnc_CommonCodeTXT(UI.USER_VRFY_PREF_CD,'VRFY_PRF') USER_VRFY_PREF  
	,CASE WHEN UI.USER_ACT_VRFY=1 THEN 'VERIFIED' ELSE ' UNVERIFIED' END USER_ACT_VRFY
	,CASE WHEN U.USER_ACCT_LCK=1 THEN 'LOCKED!' ELSE 'UnLocked' END USER_ACCT_LCK
	,U.USER_LST_LOGIN_TS
	,U.USER_LOGIN_FAIL_DT
	,U.USER_LOGIN_FAIL_CNT
	,CASE WHEN UI.REC_CRTE_TS >= U.LST_UPDT_TS THEN UI.LST_UPDT_TS ELSE U.LST_UPDT_TS END REC_CRTE_TS 
	,CASE WHEN UI.REC_CRTE_TS >= U.REC_CRTE_TS THEN UI.REC_CRTE_USER_ID ELSE U.REC_CRTE_USER_ID END REC_CRTE_USER_ID
	,CASE WHEN UI.LST_UPDT_TS >= U.LST_UPDT_TS THEN UI.LST_UPDT_TS ELSE U.LST_UPDT_TS END LST_UPDT_TS 
	,CASE WHEN UI.LST_UPDT_TS >= U.LST_UPDT_TS THEN UI.LST_UPDT_USER_ID ELSE U.LST_UPDT_USER_ID END LST_UPDT_USER_ID
FROM 
	dbo.USER_INFO UI WITH (NOLOCK)
	INNER JOIN dbo.USERS U WITH (NOLOCK)
	ON UI.USER_ID = U.USER_ID
*/


--TEST OF Exists Functions

Select dbo.fnc_CheckEmailExist('tbaz74@yahoo.com')
Select dbo.fnc_CheckUserIDExist('tbaz74')

/** ENCRYPTION OF USER TABLE (EXAMPLE)
OPEN SYMMETRIC KEY SLOCDB_SymKey
   DECRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;

Select EncryptByKey(Key_GUID('SLOCDB_SymKey'),'Pemberton') as TEMP

--VIEW DATA (THIS WILL DECRYPT THE ENCRYPTED COLUMNS)	
	Select
		USER_ID
		,CONVERT(varchar(25),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, SEC_QID_1)) as 'SEC_QID_1'
		,CONVERT(varchar(25),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, SEC_QID_2)) as 'SEC_QID_2'
		,CONVERT(varchar(25),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, SEC_QID_3)) as 'SEC_QID_3'
		,CONVERT(varchar(25),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_PWD)) as 'USER_PWD'
		,CONVERT(varchar(25),DECRYPTBYKEYAUTOASYMKEY(ASYMKEY_ID('SLOCDB_AsymKey'), NULL, USER_EMAIL)) as 'USER_EMAIL'
		,USER_LST_LOGIN_TS
		,USER_LOGIN_FAIL_DT
		,USER_LOGIN_FAIL_CNT
		,USER_ACCT_LCK
		,REC_CRTE_TS
		,REC_CRTE_USER_ID
		,LST_UPDT_TS
		,LST_UPDT_USER_ID
	FROM 
		dbo.USERS WITH (NOLOCK)
	

	Select * from dbo.USERS WITH (NOLOCK)

CLOSE SYMMETRIC KEY SLOCDB_SymKey
*/

/*
SEC_QUEST_ID	SEC_QUEST_TXT
1	What is your mother`s maiden name?
2	What is the name of the highschool you graduated from?
3	What is your favorite pet`s name?
*/


--Negative Test for BookKeeping Record Updates (REC_CRTE_* and LST_UPDT_* - THese should not trigger an updated at all in the trigger)

--NEGATIVE TEST CASE (SHOULD NOT IMPACT TRIGGER OR CAUSE TRIGGER TO DO ANYTHING)
UPDATE dbo.USER_INFO SET LST_UPDT_USER_ID = 'dboa', REC_CRTE_USER_ID = 'dboa'  WHERE USER_ID = 'TBAZ74'
UPDATE dbo.USER_INFO SET LST_UPDT_TS = GetDate(), REC_CRTE_TS = GetDate()  WHERE USER_ID = 'TBAZ74'

--TRUNCATE TABLES FOR DEVICES
TRUNCATE TABLE dbo.AUDIT_ACTIVITY
TRUNCATE TABLE dbo.LAYOUTS
TRUNCATE TABLE dbo.DEVICES
TRUNCATE TABLE dbo.DEVICE_PORT_CONFIG
TRUNCATE TABLE dbo.DEVICE_PORTS
TRUNCATE TABLE dbo.DEVICE_PORT_ATTR
TRUNCATE TABLE dbo.DEVICE_EXT_ATTR
 DECLARE @SL_JSON nvarchar(max) = N'[
	{"PRT_TYP_ID":5, "PRT_DIR_CD":"I", "PRT_CNT":16, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null}, 
	{"PRT_TYP_ID":4, "PRT_DIR_CD":"O", "PRT_CNT":19, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":4, "PRT_DIR_CD":"I", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":1, "PRT_DIR_CD":"O", "PRT_CNT":2, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":1, "PRT_DIR_CD":"I", "PRT_CNT":4, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":9, "PRT_DIR_CD":"I", "PRT_CNT":2, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":6, "PRT_DIR_CD":"O", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":7, "PRT_DIR_CD":"B", "PRT_CNT":3, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null}
]'
--	{"PRT_TYP_ID":6, "PRT_DIR_CD":"O", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
exec dbo.csp_UPDATE_Device 1, 1, 'PreSonus StudioLive 64s',null,'PreSonus','StudioLive 64s','SL1008091-102-64S','2.31','1.1.3','TommyBoyAZ', @PRT_JSON = @SL_JSON
exec dbo.csp_ADD_Device 1, 'PreSonus StudioLive @64s',null,'Pre?Sonus','Studio:Live; 64s','SL1008091-102-64S*','^2.31','$1.0.1#',1,'TommyBoyAZ', @PRT_JSON = @SL_JSON
--exec dbo.csp_ADD_Device 1, 'PreSonus StudioLive @32s',null,'Pre?Sonus','Studio:Live; 32s','SL1008061-101-32S*','^1.81','$2.1.1#',1,'TommyBoyAZ', @PRT_JSON = @SL_JSON
Go
exec csp_ADD_Layout 'Config 1 for 64s',1,'Test Notes 2','AdminTom'
exec csp_ADD_Layout 'Config 2 for 64s',1,'Test Notes 2','AdminTom'

DECLARE @KRNX_JSON nvarchar(max) = N'[
	{"PRT_TYP_ID":1, "PRT_DIR_CD":"O", "PRT_CNT":6, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":1, "PRT_DIR_CD":"I", "PRT_CNT":5, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":10, "PRT_DIR_CD":"I", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":10, "PRT_DIR_CD":"O", "PRT_CNT":2, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":3, "PRT_DIR_CD":"O", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":8, "PRT_DIR_CD":"I", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":8, "PRT_DIR_CD":"O", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"PRT_TYP_ID":7, "PRT_DIR_CD":"B", "PRT_CNT":3, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null}
]'
exec dbo.csp_ADD_Device 3, 'Korg Kronos X 88',null,'Korg','Kronos X 88','K1354150*','^3.01','$1.0.1#',1,'TommyBoyAZ', @PRT_JSON = @KRNX_JSON
Go

--LINK TWO DEVICES BY PORT
--exec dbo.csp_LINK_PortToDevice 4,5,'I','PRTDEVID',2,'AdminTom'

  /*
  5 = Combo Port Type
  1 = 1/4 Port Type
  3 = Headphones
  4 = XLR 
  6 = AES
  7 = USB
  8 = SPDIF
  9 = RCA
  10 = MIDI
  */



--exec dbo.csp_ADD_Device 1, 'Zoom LiveTrak 12',null,'Zoom','LiveTrak L-12','SL1008091-102-64S*','^2.61','$1.0.1#',1,'TommyBoyAZ', @PRT_JSON = @JSON
exec dbo.csp_UPDATE_Device 1, 1, 'PreSonus StudioLive 64s',null,'PreSonus','StudioLive 64s','SL1008091-102-64S','2.31','1.1.3','TommyBoyAZ', @PRT_JSON = @JSON

exec dbo.csp_DEL_Device 1, 1 ,'TommyBoyAZ'
exec dbo.csp_UnDEL_Device 1 ,'TommyBoyAZ'
exec dbo.csp_DEL_Device 1, 0 ,'TommyBoyAZ'

exec dbo.csp_ADD_Layout @LO_NAME = 'SL 64s', @LO_DEV_ID = 1, @LO_NOTES = 'Layout for Studio Live 64s', @USR='TommyBoyAZ'

EXEC dbo.csp_UPDATE_Device_Port_Attr 1,1,1,'O','PRTDEVID',0,'TommyBoyAZ'
EXEC dbo.csp_UPDATE_Device_Port_Attr 1,1,1,'I','PRTDEVID',0,'TommyBoyAZ'
EXEC dbo.csp_UPDATE_Device_Port_Attr_ByAttrID 42, 'F','TommyBoyAZ'
EXEC dbo.csp_ADD_Device_EXT_Attr 1,1,'DEVPHONE','6232153602','TommyBoyAZ'
EXEC dbo.csp_UPDATE_Device_EXT_Attr 1,1,'DEVPHONE','4802629115','TommyBoyAZ'


exec dbo.csp_DEL_Layout 7, 1 ,'TommyBoyAZ'
exec dbo.csp_UnDEL_Layout 7, 'TommyBoyAZ'
exec dbo.csp_DEL_Layout 7, 0 ,'TommyBoyAZ'




INSERT INTO dbo.DEVICE_PORT_ATTR (DEV_ID, LO_ID, PRT_TYP_ID, PRT_DIR_CD, ATTR_KEY_CD, ATTR_VALUE)
Select 1,1,1,'I','PRT_CHAN','1'
 
UPDATE dbo.DEVICE_PORT_ATTR SET ATTR_VALUE = 2 WHERE ATTR_KEY_CD='PRT_CHAN' AND DEV_ID=1 AND PRT_TYP_ID=1

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [ACT_ID]
      ,[ACT_TYP_ID]
      ,[ACT_DESC]
      ,[REC_CRTE_TS]
      ,[REC_CRTE_USER_ID]
  FROM [SLOC_DB].[dbo].[AUDIT_ACTIVITY]




----Parse JSON Data
--  DECLARE @json NVarChar(max)='{
--    "LoginName" : "SystemLogin",
--    "Authenticationtype" : "Windows",
--    "Roles":[ "bulkadmin", "setupadmin", "diskadmin" ]}'
 
--select *from OPENJSON(@json)


----Read Array in JSON Data
--  DECLARE @json NVarChar(max)='{
--    "LoginName" : "SystemLogin",
--    "Authenticationtype" : "Windows",
--    "Roles":[ "bulkadmin", "setupadmin", "diskadmin" ]}'
 
--select *from OPENJSON(@json, 'strict $.Roles')
--WITH( 
--Roles VARCHAR(20) '$' )


/*--THIS EXAMPLE WORKS
DECLARE @JSON1 nvarchar(max) = N'[
	{"ATTR_TYP": "P", "PRT_TYP_ID":1, "PRT_DIR_CD":"I", "PRT_CNT":4, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"ATTR_TYP": "P", "PRT_TYP_ID":1, "PRT_DIR_CD":"O", "PRT_CNT":4, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"ATTR_TYP": "P", "PRT_TYP_ID":10, "PRT_DIR_CD":"I", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"ATTR_TYP": "P", "PRT_TYP_ID":10, "PRT_DIR_CD":"O", "PRT_CNT":2, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null},
	{"ATTR_TYP": "P", "PRT_TYP_ID":4, "PRT_DIR_CD":"I", "PRT_CNT":1, "PRT_CHAN": null, "PRT_DESC": null, "PRT_GNDR": "F", "PRT_NAME": null}
]'

SELECT * FROM OPENJSON(@JSON1)
	WITH ( 
		ATTR_TYP CHAR(1) 'strict $.ATTR_TYP',
		PRT_TYP_ID tinyint 'strict $.PRT_TYP_ID',
		PRT_DIR_CD CHAR(1) 'strict $.PRT_DIR_CD',
		PRT_CNT tinyint 'strict $.PRT_CNT',
		PRT_CHAN varchar(255) 'strict $.PRT_CHAN',
		PRT_DESC varchar(255) 'strict $.PRT_DESC',
		PRT_GNDR varchar(255) 'strict $.PRT_GNDR',
		PRT_NAME varchar(255) 'strict $.PRT_NAME')
*/
