$pmatch = $false
While ($pmatch -eq $false) {
    $p1 = Read-Host -Prompt "Please Enter the Password to Enter for Obfuscation" -MaskInput
    $p2 = Read-Host -Prompt "Please Re-Enter the Password to Enter for Obfuscation" -MaskInput
    if ($p1 -eq $p2) { $pmatch = $true
    } else { Write-Host "Passwords Didn't Match.  Please Re-Enter" -ForegroundColor Yellow }
}
$password = ConvertTo-SecureString $p1 -AsPlainText -Force
#$p3 = $password | ConvertFrom-SecureString
Write-Host "$(ConvertFrom-SecureString -SecureString $password -Key (1..16))"
#$p4 = ConvertTo-SecureString $p3
#$creds = New-Object System.Net.NetworkCredential("TestUsername", $p4, "TestDomain")
#Write-Host $creds.Password
