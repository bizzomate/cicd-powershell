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
    [String]$environmentconfig,
    [Boolean]$dodeploy,
    [Boolean]$setconfiguration
)


$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Check if the functions script named 'mendix_ci_logging.ps1' is in place and import.
try {
    . ("$ScriptDirectory\mendix_ci_logging.ps1")
}
catch {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $output = "$date ERROR - Error while loading required supporting PowerShell Scripts (logging)."
    Write-output $output    
}

# Check if the functions script named 'mendix_ci_functions.ps1' is in place and import.
try {
    . ("$ScriptDirectory\mendix_ci_functions.ps1")
}
catch {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $output = "$date ERROR - Error while loading required supporting PowerShell Scripts (functions)."
    Write-output $output    
}


# FINALS
$timeOutInSeconds = 600

# FIRST CHECK INPUT OF REQUIRED VARIABLE
if (!$apiheaders) {
    LogMessage -message "API headers are required." -type ERROR
    exit
}

if (!$environmentconfig) {
    LogMessage -message "Environment configuration is required." -type ERROR
    exit
}

# STATIC VARIABLE ENDPOINT
$url = 'https://deploy.mendix.com/api/1/'

# IMPORT MENDIX API CREDENTIALS
$headers = Import-PowerShellDataFile $apiheaders

# IMPORT ENVIRONMENT CONFIGURATION 
$configuration = Import-PowerShellDataFile $environmentconfig

# Get and set the specific environment config
$appName = $configuration.Environment.AppName
$environment = $configuration.Environment.Environment
$branchName = $configuration.Environment.BranchName

LogMessage -message "START CI script for $appName, branch $branchName, environment $environment."

$branch = Get-Branch $headers $url $appName $branchName

LogMessage -message "Latest revision on branch: $branch"
$latestBuiltRevision = $branch.LatestTaggedVersion.Substring($branch.LatestTaggedVersion.LastIndexOf('.') + 1)
$latestRevisionNumber = $branch.LatestRevisionNumber

if ($latestBuiltRevision -eq $latestRevisionNumber) {
    LogMessage -message "It is not needed to build, as the latest revision is already built. Latest revision is $latestRevisionNumber."
    exit
}   

$versionWithoutRevision = $branch.LatestTaggedVersion.Remove($branch.LatestTaggedVersion.LastIndexOf('.'))
$packageId = Start-Build $headers $url $appName $branchName $latestRevisionNumber $versionWithoutRevision
$built = Wait-For-Built $headers $url $appName $packageId $timeOutInSeconds

if($built -eq $false) {
    LogMessage -message "END. No build succeeded within 10 minutes. Check in the portal if the build succeeded." -type WARNING
    exit
}

if ($dodeploy) {
    
    # TODO Check if latest built is already deployed on environment.
    
    
    Stop-App $headers $url $appName $environment
    Move-Package $headers $url $appName $environment $packageId
    # TODO Set config when requested
    $startJobId = Start-App $headers $url $appName $environment
    $started = Wait-For-Start $headers $url $appName $environment $startJobId 600

    if($started -eq $true) {
        LogMessage -message "App successfully started."
    }
}

LogMessage -message "END CI script for $appName, branch $branchName, environment $environment."