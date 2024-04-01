param(
    [string]$admins_group,
    [string]$developers_group,
    [string]$schema_readers_group,
    [string]$data_factory_name,
    [string]$service_principal,
    [string]$appmnemonic,
    [string]$environment,
    [string]$functional_area,
    [string]$data_product_name
)

$textculture = (Get-Culture).TextInfo 
$synapse_functionl_area = @{
    "commercial"      = "Comm"
    "dataops"         = "EDNA"
    "global services" = "Global"
    "it"              = "IT"
    "m&q"             = "MQ"
    "r&d"             = "RD"
  }
  $synpfa = $synapse_functionl_area[$functional_area]
  $syn_dpa = $textculture.ToTitleCase($data_product_name) | %{$_.Replace(" ","")}

  $allsynp_dbs = @{
    "dev"="BDAZE1ISQDWSV01"
    "qa"="BQAZE1IEDNADW01"
    "prod"="BPAZE1IEDNADW01"
  }
  $dbname = $allsynp_dbs[$environment]
  $allsynp_resourcenames = @{
    "dev" = "bdaze1isqdwdb01"
    "qa" = "bqaze1iednadb01"
    "prod" = "bpaze1iednadb01"
  }
  # Synapse connection string suffix 
  $int_synpserver_suffix = ".database.windows.net"
  $synapse_name  = $allsynp_resourcenames[$environment]
  # Synapse dbname and connection string.
  $internalsqlservername = $synapse_name+$int_synpserver_suffix
  # RolesName
  $datawriterrolename    = $synpfa+$syn_dpa+"DataWriter"
  $developerrolename     = $synpfa+$syn_dpa+"Developer"
  $ownerRoleName         = $synpfa+$syn_dpa+"Owner"
  $readerrolename        = $synpfa+$syn_dpa+"DataReader"
  
  # memberName
  if ($environment -eq "dev" -or $environment -eq "qa") {
    $membername = "NonProd"+$synpfa+"Admins"
  }
  else {
    $membername = "Prod"+$synpfa+"Admins"
  }
  #schemaName  
  $schemaName = $synpfa+$syn_dpa
  #azgroups
  $admins_group =  $textculture.ToUpper($admins_group)
  $developers_group = $textculture.ToUpper($developers_group)
# outputs

$alloutputs  = New-Object PSObject
#Retrieve User profile Properties 
$alloutputs | Add-Member -MemberType NoteProperty -name "adminsgroupname" -value $textculture.ToUpper($admins_group)
$alloutputs | Add-Member -MemberType NoteProperty -name "developersgroupname" -value $textculture.ToUpper($developers_group)
$alloutputs | Add-Member -MemberType NoteProperty -name "readersgroupname" -value $schema_readers_group
$alloutputs | Add-Member -MemberType NoteProperty -name "datafactoryIdName" -value $textculture.ToUpper($data_factory_name)
$alloutputs | Add-Member -MemberType NoteProperty -name "spnclientname" -value $textculture.ToLower($service_principal)
$alloutputs | Add-Member -MemberType NoteProperty -name "readerrolename" -value $readerrolename
$alloutputs | Add-Member -MemberType NoteProperty -name "datawriterrolename" -value $datawriterrolename
$alloutputs | Add-Member -MemberType NoteProperty -name "developerrolename" -value $developerrolename
$alloutputs | Add-Member -MemberType NoteProperty -name "ownerRoleName" -value $ownerRoleName
$alloutputs | Add-Member -MemberType NoteProperty -name "schemaName" -value $schemaName
$alloutputs | Add-Member -MemberType NoteProperty -name "membername" -value $membername
$alloutputs | Add-Member -MemberType NoteProperty -name "synapse_name" -value $synapse_name
$alloutputs | Add-Member -MemberType NoteProperty -name "appshortcode" -value $textculture.ToUpper($appmnemonic)
$alloutputs | Add-Member -MemberType NoteProperty -name "internalsqlservername" -value $internalsqlservername
$alloutputs | Add-Member -MemberType NoteProperty -name "databasename" -value $dbname
return $alloutputs



