#!/usr/bin/env pwsh
####################################################################
# script from https://github.com/Mokkujin/checkmk-haproxy-localcheck
#
# @ mokkujin
####################################################################
$WIUser = ''
$WIPass = ''
$HaStatusUrl = 'https://localhost/lbstatistik;csv'
$MWarnAt = 0.85
$MCritAt = 0.90
$HADefMax = 12000
$MonBackFront = $false
# try to connect haproxy status page
try {
    If ($WIPass){
    $ParaIW = @{
        URI = $HaStatusUrl
        SkipCertificateCheck = $true # if you use ssl
        Credential = (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($WIUser,(ConvertTo-SecureString -String $WIPass -AsPlainText -Force)))
        }
    } else {
    $ParaIW = @{
        URI = $HaStatusUrl
        SkipCertificateCheck = $true # if you use ssl
        }
    }
    # check if target reachable .. if not exit
    $HAContent = (Invoke-WebRequest @ParaIW)
    $HAArray = (($HAContent).content -split('\n'))
} catch {
    #region ErrorHandler
    # get error record
    [Management.Automation.ErrorRecord]$e = $_
    # retrieve information about runtime error
    $info = [PSCustomObject]@{
        Exception = $e.Exception.Message
        Reason    = $e.CategoryInfo.Reason
        Target    = $e.CategoryInfo.TargetName
        Script    = $e.InvocationInfo.ScriptName
        Line      = $e.InvocationInfo.ScriptLineNumber
        Column    = $e.InvocationInfo.OffsetInLine
    }
    $info | Out-String | Write-Verbose
    Write-Error -Message ($info.Exception) -ErrorAction Continue
    # Only here to catch a global ErrorAction overwrite
    # endregion ErrorHandler
    Write-Error -Message 'Error to connect to haproxy status page' -ErrorAction Stop -Category ResourceUnavailable -ErrorId 2
    exit 2
} finally {
    [gc]::Collect()
}
foreach ($LineInArray in $HAArray){
    try { $LineArrayElements = $LineInArray -split(',') } catch { write-output 'Wrong HAProxy Version ?'}
        if (([string]::IsNullOrEmpty($LineArrayElements[0])) -or ($LineArrayElements[0].Substring(0,1) -eq '#')){
            # skip if line starts with an # or the first string is empty or null
            continue
        }
        try {
            [string]$HaStatusName = $LineArrayElements[0]
            [string]$HaStatusElement = $LineArrayElements[1]
            [string]$HAStatusState = $LineArrayElements[17]
            [int]$HASessionsCurrent = [convert]::ToInt32($LineArrayElements[4])
            # read session limits if not set use default value
            if ($LineArrayElements[6]){
                [int]$HASessionsMax = [convert]::ToInt32($LineArrayElements[6])
            } else {
                [int]$HASessionsMax = $HADefMax
            }
            # if max sessions 0 or not defined use the default value 
            if ($HASessionsMax -eq 0)  {
                $HASessionsMax = $HADefMax
            }

            # monitore only servers behind the backend
            if ( $MonBackFront -eq $false ) {
                if (($HaStatusElement -eq "BACKEND") -or ($HaStatusElement -eq "FRONTEND")) {
                    continue
                }
            }
            # calc thresholds
            [int]$ThresholdWarning = [math]::Round($HASessionsMax * $MWarnAt)
            [int]$ThresholdCritical = [math]::Round($HASessionsMax * $MCritAt)
        } catch {
            #region ErrorHandler
            # get error record
            [Management.Automation.ErrorRecord]$e = $_
            # retrieve information about runtime error
            $info = [PSCustomObject]@{
                Exception = $e.Exception.Message
                Reason    = $e.CategoryInfo.Reason
                Target    = $e.CategoryInfo.TargetName
                Script    = $e.InvocationInfo.ScriptName
                Line      = $e.InvocationInfo.ScriptLineNumber
                Column    = $e.InvocationInfo.OffsetInLine
            }
            $info | Out-String | Write-Verbose
            Write-Error -Message ($info.Exception) -ErrorAction Continue
            # Only here to catch a global ErrorAction overwrite
            # endregion ErrorHandler
            Write-Error -Message 'something went wrong check the output of your haproxy status page - could not declare vars' -ErrorAction Stop -Category InvalidData -ErrorId 3
            exit 3
        } finally {
            [gc]::Collect()
        }
        if (($HAStatusState -eq 'UP') -or ($HAStatusState -eq 'OPEN')){
            switch ($HASessionsCurrent){
                {($_ -lt $ThresholdWarning) -and ($_ -lt $ThresholdCritical)}     { $CheckStatus = '0' }
                {($_ -ge $ThresholdWarning) -and ($_ -lt $ThresholdCritical)}     { $CheckStatus = '1' }
                {($_ -ge $ThresholdCritical)}                                     { $Checkstatus = '2' }
                # if session max or session current is 0 then set checkstate to 0
                {($_ -eq '0') -Or ($HASessionsMax -eq '0')}                       { $CheckStatus = '0' }
            }
        } else {
            $CheckStatus = '2'
        }
        Write-Output -InputObject ('{0} haproxy_{1}-{2} - {2} {3}/{4} Sessions Host is {5}' -f $CheckStatus, $HaStatusName, $HaStatusElement, $HASessionsCurrent, $HASessionsMax, $HAStatusState)
}
