/**
--CLASS: MS587
--NAME: Thomas Wallace
--PROJECT: FINAL PROJECT
--DESC: 
--		This is the SQL for Creating the table structure for my final project this is one of many SQL files
--=========================================================================================================
--	Change Date -INIT- Description of Change
--=========================================================================================================
--	09/29/2020 - TCW - CREATED INITIAL SQL LAYOUT
--	10/04/2020 - TCW - CREATED TRIGGER FOR POPULATING AUDIT_ACTIVITY TABLE
--
*/


--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_USER_INFO_INSERT 
ON dbo.USER_INFO
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC)
	Select
		dbo.fnc_GetActivityID('AUTH_NEW') as ACT_TYP_ID
		,(
			'<<USER INSERTED>>  -  [USER_ID] - ( ''' + ISNULL(i.[USER_ID],'-null-') + ''' )       ' +
			'[NAME] - ( ' + isnull(i.USER_LNAME,'-null-') + ', ' + ISNULL(i.USER_FNAME,'-null-') + ' )'
		)  as ACT_DESC
	from 
		inserted i
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_USER_INFO_UPDATE
ON dbo.USER_INFO
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THIS SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	IF UPDATE(USER_ID) OR UPDATE(SEC_QID_1) OR UPDATE(SEC_QID_2) OR UPDATE(SEC_QID_3) OR UPDATE(USER_FNAME) OR UPDATE(USER_LNAME) OR UPDATE(USER_PHONE) OR UPDATE(USER_ACT_VRFY) OR UPDATE(USER_VRFY_PREF_CD)
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('AUTH_UPD') as ACT_TYP_ID,
				--RTRIM('<<USER UPDATED>>  -  ' + 
				RTRIM('<<USER UPDATED>>  -  [USER_ID] - ( ''' + ISNULL(i.[USER_ID],'-null-') + ''' )       ' +
				'[NAME] - ( ' + isnull(i.USER_LNAME,'-null-') + ', ' + ISNULL(i.USER_FNAME,'-null-') + ' ), ' +
				CASE when I.[USER_ID] <> D.[USER_ID] THEN '[USER_ID] - ( ''' + D.USER_ID + ''' -> ''' + I.USER_ID + ''' ), ' ELSE '' END +
				CASE when I.SEC_QID_1 <> D.SEC_QID_1 THEN '[SEC_QID_1] - ( ''' + CAST(D.SEC_QID_1 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_1 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.SEC_QID_2 <> D.SEC_QID_2 THEN '[SEC_QID_2] - ( ''' + CAST(D.SEC_QID_2 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_2 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.SEC_QID_3 <> D.SEC_QID_3 THEN '[SEC_QID_3] - ( ''' + CAST(D.SEC_QID_3 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_3 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.USER_FNAME <> D.USER_FNAME THEN '[USER_FNAME] - ( ''' + D.USER_FNAME + ''' -> ''' + I.USER_FNAME + ''' ), ' ELSE '' END + 
				CASE when I.USER_LNAME <> D.USER_LNAME THEN '[USER_LNAME] - ( ''' + D.USER_LNAME + ''' -> ''' + I.USER_LNAME + ''' ), ' ELSE '' END + 
				CASE when I.USER_PHONE <> D.USER_PHONE THEN '[USER_PHONE] - ( ''' + D.USER_PHONE + ''' -> ''' + I.USER_PHONE + ''' ), ' ELSE '' END + 
				CASE when I.USER_ACT_VRFY <> D.USER_ACT_VRFY THEN '[USER_ACT_VRFY] - ( ' + CASE WHEN I.USER_ACT_VRFY = 1 THEN 'Account Verified' ELSE 'Account NOT Verified' END + ' ), ' ELSE '' END + 
				CASE when I.USER_VRFY_PREF_CD <> D.USER_VRFY_PREF_CD THEN '[USER_VRFY_PREF_CD] - ( ''' + D.USER_VRFY_PREF_CD + ''' -> ''' + I.USER_VRFY_PREF_CD + ''' ), ' ELSE '' END
				) as ACT_DESC,
				I.LST_UPDT_USER_ID
			FROM
				INSERTED I,
				DELETED D
		) DRV
	END
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_USER_INFO_DELETE
ON dbo.USER_INFO
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC)
	Select
		dbo.fnc_GetActivityID('AUTH_DEL') as ACT_TYP_ID,
		'<<USER DELETED>>  -  [USER_ID] - (''' + D.USER_ID + ''')        [NAME] - (' + D.USER_LNAME + ', ' + D.USER_FNAME + ')' as ACT_DESC
	FROM
		DELETED D
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_USERS_UPDATE
ON dbo.USERS
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THIS SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	IF UPDATE(USER_PWD) OR UPDATE(USER_EMAIL) OR UPDATE(SEC_QID_1) OR UPDATE(SEC_QID_2) OR UPDATE(SEC_QID_3) OR UPDATE(USER_LST_LOGIN_TS)
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('AUTH_UPD') as ACT_TYP_ID,
				RTRIM('<<USER UPDATED>>  -  ' + 
				CASE when I.[USER_PWD] <> D.[USER_PWD] THEN '[USER_ID] - ( Password Changed ), ' ELSE '' END +
				CASE when I.USER_EMAIL <> D.USER_EMAIL THEN '[USER_EMAIL] - ( ''' + D.USER_EMAIL + ''' -> ''' + I.USER_EMAIL + ''' ), ' ELSE '' END + 
				CASE when I.SEC_QID_1 <> D.SEC_QID_1 THEN '[SEC_QID_1] - ( ''' + CAST(D.SEC_QID_1 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_1 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.SEC_QID_2 <> D.SEC_QID_2 THEN '[SEC_QID_2] - ( ''' + CAST(D.SEC_QID_2 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_2 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.SEC_QID_3 <> D.SEC_QID_3 THEN '[SEC_QID_3] - ( ''' + CAST(D.SEC_QID_3 as varchar(3)) + ''' -> ''' + CAST(I.SEC_QID_3 as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.USER_LST_LOGIN_TS <> D.USER_LST_LOGIN_TS THEN '[USER_LST_LOGIN_TS] - ( ''' + I.USER_LST_LOGIN_TS + ''' ), ' ELSE '' END
				) as ACT_DESC,
				D.USER_ID
			FROM
				INSERTED I, 
				DELETED D
			
		) DRV
	END
END
Go

--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_LAYOUTS_INSERT 
ON dbo.LAYOUTS
AFTER INSERT
AS
BEGIN
	INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
	Select
		dbo.fnc_GetActivityID('DEVICE_ADD') as ACT_TYP_ID
		,(
			'<<LAYOUT INSERTED>>  -  [LO_ID] - ( ''' + CAST(i.[LO_ID] as varchar(60)) + ''' )       ' +
			'[LAYOUT_NAME] - ( ' + i.[LO_NAME] + ' )'
		)  as ACT_DESC,
		i.[REC_CRTE_USER_ID]
	from 
		inserted i
END
Go

--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICES_INSERT 
ON dbo.DEVICES
AFTER INSERT
AS
BEGIN
	INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
	Select
		dbo.fnc_GetActivityID('DEVICE_ADD') as ACT_TYP_ID
		,(
			'<<DEVICE INSERTED>>  -  [DEV_ID] - ( ''' + CAST(i.[DEV_ID] as varchar(60)) + ''' )       ' +
			'[DEV_NAME] - ( ' + i.[DEV_NAME] + ' )'
		)  as ACT_DESC,
		i.[REC_CRTE_USER_ID]
	from 
		inserted i
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICES_UPDATE
ON dbo.DEVICES
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THIS SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	IF UPDATE(DEV_SFT_DEL) BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			dbo.fnc_GetActivityID('DEVICE_DEL') as ACT_TYP_ID,
			'<<DEVICE SOFT DELETED>>  -  [DEV_ID] - (''' + CAST(I.DEV_ID as varchar(10)) + ''')        [DEV_NAME] - (' + I.DEV_NAME + ')' as ACT_DESC,
			I.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
			INSERTED I
	
	END
	ELSE IF UPDATE(DEV_TYP_ID) OR UPDATE(DEV_NAME) OR UPDATE(DEV_MFG) OR UPDATE(DEV_MODEL) OR UPDATE(DEV_SERIAL) OR UPDATE(DEV_FW) OR UPDATE(DEV_OS) OR UPDATE(DEV_IMG)
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('DEVICE_UPD') as ACT_TYP_ID,
				RTRIM('<<DEVICE UPDATED>>  -  [DEV_ID] - ( ''' + CAST(i.[DEV_ID] as varchar(60)) + ''' ), ' +
				CASE when I.DEV_TYP_ID <> D.DEV_TYP_ID THEN '[DEV_TYP_ID] - ( ''' + CAST(D.DEV_TYP_ID as varchar(10)) + ''' -> ''' + CAST(I.DEV_TYP_ID as varchar(10)) + ''' ), ' ELSE '' END +
				CASE when I.DEV_NAME <> D.DEV_NAME THEN '[DEV_NAME] - ( ''' + D.DEV_NAME + ''' -> ''' + I.DEV_NAME + ''' ), ' ELSE '' END + 
				CASE when I.DEV_MFG <> D.DEV_MFG THEN '[DEV_MFG] - ( ''' + CAST(D.DEV_MFG as varchar(3)) + ''' -> ''' + CAST(I.DEV_MFG as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.DEV_MODEL <> D.DEV_MODEL THEN '[DEV_MODEL] - ( ''' + CAST(D.DEV_MODEL as varchar(3)) + ''' -> ''' + CAST(I.DEV_MODEL as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.DEV_SERIAL <> D.DEV_SERIAL THEN '[DEV_SERIAL] - ( ''' + CAST(D.DEV_SERIAL as varchar(3)) + ''' -> ''' + CAST(I.DEV_SERIAL as varchar(30)) + ''' ), ' ELSE '' END + 
				CASE when I.DEV_FW <> D.DEV_FW THEN '[DEV_FW] - ( ''' + D.DEV_FW + ''' -> ''' + I.DEV_FW + ''' ), ' ELSE '' END + 
				CASE when I.DEV_OS <> D.DEV_OS THEN '[DEV_OS] - ( ''' + D.DEV_OS + ''' -> ''' + I.DEV_OS + ''' ), ' ELSE '' END +
				CASE when I.DEV_IMG <> D.DEV_IMG THEN '[DEV_IMG] - ( Image Updated! ), ' ELSE '' END 
				) as ACT_DESC,
				I.LST_UPDT_USER_ID
			FROM
				INSERTED I INNER JOIN DELETED D 
				ON D.DEV_ID = I.DEV_ID
			WHERE
				(D.DEV_TYP_ID <> I.DEV_TYP_ID
				OR D.DEV_NAME <> I.DEV_NAME
				OR D.DEV_MFG <> I.DEV_MFG
				OR D.DEV_MODEL <> I.DEV_MODEL
				OR D.DEV_SERIAL <> I.DEV_SERIAL
				OR D.DEV_FW <> I.DEV_FW
				OR D.DEV_OS <> I.DEV_OS
				OR D.DEV_IMG <> I.DEV_IMG)
		) DRV
	END
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICES_DELETE
ON dbo.DEVICES
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
	Select
		dbo.fnc_GetActivityID('DEVICE_DEL') as ACT_TYP_ID,
		'<<DEVICE DELETED>>  -  [DEV_ID] - (''' + CAST(D.DEV_ID as varchar(10)) + ''')        [DEV_NAME] - (' + D.DEV_NAME + ')' as ACT_DESC,
		d.LST_UPDT_USER_ID as REC_CRTE_USER_ID
	FROM
		DELETED D
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICE_PORTS_UPDATE
ON dbo.DEVICE_PORTS
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THESE SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	--IF NOT UPDATE(LST_UPDT_TS) AND NOT UPDATE(LST_UPDT_USER_ID) 
	IF UPDATE(PRT_CNT) 
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('DEVICE_UPD') as ACT_TYP_ID,
				RTRIM('<<DEVICE PORT UPDATED>>  -  [DEV_ID] - ( ''' + CAST(i.[DEV_ID] as varchar(60)) + ''' ), ' +
				CASE when I.PRT_CNT <> D.PRT_CNT THEN '[PRT_CNT] - ( ''' + CAST(D.PRT_CNT as varchar(10)) + ''' -> ''' + CAST(I.PRT_CNT as varchar(10)) + ''' ), ' ELSE '' END 
				) as ACT_DESC,
				I.LST_UPDT_USER_ID
			FROM
				INSERTED I INNER JOIN DELETED D
				ON D.PRT_DIR_CD = I.PRT_DIR_CD AND D.PRT_TYP_ID = I.PRT_TYP_ID AND D.DEV_ID = I.DEV_ID

		) DRV
	END
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICE_PORT_ATTR_UPDATE
ON dbo.DEVICE_PORT_ATTR
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THIS SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	IF UPDATE(ATTR_VALUE)
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('DEVICE_UPD') as ACT_TYP_ID,
				RTRIM('<<DEVICE PORT ATTR UPDATED>>  -  [DEV_ID] - ( ''' + CAST(i.[DEV_ID] as varchar(60)) + ''' ), ' +
				CASE when I.ATTR_VALUE <> D.ATTR_VALUE THEN '[ATTR_KEY_CD : ' + I.ATTR_KEY_CD + ' ] - ( ''' + CAST(D.ATTR_VALUE as varchar(10)) + ''' -> ''' + CAST(I.ATTR_VALUE as varchar(10)) + ''' ), ' ELSE '' END 
				) as ACT_DESC,
				I.LST_UPDT_USER_ID
			FROM
				INSERTED I INNER JOIN DELETED D
				ON I.ATTR_ID = D.ATTR_ID
			WHERE
				I.ATTR_VALUE <> D.ATTR_VALUE 
		) DRV
	END
END
Go


--CREATE TRIGGER (OR ALTER was added in SQL Server 2016, Wont work below 2016) 
CREATE OR ALTER TRIGGER TR_DEVICE_EXT_ATTR_UPDATE
ON dbo.DEVICE_EXT_ATTR
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON

	--DONT CARE ABOUT THE 4 FIELDS FOR THE TIMESTAMP RECORDS - THIS SHOULDN'T TRIGGER AN AUDIT RECORD (IGNORED)
	IF UPDATE(ATTR_VALUE)
	BEGIN
		--BUILDS DETAILED LIST OF WHAT CHANGED FOR THE AUDIT RECORD
		INSERT INTO dbo.AUDIT_ACTIVITY (ACT_TYP_ID, ACT_DESC, REC_CRTE_USER_ID)
		Select
			DRV.ACT_TYP_ID
			,SUBSTRING(DRV.ACT_DESC,1,LEN(DRV.ACT_DESC)-1) AS ACT_DESC
			,DRV.LST_UPDT_USER_ID as REC_CRTE_USER_ID
		FROM
		(
			Select 
				dbo.fnc_GetActivityID('DEVICE_UPD') as ACT_TYP_ID,
				RTRIM('<<DEVICE EXT ATTR UPDATED>>  -  [DEV_ID] - ( ''' + CAST(i.[DEV_ID] as varchar(60)) + ''' ), ' +
				CASE when I.ATTR_VALUE <> D.ATTR_VALUE THEN '[ATTR_KEY_CD : ' + I.ATTR_KEY_CD + ' ] - ( ''' + CAST(D.ATTR_VALUE as varchar(10)) + ''' -> ''' + CAST(I.ATTR_VALUE as varchar(10)) + ''' ), ' ELSE '' END 
				) as ACT_DESC,
				I.LST_UPDT_USER_ID
			FROM
				INSERTED I INNER JOIN DELETED D
				ON I.DEV_ID = D.DEV_ID
				AND I.LO_ID = D.LO_ID
				AND I.ATTR_KEY_CD = D.ATTR_KEY_CD
			WHERE 
				I.ATTR_VALUE <> D.ATTR_VALUE
		) DRV
	END
END
Go