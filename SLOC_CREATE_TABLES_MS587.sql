/**
--CLASS: MS587
--NAME: Thomas Wallace
--PROJECT: FINAL PROJECT
--DESC: 
--		This is the SQL for Creating the table structure for my final project this is one of many SQL files
--=========================================================================================================
--	Change Date -INIT- Description of Change
--=========================================================================================================
--	09/27/2020 - TCW - CREATED INITIAL SQL LAYOUT
--	09/28/2020 - TCW - REMOVED A TABLE FROM LAYOUT: LAYOUT_ACTIVITY
--  09/30/2020 - TCW - REMOVED PAR_LO_ID AND CHD_LO_ID FROM LAYOUTS TABLE
--  10/03/2020 - TCW - CREATED A NEW TABLE FOR LAYOUT AND DEVICE LINKING LAYOUT_DEVICE_LNK
--  10/09/2020 - TCW - UPDATED USERS AND USER_INFO TABLE TO MOVE AROUND SOME FIELDS (FOR ENCRYPTION FEATURE)
--  10/10/2020 - TCW - CREATED A NEW TABLE FOR APP_DEFAULTS 
--  10/16/2020 - TCW - CREATED A NEW TABLE FOR USERS_MASTERS (UNENCRYPTED DATA)
--  10/17/2020 - TCW - MODIFIED TABLE FOR USER... INCREASED USER_ID to MATCH HOUSEKEEPING USER_ID (varchar(60))
--
*/

--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[SECURITY_QUESTIONS]

