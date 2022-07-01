###################################################################################################
# This file is a supplement to the AVD Hands-On Lab guide
# The content below is modified from Microsoft documentation located at:
# https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-ad-ds-enable
# Please refer to the Microsoft documentation for production environments
###################################################################################################

# 1. Be sure to open PowerShell with Administrator rights to run the commands below 
#    Highlight each block of commands below and right click and click Run, or use F8 to run the block of commands.
#    Select the option to run the command when prompted.
#    Verify each command runs successfully before moving to the next.


# 2. Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser


# 3. Install the Azure module (delayed start)
#    Click Yes when prompted, this command can take a couple minutes to finish.  It may seem to "hang" at complete as it finishes.
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force


# 4. Connect to Azure AD, log in with the xxxxAdmin@isdomcode.com account
#    Login screen may be hidden behind the ISE window
Connect-AzAccount


# 5. Download and extract the AzFilesHybrid.zip Module located at the link below
Invoke-WebRequest -Uri https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.4/AzFilesHybrid.zip -OutFile C:\Users\$env:USERNAME\Downloads\AzFilesHybrid.zip
Expand-Archive -Path C:\Users\$env:USERNAME\Downloads\AzFilesHybrid.zip -DestinationPath C:\Users\$env:USERNAME\Downloads\AzFilesHybrid\


# 6. Change the working PowerShell Directory to the AzFilesHybrid directory (Defaults to the download directory)
cd C:\Users\$env:USERNAME\Downloads\AzFilesHybrid


# 7. Verify the working directory is set to where the AzFilesHybrid was unzipped run to copy the files into your path
#    Select Run Once if prompted
.\CopyToPSPath.ps1 


# 8. Import AzFilesHybrid module
#    Select Run Once and Yes to All when prompted
Import-Module -Name AzFilesHybrid


#### UPDATE REQUIRED #####
# 9. Update the variables below with your lab settings, replace everything between double quotes ""
#    Update the Lab ID
$labId = "<Enter Lab ID here>"
#    Update the storage account name
$StorageAccountName = "<storage-account-name-here>"


# 10. Define parameters
#    $StorageAccountName is the name of an existing storage account that you want to join to AD
#    $SamAccountName is an AD object, see https://docs.microsoft.com/en-us/windows/win32/adschema/a-samaccountname
#    for more information.
#    If you want to use AES256 encryption (recommended), except for the trailing '$', the storage account name must be the same as the computer object's SamAccountName.
$SubscriptionId = (Get-AzContext).Subscription.id
$ResourceGroupName = ($labId + "RG")
$SamAccountName = $StorageAccountName
$DomainAccountType = "ComputerAccount" # Default is set as ComputerAccount
# If you don't provide the OU name as an input parameter, the AD identity that represents the storage account is created under the root directory.
$OuDistinguishedName = "OU=" + $labId + ",OU=AVD,DC=isdomcode,DC=local"
# Specify the encryption algorithm used for Kerberos authentication. Using AES256 is recommended.
$EncryptionType = "AES256,RC4"


# 11. Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 


# 12. Register the target storage account with your active directory environment under the target OU (for example: specify the OU with Name as "UserAccounts" or DistinguishedName as "OU=UserAccounts,DC=CONTOSO,DC=COM"). 
#     You can use to this PowerShell cmdlet: Get-ADOrganizationalUnit to find the Name and DistinguishedName of your target OU. If you are using the OU Name, specify it with -OrganizationalUnitName as shown below. If you are using the OU DistinguishedName, you can set it with -OrganizationalUnitDistinguishedName. You can choose to provide one of the two names to specify the target OU.
#     You can choose to create the identity that represents the storage account as either a Service Logon Account or Computer Account (default parameter value), depends on the AD permission you have and preference. 
#     Run Get-Help Join-AzStorageAccountForAuth for more details on this cmdlet.
#     Click Run Once when prompted
Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -SamAccountName $SamAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName `
        -EncryptionType $EncryptionType


# 13. The storage account is now configured for Windows AD authentication
#     Run the following commands to verify configuration
#     Get the target storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName
#     List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions
#     List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties


# 14. You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration with the logged on AD user. 
#     This cmdlet is supported on AzFilesHybrid v0.1.2+ version. For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose


###########################################################################
# Mount the storage account with an access key
# Update the settings below to match your environment 
###########################################################################

net use F: \\<storage-account-name>.file.core.windows.net\<share-name> /user:Azure\<storage-account-name> <storage-account-key>
