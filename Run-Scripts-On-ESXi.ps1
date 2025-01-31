# Define paths
$vcenterServer = "<vCenter_Server>"
$vcenterUser = "<Username>"
$vcenterPassword = "<Password>"

$scriptFolder = "C:\path\to\run-scripts"  # Folder containing scripts
$archiveFolder = "C:\path\to\run-scripts\archive"  # Folder for archived scripts
$outputFile = "C:\path\to\script_results.csv"
$logFile = "C:\path\to\run-scripts.log"

# Function to log messages
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Purge log entries older than 1 year
if (Test-Path $logFile) {
    $cutoffDate = (Get-Date).AddYears(-1)
    $logLines = Get-Content $logFile
    $filteredLines = $logLines | Where-Object { 
        $_ -match '^\d{4}-\d{2}-\d{2}' -and (Get-Date ($_ -split ' - ')[0]) -ge $cutoffDate
    }
    
    $filteredLines | Set-Content -Path $logFile
    Write-Log "Log file purged: Removed entries older than $cutoffDate."
}

Write-Log "=== Script Execution Started ==="

# Connect to vCenter
try {
    Connect-VIServer -Server $vcenterServer -User $vcenterUser -Password $vcenterPassword -ErrorAction Stop
    Write-Log "Connected to vCenter successfully."
} catch {
    Write-Log "ERROR: Failed to connect to vCenter. $_"
    exit 1
}

# Ensure the archive folder exists
if (!(Test-Path $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder | Out-Null
}

# Initialize results array
$results = @()

# Get all ESXi hosts
$hosts = Get-VMHost

foreach ($host in $hosts) {
    $hostname = $host.Name
    $username = "root"
    $password = "<ESXi_Root_Password>"

    try {
        Write-Log "Processing host: $hostname"

        # Enable SSH if not already running
        $sshService = Get-VMHostService -VMHost $host | Where-Object {$_.Key -eq "TSM-SSH"}
        if ($sshService.Running -eq $false) {
            Start-VMHostService -HostService $sshService -Confirm:$false
            Write-Log "SSH enabled on $hostname."
        }

        # Get all scripts in the "run-scripts" folder
        $scripts = Get-ChildItem -Path $scriptFolder -Filter "*.sh"

        foreach ($script in $scripts) {
            $scriptName = $script.Name
            $scriptPath = $script.FullName

            # Handle "runonce-" scripts (execute and move to archive)
            if ($scriptName -match "^runonce-") {
                Write-Log "Executing one-time script: $scriptName on $hostname..."

                # Run script and collect output
                $sshCommand = "ssh ${username}@${hostname} 'bash /tmp/$scriptName'"
                $scriptOutput = Invoke-Expression $sshCommand

                # Store results
                foreach ($line in $scriptOutput -split "`n") {
                    if ($line.Trim() -ne "") {
                        $results += [PSCustomObject]@{
                            HostName  = $hostname
                            Script    = $scriptName
                            Output    = $line.Trim()
                        }
                    }
                }

                # Move script to archive
                Move-Item -Path $scriptPath -Destination $archiveFolder
                Write-Log "Moved $scriptName to archive."

                continue  # Skip further processing for this script
            }

            # Handle scripts that should run every time
            Write-Log "Executing script: $scriptName on $hostname..."

            # Run script and collect output
            $sshCommand = "ssh ${username}@${hostname} 'bash /tmp/$scriptName'"
            $scriptOutput = Invoke-Expression $sshCommand

            # Store results
            foreach ($line in $scriptOutput -split "`n") {
                if ($line.Trim() -ne "") {
                    $results += [PSCustomObject]@{
                        HostName  = $hostname
                        Script    = $scriptName
                        Output    = $line.Trim()
                    }
                }
            }
        }

        # Disable SSH after execution
        if ($sshService.Running -eq $true) {
            Stop-VMHostService -HostService $sshService -Confirm:$false
            Write-Log "SSH disabled on $hostname."
        }

        Write-Log "Successfully processed $hostname."
    } catch {
        Write-Log "ERROR processing ${hostname}: ${_}"
    }
}

# Export results to CSV
try {
    $results | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Log "Results exported to $outputFile"
} catch {
    Write-Log "ERROR: Failed to export CSV. $_"
}

# Disconnect from vCenter
Disconnect-VIServer -Confirm:$false
Write-Log "Disconnected from vCenter."
Write-Log "=== Script Execution Completed ==="
