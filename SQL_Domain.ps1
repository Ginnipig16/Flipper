# Check if the SQLServer module is installed, and install it if not
if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    Install-Module -Name SqlServer -Force -Scope CurrentUser
}
# Check if the ActiveDirectory module is available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    # Install the RSAT tools including the ActiveDirectory module (Windows 10 version 1809 and newer)
    try {
        # This requires administrative privileges
        Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -ErrorAction Stop
        Write-Host "Active Directory module installed successfully." -ForegroundColor Green
    } catch {
        throw "Failed to install the Active Directory module. Error: $_"
    }
}

# Import the ActiveDirectory module
Import-Module ActiveDirectory

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
            # Check if the computer object already exists in AD
            $existingComputer = Get-ADComputer -Filter "Name -eq '$intendedComputerName'" -ErrorAction SilentlyContinue
            if ($existingComputer) {
                # If it exists, remove it
                Remove-ADComputer -Identity $existingComputer.DistinguishedName -Credential $credential -Confirm:$false -ErrorAction Stop
                Write-Host "Removed existing AD object with name $intendedComputerName." -ForegroundColor Green
            }
        
            # Proceed to add the computer to the domain and OU
            Add-Computer -DomainName $domain -Credential $credential -OUPath $ouPath -NewName $intendedComputerName -Force -Confirm:$false -ErrorAction Stop
            Write-Host "Computer $intendedComputerName has been added to the domain $domain and placed in OU $ouPath." -ForegroundColor Green
        
            # Add the computer to the AD group
            Add-ADGroupMember -Identity $groupName -Members "$intendedComputerName`$" -Credential $credential -ErrorAction Stop
            Write-Host "Computer $intendedComputerName has been added to the group $groupName." -ForegroundColor Green
        
            # Restart the computer to apply changes
            Restart-Computer -Force
        } catch {
            throw "Failed to process AD operations. Error: $_"
        }
} else {
    throw "No matching device found. Likely a Serial number mismatch."
}
