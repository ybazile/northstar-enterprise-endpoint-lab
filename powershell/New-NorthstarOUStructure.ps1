Import-Module ActiveDirectory

$DomainDN = "DC=corp,DC=northstar,DC=test"

function Ensure-OU {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Description
    )

    $ExistingOU = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$Name'" `
        -SearchBase $Path `
        -SearchScope OneLevel `
        -ErrorAction SilentlyContinue

    if ($ExistingOU) {
        Write-Host "[EXISTS] $Name"
    }
    else {
        New-ADOrganizationalUnit `
            -Name $Name `
            -Path $Path `
            -Description $Description `
            -ProtectedFromAccidentalDeletion $true

        Write-Host "[CREATED] $Name"
    }
}

# ---------------------------------------------------------
# Northstar Business Solutions
# Enterprise Active Directory OU Structure
# ---------------------------------------------------------

Ensure-OU `
    -Name "Northstar" `
    -Path $DomainDN `
    -Description "Northstar Business Solutions managed objects"

$NorthstarDN = "OU=Northstar,$DomainDN"

$TopLevelOUs = @(
    @{ Name = "Users";            Description = "Standard Northstar employee user accounts" },
    @{ Name = "Workstations";     Description = "Northstar corporate endpoint computer objects" },
    @{ Name = "Servers";          Description = "Northstar server computer objects" },
    @{ Name = "Groups";           Description = "Northstar security and distribution groups" },
    @{ Name = "Admin Accounts";   Description = "Privileged administrative accounts" },
    @{ Name = "Service Accounts"; Description = "Application and service identities" },
    @{ Name = "Disabled Objects"; Description = "Disabled accounts and retired computer objects" }
)

foreach ($OU in $TopLevelOUs) {
    Ensure-OU `
        -Name $OU.Name `
        -Path $NorthstarDN `
        -Description $OU.Description
}

$Departments = @(
    "Finance",
    "Human Resources",
    "Sales",
    "Operations",
    "IT"
)

$UsersDN = "OU=Users,$NorthstarDN"
$WorkstationsDN = "OU=Workstations,$NorthstarDN"

foreach ($Department in $Departments) {

    Ensure-OU `
        -Name $Department `
        -Path $UsersDN `
        -Description "$Department employee accounts"

    Ensure-OU `
        -Name $Department `
        -Path $WorkstationsDN `
        -Description "$Department corporate endpoints"
}

Write-Host ""
Write-Host "Northstar OU structure completed successfully."
