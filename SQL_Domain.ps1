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
    $DC = "tc-dc01.templestowe-co.wan"
    $domain = "templestowe-co.wan"
    $domainUsername = "administrator"  # Use just the username here, not UPN format
    $domainFullUsername = "$domainUsername@$domain"  # Construct the full domain\username
    $plaintextPassword = "1mp0rtant"
    $securePassword = ConvertTo-SecureString $plaintextPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainFullUsername, $securePassword)

    # Define the OU path where the computer object should be placed
    # Note: You need to provide the distinguished name (DN) of the OU.
    $ouPath = "OU=Student BYOD,OU=BYO Primary Devices,OU=ALL TC COMPUTERS,DC=templestowe-co,DC=wan"
    $groupName = "All BYO Devices"
    
    try {
        # Check if the computer object already exists in AD and remove it
        $existingComputer = Get-ADComputer -Identity $intendedComputerName -ErrorAction SilentlyContinue
        if ($existingComputer) {
            Remove-ADComputer -Identity $existingComputer -Credential $credential -Confirm:$false -ErrorAction Stop
            Write-Host "Removed existing AD object.." -ForegroundColor Green
        }
        Write-Host "Attempting to Add computer..." -ForegroundColor Green
        Add-Computer -DomainName $domain -Credential $credential -OUPath $ouPath -NewName $intendedComputerName -Force -Confirm:$false -ErrorAction Stop
        # The computer object should now exist in AD, so we can try to add it to the group.
        
        # Define the group's distinguished name (DN)
        $groupDN = "CN=All BYO Devices,OU=Groups,DC=templestowe-co,DC=wan"
        
        # Add the computer to the AD group
        Add-ADGroupMember -Identity $groupDN -Members "$intendedComputerName`$" -Credential $credential -ErrorAction Stop
        
        # Restart the computer to apply changes
        Restart-Computer -Force
    } catch {
        throw "Failed to reset the AD object, join the domain, and/or rename the computer. Error: $_"
    }
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
