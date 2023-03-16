#480-AddADUser

# Set the parent OU where you want to create the new user
$ParentOU = "OU=480,DC=guinther,DC=local"

# Set the nested OU where you want to create the new user
$NestedOU = "OU=accounts,$ParentOU"

# Set the service accounts OU where you want to create the new user
$ServiceAccountsOU = "OU=serviceaccounts,$NestedOU"

# Set the user's login name and display name
$SamAccountName = "vcenterldap"
$DisplayName = "vcenterldap"

# Generate a secure password for the user
$Password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

# Create the new user in the nested OU
New-ADUser `
    -SamAccountName $SamAccountName `
    -Name $DisplayName `
    -DisplayName $DisplayName `
    -AccountPassword $Password `
    -Enabled $true `
    -Path $ServiceAccountsOU