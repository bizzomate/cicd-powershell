function LogMessage () {
    param(
        [Parameter(Mandatory=$true)][string]$message,
        [ValidateSet("INFO", "WARNING", "ERROR")][string]$type="INFO"
    )

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $output = "$date $type - $message"
    
    Write-output $output
}

