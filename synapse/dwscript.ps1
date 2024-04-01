param(
    [Parameter(Mandatory=$True)]    
    [string]$adminsgroupname,
    [Parameter(Mandatory=$True)]    
    [string]$developersgroupname,
    [Parameter(Mandatory=$True)]    
    [string]$readersgroupname,
    [Parameter(Mandatory=$True)]    
    [string]$readerrolename,
    [Parameter(Mandatory=$True)]    
    [string]$datawriterrolename,
    [Parameter(Mandatory=$True)]    
    [string]$developerrolename,
    [Parameter(Mandatory=$True)]    
    [string]$ownerRoleName,
    [Parameter(Mandatory=$True)]    
    [string]$schemaName,
    [Parameter(Mandatory=$True)]    
    [string]$membername,
    [Parameter(Mandatory=$True)]    
    [string]$datafactoryIdName,
    [Parameter(Mandatory=$True)]    
    [string]$spnName
    
)

[string]$script1_createusers = "
-- Admins group
CREATE USER [$($adminsgroupname)] FOR EXTERNAL PROVIDER;

-- Developers group
CREATE USER [$($developersgroupname)] FOR EXTERNAL PROVIDER;

-- Schema readers group
CREATE USER [$($readersgroupname)] FOR EXTERNAL PROVIDER;

-- Data Factory
CREATE USER [$($datafactoryIdName)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($datafactoryIdName)];

-- Service Principal
CREATE USER [$($spnName)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($spnName)];

"
Write-Host $script1_createusers

Write-Host ############

$script2_createusersindwdb ="
-- Admins group
CREATE USER [$($adminsgroupname)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($adminsgroupname)];

-- Developers group
CREATE USER [$($developersgroupname)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($developersgroupname)];

-- Schema readers group
CREATE USER [$($readersgroupname)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($readersgroupname)];

-- Data Factory
CREATE USER [$($datafactoryIdName)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($datafactoryIdName)];

-- Service Principal
CREATE USER [$($spnName)] FOR EXTERNAL PROVIDER;

GRANT CONNECT TO [$($spnName)];

"
Write-Host $script2_createusersindwdb

Write-Host ############

$script3_createrolesindwdb = "
-- Reader role
CREATE ROLE [$($readerrolename)]     AUTHORIZATION [dbo];

EXECUTE sp_addrolemember @rolename = N'$($readerrolename)', @membername = N'$($readersgroupname)';

-- Writer role
CREATE ROLE [$($datawriterrolename)] AUTHORIZATION [dbo];

-- Developer role
CREATE ROLE [$($developerrolename)] AUTHORIZATION [dbo];

EXECUTE sp_addrolemember @rolename = N'$($developerrolename)', @membername = N'$($developersgroupname)';

EXECUTE sp_addrolemember @rolename = N'$($developerrolename)', @membername = N'$($datafactoryIdName)';

EXECUTE sp_addrolemember @rolename = N'$($developerrolename)', @membername = N'$($spnName)';

-- Owner role
CREATE ROLE [$($ownerRoleName)] AUTHORIZATION [dbo];

EXECUTE sp_addrolemember @rolename = N'$($ownerRoleName)', @membername = N'$($adminsgroupname)';

-- DDL Admin
EXECUTE sp_addrolemember @rolename = N'db_ddladmin', @membername = N'$($ownerRoleName)';


"

Write-Host $script3_createrolesindwdb
Write-Host ############



$script4_CreateSchema = "

CREATE SCHEMA [$($schemaName)] AUTHORIZATION [$($ownerRoleName)];

"

Write-Host $script4_CreateSchema
Write-Host ############

$script5_CreateSchema_Rolesindwdb = "

--Owner

GRANT CONTROL ON SCHEMA::$($schemaName) to $($ownerRoleName);

GRANT SELECT, DELETE, EXECUTE, INSERT, UPDATE, VIEW DEFINITION, ALTER, REFERENCES ON SCHEMA::$($schemaName) to $($ownerRoleName);

GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, VIEW DATABASE STATE, ADMINISTER DATABASE BULK OPERATIONS, VIEW DEFINITION to $($ownerRoleName);


--The following grants are to support Polybase

GRANT ALTER ANY EXTERNAL DATA SOURCE TO $($ownerRoleName);

GRANT ALTER ANY EXTERNAL FILE FORMAT TO $($ownerRoleName);


--Developer

GRANT SELECT, DELETE, EXECUTE, INSERT, UPDATE, VIEW DEFINITION, ALTER, REFERENCES ON SCHEMA::$($schemaName) to $($developerrolename);

GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, VIEW DATABASE STATE, ADMINISTER DATABASE BULK OPERATIONS to $($developerrolename);


--Reader

GRANT SELECT, VIEW DEFINITION ON SCHEMA::$($schemaName) to $($readerrolename);


--Writer

GRANT SELECT, DELETE, EXECUTE, INSERT, UPDATE ON SCHEMA::$($schemaName) to $($datawriterrolename);


"
Write-Host $script5_CreateSchema_Rolesindwdb
Write-Host ############


$script6_creatememberindwdb = "

--AddOwnerRoleMember
EXECUTE sp_addrolemember @rolename = N'$($ownerRoleName)', @membername = N'$($membername)';

"
Write-Host $script6_creatememberindwdb
Write-Host ############

## Generating SQL files
 $script1_createusers >> "master_1CreateUsersinMasterdb.sql"

 $script2_createusersindwdb >> "syndw_1CreateUser.sql"

 $script3_createrolesindwdb >> "syndw_2CreateRole.sql"

 $script4_CreateSchema >> "syndw_3CreateSchema.sql"

 $script5_CreateSchema_Rolesindwdb >> "syndw_4GrantRolestoSchema.sql"

 $script6_creatememberindwdb >> "syndw_5creatememberindwdb.sql"