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

    # Rename the computer to the intended name
   
    
    

    # Domain Join Logic
    $domain = "templestowe-co.wan"
    $domainUsername = "administrator@$domain"
    $plaintextPassword = "1mp0rtant"
    $securePassword = ConvertTo-SecureString $plaintextPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainUsername, $securePassword)

    # Join the domain with the new name
    Rename-Computer -NewName $intendedComputerName -Credential $credential -Force -ErrorAction Stop
    Add-Computer -DomainName $domain -Credential $credential -Force -ErrorAction Stop
    

    # Restart the computer
    Restart-Computer -Force
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
