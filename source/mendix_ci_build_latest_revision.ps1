###########################################################
# Script for creating mda-file (Mendix Deployment Archive)
###########################################################
#
# Prerequisites: Set-ExecutionPolicy RemoteSigned
#
###########################################################

Param(
    [Parameter(Position=0)]
    [String]$apiheaders,
    [String]$environmentconfig
)

# Check if the functions script is in place.
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\mendix_ci_functions.ps1")
}
catch {
    Write-Host "Error while loading required supporting PowerShell Scripts."
}

#FIRST CHECK INPUT OF REQUIRED VARIABLE
if (!$apiheaders) {
    Write-Host "API headers are required."
    exit
}

if (!$envconfig) {
    Write-Host "Environment configuration is required."
    exit
}

# INCLUDE FUNCTIONS FILE
Include '.\mendix_ci_functions.ps1'

# STATIC VARIABLE ENDPOINT
$url = 'https://deploy.mendix.com/api/1/'

# IMPORT MENDIX API CREDENTIALS
$headers = Import-PowerShellDataFile $apiheaders

# IMPORT ENVIRONMENT CONFIGURATION 
$configuration = Import-PowerShellDataFile $environmentconfig

# Get and set the specific environment config
$appName = $configuration.Environment.AppName
$branchName = $configuration.Environment.BranchName

$branch = Get-Branch $headers $url $appName $branchName

"Branch to build: $branch"
$latestBuiltRevision = $branch.LatestTaggedVersion.Substring($branch.LatestTaggedVersion.LastIndexOf('.') + 1)
$latestRevisionNumber = $branch.LatestRevisionNumber

if ($latestBuiltRevision -eq $latestRevisionNumber) {
    "It is not needed to build, as the latest revision is already built."
    exit
}

$versionWithoutRevision = $branch.LatestTaggedVersion.Remove($branch.LatestTaggedVersion.LastIndexOf('.'))
$packageId = Start-Build $headers $url $appName $branchName $latestRevisionNumber $versionWithoutRevision
$built = Wait-For-Built $headers $url $appName $packageId 600

if($built -eq $false) {
    "No build succeeded within 10 minutes."
    exit
}