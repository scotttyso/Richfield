param (
    [string]$wb=$(throw "-wb <path_for_workbook.xlsx> is required."),
    [string]$y=$(throw "-y <path_for_groups.yaml> is required.")
)
#=============================================================================
# Import/Install PowerShell Required Modules
#=============================================================================
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
#$computer = Get-ComputerInfo
#$computer_name = $computer.CsDNSHostName
$win_version = (Get-WmiObject -class Win32_OperatingSystem).Caption
if ($win_version -like "*Windows 11*") {
    $required_modules = @("ActiveDirectory\RSAT: Active Directory Domain Services and Lightweight Directory Services Tools")
    $get_win_capabilities = Get-WindowsCapability -Name RSAT* -Online
    foreach ($rm in $required_modules) {
        $mod = $get_win_capabilities | Where-Object {$_.DisplayName -eq "$($rm.Split("\")[1])"}
        if ($mod.State -eq "NotPresent") {
            Write-Host " * $($computer_name) Installing $($mod.Name)." -ForegroundColor Green
            Add-WindowsCapability -online -Name "$($mod.Name)"
            Import-Module $rm.Split("\")[0]
        } else {
            Write-Host " * $($computer_name) $($mod.Name) Already Installed." -ForegroundColor Cyan
            Import-Module $rm.Split("\")[0]
        }
    }
} elseif ($win_version -like "*Windows Server 2022*") {
    $required_modules = @("ActiveDirectory\RSAT-AD-PowerShell")
    $get_win_features = Get-WindowsFeature
    foreach ($rm in $required_modules) {
        $mod = $get_win_features | Where-Object {$_.Name -eq "RSAT-AD-PowerShell"}
        if ($mod.InstallState -eq "Available") {
            Write-Host " * $($computer_name) Installing $($mod.Name)." -ForegroundColor Green
            Install-WindowsFeature $mod.Name
            Import-Module $rm.Split("\")[0]
        } else {
            Write-Host " * $($computer_name) $($mod.Name) Already Installed." -ForegroundColor Cyan
            Import-Module $rm.Split("\")[0]
        }
    }
} else { Write-Host "DIDNT MATCH $win_version"; exit }
$get_modules = Get-Module -ListAvailable
$required_modules = @("ImportExcel", "powershell-yaml")
foreach ($rm in $required_modules) {
    if (!($get_modules | Where-Object {$_.Name -eq $rm})) {
        Write-Host " * $($computer_name) Installing $rm." -ForegroundColor Green
        Install-Module $rm -AllowClobber -Confirm:$False -Force
        Import-Module $rm
    } else {
        Write-Host " * $($computer_name) $rm Already Installed." -ForegroundColor Cyan
        Import-Module $rm
    }
}

# Define UPN
$UPN = "rich.ciscolabs.com"
$workbook = Import-Excel $wb
$Global:ydata   = Get-Content -Path $y | ConvertFrom-Yaml
foreach ($row in $workbook) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($row.Username)'") {
        Write-Warning "A user account '$($row.Username)' already exists in Active Directory."
    }
    else {
        # User does not exist then proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        Write-Host $row.Password
        $password = $row.Password | ConvertTo-SecureString -Key (1..16)
        New-ADUser `
            -SamAccountName $row.Username `
            -UserPrincipalName "$($row.Username)@$UPN" `
            -Name "$($row.FirstName) $($row.LastName)" `
            -GivenName $row.FirstName `
            -Surname $row.LastName `
            -Initials $row.Initials `
            -Enabled $True `
            -DisplayName "$($row.FirstName) $($row.LastName)" `
            -Path $row.OU `
            -City $row.City `
            -PostalCode $row.ZipCode `
            -Country $row.Country `
            -Company $row.Company `
            -State $row.State `
            -StreetAddress $row.StreetAddress `
            -OfficePhone $row.Telephone `
            -EmailAddress $row.Email `
            -Title $row.JobTitle `
            -Department $row.Department `
            -AccountPassword $password -ChangePasswordAtLogon $False
        $Global:ydata[$row.AccountType].users.Add($row.Username)
        # If user is created, show message.
        Write-Host "The user account '$($row.Username)' is created." -ForegroundColor Cyan
    }
}
$Global:ydata.GetEnumerator() | ForEach-Object {
    Write-Host $_.Key
    if ($_.Value.users -gt 1) {
        Write-Host "Adding $($_.Value.users)" -ForegroundColor Cyan
        Write-Host "To: $($_.Value.groups)" -ForegroundColor Cyan
        foreach ($group in $_.Value.groups) {
            Write-Host $group
            Write-Host $_.Value.users
            Add-AdGroupMember -Identity $group -Members $_.Value.users
        }
    }
}
