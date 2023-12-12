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
    $intendedComputerName = $results.$columnName
    # Copy the intended computer name to clipboard
    Set-Clipboard -Value $intendedComputerName

    # Domain Join Logic
    $domain = "templestowe-co.wan"
    $domainUsername = "administrator@$domain"
    $plaintextPassword = "1mp0rtant"
    $securePassword = ConvertTo-SecureString $plaintextPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainUsername, $securePassword)

    # Remove the existing computer object with the same name, if it exists
    try {
        Remove-ADComputer -Identity $intendedComputerName -Credential $credential -Confirm:$false -ErrorAction Stop
    } catch {
        # Ignoring errors that occur if the computer object doesn't exist
    }

    # Attempt to join the domain with the intended name
    try {
        Add-Computer -DomainName $domain -Credential $credential -NewName $intendedComputerName -Force -Restart -Confirm:$false
    } catch {
        throw "Failed to join the domain with the name $intendedComputerName. Error: $_"
    }
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
