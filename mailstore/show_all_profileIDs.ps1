# unblock api files from mailstore
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psm1' 
# import module
Import-Module 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
##################################################################################################
#
#
#  HELLO to the show_all_profileIDs.ps1 Script ;)
#
#  will list all profiles of the past ten days if you want more change the var $CheckStartTime
#
#  installation API Wrapper from Mailstore is required :
#  https://help.mailstore.com/de/server/images/3/37/MailStore_Server_Scripting_Tutorial.zip
#
#  API Referenz Mailstore :
#  https://help.mailstore.com/de/server/Administration_API_-_Function_Reference
#
#  check is from https://github.com/Mokkujin/Checks-for-Check_MK
#
#  @mokkujin in 2021
# 
##################################################################################################
$configFile = 'C:\Develope\cfgCMAmulti.json'
If (Test-Path -Path $configFile -PathType Leaf) {
    # try to read config from json file
    try {
        $JsonConfig=((Get-Content -Path $configFile -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        # error at reading do an exit 
        Write-Output "error reading json for script"
        exit 2
    }
} else {
    # error file not exists
    Write-Output "Config JSON not found"
    exit 1
}
# get date & time for check
$CheckStartTime = ((Get-Date (Get-Date).AddDays(-10) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)
$CheckEndTime = ((Get-Date (Get-Date).AddMinutes(-0) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)

# set parameter for api client
$ParaApiClient = @{
    Username = $JsonConfig.Username
    Password = $JsonConfig.Password
    MailStoreServer = $JsonConfig.MailStoreServer
    Port = $JsonConfig.Port
    IgnoreInvalidSSLCerts = $true
}

# Check Config
try {
    If ((-not $ParaApiClient['Port']) -or 
        ($ParaApiClient['Port'].GetType().Name -ne 'Int32')){ 
        Write-Output 'JSON Config - check PORT/ProfileID (not set or not an Integer)'
        exit 4
    } 
} catch {
    Write-Output 'JSON Config - check PORT/ProfileID (not set or not an Integer)'
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
        exit 4
    } 
} catch {
    Write-Output 'JSON Config - check Username / Password / MailStoreServer (not set or not an string)'
    exit 4
}

try {
    $msapiclient = (New-MSApiClient @ParaApiClient)
    $return = (Invoke-MSApiCall -MSApiClient $msapiclient -ApiFunction "GetWorkerResults" -ApiFunctionParameters @{
        fromIncluding = $CheckStartTime
        toExcluding = $CheckEndTime
        timeZoneID = "`$Local"
    })
    $out = ($return.result | Select-Object profileID,profileName)
    $out = $out | Sort-Object -Property profileID -Unique
    # output to terminal
    $out
} catch {
    Write-Output "Could not connect to Mailstore Server"
}
