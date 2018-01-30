/* 

Collect info for sysparam, volume updates and various other tables and store in DB for update by 002 Sysparam_And_Volumes
Created by Darren Fitter on 22/05/2016 - based on original scrip from Bruce Parker.

•	Stop ALB Services (some of these might not be present if they don’t have Exchange Integration)

Advanced Diary Notification Service
Advanced Diary Task Sync
Advanced Legal Search Service
LegalServiceHost
LegalTaskScheduler

•	Export existing ALB fields

Module Info: Forms and Document Paths
Table: Volumes
Column: VolumeLocation
VolumeID: 1 - 13

Module Info: Scanning Integration
Table: SysParam
Column: SysParamValue
SysParamID: 118, 119, 120, 121, 122, 123

Module Info: Update path
Table: SysParam
Column: SysParamValue
SysParamID: 65

Module Info: Reporting Services
Table: SysParam
Column: SysParamValue
SysParamID: 66

Module Info: BigHand Integration
Table: SysParam
Column: SysParamValue
SysParamID: 98, 99, 101

Module Info: TAPI Integration
Table: SysParam
Column: SysParamValue
SysParamID: 104, 105

Module Info: pdfDocs Integration
Table: SysParam
Column: SysParamValue
SysParamID: 106, 192, 194

Module Info: Equitrac Integration
Table: SysParam
Column: SysParamValue
SysParamID: 113, 114, 115

Module Info: WorkFlow/SaveToALB Integration
Table: SysParam
Column: SysParamValue
SysParamID: 158

Module Info: Client Interest Start Date
Table: SysParam
Column: SysParamValue
SysParamID: 171

Module Info: CapScan Integration
Table: WebServicePasswords
*Entire table

Module Info: Central Scanning
Table: CentralScanFileExtensions
*Entire table

Module Info: Central Scanning
Table: CentralScanFolders
*Entire table

Module Info: SMS
Table: TextMsgServiceProvider
*Entire table

•	Restore ALB DB with new Live version (and perform any other standard tasks against this DB you normally carry out)

•	Import ALB fields from backup

•	Start ALB Services

Advanced Diary Notification Service
Advanced Diary Task Sync
Advanced Legal Search Service
LegalServiceHost
LegalTaskScheduler
====================================================================================================================================

*/
Use Master

:Setvar ALBDB		"ALB"
:Setvar ALBTestDB	"ALBTest"
:Setvar ALBDevDB	"ALBDev"
:SetVar	ALBPRAMDB	"ALB_Mig_Deployment_DB"

--EXEC sp_configure 'show advanced options', 1
--GO

---- To update the currently configured value for advanced options.
--RECONFIGURE
--GO

-- To enable the feature.
EXEC sp_configure 'xp_cmdshell', 1
GO

SET NOCOUNT ON
GO

--
-- back Live, Test and Dev Database first
--
DECLARE @name VARCHAR(50)		-- database name  
DECLARE @path VARCHAR(256)		-- path for backup files  
DECLARE @fileName VARCHAR(256)	-- filename for backup  
DECLARE @fileDate VARCHAR(20)	-- used for file name
DECLARE @fileTime VARCHAR(10)	-- used for set file time
 
