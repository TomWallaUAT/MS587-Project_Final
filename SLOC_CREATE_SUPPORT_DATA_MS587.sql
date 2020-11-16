/**
--CLASS: MS587
--NAME: Thomas Wallace
--PROJECT: FINAL PROJECT
--DESC: 
--		This is the SQL for Creating the table structure for my final project this is one of many SQL files
--=========================================================================================================
--	Change Date -INIT- Description of Change
--=========================================================================================================
--	09/28/2020 - TCW - CREATED INITIAL SQL LAYOUT
--  09/29/2020 - TCW - FINISHED 90% OF THE DATA LOADS FOR CORE LOOKUP TABLES
--	10/03/2020 - TCW - COMPLETE CORE DATA LOAD FOR NEW TABLE LAYOUT_DEVICE_LNK
--
*/

--SET DATABASE FOR APPLICATIONS TO SLOC_DB  (Studio LayOut Companion DataBase)
USE SLOC_DB
Go

--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.ACTIVITY_TYPES

INSERT INTO dbo.ACTIVITY_TYPES (ACT_TYP_NM, ACT_TYP_DESC)
VALUES 
	('DEVICE_ATTR_ERR','Error occured during device attribute entry or update.')
	,('DEVICE_ERR','Error occured during device entry or update.')
	,('DEVICE_ADD','A new Device has been added.')
	,('DEVICE_UPD','A Device has been updated.')
	,('DEVICE_DEL','A Device has been deleted.')
	,('DEVICE_PORT_ADD','A new Device Port has been added.')
	,('DEVICE_PORT_UPD','A Device Port has been updated.')
	,('DEVICE_PORT_DEL','A Device Port has been deleted.')
	,('DEVICE_ATTR_ADD','A new Device Attribute has been added.')
	,('DEVICE_ATTR_UPD','A Device Attribute has been updated.')
	,('DEVICE_ATTR_DEL','A Device Attribute has been deleted.')
	,('DEV_LNK_ERR','A Device Layout Linking Error,')
	,('PORT_ERR','Error occured during port entry or update.')
	,('PORT_ADD','A new Port has been added.')
	,('PORT_UPD','A Port has been updated.')
	,('PORT_DEL','A Port has been deleted.')
	,('PORT_ATTR_ERR','Error occured during port attribute entry or update.')
	,('PORT_ATTR_ADD','A new Port Attribute has been added.')
	,('PORT_ATTR_UPD','A Port Attribute has been updated.')
	,('PORT_ATTR_DEL','A Port Attribute has been deleted.')
	,('LAYOUT_ERR','Error occured during layout entry or update.')
	,('LAYOUT_ADD','A new Layout has been added.')
	,('LAYOUT_UPD','A Layout has been updated.')
	,('LAYOUT_DEL','A Layout has been deleted.')
	,('AUTH_SUCCESS','A Successful Authentication was encountered (Login)')
	,('AUTH_FAILURE','A Failed Authentication was encountered (Login)')
	,('USER_NEW','A new Authentication account was created (New Login)')
	,('USER_DEL','A Authentication account was Deleted')
	,('USER_UPD','A Authentication account was Updated')
	,('USER_ERR','A Error was encountered trying to add a new account.')


--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.COMMON_TYPE_CODES

INSERT INTO dbo.COMMON_TYPE_CODES (COMM_TYPE_CD, COMM_TYPE_DESC)
VALUES
	('DEV_ATTR','Common Codes for Device Attributes')
	,('PRT_ATTR','Common Codes for Device Attributes')
	,('PORT_DIR','Direction Indicator for Port, Inbound, Outbound or Bi-Directional')
	,('VRFY_PRF','Verification Preference Codes')
	,('PRT_GNDR','Port Genders')
	,('PRT_CATG','Port Category')
	,('APP_DFLT','Application Defaults')


--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.COMMON_CODES

INSERT INTO dbo.COMMON_CODES (COMM_CD, COMM_TYPE_CD, COMM_TXT, COMM_DESC)
VALUES
	('F','PRT_GNDR','Female','Female Plug Gender')
	,('M','PRT_GNDR','Male','Male Plug Gender')
	,('I','PORT_DIR','Input','Communication type Inbound Direction')
	,('O','PORT_DIR','Output','Communication type Outbound Direction')
	,('B','PORT_DIR','Bi-Directional','Communication type Bi-Directional Direction')
	,('P','VRFY_PRF','Phone','Verification Preference Phone/Text')
	,('E','VRFY_PRF','Email','Verification Preference Email')
	,('S','VRFY_PRF','Security Questions','Verification Preference Security Question')
	,('N','VRFY_PRF','Not Set','Verification Preference Not Set')
	,('DEVOWNER','DEV_ATTR','Owner Name','Attribute Key for Owner name')
	,('DEVPHONE','DEV_ATTR','Owner Phone','Attribute Key for Owner Phone number')
	,('DEVEMAIL','DEV_ATTR','Owner Email','Attribute Key for Owner Email')
	,('DEVPRICE','DEV_ATTR','Purchase Price','Attribute Key for Purchase Price')
	,('DEV_RETL','DEV_ATTR','Retailer Location','Attribute Key for Retail Purchase Location')
	,('DEVPURDT','DEV_ATTR','Purchase Date','Attribute Key for Retail Purchase Date')
	,('DEVINSUR','DEV_ATTR','Policy Number','Attribute Key for Insurance Policy Number')
	,('PRT_NAME','PRT_ATTR','Port Name','Attribute Key for Port Name')
	,('PRT_CHAN','PRT_ATTR','Channel #','Attribute Key for Port Channel')
	,('PRT_DESC','PRT_ATTR','Description','Attribute Key for Port Desc')
	,('LOD_ASSN','PRT_ATTR','Layout Device','Attribute Key for states which layout device this port is assigned to')
	,('PRT_ASSN','PRT_ATTR','Port Config Key','Assignment key for PRT_CFG_ID and PRT_ID')
	,('PRT_AUDI','PRT_CATG','Port Type Audio','Category to indicate Port is used for audio')
	,('PRT_PEDL','PRT_CATG','Port Type Pedal','Category to indicate Port is used for a Pedal')
	,('PRT_CTRL','PRT_CATG','Port Type Controller','Category to indicate Port is used for a Controller')
	,('PRT_SYNC','PRT_CATG','Port Type Sync','Category to indicate Port is used for a Clock Sync')
	,('PRT_UDEV','PRT_CATG','Port Type USB Device','Category to indicate Port is used for a USB Device Extention')
	,('PRT_UCMP','PRT_CATG','Port Type Computer','Category to indicate Port is used for a USB to Computer')
	,('PRT_EXPN','PRT_CATG','Port Type Expansion','Category to indicate Port is used as an Expansion port')
	,('PRT_MASS','PRT_CATG','Port Type Mass stroage','Category to indicate Port is used Mass Storage Device (SD/USB)')
	,('NO_IMAGE','APP_DFLT','Default Image','Application Default for NO IMAGE image')
	,('PG_TITLE','APP_DFLT','Default Title','Application Default for Document TITLE')
	,('SFTDELVL','APP_DFLT','Soft Delete Days','Application Default for how many days to keep soft deletes before purging')
	,('PRT_CHAN','APP_DFLT','Default Value','Default value used for setting Port Channel attribute')
	,('PRT_NAME','APP_DFLT','Default Value','Default value used for setting Port NAME attribute')
	,('PRT_DESC','APP_DFLT','Default Value','Default value used for setting Port Descriptino Attribute')
	,('PRT_GNDR','APP_DFLT','Default Value','Default value used for setting Port plug gender in Attributes')
	,('PRTDEVID','APP_DFLT','Default Value','Default value used for new ports attributes (0) where device is not assigned')
	,('MAX_FAIL','APP_DFLT','Default Value','Default value used for new Maximum Failed login attempts before Account is locked')
	,('WAITTIME','APP_DFLT','Default Value','Default value used for Wait time between locked and failed logins')
	,('DEBUGSQL','APP_DFLT','Default Value','Default value used for Turrning On/Off SQL Proc Debug Msgs')
	,('DEBUGWEB','APP_DFLT','Default Value','Default value used for Turrning On/Off WEB Proc Debug Msgs')


--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.DEVICE_TYPES

INSERT INTO dbo.DEVICE_TYPES (DEV_TYP_DESC)
VALUES
	('Mixer Board')
	,('Keyboard (Synth)')
	,('Keyboard (Workstation)')
	,('Controller (Keyboard)')
	,('Controller (Drums)')
	,('Controller (Pad)')
	,('Rack Unit (Audio)')
	,('Rack Unit (Expansion)')
	,('Rack Unit (Sound Module)')
	,('Monitor (Speaker)')
	,('Monitor (InEar)')
	,('Monitor (Headphones)')
	,('Vocal Processor')
	,('Guitar (Accoustic)')
	,('Guitar (Electric)')
	,('Microphone (Instrument)')
	,('Microphone (Vocal)')
	,('USB (Storage)')
	,('USB (Computer)')
	,('USB (Device)')
	,('Rhythm/Drum Device')
	,('Time Clock')
	,('Pedal')
	,('Interface Device')
	,('Computer')
	,('Tablet')
	,('Mobile Device')
	,('Amplifier (Instrument)')
	,('Amplifier (Headphones)')
	,('DAC/Recorder')
	,('Looper')
	,('AES/EBU Extension')


