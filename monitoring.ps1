# Get the paths for the server file and log folder
$counterSet = "\Processor(_Total)\% Processor Time", "\Memory\Available MBytes", "\LogicalDisk(_Total)\% Disk Time", "\Network Interface(*)\Bytes Total/sec"
$servers = Import-Csv "C:\Users\dcasey\Documents\Work-Programming\Powershell\server-monitoring\data\servers.csv" | Select-Object -ExpandProperty Name
$logPath = "C:\Users\dcasey\Documents\Work-Programming\Powershell\server-monitoring\data\logs"

# Prompt the user to enter the Microsoft Teams webhook URL and recipient
# $teamsWebhookUrl = Read-Host "Enter the Microsoft Teams webhook URL"
# $teamsRecipient = Read-Host "Enter the Microsoft Teams recipient"

# Start an infinite loop to continuously monitor the servers
while($true) {

    # Create an empty array to hold the performance data for each server
    $data = @()

    # Iterate through each server in the list and get its performance data
    foreach($server in $servers) {

        # Create an ordered dictionary to hold the performance data for the current server
        $record = [ordered]@{
            Timestamp = Get-Date
            Server = $server
            CPU = $null
            Memory = $null
            Disk = $null
            Network = $null
        }

        # Get the performance counters for the current server
        $counter = Get-Counter -ComputerName $server -Counter $counterSet -ErrorAction SilentlyContinue
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
        # if ($record['Disk'] -gt 80 -or $record['Network'] -gt 80) {
        #     $message = "Server $($record['Server']) has exceeded 80% $($(if ($record['Disk'] -gt 80) { 'disk time' } else { 'network utilization' }))!"
        #     $payload = @{
        #         "@type" = "MessageCard"
        #         "title" = "SERVER PERFORMANCE ALERT"
        #         "text" = $message
        #     }

        #     $body = ConvertTo-Json @($payload)
        #     Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $body

        #     Write-Host "Alert sent: $message"
        # }
    }

    # Save csv each day 
    $logFile = Join-Path -Path $logPath -ChildPath "PerformanceData_$(Get-Date -Format 'yyyy-MM-dd').csv"
    $data | Export-Csv -Path $logFile -NoTypeInformation -Append

    # Delete log files older than 7 days
    $oldLogs = Get-ChildItem -Path $logPath -Recurse -File | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)}
    $oldLogs | Remove-Item -Force

    Start-Sleep -Seconds 10
}