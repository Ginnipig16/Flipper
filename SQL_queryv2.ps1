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
if ($results) {
    $deviceName = $results.$columnName
    # Copy the device name to clipboard
    Set-Clipboard -Value $deviceName

       # Domain Join Logic
    $domain = "templestowe-co.wan"
    $domainUsername = "administrator"
    $domainPassword = "1mp0rtant"
    $credential = New-Object System.Management.Automation.PSCredential($domainUsername, $domainPassword)
    $computerName = Get-Clipboard # Assuming the new computer name is now on the clipboard
    Add-Computer -DomainName $domain -Credential $credential -NewName $computerName -Force -Restart -Confirm:$false
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
