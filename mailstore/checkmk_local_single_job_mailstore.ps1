# unblock api files from mailstore
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
Unblock-File -Path 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psm1' 
# import module
Import-Module 'C:\Program Files (x86)\MailStore\MailStore Server\API\MS.PS.Lib.psd1'
##################################################################################################
#
#  local check for check mk 
#  
#  you need the workerId for the Check
#
#  Its pain to get the workerId from Mailstore Server , its easier to use the Mailstore Client
#  Go to Mailstore Client choose your Job and Press STRG+SHIFT+P to show the json for the job
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
#region Read_JSON
$configFile = 'C:\Develope\cfgCMA.json'
If (Test-Path -Path $configFile -PathType Leaf) {
        # try to read config from json file
        try {
            $JsonConfig=((Get-Content -Path $configFile -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop)
        } catch {
            # error at reading do an exit 
            Write-Output '2 Mailstore - error reading json for script'
            exit 2
        }
    } else {
        # error file not exists
        Write-Output '2 Mailstore - Config JSON not found'
        exit 1
    }
# get date & time for check
$CheckStartTime = ((Get-Date (Get-Date).AddMinutes(-10) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)
$CheckEndTime = ((Get-Date (Get-Date).AddMinutes(-0) -Format yyyy-MM-ddTHH:mm:ss) | Out-String)
# set parameter for api client
$ParaApiClient = @{
    Username = $JsonConfig.Username
    Password = $JsonConfig.Password
    MailStoreServer = $JsonConfig.MailStoreServer
    Port = $JsonConfig.Port
    IgnoreInvalidSSLCerts = $true
}
$ProfileID = [int]$JsonConfig.profileID
#endregion Read_JSON

#region Check_Config
try {
    If ((-not $ParaApiClient['Port']) -or 
        ($ParaApiClient['Port'].GetType().Name -ne 'Int32') -or 
        (-not $ProfileID) -or 
        ($ProfileID.GetType().Name -ne 'Int32')){ 
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
            $ParaApiClient = $null
            [gc]::Collect()
            exit 4
    } 
} catch {
    Write-Output 'JSON Config - check Username / Password / MailStoreServer (not set or not an string)'
    $ParaApiClient = $null
    [gc]::Collect()
    exit 4
}
#endregion Check_Config

#region Do_Request
try {
    $msapiclient = (New-MSApiClient @ParaApiClient)
    $return = (Invoke-MSApiCall -MSApiClient $msapiclient -ApiFunction "GetWorkerResults" -ApiFunctionParameters @{
        fromIncluding = $CheckStartTime
        toExcluding = $CheckEndTime
        timeZoneID = "`$Local"
        profileID=$ProfileID
    })
    if (-not ($return.result.result -eq 'succeeded')) {
        Write-Output '2 Mailstore - Error at Archiving'
    } else { 
        Write-Output '0 Mailstore - Archiving is OK'
    }
} catch {
    Write-Output '2 Mailstore - Error at Request Archiving'
}
#endregion Do_Request

#region cleanup
$CheckStartTime = $null
$CheckEndTime = $null
$ProfileID = $null
$ParaApiClient = $null
$msapiclient = $null
[gc]::Collect()
#endregion cleanup