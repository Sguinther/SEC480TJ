
function ActiveDirectory-Install(){
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart

    # Set up a new forest
    $DomainName = "blue1.local"
    $DomainNetBIOSName = "blue1"
    $SafeModePassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
    $InstallCredential = Get-Credential -Message "Enter credentials with domain installation rights"

    Install-ADDSForest -DomainName $DomainName -DomainNetBIOSName $DomainNetBIOSName -SafeModeAdministratorPassword $SafeModePassword -InstallDns -Force:$true -Credential $InstallCredential

    # Promote the server to a domain controller
    $DCPromoCredential = Get-Credential -Message "Enter credentials with domain promotion rights"

    Install-ADDSDomainController -NoGlobalCatalog:$false -InstallDns:$true -Credential $DCPromoCredential -Force:$true



    # Create Organizational Units
    New-ADOrganizationalUnit -Name "480Users" -Path "DC=blue1,DC=local"
    New-ADOrganizationalUnit -Name "480Other" -Path "DC=blue1,DC=local"

    # Create users
    $UserCredential = Get-Credential -Message "Enter credentials for creating users"

    New-ADUser -Name "sam guinther" -GivenName "sam" -Surname "guinther" -SamAccountName "sam" -UserPrincipalName "jsmith@blue1.local" -Enabled $true -AccountPassword (ConvertTo-SecureString -String "password" -AsPlainText -Force) -Path "OU=480Misc,DC=blue1,DC=local" -Credential $UserCredential
    
} 
# Install required roles and features
