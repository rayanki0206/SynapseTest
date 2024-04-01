
param (
    [Parameter(mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $subscriptionId,
    [Parameter(Mandatory =  $false)]
    $tenantId,
    [Parameter(Mandatory =  $false)]
    [string]$mysecret,
    [ValidateNotNullOrEmpty()]
    [String]$synpaseName,
    [Parameter(Mandatory =  $true)]
    [string]$sqlpoolname,
    [Parameter(Mandatory =  $true)]
    [string]$clientId,
    [Parameter(Mandatory =  $true)]
    [string]$databasename,
    [string]$synapseconnectionstring
)


### Remove this Hardcoded
# $synpaseName = "elsynapsepoolww1"
# $sqlpoolname = "elsynapsepoolww1.database.windows.net"
# $databasename = "testsqlpool"

try {
    Write-Output  "Importing required Azure modules"
    
    Import-Module Az 
    Import-Module -Name Az.Synapse -Confirm:$false -Force
    # add final
    # Start-Sleep -Seconds 300
}
catch {
    $_.Exception
}

# Connect to Azure Subscription.
### Main
if( $clientId -and $mysecret -and $tenantId){
    $SecuredPassword = ConvertTo-SecureString $mysecret -AsPlainText -Force
    $pscredential = New-Object System.Management.Automation.PSCredential($clientId, $SecuredPassword)
    # connect to Azure
    $azconnection = Connect-AzAccount -Tenant $tenantId -Credential $pscredential -ServicePrincipal  -ErrorAction Stop
   
    Write-Output "Subscription : $subscriptionId"
   
    if($azconnection){ Set-AzContext -SubscriptionId $subscriptionId }
    
}

### Read standard configuration File
if (-not (Get-Module -Name SqlServer)){
    Install-Module -Name SqlServer -AllowClobber -Force 
}

$synpse = Get-AzResource | where-object{$_.resourceType -eq 'Microsoft.Synapse/workspaces' -and $_.Name -match $synpaseName }
# $synwrksp = Get-AzSynapseWorkspace -ResourceGroupName $synpse.ResourceGroupName -Name $synpse.Name
# $synpsqlpool = Get-AzSynapseSqlPool -WorkspaceName $synwrksp.Name -ResourceGroupName $synpse.ResourceGroupName | Where-Object{$_.SqlPoolName -eq $synpaseName}
# if ($synpsqlpool) {
#     $sqlendpoint = $synwrksp.ConnectivityEndpoints.sql
#     # $synapseconnectionstring = "Server=$sqlendpoint; Authentication=Active Directory Service Principal; Encrypt=True; Database=master; User Id=$clientId; Password=$mysecret"
    
# }
Write-Output "############################################################"

#### < Add the public ip of the github hosted Agent>
# Get publicIp of Machine
$res =  Invoke-WebRequest -Uri 'https://api.ipify.org?format=json'
$pip_azagent = ($res.Content | ConvertFrom-Json).ip

# validate if this IP Exist in Synapse SQL Firewall  if doesn't then add the $pip_azagent.

$exists = Get-AzSynapseFirewallRule -WorkspaceName $synpse.Name -ResourceGroupName $synpse.ResourceGroupName | Where-Object {$_.Name -eq "ghhostedAgent"}

if( -not $exists){
    New-AzSynapseFirewallRule -WorkspaceName $synpse.Name -ResourceGroupName $synpse.ResourceGroupName `
    -Name "ghhostedAgent" -StartIpAddress "$pip_azagent" -EndIpAddress "$pip_azagent"
}
else {
    Update-AzSynapseFirewallRule -WorkspaceName $synpse.Name -ResourceGroupName $synpse.ResourceGroupName `
    -Name "ghhostedAgent" -StartIpAddress "$pip_azagent" -EndIpAddress "$pip_azagent" 
}

# Synapse Connections String 
$synapseconnectionstring = "Server=$sqlpoolname; Authentication=Active Directory Service Principal; Encrypt=True; Database=$databasename; User Id=$clientId; Password=$mysecret"
$mastersynapseconnectionstring = "Server=$sqlpoolname; Authentication=Active Directory Service Principal; Encrypt=True; Database=master; User Id=$clientId; Password=$mysecret"

# Set Script Working Directory
$scriptDirectory = Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent
set-location $scriptDirectory

$allsqlfiles  =  Get-ChildItem -Recurse -Filter "*.sql" |Select-Object Name,FullName  |Sort-Object Name

foreach ($sqlfile in $allsqlfiles) {
    Write-Output "Executing the sql file: $sqlfile"
    $sqlscript = Get-Content $sqlfile.FullName
    Write-Output "SQL Scrip: ####  \n  $sqlscript"

    if ($sqlfile.Name -match "master_") {

        Invoke-Sqlcmd -ConnectionString $mastersynapseconnectionstring -InputFile $sqlfile.FullName -ErrorAction Continue
    }
    else {
        
        Invoke-Sqlcmd -ConnectionString $synapseconnectionstring -InputFile $sqlfile.FullName -ErrorAction Continue
    }

}