--CREATE TABLE FOR SECURITY_QUESTIONS (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.SECURITY_QUESTIONS (
	SEC_QUEST_ID tinyint identity(1,1) not null,
	SEC_QUEST_TXT varchar(255) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_SECURITY_QUESTIONS] PRIMARY KEY CLUSTERED 
	(
		[SEC_QUEST_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[USERS_MASTER]

--CREATE TABLE FOR USERS_MASTER (HAS DEFAULTS AND KEY, UNENCRYPTED DATA)
CREATE TABLE dbo.USERS_MASTER (

	[USER_ID] varchar(60) not null,
	[SEC_QID_1] varchar(100) not null,
	[SEC_QID_2] varchar(100) not null,
	[SEC_QID_3] varchar(100) not null,
	[USER_PWD] varchar(40) not null,
	[USER_EMAIL] varchar(60) not null,
	[USER_LST_LOGIN_TS] datetime null,
	[USER_LOGIN_FAIL_DT] datetime null,
	[USER_LOGIN_FAIL_CNT] tinyint null,
	[USER_ACCT_LCK] bit default(0) not null,
	[REC_CRTE_TS] datetime default(getDate()) not null,
	[REC_CRTE_USER_ID] varchar(60) default(user_name()) not null,
	[LST_UPDT_TS] datetime default(getDate()) not null,
	[LST_UPDT_USER_ID] varchar(60) default(user_name()) not null
	CONSTRAINT [PK_USERS_MASTER] PRIMARY KEY CLUSTERED 
	(
		[USER_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[USERS]

--CREATE TABLE FOR USERS (HAS DEFAULTS AND KEY, ENCRYPTED DATA)
CREATE TABLE dbo.USERS (
	[USER_ID] varchar(60) not null,
	
	-- IF NOT USING ENCRYPTION THEN UNCOMMENT THE BELOW 5 LINES
	--[SEC_QID_1] varbinary(100) not null,
	--[SEC_QID_2] varbinary(100) not null,
	--[SEC_QID_3] varbinary(100) not null,
	--[USER_PWD] varbinary(40) not null,
	--[USER_EMAIL] varbinary(60) not null,

	-- IF USING ENCRYPTION THEN UNCOMMENT THE BELOW 5 LINES
	[SEC_QID_1] varbinary(128) not null,
	[SEC_QID_2] varbinary(128) not null,
	[SEC_QID_3] varbinary(128) not null,
	[USER_PWD] varbinary(128) not null,
	[USER_EMAIL] varbinary(128) not null,
	[USER_LST_LOGIN_TS] datetime  null,
	[USER_LOGIN_FAIL_DT] datetime null,
	[USER_LOGIN_FAIL_CNT] tinyint null,
	[USER_ACCT_LCK] bit default(0) not null,
	[REC_CRTE_TS] datetime default(getDate()) not null,
	[REC_CRTE_USER_ID] varchar(60) default(user_name()) not null,
	[LST_UPDT_TS] datetime default(getDate()) not null,
	[LST_UPDT_USER_ID] varchar(60) default(user_name()) not null
	CONSTRAINT [PK_USERS] PRIMARY KEY CLUSTERED 
	(
		[USER_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[USER_INFO]

--CREATE TABLE FOR USER_INFO (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.USER_INFO (
	[USER_ID] varchar(60) not null,
	[SEC_QID_1] tinyint not null,
	[SEC_QID_2] tinyint not null,
	[SEC_QID_3] tinyint not null,
	[USER_FNAME] varchar(30) not null,
	[USER_LNAME] varchar(30) not null,
	[USER_PHONE] varchar(10) not null,
	[USER_ACT_VRFY] bit default(0) not null,
	[USER_VRFY_PREF_CD] CHAR(1) not null,
	[REC_CRTE_TS] datetime default(getDate()) not null,
	[REC_CRTE_USER_ID] varchar(60) default(user_name()) not null,
	[LST_UPDT_TS] datetime default(getDate()) not null,
	[LST_UPDT_USER_ID] varchar(60) default(user_name()) not null
	CONSTRAINT [PK_USER_INFO] PRIMARY KEY CLUSTERED 
	(
		[USER_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[ACTIVITY_TYPES]

--CREATE TABLE FOR ACTIVITY_TYPES (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.ACTIVITY_TYPES (
	ACT_TYP_ID smallint identity(1,1) not null,
	ACT_TYP_NM varchar(50) not null,
	ACT_TYP_DESC varchar(200) not null,
	[REC_CRTE_TS] datetime default(getDate()) not null,
	[REC_CRTE_USER_ID] varchar(60) default(user_name()) not null,
	[LST_UPDT_TS] datetime default(getDate()) not null,
	[LST_UPDT_USER_ID] varchar(60) default(user_name()) not null
	CONSTRAINT [PK_ACTIVITY_TYPES] PRIMARY KEY CLUSTERED 
	(
		[ACT_TYP_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[AUDIT_ACTIVITY]

--CREATE TABLE FOR AUDIT_ACTIVITY (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.AUDIT_ACTIVITY (
	ACT_ID numeric(18,0) identity(1,1) not null,
	ACT_DEV_ID int null,
	ACT_TYP_ID smallint not null,
	ACT_DESC varchar(1500) not null,
	[REC_CRTE_TS] datetime default(getDate()) not null,
	[REC_CRTE_USER_ID] varchar(60) default(user_name()) not null,
	CONSTRAINT [PK_AUDIT_ACTIVITY] PRIMARY KEY CLUSTERED 
	(
		[ACT_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[COMMON_TYPE_CODES]

--CREATE TABLE FOR COMMON_TYPE_CODES (HAS DEFAULTS AND KEY)
CREATE TABLE [dbo].[COMMON_TYPE_CODES](
	COMM_TYPE_CD char(8) NOT NULL,
	COMM_TYPE_DESC varchar(255) NOT NULL,
	REC_CRTE_TS datetime default(getdate()) NOT NULL,
	REC_CRTE_USER_ID varchar(60) default(user_name()) NOT NULL,
	LST_UPDT_TS datetime default(getdate()) NOT NULL,
	LST_UPDT_USER_ID varchar(60) default(user_name()) NOT NULL,
	 CONSTRAINT [PK_COMMON_TYPE_CODES] PRIMARY KEY CLUSTERED 
	(
		[COMM_TYPE_CD] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[COMMON_CODES]

--CREATE TABLE FOR COMMON_CODES (HAS DEFAULTS AND KEY)
CREATE TABLE [dbo].[COMMON_CODES](
	COMM_CD char(8) NOT NULL,
	COMM_TYPE_CD char(8) NOT NULL,
	COMM_TXT varchar(100) NOT NULL,
	COMM_DESC varchar(255) NULL,
	REC_CRTE_TS datetime default(getdate()) NOT NULL,
	REC_CRTE_USER_ID varchar(60) default(user_name()) NOT NULL,
	LST_UPDT_TS datetime default(getdate()) NOT NULL,
	LST_UPDT_USER_ID varchar(60) default(user_name()) NOT NULL,
	CONSTRAINT [PK_COMMON_CODES] PRIMARY KEY CLUSTERED 
	(
		[COMM_CD] ASC,
		[COMM_TYPE_CD] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[PORT_TYPES]

--CREATE TABLE FOR PORT_TYPES (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.PORT_TYPES (
	PRT_TYP_ID tinyint identity(1,1) not null,
	PRT_TXT varchar(25) not null,
	PRT_ALT_TXT varchar(50) null,
	PRT_TYP_DESC varchar(100) not null,
	PRT_CAT_CD CHAR(8) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_PORT_TYPES] PRIMARY KEY CLUSTERED 
	(
		[PRT_TYP_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICE_TYPES]

--CREATE TABLE FOR DEVICES_TYPES (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.DEVICE_TYPES (
	DEV_TYP_ID smallint identity(1,1) not null,
	DEV_TYP_DESC varchar(100) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICE_TYPES] PRIMARY KEY CLUSTERED 
	(
		[DEV_TYP_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICES]

--CREATE TABLE FOR DEVICES (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.DEVICES (
	DEV_ID int identity(1,1) not null,
	DEV_IMG varbinary(max) null,
	DEV_TYP_ID smallint not null,
	DEV_NAME varchar(100) not null,
	DEV_MFG varchar(100) null,
	DEV_MODEL varchar(100) null,
	DEV_SERIAL varchar(100) null,
	DEV_FW varchar(30) null,
	DEV_OS varchar(30) null,
	DEV_SFT_DEL bit default(0) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICES] PRIMARY KEY CLUSTERED 
	(
		[DEV_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICE_EXT_ATTR]

--CREATE TABLE FOR DEVICES_EXT_ATTR (HAS DEFAULTS AND KEY) - PREDICATE TABLE
CREATE TABLE dbo.DEVICE_EXT_ATTR (
	DEV_ID int not null,
	LO_ID int not null,
	ATTR_KEY_CD CHAR(8) not null,
	ATTR_VALUE varchar(255) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICE_ATTR] PRIMARY KEY CLUSTERED 
	(
		[DEV_ID] ASC,
		[LO_ID] ASC,
		[ATTR_KEY_CD] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICE_PORT_CONFIG]

--CREATE TABLE FOR DEVICE_PORT_CONFIG (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.DEVICE_PORT_CONFIG (
	PRT_CFG_ID int identity(1,1) not null,
	DEV_ID int not null,
	PRT_TYP_ID tinyint not null,
	PRT_DIR_CD CHAR(1) not null, -- "I" for Inbound / "O" for Outbound / "B" Bi-Directional
	PRT_CNT tinyint not null,
	PRT_GNDR char(1) null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICE_PORT_CONFIG] PRIMARY KEY CLUSTERED 
	(
		[PRT_CFG_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICE_PORTS]

--CREATE TABLE FOR DEVICE_PORTS HAS DEFAULTS AND KEY)
CREATE TABLE dbo.DEVICE_PORTS (
	PRT_CFG_ID int not null,
	PRT_ID tinyint not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICE_PORTS] PRIMARY KEY CLUSTERED 
	(
		[PRT_CFG_ID] ASC
		,[PRT_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[DEVICE_PORT_ATTR]

--CREATE TABLE FOR DEVICE_PORT_ATTR (HAS DEFAULTS AND KEY) - PREDICATE TABLE
CREATE TABLE dbo.DEVICE_PORT_ATTR (
	PRT_CFG_ID int not null,
	PRT_ID int not null,
	LO_ID int not null,
	ATTR_KEY_CD CHAR(8) not null,
	ATTR_VALUE varchar(255) not null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_DEVICE_PORT_ATTR] PRIMARY KEY CLUSTERED 
	(
		[PRT_CFG_ID] ASC
		,[PRT_ID] ASC
		,[LO_ID] ASC
		,[ATTR_KEY_CD] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[LAYOUTS]

--CREATE TABLE FOR LAYOUTS (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.LAYOUTS (
	LO_ID int identity(1,1) not null,
	LO_NAME varchar(100) not null,
	LO_DEV_ID int not null, -- Layout must belong to some type of device
	LO_NOTES varchar(500) null, -- Notes that can be visible on the front screen
	LO_SFT_DEL bit default(0) not null, -- Used for Soft Delete
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_LAYOUTS] PRIMARY KEY CLUSTERED 
	(
		[LO_ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--IF TABLE EXISTS DROP IT SO THAT IT CAN BE RECREATED
DROP TABLE IF EXISTS [dbo].[APP_DEFAULTS]

--CREATE TABLE FOR APP_DEFAULTS (HAS DEFAULTS AND KEY)
CREATE TABLE dbo.APP_DEFAULTS (
	APP_KEY char(8) not null,
	APP_VALUE varchar(255) not null,
	APP_BIN_VALUE varbinary(max) null,
	REC_CRTE_TS datetime default(getDate()) not null,
	REC_CRTE_USER_ID varchar(60) default(user_name()) not null,
	LST_UPDT_TS datetime default(getDate()) not null,
	LST_UPDT_USER_ID varchar(60) default(user_name()) not null
	CONSTRAINT [PK_APP_DEFAULTS] PRIMARY KEY CLUSTERED 
	(
		[APP_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