--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.PORT_TYPES

INSERT INTO dbo.PORT_TYPES (PRT_TXT, PRT_ALT_TXT, PRT_TYP_DESC, PRT_CAT_CD)
VALUES
	('1/4',null,'1/4" TS/TRS','PRT_AUDI')
	,('PDL','Pedal','1/4" Pedal','PRT_PEDL')
	,('3/8',null,'3/8" TS/TRS','PRT_AUDI')
	,('SYNC',null,'3/8" SYNC','PRT_SYNC')
	,('CV',null,'3/8" CV','PRT_CTRL')
	,('GATE',null,'3/8" GATE','PRT_CTRL')
	,('HP25','Headphone','1/4" Headphone/Reference','PRT_AUDI')
	,('HP38','Headphone','3/8" Headphone/Reference','PRT_AUDI')
	,('XLR',null,'XLR','PRT_AUDI')
	,('Combo',null,'1/4"/XLR combo','PRT_AUDI')
	,('AES',null,'AES/EBU Out','PRT_EXPN')
	,('AVB',null,'AVB Audio Network','PRT_EXPN')
	,('NETC',null,'Network Control ','PRT_CTRL')
	,('USBDEV','USB (Dev)','USB Device','PRT_UDEV')
	,('USBCPU','USB (Comp)','USB to Computer','PRT_UCMP')
	,('USBSTR','USB (Stor)','USB Storage','PRT_MASS')
	,('SPDIF',null,'SPDIF Signal','PRT_AUDI')
	,('RCA',null,'RCA Audio','PRT_AUDI')
	,('MIDI',null,'MID In/Out/Thru','PRT_CTRL')
	,('SD Card',null,'Storage Device','PRT_MASS')


--WIPE TABLE AND RE-INSERT VALUES
TRUNCATE TABLE dbo.SECURITY_QUESTIONS

INSERT INTO dbo.SECURITY_QUESTIONS (SEC_QUEST_TXT)
VALUES
	('What is your mother`s maiden name?')
	,('What is the name of the highschool you graduated from?')
	,('What is your favorite pet`s name?')
	,('What is was the make and model of your first car?')
	,('What city were you born in?')
	,('What city did you get married in?')
	,('What is your favorite color?')
	,('What is your father`s middle name?')
	,('What is the name of your childhood best friend?')
	,('What is the name of your first crush?')
	,('What is the name of person you went to Prom with?')
	,('What is your favorite hobby?')


--WIPE TABLE AND RE-INSERT VALUES  
TRUNCATE TABLE dbo.APP_DEFAULTS

--INSERT APP DEFAULTS (Has to be ran under Windows Account not as SA or you get a access denied) 
INSERT INTO dbo.APP_DEFAULTS (APP_KEY, APP_VALUE, APP_BIN_VALUE)
Select 'NO_IMAGE' as APP_KEY,'NO IMAGE' as APP_VALUE, BulkColumn as APP_BIN_VALUE from OPENROWSET(BULK N'C:\Users\TBAZ7\OneDrive\Documents\School\UAT\MS587\Assignment_Final\IMAGES\NIA.png', SINGLE_BLOB) image UNION
Select 'PG_TITLE' as APP_KEY,'Studio Layout Companion' as APP_VALUE, null as APP_BIN_VALUE union
select 'SFTDELVL' as APP_KEY,'30' as APP_VALUE, null as APP_BIN_VALUE union
select 'PRT_CHAN' as APP_KEY,'@VAL' as APP_VALUE, null as APP_BIN_VALUE union
select 'PRT_NAME' as APP_KEY,'CH @VAL' as APP_VALUE, null as APP_BIN_VALUE union
select 'PRT_DESC' as APP_KEY,'@PT @CT Channel @VAL' as APP_VALUE, null as APP_BIN_VALUE union
select 'LOD_ASSN' as APP_KEY,'0' as APP_VALUE, null as APP_BIN_VALUE union
select 'PRT_ASSN' as APP_KEY,'0' as APP_VALUE, null as APP_BIN_VALUE union
select 'MAX_FAIL' as APP_KEY, '5' as APP_VALUE, null as APP_BIN_VALUE union
select 'WAITTIME' as APP_KEY, '5' as APP_VALUE, null as APP_BIN_VALUE union 
select 'DEBUGSQL' as APP_KEY, '1' as APP_VALUE, null as APP_BIN_VALUE union
select 'DEBUBWEB' as APP_KEY, '0' as APP_VALUE, null as APP_BIN_VALUE 