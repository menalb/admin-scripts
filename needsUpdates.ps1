$machines = @("...")
Function CheckUpdates() {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateupdateSearcher()
    $Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
    $Updates | Select-Object Title
}

Function ShowUpdatesStatus {
    param([string]$machineName)
    Write-Host $machineName
    Invoke-Command -ComputerName $machineName -ScriptBlock ${Function:CheckUpdates}
}

$machines | ForEach-Object { ShowUpdatesStatus $_ }