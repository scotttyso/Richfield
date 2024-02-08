# Active Directory
Module to Add Users to Active Directory

## password.ps1
Run this script to generate encrypted user passwords

## ad_add_usrs.ps1

Script to Add Users to Active Directory and to the necessary Security Groups.

Requires two input files

### Excel spreadsheet `user_import.xlsx`

Each Row contains the User Data for Import.  Use the `password.ps1` to generate user passwords.

### YAML file `groups.yaml`

Example here shows the top level `AccountType` as called out in the spreadsheet, and then for those account types the security groups to add to the users.  The `user` field in the YAML file is an empty list that is populated as the script runs through the loop to then assign to the users.  You can update the `AccountType` field in the excel spreadsheet for your use case but this worked for our lab.

An Example to run the script

```powershell
.\ad_add_users.ps1 -wb $HOME\user_import.xlsx -y $HOME\groups.yaml
```