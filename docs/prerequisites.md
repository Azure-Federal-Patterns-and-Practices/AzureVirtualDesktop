# Azure Virtual Desktop Solution

[**Home**](../readme.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Post Deployment**](./post.md) | [**Troubleshooting**](./troubleshooting.md)

## Prerequisites

To successfully deploy this solution, you will need to ensure the following prerequisites have been completed:

- **Licenses:** [supported operating system licenses](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview#requirements)
- **Landing Zone:** ensure the minimum required resources are deployed in your Azure subscription.
  - Virtual network and subnet(s)
  - Domain services if you plan to domain or hybrid join the session hosts with sychronization to Azure AD using Azure AD Connect.
- **Permissions:**
  - Azure: ensure the principal deploying the solution has "Owner" and "Key Vault Administrator" roles assigned on the target Azure subscription. This solution contains many role assignments at different scopes so the principal deploying this solution will need to be an Owner at the subscription scope for a successful deployment. It also deploys a key and secrets in a key vault to enhance security.
  - Domain Services: if using domain services, create a principal to domain join the session hosts and Azure Files, if applicable.
    - AD DS: ensure the principal has the following permissions.
      - "Join the Domain" on the domain
      - "Create Computer" on the parent OU or domain
      - "Delete Computer" on the parent OU or domain
    - Azure AD DS: ensure the principal is a member of the "AAD DC Administrators" group.
- **Security Group:** create a security group for your AVD users.
  - AD DS: create the group in ADUC and ensure the group has synchronized to Azure AD.
  - Azure AD: create the group.
  - Azure AD DS: create the group in Azure AD and ensure the group has synchronized to Azure AD DS.
- **FSLogix:**
  - Azure Files:
    - If you plan to deploy Azure Files with a Service Endpoint, be sure the subnet for the sessions hosts has the "Azure Storage" service endpoint enabled on the subnet.
    - If you plan to deploy Azure Files with a Private Endpoint, ensure the [Private Endpoint Network Policy has been disabled](https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy). Otherwise, the private endpoint resource will fail to deploy. Also, ensure the forwarder or conditional forwarder in DNS has been setup for the storage namespace.
  - Azure NetApp Files:
    - [Register the resource provider](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register)
    - [Delegate a subnet to Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
    - [Enable the shared AD feature](https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections#shared_ad): this feature is required if you plan to deploy more than one domain joined NetApp account in the same Azure subscription and region.  As of 1/31/2022, this feature is in "public preview" in Azure Cloud and not available in Azure US Government.
- **Disk Encryption:** the encryption at host feature is deployed on the virtual machines when the "DiskEncryption" parameter is set to "true". This feature is not enabled in your Azure subscription by default and must be manually enabled. Use the following steps to enable the feature: [Enable Encryption at Host](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal).
- **Marketplace Image:** If you plan to deploy this solution using PowerShell or AzureCLI and use a marketplace image for the virtual machines, use the code below to find the appropriate image:

```powershell
# Determine the Publisher; input the location for your AVD deployment
$Location = ''
(Get-AzVMImagePublisher -Location $Location).PublisherName

# Determine the Offer; common publisher is 'MicrosoftWindowsDesktop' for Win 10/11
$Publisher = ''
(Get-AzVMImageOffer -Location $Location -PublisherName $Publisher).Offer

# Determine the SKU; common offers are 'Windows-10' for Win 10 and 'office-365' for the Win10/11 multi-session with M365 apps
$Offer = ''
(Get-AzVMImageSku -Location $Location -PublisherName $Publisher -Offer $Offer).Skus

# Determine the Image Version; common offers are '21h1-evd-o365pp' and 'win11-21h2-avd-m365'
$Sku = ''
Get-AzVMImage -Location $Location -PublisherName $Publisher -Offer $Offer -Skus $Sku | Select-Object * | Format-List

# Common version is 'latest'
```
