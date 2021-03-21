#Requires -Modules @{ ModuleName='FileServerResourceManager'; ModuleVersion='2.0' }
#Requires -Version 5.0

<#
.SYNOPSIS
    Check_MK Plugin to monitor Quotas
.DESCRIPTION
    Check_MK Plugin to monitor Quotas with FSRM Module to replace the old VBS Version 
.EXAMPLE
    PS C:\> ./local_check_quota.ps1
    0 FSRM-Abteilung-C - Usage:0 MB/200 MB Share:\\FSSRV01.test.local\Abteilung-C Path:C:\Share\Abt_C
    0 FSRM-Abteilung-B - Usage:0 MB/100 MB Share:\\FSSRV01.test.local\Abteilung-B Path:C:\Share\Abt_B
    0 FSRM-Abteilung-A - Usage:0 MB/100 MB Share:\\FSSRV01.test.local\Abteilung-A Path:C:\Share\Abt_A

    normaly this Script is located at the local plugin folder from check_mk
.NOTES
    check is from https://github.com/Mokkujin/Checks-for-Check_MK
.LINK
    https://github.com/Mokkujin/Checks-for-Check_MK
#>

# Change your Levels here - default is $WarningAt = 0.85 and $CriticalAt = 0.90
[float]$script:WarningAt = 0.85 
[float]$script:CriticalAt = 0.90

function script:Get-Rounded
{
    <#
    .SYNOPSIS
        Get-Rounded round a value
    .DESCRIPTION
        Get-Rounded round a value to a defind unit, the Input must be in Byte
    .Parameter RoundTo
        The Target Unit to Round .. possible Values are TB/GB/MB/KB default is MB
    .Parameter Value
        The Value to be calculate
    .EXAMPLE
        PS C:\> Get-Rounded -Value 123123123 

        Round the value to Megabyte 
    .EXAMPLE
        PS C:\> Get-Rounded -Value 123123123 -RoundTo GB

        Round the value to Gigabyte
    #>
    Param (
        [Parameter(HelpMessage = 'Round to TB / GB / MB / KB ?')]
        [string]$RoundTo,
        [Parameter(Mandatory, HelpMessage = 'Value to round - Input is in Byte')]
        [int]$Value
    )

    switch ($RoundTo)
    {
        KB
        {
            $Value = ([math]::Round($Value / 1024))
        }
        MB
        {
            $Value = ([math]::Round(($Value / 1024) / 1024))
        }
        GB
        {
            $Value = ([math]::Round((($Value / 1024) / 1024 ) / 1024))
        }
        TB
        {
            $Value = ([math]::Round(((($Value / 1024) / 1024 ) / 1024 ) / 1024))
        }
        default
        {
            $RoundTo = 'MB'
            $Value = ([math]::Round(($Value / 1024) / 1024))
        }
    }

    [string]$Value = ("$Value {0}" -f $RoundTo)
    # Output
    $Value
}

function script:Test-Quota
{
    <#
    .SYNOPSIS
        Test-Quota test with FSRM and SMB
    .DESCRIPTION
        Test-Quota test a quota set on the localserver and try to get the sbmshare name for the checkmk message
    .PARAMETER Path
        The Path to the configured quota
    .PARAMETER Size
        The maximum size of the quota
    .PARAMETER Usage
        actual usage of the quota

    .EXAMPLE
        PS C:\> Test-Quota -Path $Path -Size $Size -Usage $Usage 

        Round the value to Megabyte 
    #>
    Param (
        [Parameter(Mandatory, HelpMessage = 'Path to Share')]
        [string]$Path,
        [Parameter(Mandatory, HelpMessage = 'Size of Share')]
        [int]$Size,
        [Parameter(Mandatory, HelpMessage = 'Usage of Share')]
        [int]$Usage
    )

    [int]$Warning = ([math]::ceiling($script:WarningAt * $Size))
    [int]$Critical = ([math]::ceiling($script:CriticalAt * $Size))

    [string]$ShareName = (Get-SmbShare | Where-Object { $_.Path -eq $Path } | Select-Object -ExpandProperty Name)
    [string]$ServerName = ([System.Net.Dns]::GetHostByName(($env:computerName)) | Select-Object -ExpandProperty HostName)

    If (-not $ShareName)
    {
        [string]$ShareName = $script:LocalQuotas
        $script:LocalQuotas++
        [string]$ShareNameFull = ('Path:{0}' -f $Path) 
    }
    else
    {
        [string]$ShareNameFull = ('Share:\\{0}\{1} Path:{2}' -f $ServerName, $Sharename, $Path) 
    }

    $UsageInMB = (script:Get-Rounded -Value $Usage)
    $SizeInMB = (script:Get-Rounded -Value $Size)

    switch ($Usage)
    {
        ( { ($_ -lt $Warning) } ) 
        {
            Write-Output ('0 FSRM-{2} - Usage:{0}/{1} {3}' -f $UsageInMb, $SizeInMB, $ShareName, $ShareNameFull)
        }
        ( { ($_ -ge $Warning) -and ($_ -lt $Critical) } )
        {
            Write-Output ('1 FSRM-{2} - Usage:{0}/{1} {3}' -f $UsageInMb, $SizeInMB, $ShareName, $ShareNameFull)
        }
        ( { ($_ -ge $Critical) } )
        {
            Write-Output ('2 FSRM-{2} - Usage:{0}/{1} {3}' -f $UsageInMb, $SizeInMB, $ShareName, $ShareNameFull)
        }
        default
        {
            Write-Output ('3 FSRM-{2} - Unknown Error')
        }
    }
}

$AllSharesWithQuotas = (Get-FSRMQuota)
$CheckMKOutput = New-Object System.Collections.Generic.List[System.Object]
[int]$script:LocalQuotas = 0

foreach ($Share in $AllSharesWithQuotas)
{
    [int]$Max = $Share.Size
    [int]$Usage = $Share.Usage
    $Path = $Share.Path

    $result = (script:Test-Quota -Path $Path -Size $Max -Usage $Usage)
    $CheckMKOutput.Add($result)
}

$CheckMKOutput