--
-- specify database backup directory
--
set @path = (SELECT Physical_name FROM $(ALBDB).sys.database_files where type_desc = 'ROWS')
set @path = substring(@path,1,(LEN(@path) - CHARINDEX('\',REVERSE(@path))+1))

-- specify filename format
SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 
SELECT @fileTime = REPLACE(CONVERT(varchar,getdate(),108),':','_')
 
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name IN ('$(ALBDB)','$(ALBTestDB)','$(ALBDevDB)')  -- only these databases

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   
 
WHILE @@FETCH_STATUS = 0   
BEGIN   
       SET @fileName = @path + @name + '_' + @fileDate + '_' + @fileTime + '.BAK'  
       BACKUP DATABASE @name TO DISK = @fileName  

       FETCH NEXT FROM db_cursor INTO @name   
END   
 
CLOSE db_cursor   
DEALLOCATE db_cursor

--
-- check to see if the PARAMDB exist and if it does kills of any processes and then drops the DB
--
IF EXISTS(select * from sys.databases where name='$(ALBPRAMDB)')
WHILE EXISTS(select NULL from sys.databases where name='$(ALBPRAMDB)')
BEGIN
    DECLARE @SQL varchar(max)
    SELECT @SQL = COALESCE(@SQL,'') + 'Kill ' + Convert(varchar, SPId) + ';'
    FROM MASTER..SysProcesses
    WHERE DBId = DB_ID(N'$(ALBPRAMDB)') AND SPId <> @@SPId
    EXEC(@SQL)
    DROP DATABASE $(ALBPRAMDB)
END
GO

-- creates the ALB_Mig_Deployment_DB first checking for the DB file location of the ALB_Mig_Deployment_DB so that it can recreate the ALB_Mig_Deployment_DB in the same location
Declare @RowLocation	VARCHAR(150),
		@LogLocation	VARCHAR(150),
		@SQLSTRING		VARCHAR(MAX)

set @RowLocation = (SELECT Physical_name FROM $(ALBDB).sys.database_files where type_desc = 'ROWS')
set @LogLocation = (SELECT Physical_name FROM $(ALBDB).sys.database_files where type_desc = 'LOG')

-- build up the new mdf file path
set @RowLocation = substring(@RowLocation,1,(LEN(@RowLocation) - CHARINDEX('\',REVERSE(@RowLocation))+1))
set @RowLocation = @RowLocation + '$(ALBPRAMDB)'+'.mdf'

-- build up the new ldf file pat
set @LogLocation = substring(@LogLocation,1,(LEN(@LogLocation) - CHARINDEX('\',REVERSE(@LogLocation))+1))
set @LogLocation = @LogLocation + '$(ALBPRAMDB)'+'.ldf'

-- create the new Param DB using the new MDF and LDF Locations
SET @SQLSTRING = 'CREATE DATABASE $(ALBPRAMDB)  '
SET @SQLSTRING = @SQLSTRING + ' ON      ( NAME = ' + ''''+ '$(ALBPRAMDB)'+ '_data' + '''' + ', FILENAME = ' + '''' + @RowLocation + '''' + ') '
SET @SQLSTRING = @SQLSTRING + ' LOG ON  ( NAME = ' + '''' + '$(ALBPRAMDB)'  + '_Log' + '''' + ', FILENAME = ' + '''' + @LogLocation + '''' + ');'
--select @SQLSTRING
EXEC (@SQLSTRING)
GO

--
-- Export select sysparams from the ALB, Live, Test and Dev DBs
--
select * into $(ALBPRAMDB)..ALBPARAMS		from $(ALBDB)..SysParam		where SysParamId in	(66,65,98,99,101,104,105,106,113,114,115,118,119,120,121,122,123,158,171,192,194)
select * into $(ALBPRAMDB)..ALBTestPARAMS	from $(ALBTestDB)..SysParam where SysParamId in	(66,65,98,99,101,104,105,106,113,114,115,118,119,120,121,122,123,158,171,192,194)
select * into $(ALBPRAMDB)..ALBDevPARAMS	from $(ALBDevDB)..SysParam	where SysParamId in	(66,65,98,99,101,104,105,106,113,114,115,118,119,120,121,122,123,158,171,192,194)

--
-- Export out the Volume tables
--
select * into $(ALBPRAMDB)..ALBVolumes		from $(ALBDB)..volumes		where volumeid < 14
select * into $(ALBPRAMDB)..ALBTestVolumes	from $(ALBTestDB)..volumes	where volumeid < 14
select * into $(ALBPRAMDB)..ALBDevVolumes	from $(ALBDevDB)..volumes	where volumeid < 14

--
-- Export out specific tables for 3rd party modules
--

-- CapScan Integration
select * into $(ALBPRAMDB)..ALBWebServicePasswords				from $(ALBDB)..WebServicePasswords		
select * into $(ALBPRAMDB)..ALBTestWebServicePasswords			from $(ALBTestDB)..WebServicePasswords
select * into $(ALBPRAMDB)..ALBDevWebServicePasswords			from $(ALBDevDB)..WebServicePasswords

--Central Scanning
select * into $(ALBPRAMDB)..ALBCentralScanFileExtensions		from $(ALBDB)..CentralScanFileExtensions		
select * into $(ALBPRAMDB)..ALBTestCentralScanFileExtensions	from $(ALBTestDB)..CentralScanFileExtensions	
select * into $(ALBPRAMDB)..ALBDevCentralScanFileExtensions		from $(ALBDevDB)..CentralScanFileExtensions

select * into $(ALBPRAMDB)..ALBCentralScanFolders				from $(ALBDB)..CentralScanFolders		
select * into $(ALBPRAMDB)..ALBTestCentralScanFolders			from $(ALBTestDB)..CentralScanFolders	
select * into $(ALBPRAMDB)..ALBDevCentralScanFolders			from $(ALBDevDB)..CentralScanFolders

-- SMS
select * into $(ALBPRAMDB)..ALBTextMsgServiceProvider			from $(ALBDB)..TextMsgServiceProvider	
select * into $(ALBPRAMDB)..ALBTestTextMsgServiceProvider		from $(ALBTestDB)..TextMsgServiceProvider	
select * into $(ALBPRAMDB)..ALBDevTextMsgServiceProvider		from $(ALBDevDB)..TextMsgServiceProvider

--
-- Build Table holding the names of the services that need to be Stopped / Started
--
declare 
		@count			int = 1,
		@noi			int, -- number of items
		@Svrname		Varchar(100),
		@Command		varchar(200),
		@RetInfo		varchar(8000)



CREATE TABLE $(ALBPRAMDB).[dbo].[ServicesTable]
(
	ServiceTableID	int IDENTITY(1,1) NOT NULL,
	Servicename		varchar(100) NOT NULL
) ON [PRIMARY]


Insert into $(ALBPRAMDB)..ServicesTable
	(Servicename)
Values
	('Advanced Diary Notification Service'),
	('Advanced Diary Task Sync'),
	('Advanced Legal Search Service'),
	('LegalServiceHost'),
	('LegalServiceHostDev'),
	('LegalTaskScheduler'),
	('LegalTaskSchedulerDev')

--
-- now stop each service in turn
--
select @noi = count(*) from $(ALBPRAMDB)..ServicesTable

while @count <= @noi
begin
   select @Svrname = Servicename
   from $(ALBPRAMDB)..ServicesTable
   where ServiceTableID = @count
   select @Command = 'net stop '+@Svrname
  -- select @command
   exec @RetInfo = master.dbo.xp_cmdshell @Command
   set @count +=1			
end

--
-- check to see if the PARAMDB exist and if it does kills of any processes and then drops the DB
--
Declare	 @Errors int
		
Set @Errors =  (select count(*) from sys.databases d join sysprocesses p  on d.database_id = p.dbid where d.name=(N'$(ALBDB)'))
if @Errors <> 0
begin
	Declare @Err varchar
	Set @Err = CONVERT(varchar, @Errors)
	print ''
	print ''
	print '*** ' + @Err + ' Processes(s) still running***'
	PRINT	'******************************************************************************'
	PRINT	'                         !!!! ALB DATABASE STILL IN USE !!!!						       '
	PRINT	'******************************************************************************'
	select d.name, p.spid, p.login_time, p.hostname, p.program_name, p.loginame from sys.databases d join sysprocesses p  on d.database_id = p.dbid where d.name=(N'$(ALBDB)')
end

-- use the script below to kill of any processes you will need to change $(ALBDB) for the name of the ALB DB

--IF EXISTS(select * from sys.databases where name='$(ALBDB)')
--WHILE EXISTS(select NULL from sys.databases where name='$(ALBDB)')
--BEGIN
--    DECLARE @SQL varchar(max)
--    SELECT @SQL = COALESCE(@SQL,'') + 'kill ' + Convert(varchar, SPId) + ';'
--    FROM MASTER..SysProcesses
--    WHERE DBId = DB_ID(N'$(ALBDB)') AND SPId <> @@SPId
--    EXEC(@SQL)
--    DROP DATABASE $(ALBDB)  
--END
--GO

Print '************************************************************************************************************************************'
print 'Backup of parameters and selected files is now completed - The associated services have been stopped - Please restore ALB databases.'
Print '************************************************************************************************************************************'