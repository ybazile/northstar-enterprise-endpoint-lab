Import-Module ActiveDirectory

$GroupsDN = "OU=Groups,OU=Northstar,DC=corp,DC=northstar,DC=test"

function Ensure-ADGroup {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("Global","DomainLocal")]
        [string]$Scope,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $ExistingGroup = Get-ADGroup `
        -Filter "SamAccountName -eq '$Name'" `
        -ErrorAction SilentlyContinue

    if ($ExistingGroup) {
        Write-Host "[EXISTS] $Name"
    }
    else {
        New-ADGroup `
            -Name $Name `
            -SamAccountName $Name `
            -GroupCategory Security `
            -GroupScope $Scope `
            -Path $GroupsDN `
            -Description $Description

        Write-Host "[CREATED] $Name"
    }
}

function Ensure-GroupMembership {
    param (
        [Parameter(Mandatory)]
        [string]$MemberGroup,

        [Parameter(Mandatory)]
        [string]$TargetGroup
    )

    $Member = Get-ADGroup -Identity $MemberGroup
    $Target = Get-ADGroup -Identity $TargetGroup

    $AlreadyMember = Get-ADGroupMember -Identity $Target |
        Where-Object {
            $_.DistinguishedName -eq $Member.DistinguishedName
        }

    if ($AlreadyMember) {
        Write-Host "[MEMBERSHIP EXISTS] $MemberGroup -> $TargetGroup"
    }
    else {
        Add-ADGroupMember `
            -Identity $TargetGroup `
            -Members $MemberGroup

        Write-Host "[MEMBERSHIP CREATED] $MemberGroup -> $TargetGroup"
    }
}

# ---------------------------------------------------------
# Northstar Business Solutions
# Enterprise Security Group / RBAC Model
# ---------------------------------------------------------

$Groups = @(

    # Department Global Groups
    @{
        Name = "GG-FIN-Users"
        Scope = "Global"
        Description = "Finance department employee accounts"
    },

    @{
        Name = "GG-HR-Users"
        Scope = "Global"
        Description = "Human Resources employee accounts"
    },

    @{
        Name = "GG-SALES-Users"
        Scope = "Global"
        Description = "Sales department employee accounts"
    },

    @{
        Name = "GG-OPS-Users"
        Scope = "Global"
        Description = "Operations department employee accounts"
    },

    @{
        Name = "GG-IT-Users"
        Scope = "Global"
        Description = "Information Technology employee accounts"
    },

    # Enterprise / IT Role Groups
    @{
        Name = "GG-All-Employees"
        Scope = "Global"
        Description = "All Northstar Business Solutions employees"
    },

    @{
        Name = "GG-IT-Helpdesk"
        Scope = "Global"
        Description = "IT support personnel with delegated support permissions"
    },

    @{
        Name = "GG-IT-EndpointAdmins"
        Scope = "Global"
        Description = "IT personnel responsible for endpoint administration"
    },

    # Resource Permission Groups
    @{
        Name = "DL-FIN-Share-RW"
        Scope = "DomainLocal"
        Description = "Read/write access to Finance departmental resources"
    },

    @{
        Name = "DL-HR-Share-RW"
        Scope = "DomainLocal"
        Description = "Read/write access to Human Resources departmental resources"
    },

    @{
        Name = "DL-SALES-Share-RW"
        Scope = "DomainLocal"
        Description = "Read/write access to Sales departmental resources"
    },

    @{
        Name = "DL-OPS-Share-RW"
        Scope = "DomainLocal"
        Description = "Read/write access to Operations departmental resources"
    },

    @{
        Name = "DL-IT-Share-RW"
        Scope = "DomainLocal"
        Description = "Read/write access to IT departmental resources"
    },

    @{
        Name = "DL-Common-Share-R"
        Scope = "DomainLocal"
        Description = "Read access to common Northstar corporate resources"
    },

    @{
        Name = "DL-Workstation-LocalAdmins"
        Scope = "DomainLocal"
        Description = "Authorized administrative access to Northstar workstations"
    }
)

foreach ($Group in $Groups) {
    Ensure-ADGroup `
        -Name $Group.Name `
        -Scope $Group.Scope `
        -Description $Group.Description
}

# ---------------------------------------------------------
# Department groups -> All Employees
# ---------------------------------------------------------

$DepartmentGroups = @(
    "GG-FIN-Users",
    "GG-HR-Users",
    "GG-SALES-Users",
    "GG-OPS-Users",
    "GG-IT-Users"
)

foreach ($DepartmentGroup in $DepartmentGroups) {
    Ensure-GroupMembership `
        -MemberGroup $DepartmentGroup `
        -TargetGroup "GG-All-Employees"
}

# ---------------------------------------------------------
# AGDLP Resource Access
# ---------------------------------------------------------

Ensure-GroupMembership `
    -MemberGroup "GG-FIN-Users" `
    -TargetGroup "DL-FIN-Share-RW"

Ensure-GroupMembership `
    -MemberGroup "GG-HR-Users" `
    -TargetGroup "DL-HR-Share-RW"

Ensure-GroupMembership `
    -MemberGroup "GG-SALES-Users" `
    -TargetGroup "DL-SALES-Share-RW"

Ensure-GroupMembership `
    -MemberGroup "GG-OPS-Users" `
    -TargetGroup "DL-OPS-Share-RW"

Ensure-GroupMembership `
    -MemberGroup "GG-IT-Users" `
    -TargetGroup "DL-IT-Share-RW"

Ensure-GroupMembership `
    -MemberGroup "GG-All-Employees" `
    -TargetGroup "DL-Common-Share-R"

# Endpoint administration
Ensure-GroupMembership `
    -MemberGroup "GG-IT-EndpointAdmins" `
    -TargetGroup "DL-Workstation-LocalAdmins"

Write-Host ""
Write-Host "Northstar security group and RBAC structure completed successfully."
