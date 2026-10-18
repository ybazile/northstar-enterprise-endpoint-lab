$OutputPath = "C:\NorthstarLab\Data\employees.csv"

$DataFolder = Split-Path $OutputPath

if (-not (Test-Path $DataFolder)) {
    New-Item -Path $DataFolder -ItemType Directory -Force | Out-Null
}

# ---------------------------------------------------------
# Existing validated employees
# ---------------------------------------------------------

$Employees = @(
    [PSCustomObject]@{
        EmployeeID = "NS1001"
        FirstName  = "Maya"
        LastName   = "Johnson"
        Department = "Finance"
        Title      = "Financial Analyst"
        Office     = "HQ"
    }

    [PSCustomObject]@{
        EmployeeID = "NS1002"
        FirstName  = "Marcus"
        LastName   = "Reed"
        Department = "Sales"
        Title      = "Account Executive"
        Office     = "HQ"
    }

    [PSCustomObject]@{
        EmployeeID = "NS1003"
        FirstName  = "Aaliyah"
        LastName   = "Brooks"
        Department = "IT"
        Title      = "Endpoint Support Specialist"
        Office     = "HQ"
    }
)

# ---------------------------------------------------------
# Fictional employee name pools
# ---------------------------------------------------------

$FirstNames = @(
    "Aaron","Brianna","Carlos","Danielle","Ethan",
    "Fatima","Gabriel","Hannah","Isaiah","Jasmine",
    "Kevin","Lauren","Malik","Nadia","Olivia",
    "Peter","Quentin","Renee","Samuel","Tiana",
    "Andre","Bianca","Cameron","Destiny","Elijah",
    "Farah","Grant","Hailey","Ian","Jada",
    "Kyle","Leah","Miles","Naomi","Owen",
    "Priya","Rafael","Sabrina","Trevor","Vanessa",
    "Adrian","Camille","Darius","Elena","Jordan",
    "Kiara","Micah","Natalie","Roman","Zoe"
)

$LastNames = @(
    "Carter","Davis","Edwards","Foster","Garcia",
    "Harris","Jackson","Kim","Lewis","Mitchell",
    "Nelson","Owens","Parker","Ramirez","Scott",
    "Turner","Walker","Young","Allen","Bennett",
    "Collins","Diaz","Evans","Flores","Green",
    "Hill","Ingram","Jenkins","King","Lopez",
    "Morgan","Nguyen","Ortiz","Price","Roberts",
    "Sanchez","Taylor","Ward","Williams","Adams",
    "Bailey","Clark","Gomez","Howard","James",
    "Kelly","Martin","Reynolds","Stewart","Thomas"
)

# ---------------------------------------------------------
# Build a deterministic mixed-name pool
#
# This deliberately rotates surnames so employees are not
# generated in artificial blocks such as 20 Carters followed
# by 20 Davises.
# ---------------------------------------------------------

$NamePool = @()

for ($i = 0; $i -lt 197; $i++) {

    $FirstIndex = $i % $FirstNames.Count

    # The multiplier 17 mixes surname distribution.
    # The block offset prevents repeated first/last combinations.
    $Block = [math]::Floor($i / $FirstNames.Count)
    $LastIndex = (($i * 17) + $Block) % $LastNames.Count

    $NamePool += [PSCustomObject]@{
        FirstName = $FirstNames[$FirstIndex]
        LastName  = $LastNames[$LastIndex]
    }
}

# ---------------------------------------------------------
# Remaining headcount
#
# Final company totals:
# Sales             70
# Operations        60
# Finance           30
# Human Resources   20
# IT                20
# ---------------------------------------------------------

