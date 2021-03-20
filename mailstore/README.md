# checkmk_mailstore_local

- [Requirements](#requirements)
- [Install Mailstore API](#install-api)
- [Install local Check](#install-check)
  - [Single Job](#one-job)
  - [Multi Job](#multi-job)
- [Configuration](#config)
  - [Single Job Config](#single-job-config)
  - [Multi Job Config](#multi-job-config)
- [Hints](#hints)

local single check for checkmk to monitor mailstore with powershell

![Output CheckMk](https://github.com/Mokkujin/Checks-for-Check_MK/blob/main/mailstore/src/checkmk_output.png)

local multi check for checkmk to monitor mailstore with powershell

![Output Multi CheckMk](https://github.com/Mokkujin/Checks-for-Check_MK/blob/main/mailstore/src/checkmk_multi.png)

<a name="requirements"></a>
## Requirements

you have to install the API Wrapper from Mailstore

<https://help.mailstore.com/de/server/PowerShell_API-Wrapper_Tutorial>

and open the Port for the API for external Calls (MailStore Administration API)

<https://help.mailstore.com/en/server/MailStore_Server_Service_Configuration>

here you find the API Reference

<https://help.mailstore.com/de/server/Administration_API_-_Function_Reference>

<a name="install-api"></a>
## Install the API Warpper

create a folder **"C:\Program Files (x86)\MailStore\MailStore Server\API\"**
copy the API Files from Mailstore to this Folder otherwise you have to correct the path
in the script !

<a name="install-check"></a>
## install the single / multi check on mailstore server

<a name="one-job"></a>
### monitoring of just one job

copy **cfgCMA.json.example** to **cfgCMA.json** and set your config

set the path to the json file in script **checkmk_local_single_job_mailstore.ps1** ($configFile = XXXXX)

copy the script **checkmk_local_single_job_mailstore.ps1** to **"C:\Program Files (x86)\check_mk\local\"**

<a name="multi-job"></a>
### monitoring of more then one job

copy **cfgCMAmulti.json.example** to **cfgCMAmulti.json** and set your config

look at the example configuration ! its json :wink:

set the path to the json file in script **checkmk_local_multi_job_mailstore.ps1** ($configFile = XXXXX)

copy the script **checkmk_local_multi_job_mailstore.ps1** to **"C:\Program Files (x86)\check_mk\local\"**

### do it always :)

wait or restart the check_mk_agent

do an service discover in CheckMK WATO

<a name="config"></a>
## Configuration

<a name="single-job-config"></a>
### single job

|   Config Name    |    Value    |
| ---------------- | ----------- |
| Username | User with API Access |
| Password | Password for User |
| MailStoreServer | MailStoreServer FQDN or localhost (default : localhost) |
| Port | Port to Mail Store API |
| profileID  | profileID to check the job |

```
{
    "Username" : "USERNAME OF ADMINUSER",
    "Password" : "PASSWORD OF USER",
    "MailStoreServer" : "SERVER FQDN OR localhost (most localhost)",
    "Port" : PortToApi,
    "profileID" : ProfileIDFromWorker
}
```

<a name="multi-job-config"></a>
### multi job

|   Config Name    |    Value    |
| ---------------- | ----------- |
| Username | User with API Access |
| Password | Password for User |
| MailStoreServer | MailStoreServer FQDN or localhost (default : localhost) |
| Port | Port to Mail Store API [int] |
| useprofilenames  | use the configured names in profiles section <br> Default is true if you choose false the JOB ID will be show in WATO |
| CheckLicence | if you want to check the licence then set to true |
| Licence | MailStore Licence [int] |
| profiles | profiles of mailstore jobs (see example file) |

[int] : means it should be an integer !

```
{
  "Username" : "ADMINUSER",
  "Password" : "PASSWORD",
  "MailStoreServer" : "FQDN or localhost",
  "Port" : PortToApi,
  "useprofilenames" : true,
  "CheckLicence" : true,
  "Licence" : 200, 
  "profiles":
  [
    {
      "profileID": ProfileIDFromWorker[int],
      "name": "ProfileNameToDisplayCheckMK",
      "interval": CheckIntervalInMinutes[int]
    },
    {
      "profileID": ProfileIDFromWorker[int],
      "name": "ProfileNameToDisplayCheckMK",
      "interval": CheckIntervalInMinutes[int]
    },
    {
      "profileID": ProfileIDFromWorker[int],
      "name": "ProfileNameToDisplayCheckMK",
      "interval": CheckIntervalInMinutes[int]
    },
    {
      "profileID": ProfileIDFromWorker[int],
      "name": "ProfileNameToDisplayCheckMK",
      "interval": CheckIntervalInMinutes[int]
    },
    {
      "profileID": ProfileIDFromWorker[int],
      "name": "ProfileNameToDisplayCheckMK",
      "interval": CheckIntervalInMinutes[int]
    }
  ]
}
```

look at the example configs to understand

<a name="hints"></a>
## Hints

to get all profileIDs from Mailstore you can run the script **show_all_profileIDs.ps1**

or use the UI to get the profileID from the job to be monitored go to the gui click on the Job and

Press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> then you will see a form with an json

![Get ProfileId from Mailstore](https://github.com/Mokkujin/Checks-for-Check_MK/blob/main/mailstore/src/mailstore_json.png)

Contributor : [@jhochwald](https://github.com/jhochwald)
