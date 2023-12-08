# PowerShell Script to Audit System Information

# Define the path for the output file on the Desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$outputFile = Join-Path $desktopPath "SystemAuditReport.txt"

# Function to write output both to console and to file
function Write-OutputToFile {
    Param ([string]$output)
    Write-Output $output
    Add-Content -Path $outputFile -Value $output
}

# Get the computer name
$computerName = $env:COMPUTERNAME
Write-OutputToFile "Computer Name: $computerName"

# Get Operating System Information
$os = Get-CimInstance Win32_OperatingSystem
Write-OutputToFile "Operating System: $($os.Caption)"
Write-OutputToFile "OS Architecture: $($os.OSArchitecture)"
Write-OutputToFile "OS Version: $($os.Version)"

# Get CPU Information
$cpu = Get-CimInstance Win32_Processor
Write-OutputToFile "CPU: $($cpu.Name)"
Write-OutputToFile "Cores: $($cpu.NumberOfCores)"
Write-OutputToFile "Logical Processors: $($cpu.NumberOfLogicalProcessors)"

# Get Memory Information
$mem = Get-CimInstance Win32_PhysicalMemory
$totalMem = ($mem | Measure-Object -Property Capacity -Sum).Sum / 1GB
Write-OutputToFile "Total Memory: ${totalMem}GB"

# Get Disk Information
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
foreach ($disk in $disks) {
    $size = [math]::round($disk.Size / 1GB, 2)
    $freeSpace = [math]::round($disk.FreeSpace / 1GB, 2)
    Write-OutputToFile "Disk $($disk.DeviceID): Size = ${size}GB, Free Space = ${freeSpace}GB"
}

# Inform the user about the output file location
Write-Host "Audit information saved to $outputFile"
