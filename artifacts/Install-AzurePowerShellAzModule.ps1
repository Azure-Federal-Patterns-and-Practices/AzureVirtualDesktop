[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $URI
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

function Get-WebFile
{
    param(
        [parameter(Mandatory)]
        [string]$FileName,

        [parameter(Mandatory)]
        [string]$URL
    )
    $Counter = 0
    do
    {
        Invoke-WebRequest -Uri $URL -OutFile $FileName -ErrorAction 'SilentlyContinue'
        if($Counter -gt 0)
        {
            Start-Sleep -Seconds 30
        }
        $Counter++
    }
    until((Test-Path $FileName) -or $Counter -eq 9)
}

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
    $Installer = $URI.Split('/')[-1]
    Get-WebFile -FileName $Installer -URL $URI
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i $Installer /quiet /qn /norestart /passive" -Wait -Passthru | Out-Null
    Write-Log -Message 'Installed Azure PowerShell AZ Module' -Type 'INFO'
    $Output = [pscustomobject][ordered]@{
        installer = $Installer
    }
    $Output | ConvertTo-Json
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}