$DepartmentPlan = @(
    [PSCustomObject]@{
        Department = "Sales"
        Count      = 69
        Titles     = @(
            "Account Executive",
            "Sales Development Representative",
            "Account Manager",
            "Sales Operations Specialist",
            "Regional Sales Representative"
        )
    }

    [PSCustomObject]@{
        Department = "Operations"
        Count      = 60
        Titles     = @(
            "Operations Coordinator",
            "Operations Analyst",
            "Logistics Coordinator",
            "Inventory Specialist",
            "Business Operations Specialist"
        )
    }

    [PSCustomObject]@{
        Department = "Finance"
        Count      = 29
        Titles     = @(
            "Financial Analyst",
            "Accounts Payable Specialist",
            "Accounts Receivable Specialist",
            "Staff Accountant",
            "Payroll Analyst"
        )
    }

    [PSCustomObject]@{
        Department = "Human Resources"
        Count      = 20
        Titles     = @(
            "HR Coordinator",
            "HR Generalist",
            "Talent Acquisition Specialist",
            "Benefits Specialist",
            "Learning and Development Coordinator"
        )
    }

    [PSCustomObject]@{
        Department = "IT"
        Count      = 19
        Titles     = @(
            "Endpoint Support Specialist",
            "Systems Support Technician",
            "Junior Systems Administrator",
            "IT Support Specialist",
            "Service Desk Analyst"
        )
    }
)

$NextEmployeeID = 1004
$NameIndex = 0

foreach ($DepartmentInfo in $DepartmentPlan) {

    for ($i = 0; $i -lt $DepartmentInfo.Count; $i++) {

        $Name = $NamePool[$NameIndex]

        $Title = $DepartmentInfo.Titles[
            $i % $DepartmentInfo.Titles.Count
        ]

        $Employees += [PSCustomObject]@{
            EmployeeID = "NS{0:D4}" -f $NextEmployeeID
            FirstName  = $Name.FirstName
            LastName   = $Name.LastName
            Department = $DepartmentInfo.Department
            Title      = $Title
            Office     = "HQ"
        }

        $NextEmployeeID++
        $NameIndex++
    }
}

# ---------------------------------------------------------
# Validation
# ---------------------------------------------------------

if ($Employees.Count -ne 200) {
    throw "Expected 200 employees but found $($Employees.Count)."
}

$ExpectedCounts = @{
    "Sales"           = 70
    "Operations"      = 60
    "Finance"         = 30
    "Human Resources" = 20
    "IT"              = 20
}

foreach ($Department in $ExpectedCounts.Keys) {

    $ActualCount = @(
        $Employees | Where-Object Department -eq $Department
    ).Count

    if ($ActualCount -ne $ExpectedCounts[$Department]) {
        throw "Department count failed for $Department. Expected $($ExpectedCounts[$Department]), found $ActualCount."
    }
}

$DuplicateIDs = $Employees |
    Group-Object EmployeeID |
    Where-Object Count -gt 1

if ($DuplicateIDs) {
    throw "Duplicate EmployeeIDs detected."
}

$DuplicateNames = $Employees |
    Group-Object FirstName,LastName |
    Where-Object Count -gt 1

if ($DuplicateNames) {
    throw "Duplicate employee names detected."
}

$ExpectedIDs = 1001..1200 |
    ForEach-Object { "NS{0:D4}" -f $_ }

$IDDifference = Compare-Object `
    ($ExpectedIDs | Sort-Object) `
    ($Employees.EmployeeID | Sort-Object)

if ($IDDifference) {
    throw "EmployeeID sequence NS1001 through NS1200 is incomplete."
}

# ---------------------------------------------------------
# Export
# ---------------------------------------------------------

$Employees |
    Export-Csv `
        -Path $OutputPath `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "Employee dataset generated successfully."
Write-Host "File: $OutputPath"
Write-Host "Total employees: $($Employees.Count)"
Write-Host ""

$Employees |
    Group-Object Department |
    Sort-Object Name |
    Select-Object Name,Count |
    Format-Table -AutoSize

Write-Host "First 20 records:"
Write-Host ""

$Employees |
    Select-Object -First 20 |
    Format-Table EmployeeID,FirstName,LastName,Department,Title -AutoSize
