-- ====================================================================================================
-- Backup and Restore of Master Key
-- ====================================================================================================
/*
USE SLOC_DB;
--RESTORE MASTER KEY FROM FILE
  Print 'Restoring Master Key From File: ''C:\temp\MasterKey_Bkup_ADVC'''
  RESTORE MASTER KEY FROM FILE = 'C:\temp\MasterKey_Bkup_ADVC'
	 DECRYPTION BY PASSWORD = 'SLOC1234Gr33nFr0g1!'
	 ENCRYPTION BY PASSWORD = 'SLOC1234Gr33nFr0g1!'
	--FORCE

  --ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'ava2930CU1!'
  --OPEN MASTER KEY DECRYPTION BY PASSWORD = 'SLOC1234Gr33nFr0g1!'
  
  USE SLOC_DB;
--BACKUP MASTER KEY TO FILE
  Print 'Backing up Master Key to File: ''C:\temp\MasterKey_Bkup_ADVC'''
  BACKUP MASTER KEY TO FILE = 'C:\temp\MasterKey_Bkup_ADVC'
	 Encryption by password ='SLOC1234Gr33nFr0g1!'



--HOW TO SEE THE ServiceMasterKey
  USE MASTER;
  GO

  SELECT * FROM SYS.SYMMETRIC_KEYS
*/


USE SLOC_DB;
GO

-- ====================================================================================================
-- SCRIPT CHECK AND DELETE Master Key, Certificate, and Symmetric Key
-- ====================================================================================================
-- UNCOMMENT IF YOU WANT TO DELETE THE KEYS 
IF EXISTS (Select * from sys.symmetric_keys where name = 'SLOCDB_SymKey')
BEGIN	
	PRINT 'Dropping Symmetric Key: SLOCDB_SymKey'
	DROP SYMMETRIC KEY SLOCDB_SymKey
END
Go

IF EXISTS (Select * from sys.asymmetric_keys where name = 'SLOCDB_ASymKey')
BEGIN	
	PRINT 'Dropping ASymmetric Key: SLOCDB_ASymKey'
	DROP ASYMMETRIC KEY SLOCDB_ASymKey
END
Go

IF EXISTS (Select * from sys.Certificates where name = 'SLOCDB_FTPCert')
BEGIN
	PRINT 'Dropping Certificate: SLOCDB_FTPCert'
	Drop Certificate SLOCDB_FTPCert
END
Go

IF EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN	
	PRINT 'Dropping Master Key'
	DROP MASTER KEY
END
Go




-- ====================================================================================================
-- SCRIPT CHECK AND SETUP of Master Key, Certificate, and Symmetric Key
-- ====================================================================================================
--If there is no master key, create one now. 
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101) 
BEGIN
    PRINT 'Creating Master Key'
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SLOC1234Gr33nFr0g1!'
END
GO

--[If there is no Certificate key create one (Not needed for encryption)]

--IF NOT EXISTS (Select * from sys.Certificates where name = 'ADVC_FTPCert')
--BEGIN
--	PRINT 'Creating Certificate: ADVC_FTPCert'
--	CREATE CERTIFICATE ADVC_FTPCert
--	AUTHORIZATION dbo
--	WITH SUBJECT = 'FTP User Credentials'
--	, EXPIRY_DATE = '12/31/2039'
--END
--GO

IF NOT EXISTS (Select * from sys.asymmetric_keys where name = 'SLOCDB_ASymKey')
BEGIN
	PRINT 'Creating ASymmetric Key: SLOCDB_ASymKey'
	CREATE ASYMMETRIC KEY SLOCDB_ASymKey
	WITH ALGORITHM = RSA_2048;
END
Go

IF NOT EXISTS (Select * from sys.symmetric_keys where name = 'SLOCDB_SymKey')
BEGIN
	PRINT 'Creating Symmetric Key: SLOCDB_SymKey'
	CREATE SYMMETRIC KEY SLOCDB_SymKey
	--AUTHORIZATION dbo
	WITH ALGORITHM = AES_256
	ENCRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;
END
GO

--SEEING WE ARE NOT USING A CERTIFICATE (COMMENT OUT)
--OPEN SYMMETRIC KEY FTPCredential_Key11
--   DECRYPTION BY CERTIFICATE SLOCDB_FTPCert;


OPEN SYMMETRIC KEY SLOCDB_SymKey
   DECRYPTION BY ASYMMETRIC KEY SLOCDB_ASymKey;
