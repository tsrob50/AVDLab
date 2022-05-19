###################################################################################################
# This file is a supplement to the AVD Hands-On Lab guide
# The content below is modified from Microsoft documentation located at:
# https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable
# Please refer to the Microsoft documentation for production environments
###################################################################################################

# 1. Be sure to open PowerShell with Administrator rights to run the commands below 

# 2. Connect to Azure AD
Connect-AzAccount

# 3. Download and extract the AzFilesHybrid.zip Module located at the link below
#    https://github.com/Azure-Samples/azure-files-samples/releases

# 4. Change the working PowerShell Directory to the AzFilesHybrid directory (Defaults to the download directory)
cd C:\Users\xxxxAdmin\Downloads\AzFilesHybrid

# 5. Update the variables below with your lab settings
# Update the Lab ID
$labId = "<Enter Lab ID here>"
# Update the storage account name
$StorageAccountName = "<storage-account-name-here>"

# 6. Highlight each block of commands below and right click and click Run, or use F8 to run the block of commands.
#    Select the option to run the command when prompted.
#    Verify each command runs successfully before moving to the next.


# Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

# Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid

# Login with an Azure AD credential that has either storage account owner or contributor Azure role assignment
# If you are logging into an Azure environment other than Public (ex. AzureUSGovernment) you will need to specify that.
# See https://docs.microsoft.com/azure/azure-government/documentation-government-get-started-connect-with-ps
# for more information.
Connect-AzAccount

# Define parameters
# $StorageAccountName is the name of an existing storage account that you want to join to AD
# $SamAccountName is an AD object, see https://docs.microsoft.com/en-us/windows/win32/adschema/a-samaccountname
# for more information.
# If you want to use AES256 encryption (recommended), except for the trailing '$', the storage account name must be the same as the computer object's SamAccountName.
$SubscriptionId = (Get-AzContext).Subscription.id
$ResourceGroupName = ($labId + "RG")
$SamAccountName = $StorageAccountName
$DomainAccountType = "ComputerAccount" # Default is set as ComputerAccount
# If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.
$OuDistinguishedName = "OU=" + $labId + ",OU=AVD,DC=isdomcode,DC=local"
# Specify the encryption algorithm used for Kerberos authentication. Using AES256 is recommended.
$EncryptionType = "AES256,RC4"

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

# Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
# You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
# You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
# Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -SamAccountName $SamAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName `
        -EncryptionType $EncryptionType

#Run the command below to enable AES256 encryption. If you plan to use RC4, you can skip this step.
Update-AzStorageAccountAuthForAES256 -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName

#You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
#Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose

########################################################################
# 7. The storage account is now configured for Windows AD authentication
#    Run the following commands to verify configuration
########################################################################

# Get the target storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccount
# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions
# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties