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
        Add-Computer -DomainName $domain -Credential $credential -NewName $intendedComputerName -Force -Confirm:$false
        Write-Host "The computer is now joined to the domain and will restart." -ForegroundColor Green
        Write-Host "Starting sleep for 10 seconds, will attempt rename again after" -ForegroundColor Green
        Start-Sleep -Seconds 10
        Rename-Computer -NewName $intendedComputerName -Force -ErrorAction Stop
    } catch {
        throw "Failed to join the domain and/or rename the computer. Error: $_"
    }
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
