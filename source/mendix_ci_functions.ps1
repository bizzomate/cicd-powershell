$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Check if the functions script named 'mendix_ci_logging.ps1' is in place.
try {
    . ("$ScriptDirectory\mendix_ci_logging.ps1")
}
catch {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $output = "$date ERROR - Error while loading required supporting PowerShell Scripts (logging)."
    Write-output $output    
}

Function Get-Branch($headers, $url, $appName, $branchName) {
    Invoke-RestMethod -Headers $headers ${url}apps/$appName/branches/$branchName
}

Function Start-Build($headers, $url, $appName, $branchName, $revision, $version) {
    $buildinput = "{
        'Branch' = '$branchName',
        'Revision' = $revision,
        'Version' = '$version',
        'Description' = 'CI Build $((Get-Date).ToString('s'))'
    }"

    LogMessage -message "Start build with the following input: $buildinput"
    $buildResult = $buildinput | Invoke-RestMethod -Headers $headers -ContentType "application/json" -Method Post ${url}apps/$appName/packages/
    $buildResult.PackageId
}

Function Wait-For-Built($headers, $url, $appName, $packageId, $timeOutSeconds) {
   $date = Get-Date

    while($true) {
        $duration = ((Get-Date) - $date).TotalSeconds

        if($duration -gt $timeOutSeconds) {
            LogMessage -message "Build timed out after $duration"

            return $false
        }

        Start-Sleep -s 10
        $package = Get-Package $headers $url $appName $packageId

        if($package.Status -eq 'Succeeded') {
            LogMessage -message "Built package: $package"

            return $true
        }
    }
}

Function Get-Package($headers, $url, $appName, $packageId) {
    Invoke-RestMethod -Headers $headers ${url}apps/$appName/packages/$packageId
}

Function Move-Package($headers, $url, $appName, $environment, $packageId) {
    $transportInput = "{ 'PackageId' = '$packageId' }"
    LogMessage -message "Transport package with the following input: $transportInput"
    $transportInput | Invoke-RestMethod -Headers $headers -ContentType "application/json" -Method Post ${url}apps/$appName/environments/$environment/transport
}

Function Stop-App($headers, $url, $appName, $environment) {
    LogMessage -message "Stop app $appName ($environment)"
    Invoke-RestMethod -Headers $headers -Method Post ${url}apps/$appName/environments/$environment/stop
}

Function Start-App($headers, $url, $appName, $environment) {
    LogMessage -message "Start app $appName ($environment)"
    $startJob = "{ 'AutoSyncDb' = true }" | Invoke-RestMethod -Headers $headers -ContentType "application/json" -Method Post ${url}apps/$appName/environments/$environment/start
    $startJob.JobId
}

Function Get-Start-App-Status($headers, $url, $appName, $environment, $jobId) {
    Invoke-RestMethod -Headers $headers ${url}apps/$appName/environments/$environment/start/$jobId
}

Function Wait-For-Start($headers, $url, $appName, $environment, $jobId, $timeOutSeconds) {
   $date = Get-Date

    while($true) {
        $duration = ((Get-Date) - $date).TotalSeconds

        if($duration -gt $timeOutSeconds) {
            LogMessage -message "Start app timed out after $duration"

            return $false
        }

        Start-Sleep -s 10
        $startStatus = Get-Start-App-Status $headers $url $appName $environment $jobId

        if($startStatus.Status -eq 'Started') {
            return $true
        }
    }
}

Function Clear-App($headers, $url, $appName, $environment) {
    LogMessage -message "Clear app $appName ($environment)"
    Invoke-RestMethod -Headers $headers -Method Post ${url}apps/$appName/environments/$environment/clean
}