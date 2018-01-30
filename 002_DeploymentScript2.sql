--nilesh desai
/* 
Update info for sysparam and volume updatescolected by 001_SysparamAndVolumes
WHICH MUST BE RUN BEFORE THE DB's ARE UPDATED
NB Only doing the 1st 13 volumes entries here as the main converted one should already be correct

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


EXEC sp_configure 'show advanced options', 1
GO

-- To update the currently configured value for advanced options.
RECONFIGURE
GO

-- To enable the feature.
EXEC sp_configure 'xp_cmdshell', 1
GO

SET NOCOUNT ON
GO

--
-- re-import the sysparams
--

-- ALB
UPDATE $(ALBDB)..Sysparam
SET		SysparamValue = Live.SysparamValue
FROM (
		SELECT	 SysparamId
				,SysparamValue
		FROM	$(ALBPRAMDB)..ALBPARAMS
	) Live
JOIN	$(ALBDB)..SysParam ALB on ALB.sysparamId = Live.SysparamId

--ALBTest
UPDATE $(ALBTestDB)..Sysparam
SET		SysparamValue = Test.SysparamValue
FROM (
		SELECT	 SysparamId
				,SysparamValue
		FROM	$(ALBPRAMDB)..ALBTestPARAMS
	) Test
JOIN	$(ALBTestDB)..SysParam ALB on ALB.sysparamId = Test.SysparamId

--ALBDev
UPDATE $(ALBDevDB)..Sysparam
SET		SysparamValue = Dev.SysparamValue
FROM (
		SELECT	 SysparamId
				,SysparamValue
		FROM	$(ALBPRAMDB)..ALBDevPARAMS
	) Dev
JOIN	$(ALBDevDB)..SysParam ALB on ALB.sysparamId = Dev.SysparamId

---
--- Update Volumes
---

--ALB
UPDATE  $(ALBDB)..Volumes
SET		VolumeLocation = Live.VolumeLocation
FROM (
	SELECT	 VolumeId
			,VolumeLocation
	FROM	$(ALBPRAMDB)..ALBVolumes
) Live
JOIN	 $(ALBDB)..Volumes ALB on ALB.VolumeId = Live.VolumeId

--ALBTest
UPDATE  $(ALBTestDB)..Volumes
SET		VolumeLocation = Test.VolumeLocation
FROM (
	SELECT	 VolumeId
			,VolumeLocation
	FROM	$(ALBPRAMDB)..ALBTestVolumes
) Test
JOIN	 $(ALBTestDB)..Volumes ALB on ALB.VolumeId = Test.VolumeId

--ALBDev
UPDATE  $(ALBDevDB)..Volumes
SET		VolumeLocation = Dev.VolumeLocation
FROM (
	SELECT	 VolumeId
			,VolumeLocation
	FROM	$(ALBPRAMDB)..ALBDevVolumes
) Dev
JOIN	 $(ALBDevDB)..Volumes ALB on ALB.VolumeId = Dev.VolumeId

--
-- update the FIRM name on the Dev and Test DBs in order to help identify which DB is what
--
update $(ALBTestDB)..Organisations
set Orgname = Orgname +' - Test'
where Orgdisplaycode = 'Firm'

update $(ALBDevDB)..Organisations
set Orgname = Orgname +' - Development'
where Orgdisplaycode = 'Firm'

--
-- Import back in specific tables for 3rd party modules
--

-- CapScan Integration
-- Live Area
	TRUNCATE table $(ALBDB).dbo.WebServicePasswords   

	SET IDENTITY_INSERT $(ALBDB).[dbo].[WebServicePasswords] ON

	INSERT INTO $(ALBDB).[dbo].[WebServicePasswords] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestWebServicePasswords Live

	SET IDENTITY_INSERT $(ALBDB).[dbo].[WebServicePasswords] OFF
	
-- CapScan Integration
-- Test Area
	TRUNCATE table $(ALBTestDB).dbo.WebServicePasswords   

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[WebServicePasswords] ON

	INSERT INTO $(ALBTestDB).[dbo].[WebServicePasswords] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestWebServicePasswords Test

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[WebServicePasswords] OFF
	
-- CapScan Integration
-- Dev Area
	TRUNCATE table $(ALBDevDB).dbo.WebServicePasswords   

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[WebServicePasswords] ON

	INSERT INTO $(ALBDevDB).[dbo].[WebServicePasswords] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestWebServicePasswords Dev

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[WebServicePasswords] OFF


--Central Scanning
-- Live Area
	TRUNCATE table $(ALBDB).dbo.CentralScanFileExtensions   

	SET IDENTITY_INSERT $(ALBDB).[dbo].[CentralScanFileExtensions] ON

	INSERT INTO $(ALBDB).[dbo].[CentralScanFileExtensions] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBCentralScanFileExtensions Live

	SET IDENTITY_INSERT $(ALBDB).[dbo].[CentralScanFileExtensions] OFF

	TRUNCATE table $(ALBDB).dbo.CentralScanFolders   

	SET IDENTITY_INSERT $(ALBDB).[dbo].[CentralScanFolders] ON

	INSERT INTO $(ALBDB).[dbo].[CentralScanFolders] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBCentralScanFolders Live

	SET IDENTITY_INSERT $(ALBDB).[dbo].[CentralScanFolders] OFF

--Central Scanning
-- Test Area
	TRUNCATE table $(ALBTestDB).dbo.CentralScanFileExtensions   

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[CentralScanFileExtensions] ON

	INSERT INTO $(ALBTestDB).[dbo].[CentralScanFileExtensions] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestCentralScanFileExtensions Test

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[CentralScanFileExtensions] OFF

	TRUNCATE table $(ALBTestDB).dbo.CentralScanFolders   

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[CentralScanFolders] ON

	INSERT INTO $(ALBTestDB).[dbo].[CentralScanFolders] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestCentralScanFolders Test

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[CentralScanFolders] OFF

--Central Scanning
-- Dev Area
	TRUNCATE table $(ALBDevDB).dbo.CentralScanFileExtensions   

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[CentralScanFileExtensions] ON

	INSERT INTO $(ALBDevDB).[dbo].[CentralScanFileExtensions] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBDevCentralScanFileExtensions Dev

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[CentralScanFileExtensions] OFF

	TRUNCATE table $(ALBDevDB).dbo.CentralScanFolders   

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[CentralScanFolders] ON

	INSERT INTO $(ALBDevDB).[dbo].[CentralScanFolders] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBDevCentralScanFolders Dev

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[CentralScanFolders] OFF


-- SMS
-- Live Area
	TRUNCATE table $(ALBDB).dbo.TextMsgServiceProvider   

	SET IDENTITY_INSERT $(ALBDB).[dbo].[TextMsgServiceProvider] ON

	INSERT INTO $(ALBDB).[dbo].[TextMsgServiceProvider] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTextMsgServiceProvider Live

	SET IDENTITY_INSERT $(ALBDB).[dbo].[TextMsgServiceProvider] OFF

	TRUNCATE table $(ALBDB).dbo.CentralScanFolders   

-- SMS
-- Test Area
	TRUNCATE table $(ALBTestDB).dbo.TextMsgServiceProvider   

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[TextMsgServiceProvider] ON

	INSERT INTO $(ALBTestDB).[dbo].[TextMsgServiceProvider] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBTestTextMsgServiceProvider Test

	SET IDENTITY_INSERT $(ALBTestDB).[dbo].[TextMsgServiceProvider] OFF

-- SMS
-- Dev Area
	TRUNCATE table $(ALBDevDB).dbo.TextMsgServiceProvider   

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[TextMsgServiceProvider] ON

	INSERT INTO $(ALBDevDB).[dbo].[TextMsgServiceProvider] 
	SELECT *
	FROM        $(ALBPRAMDB)..ALBDevTextMsgServiceProvider Dev

	SET IDENTITY_INSERT $(ALBDevDB).[dbo].[TextMsgServiceProvider] OFF

--
-- now Start each service in turn
--
declare 
		@count			int = 1,
		@noi			int, -- number of items
		@Svrname		Varchar(100),
		@Command		varchar(200),
		@RetInfo		varchar(8000)

select @noi = count(*) from $(ALBPRAMDB)..ServicesTable

while @count <= @noi
begin
   select @Svrname = Servicename
   from $(ALBPRAMDB)..ServicesTable
   where ServiceTableID = @count
   select @Command = 'net start '+@Svrname
   --select @command
   exec @RetInfo = master.dbo.xp_cmdshell @Command
   set @count +=1			
end


---
--- Run usp_ILBLogins_CheckAdd for each DB
---
use $(ALBDB)
go
DECLARE @RC int
EXECUTE @RC = $(ALBDB).[dbo].[usp_ILBLogins_CheckAdd] 
GO

use $(ALBTestDB)
go
DECLARE @RC int
EXECUTE @RC = $(ALBTestDB).[dbo].[usp_ILBLogins_CheckAdd] 
GO

use $(ALBDevDB)
go
DECLARE @RC int
EXECUTE @RC =$(ALBDevDB).[dbo].[usp_ILBLogins_CheckAdd] 
GO

Print '********************************************************************************************************************'
print 'Import of parameters and selected files is now completed - The please that the associated services have been started' 
Print '********************************************************************************************************************'