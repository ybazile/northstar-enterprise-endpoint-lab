param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)


Import-Module ActiveDirectory

$DomainDN  = "DC=corp,DC=northstar,DC=test"
$UPNSuffix = "corp.northstar.test"
$LogFolder = "C:\NorthstarLab\Logs"

# Create log directory if needed
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$LogFile = Join-Path $LogFolder "UserProvisioning-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"

    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry
}

# Department -> OU and Global Group mapping
$DepartmentMap = @{
    "Finance" = @{
        OU    = "OU=Finance,OU=Users,OU=Northstar,$DomainDN"
        Group = "GG-FIN-Users"
    }

    "Human Resources" = @{
        OU    = "OU=Human Resources,OU=Users,OU=Northstar,$DomainDN"
        Group = "GG-HR-Users"
    }

    "Sales" = @{
        OU    = "OU=Sales,OU=Users,OU=Northstar,$DomainDN"
        Group = "GG-SALES-Users"
    }

    "Operations" = @{
        OU    = "OU=Operations,OU=Users,OU=Northstar,$DomainDN"
        Group = "GG-OPS-Users"
    }

    "IT" = @{
        OU    = "OU=IT,OU=Users,OU=Northstar,$DomainDN"
        Group = "GG-IT-Users"
    }
}

function Get-UniqueSamAccountName {
    param (
        [string]$FirstName,
        [string]$LastName
    )

    # Example: Maya Johnson -> mjohnson
    $BaseName = (
        $FirstName.Substring(0,1) + $LastName
    ).ToLower() -replace '[^a-z0-9]', ''

    # sAMAccountName maximum is 20 characters
    if ($BaseName.Length -gt 20) {
        $BaseName = $BaseName.Substring(0,20)
    }

    $Candidate = $BaseName
    $Counter = 1

    while (Get-ADUser -Filter "SamAccountName -eq '$Candidate'" -ErrorAction SilentlyContinue) {

        $Suffix = $Counter.ToString()

        $MaxBaseLength = 20 - $Suffix.Length

        if ($BaseName.Length -gt $MaxBaseLength) {
            $TrimmedBase = $BaseName.Substring(0,$MaxBaseLength)
        }
        else {
            $TrimmedBase = $BaseName
        }

        $Candidate = "$TrimmedBase$Suffix"
        $Counter++
    }

    return $Candidate
}

# ---------------------------------------------------------
# Preflight validation
# ---------------------------------------------------------

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$Users = Import-Csv $CsvPath

$RequiredColumns = @(
    "EmployeeID",
    "FirstName",
    "LastName",
    "Department",
    "Title",
    "Office"
)

foreach ($Column in $RequiredColumns) {

    if ($Column -notin $Users[0].PSObject.Properties.Name) {
        throw "Required CSV column missing: $Column"
    }
}

# Verify department OUs and groups exist before provisioning
foreach ($Department in $DepartmentMap.Keys) {

    $OU = $DepartmentMap[$Department].OU
    $Group = $DepartmentMap[$Department].Group

    if (-not (Get-ADOrganizationalUnit -Identity $OU -ErrorAction SilentlyContinue)) {
        throw "Required OU does not exist: $OU"
    }

    if (-not (Get-ADGroup -Identity $Group -ErrorAction SilentlyContinue)) {
        throw "Required security group does not exist: $Group"
    }
}

Write-Log "Preflight validation completed successfully."
Write-Log "CSV contains $($Users.Count) employee record(s)."

$InitialPassword = $null

# ---------------------------------------------------------
# User provisioning
# ---------------------------------------------------------

foreach ($User in $Users) {

    try {

        $EmployeeID = $User.EmployeeID.Trim()
        $FirstName  = $User.FirstName.Trim()
        $LastName   = $User.LastName.Trim()
        $Department = $User.Department.Trim()
        $Title      = $User.Title.Trim()
        $Office     = $User.Office.Trim()

        if (-not $DepartmentMap.ContainsKey($Department)) {
            Write-Log "Unsupported department for EmployeeID ${EmployeeID}: $Department" "ERROR"
            continue
        }

        # EmployeeID is our primary duplicate check
        $ExistingEmployee = Get-ADUser `
            -Filter "EmployeeID -eq '$EmployeeID'" `
            -ErrorAction SilentlyContinue

        if ($ExistingEmployee) {
            Write-Log "SKIPPED $EmployeeID - employee already exists as $($ExistingEmployee.SamAccountName)" "WARN"
            continue
        }
	if ($null -eq $InitialPassword) {
    	$InitialPassword = Read-Host `
        "Enter the temporary password for the new accounts" `
        -AsSecureString
	}

        $SamAccountName = Get-UniqueSamAccountName `
            -FirstName $FirstName `
            -LastName $LastName

        $UPN = "$SamAccountName@$UPNSuffix"
        $DisplayName = "$FirstName $LastName"

        $TargetOU = $DepartmentMap[$Department].OU
        $TargetGroup = $DepartmentMap[$Department].Group

        New-ADUser `
            -Name $DisplayName `
            -GivenName $FirstName `
            -Surname $LastName `
            -DisplayName $DisplayName `
            -SamAccountName $SamAccountName `
            -UserPrincipalName $UPN `
            -EmployeeID $EmployeeID `
            -Department $Department `
            -Title $Title `
            -Office $Office `
            -Path $TargetOU `
            -AccountPassword $InitialPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Add-ADGroupMember `
            -Identity $TargetGroup `
            -Members $SamAccountName

        Write-Log "CREATED $EmployeeID | $SamAccountName | $DisplayName | $Department | $TargetGroup"
    }
    catch {
        Write-Log "FAILED EmployeeID $($User.EmployeeID): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "User provisioning process completed."
Write-Host ""
Write-Host "Log file: $LogFile"
