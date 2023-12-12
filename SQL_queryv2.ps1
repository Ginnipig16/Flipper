# Check if the SQLServer module is installed, and install it if not
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module -Name SqlServer -Force -Scope CurrentUser
}

# Import the SQLServer module
Import-Module -Name SqlServer

# Specify your server and database names
$serverName = "tc-sql01.templestowe-co.wan"
$databaseName = "DB_TC-ICTAssets"
$tableName = "BYOD-Assets"
$columnName = "DeviceName"
$serialNumberColumn = "Serial-Number" 
$username = "ByodQuery"
$password = "1mp0rtant."

# Read the serial number from the clipboard
$serialNumber = Get-Clipboard

# Prepare the SQL query
$query = "SELECT [$columnName] FROM [$tableName] WHERE [$serialNumberColumn] = '$serialNumber'"

# Run the SQL query
$results = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query -TrustServerCertificate -Username $username -Password $password

# Check if results were returned and act accordingly
# Check if results were returned and act accordingly
if ($results) {
    $intendedComputerName = $results.$columnName

    # Domain Join Logic
    $domain = "templestowe-co.wan"
    $domainUsername = "administrator"  # Use just the username here, not UPN format
    $domainFullUsername = "$domainUsername@$domain"  # Construct the full domain\username
    $plaintextPassword = "1mp0rtant"
    $securePassword = ConvertTo-SecureString $plaintextPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainFullUsername, $securePassword)

    try {
        # Join the domain and rename the computer
        Add-Computer -DomainName $domain -Credential $credential -NewName $intendedComputerName -Force -Restart -Confirm:$false
        Write-Host "Renaming likely failed, starting sleep for 15 seconds, will attempt rename again after" -ForegroundColor Green
        Start-Sleep -Seconds 15
        
        # Set the maximum number of rename attempts
        $maxAttempts = 5
        $attemptCount = 0
        $success = $false
        
        # Loop until the computer name is changed or the maximum number of attempts is reached
        while (($env:COMPUTERNAME -ne $intendedComputerName) -and ($attemptCount -lt $maxAttempts)) {
            try {
                # Attempt to rename the computer
                Rename-Computer -NewName $intendedComputerName -Force -ErrorAction Stop
                $success = $true
                break # Exit the loop if rename is successful
            } catch {
                Write-Error "Attempt $attemptCount : Failed to rename the computer. Error: $_"
                Start-Sleep -Seconds 5 # Wait for 5 seconds before trying again
                $attemptCount++
            }
        }
        
        if ($success) {
            # If rename was successful, restart the computer
            Write-Host "The computer name has been changed to $intendedComputerName. Restarting..."
            Restart-Computer -Force
        } else {
            Write-Host "Failed to rename the computer after $maxAttempts attempts."
        }


        
    } catch {
        throw "Failed to join the domain and/or rename the computer. Error: $_"
    }
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
