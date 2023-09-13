# Azure Virtual Desktop Solution

[**Home**](../README.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Troubleshooting**](./troubleshooting.md)

## Prerequisites

To successfully deploy this solution, you will need to ensure the following prerequisites have been completed:

- **Licenses:** ensure you have the [required licensing for AVD](https://learn.microsoft.com/en-us/azure/virtual-desktop/overview#requirements).
- **Landing Zone:** ensure the minimum required resources are deployed in your Azure subscription.
  - Virtual network and subnet(s)
  - Domain Services: if you plan to domain or hybrid join the session hosts, ensure ADDS or Azure ADDS is available in your enviroment and that you are synchronizing the required objects using Azure AD Connect. AD Sites & Services should be configured for the address space of your Azure virtual network if you are extending your on premises AD infrastruture into the cloud.

> **NOTE**
> A simple landing zone can be deployed using my [Azure Landing Zones repository](https://github.com/jamasten/AzureLandingZones).

- **DNS:** if you plan to deploy private endpoints, you must ensure your DNS is configured with ONE of the following:
  - DNS forwarder points the [Azure VIP, 168.63.129.16](https://learn.microsoft.com/azure/virtual-network/what-is-ip-address-168-63-129-16).
  - Conditional forwarders for the following [public DNS zone forwarders](https://learn.microsoft.com/azure/private-link/private-endpoint-dns) that point to the [Azure VIP, 168.63.129.16](https://learn.microsoft.com/azure/virtual-network/what-is-ip-address-168-63-129-16):
    | Cloud | Automation Account | Azure Files | Azure Virtual Desktop | Key Vault |
    |-------|--------------------|-------------|-----------------------|-----------|
    | AzureCloud | azure-automation.net | file.core.windows.net | wvd.microsoft.com | vault.azure.net & vaultcore.azure.net |
    | AzureUsGovernment | azure-automation.us | file.core.usgovcloudapi.net | wvd.azure.us | vault.usgovcloudapi.net & vaultcore.usgovcloudapi.net |
- **Permissions:**
  - Azure: ensure the principal deploying the solution has "Owner" and "Key Vault Administrator" roles assigned on the target Azure subscription. This solution contains many role assignments at different scopes so the principal deploying this solution will need to be an Owner at the subscription scope for a successful deployment. It also deploys a key and secrets in a key vault to enhance security.
  - Domain Services: if using domain services, create a principal to domain join the session hosts and Azure Files, if applicable.
    - AD DS: ensure the principal has the following permissions.
      - "Join the Domain" on the domain
      - "Create Computer" on the parent OU or domain
      - "Delete Computer" on the parent OU or domain
    - Azure AD DS: ensure the principal is a member of the "AAD DC Administrators" group in Azure AD.
- **Security Group:** create a security group for your AVD users.
  - AD DS: create the group in ADUC and ensure the group has synchronized to Azure AD.
  - Azure AD: create the group.
  - Azure AD DS: create the group in Azure AD and ensure the group has synchronized to Azure AD DS.
- **Artifacts:** this solution depends on many artifacts, PowerShell modules & scripts. If your Azure environment does not allow outbound internet access, you must:
  - host the following files in Azure Blobs:
    - [Azure PowerShell AZ Module](https://github.com/Azure/azure-powershell/releases/download/v10.2.0-August2023/Az-Cmdlets-10.2.0.37547-x64.msi)
    - [PowerShell Scripts](https://github.com/jamasten/AzureVirtualDesktop/tree/main/artifacts)
    - [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip)
  - update the following parameters during deployment:
    - ArtifactsLocation - this is the URL to your container in Azure Blobs (e.g. https[]://saavdduse.blob.core.windows.net/artifacts/).
    - ArtifactsStorageAccountResourceId - this is the resource ID for your storage account that contains the artifacts in Azure Blobs.
- **FSLogix:**
  - Azure Files:
    - Service Endpoint - if you plan to deploy Azure Files with a Service Endpoint, be sure the subnet for the sessions hosts has the "Azure Storage" service endpoint enabled on the subnet.
    - Private Endpoint - if you plan to deploy Azure Files with a Private Endpoint, ensure the [Private Endpoint Network Policy has been disabled](https://learn.microsoft.com/azure/private-link/disable-private-endpoint-network-policy) on the subnet. Otherwise, the private endpoint resource will fail to deploy.
  - Azure NetApp Files:
    - [Register the resource provider](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-register)
    - [Delegate a subnet to Azure NetApp Files](https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
    - [Enable the shared AD feature](https://learn.microsoft.com/azure/azure-netapp-files/create-active-directory-connections#shared_ad) - this feature is required if you plan to deploy more than one domain joined NetApp account in the same Azure subscription and region.
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
