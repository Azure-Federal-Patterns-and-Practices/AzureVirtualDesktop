[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $HostPoolName,

    [parameter(Mandatory)]
    [string]
    $HostPoolResourceGroupName
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

try 
{
    $SessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool).Name
    foreach($SessionHost in $SessionHosts)
    {
        $Name = ($SessionHost -split "/")[1]; Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $Name -AllowNewSession:$False
    }
    Write-Log -Message 'Drain Mode Succeeded' -Type 'INFO'
    $JsonOutput = $HostPool | ConvertTo-Json
    return $JsonOutput
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}