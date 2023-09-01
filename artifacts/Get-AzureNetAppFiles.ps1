[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $Location,

    [parameter(Mandatory)]
    [string]
    $StorageSolution,

    [parameter(Mandatory)]
    [string]
    $SubscriptionId,

    [parameter(Mandatory)]
    [string]
    $TenantId,

    [parameter(Mandatory)]
    [string]
    $UserAssignedIdentityClientId,

    [parameter(Mandatory)]
    [string]
    $VirtualNetworkName,

    [parameter(Mandatory)]
    [string]
    $VirtualNetworkResourceGroupName
)

$ErrorActionPreference = 'Stop'

try 
{
    Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId
    if($StorageSolution -eq "AzureNetAppFiles")
    {
        $Vnet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $VirtualNetworkResourceGroupName
        $DnsServers = "$($Vnet.DhcpOptions.DnsServers[0]),$($Vnet.DhcpOptions.DnsServers[1])"
        $SubnetId = ($Vnet.Subnets | Where-Object {$_.Delegations[0].ServiceName -eq "Microsoft.NetApp/volumes"}).Id
        if($null -eq $SubnetId -or $SubnetId -eq "")
        {
            Write-Error -Exception "INVALID AZURE NETAPP FILES CONFIGURATION: A dedicated subnet must be delegated to the ANF resource provider."
        }
        $DeployAnfAd = "true"
        $Accounts = Get-AzResource -ResourceType "Microsoft.NetApp/netAppAccounts" | Where-Object {$_.Location -eq $Location}
        foreach($Account in $Accounts)
        {
            $AD = Get-AzNetAppFilesActiveDirectory -ResourceGroupName $Account.ResourceGroupName -AccountName $Account.Name
            if($AD.ActiveDirectoryId)
            {
                $DeployAnfAd = "false"
            }
        }
        $Object = [PSCustomObject]@{
            anfDnsServers = $DnsServers
            anfSubnetId = $SubnetId
            anfActiveDirectory = $DeployAnfAd
        }
    } 
    else
    {
        $Object = [PSCustomObject]@{
            anfDnsServers = "NotApplicable"
            anfSubnetId = "NotApplicable"
            anfActiveDirectory = "false"
        }
    }
    $Value = $Object | ConvertTo-Json
    Write-Log -Message "Azure NetApp Files Validation: $Value" -Type 'INFO'
    Disconnect-AzAccount
    return $Value
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}