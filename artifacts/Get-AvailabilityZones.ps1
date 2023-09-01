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
    $SubscriptionId,

    [parameter(Mandatory)]
    [string]
    $TenantId,

    [parameter(Mandatory)]
    [string]
    $UserAssignedIdentityClientId,

    [parameter(Mandatory)]
    [string]
    $VirtualMachineSize
)

$ErrorActionPreference = 'Stop'

try 
{
    Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId
    $Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq "virtualMachines" -and $_.Name -eq $VirtualMachineSize}
    $Value = $Sku.locationInfo.zones | Sort-Object | ConvertTo-Json -AsArray
    Write-Log -Message "Availability Zones Validation: $Value" -Type 'INFO'
    Disconnect-AzAccount
    return $Value
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}