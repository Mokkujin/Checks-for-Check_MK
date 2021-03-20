# unblock api files from mailstore
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psm1' 
# import module
Import-Module 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
##################################################################################################
#
#  local check for check mk 
#  
#  you need the workerId's for the Check
#
#  Its pain to get the workerId from Mailstore Server , its easier to use the Mailstore Client
#  Go to Mailstore Client choose your Job and Press STRG+SHIFT+P to show the json for the job.
#  Or run the script show_all_profileIDs.ps1 :)
#
#  installation API Wrapper from Mailstore is required :
#  https://help.mailstore.com/de/server/images/3/37/MailStore_Server_Scripting_Tutorial.zip
#
#  API Referenz Mailstore :
#  https://help.mailstore.com/de/server/Administration_API_-_Function_Reference
#
#  check is from https://github.com/Mokkujin/checkmk_mailstore_local
#
#  @mokkujin in 2021
# 
##################################################################################################
# vars
$CheckMKOutput = New-Object System.Collections.Generic.List[System.Object]

#region read_config_file
$configFile = 'C:\Develope\cfgCMAmulti.json'
If (Test-Path -Path $configFile -PathType Leaf) {
        # try to read config from json file
        try {
            $JsonConfig = ((Get-Content -Path $configFile -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop)
        } catch {
            # error at reading do an exit 
            Write-Output '2 Mailstore - error reading json for script'
            $JsonConfig = $null
            [gc]::Collect()
            exit 2
        }
    } else {
        # error file not exists
        Write-Output '2 Mailstore - Config JSON not found'
        [gc]::Collect()
        exit 1
    }
# set parameter for api client
$ParaApiClient = @{
    Username = $JsonConfig.Username
    Password = $JsonConfig.Password
    MailStoreServer = $JsonConfig.MailStoreServer
    Port = $JsonConfig.Port
    IgnoreInvalidSSLCerts = $true
}
#endregion read_config_file

#region check_config_entries
try {
    If ((-not $ParaApiClient['Port']) -or 
        ($ParaApiClient['Port'].GetType().Name -ne 'Int32')){ 
        Write-Output 'JSON Config - check PORT (not set or not an Integer)'
        [gc]::Collect()
        exit 4
    } 
} catch {
    Write-Output 'JSON Config - check PORT (not set or not an Integer)'
    [gc]::Collect()
    exit 4 
}
try {
    If ((-not $ParaApiClient['Username']) -or 
        (-not $ParaApiClient['Password']) -or 
        (-not $ParaApiClient['MailStoreServer']) -or 
        ($ParaApiClient['Username'].GetType().Name -ne 'String') -or 
        ($ParaApiClient['Password'].GetType().Name -ne 'String') -or 
        ($ParaApiClient['MailStoreServer'].GetType().Name -ne 'String')) {
        Write-Output 'JSON Config - check Username / Password / MailStoreServer (not set or not an string)'
        $ParaApiClient = $null
        [gc]::Collect()
        exit 4
    } 
} catch {
    Write-Output 'JSON Config - check Username / Password / MailStoreServer (not set or not an string)'
    #region cleanup
    $JsonConfig = $null 
    $ParaApiClient = $null
    [gc]::Collect()
    #endregion cleanup
    exit 4
}
#endregion check_config_entries

#region do_request
# declare maspi 
try {
    $msapiclient = (New-MSApiClient @ParaApiClient)
} catch {
    Write-Output 'could not initialize MSAPI CLient , is the Mailstore Powershell Modul available ?'
    #region cleanup
    $JsonConfig = $null
    $ParaApiClient = $null
    $msapiclient = $null
    [gc]::Collect()
    #endregion cleanup
    exit 4
}
#endregion do_request

#region check_licence
if ($JsonConfig.CheckLicence) {
    try {
        [int]$JSLic = $JsonConfig.Licence
        $return = (Invoke-MSApiCall -MSApiClient $msapiclient -ApiFunction "GetUsers")
        [int]$UsedLicence = (($return.result.userName).count)
        [int]$FreeLicence = ($JSLic - $UsedLicence)
        # Warning at 90% licence used
        [int]$WarningLicence = [math]::ceiling($JSLic * 0.9)

        if ($UsedLicence -ge $WarningLicence) {
            $CheckMKOutput.Add(( '2 Mailstore-Licence - {0}/{1} licence - free {2} !' -f $UsedLicence,$JSLic,$FreeLicence ))
        } else {
            $CheckMKOutput.Add(( '0 Mailstore-Licence - {0}/{1} licence - free {2} !' -f $UsedLicence,$JSLic,$FreeLicence ))
        }
    } catch {
        $CheckMKOutput.Add(( '2 Mailstore-Licence - could not check licence' ))
        #region cleanup
        $JsLic = $null
        $UsedLicence = $null
        $FreeLicence = $null
        $WarningLicence = $null
        #endregion cleanup
    }
}
#endregion check_licence

#region check_mailstore_profiles
foreach ($key in $JsonConfig.profiles) {
    try {
        # cleanup vars to prevent array shit ;)
        $CheckStartTime = $null
        $CheckEndTime = $null
        $return = $null
        try {
            # get date & time for check
            $CheckStartTime = ((Get-Date (Get-Date).AddMinutes(-$key.interval) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)
            $CheckEndTime = ((Get-Date (Get-Date).AddMinutes(-0) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)
            $return = (Invoke-MSApiCall -MSApiClient $msapiclient -ApiFunction "GetWorkerResults" -ApiFunctionParameters @{
                fromIncluding = $CheckStartTime
                toExcluding = $CheckEndTime
                timeZoneID = "`$Local"
                profileID=$key.profileID
                })
            # get profileID & profileName 
            $JID = $null
            $JID = $key.profileID
            $JName = $null
            $JName = ($return.result.profileName | Sort-Object -Unique)
            # check if profile Names enabled in Config
            if ($JsonConfig.useprofilenames) { 
                $JName = $key.name 
            } 
            # check if name is empty 
            if ([string]::IsNullOrWhitespace($JName)) { 
                $JName = ('Job ID :  {0}' -f $JID)
            }
        } catch {
            Write-Output 'JSON Config - wrong configuration at profiles section'
            #region cleanup
            $CheckStartTime = $null
            $CheckEndTime = $null
            $JsonConfig = $null
            $ParaApiClient = $null
            $msapiclient = $null
            $JID = $null
            $JName = $null
            [gc]::Collect()
            #endregion cleanup
            exit 5
        }
        # get result from check
        if (-not ($return.result.result -eq 'succeeded')) {
            $CheckMKOutput.Add(('1 Mailstore-{0} - WARN - {1} need some love !' -f $JID,$JName ))
            continue
        } else { 
            $CheckMKOutput.Add(('0 Mailstore-{0} - OK - {1} is running fine' -f $JID,$JName ))
            continue
        }
    } catch {
        $CheckMKOutput.Add(('2 Mailstore-{0} - Error at Request {1} Archiving' -f  $JID,$JName))
    }
}
#endregion check_mailstore_profiles

# let the terminal do :-)
$CheckMKOutput

#region cleanup
# final cleanup & garbage collection
$CheckStartTime = $null
$CheckEndTime = $null
$JsonConfig = $null
$ParaApiClient = $null
$msapiclient = $null
$return = $null
$JID = $null
$JName = $null
$CheckMKOutput = $null
[gc]::Collect()
#endregion cleanup