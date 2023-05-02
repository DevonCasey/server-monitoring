Write-Host "Loading the list of servers from servers.csv..."
$counterSet = "\Processor(_Total)\% Processor Time", "\Memory\Available MBytes", "\LogicalDisk(_Total)\% Disk Time", "\Network Interface(*)\Bytes Total/sec"
$csvFile = Import-Csv "./data/servers.csv"
$logPath = "./data/logs"

# $teamsWebhookUrl = Read-Host "Enter the Microsoft Teams webhook URL"
# teamsRecipient = Read-Host "Enter the Microsoft Teams recipient"

while($true) {
    $data = @()

    foreach($server in $csvFile) {
        $record = [ordered]@{
            Timestamp = Get-Date
            Server = $server.Name
            CPU = $null
            Memory = $null
            Disk = $null
            Network = $null
        }

        $counter = Get-Counter -ComputerName $server.Name -Counter $counterSet -ErrorAction SilentlyContinue
        $counterArray = $counter.CounterSamples | Select-Object -ExpandProperty CookedValue
        $record['CPU'] = [Math]::Round($counterArray[0], 4)
        $record['Memory'] = [Math]::Round($counterArray[1], 4)
        $record['Disk'] = [Math]::Round($counterArray[2], 4)
        $record['Network'] = [Math]::Round($counterArray[3], 4)

        Write-Host "==================================="
        Write-Host "Server: $($record['Server'])"
        Write-Host "==================================="
        Write-Host "CPU Usage: $($record['CPU'])%"
        Write-Host "Memory Available: $($record['Memory']) MB"
        Write-Host "Disk Time: $($record['Disk'])%"
        Write-Host "Network Utilization: $($record['Network']) bytes/sec"

        $data += New-Object psobject -Property $record

        # Check if disk time or network utilization is above 80%
        if ($record['Disk'] -gt 80 -or $record['Network'] -gt 80) {
            $message = "Server $($record['Server']) has exceeded 80% $($(if ($record['Disk'] -gt 80) { 'disk time' } else { 'network utilization' }))!"
            $payload = @{
                "@type" = "MessageCard"
                "title" = "Server Performance Alert"
                "text" = $message
            }

            $body = ConvertTo-Json @($payload)
            Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $body

            Write-Host "Alert sent: $message"
        }
    }

    $logFile = Join-Path -Path $logPath -ChildPath "PerformanceData_$(Get-Date -Format 'yyyy-MM-dd').csv"
    $data | Export-Csv -Path $logFile -NoTypeInformation -Append

    Start-Sleep -Seconds 10
}