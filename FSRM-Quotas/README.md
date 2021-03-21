# check quota on windows server 2019

this is a localcheck the configuration has to be done in the check directly 

## TL;DR

1. configure the check
2. copy **local_check_quota.ps1** to **"C:\Program Files (x86)\check_mk\local\"** if you are on check_mk 1.6 and lower on check_mk 2.0 and above copy to location **"%ProgramData%\checkmk\agent\local"**
3. restart the check_mk_agent
4. do an service discover in WATO

![Output CheckMk](https://github.com/Mokkujin/Checks-for-Check_MK/blob/main/FSRM-Quota/src/check_mk_show.png)

## installation

place the check in **"%ProgramData%\checkmk\agent\local"** if you use check_mk 2.0 and above
if you use check_mk 1.6 and lower the check has to be copied to **"C:\Program Files (x86)\check_mk\local\"**


## configuration

change the threshold in script direct (line 23/24)

```powershell
# Change your Levels here - default is $WarningAt = 0.85 and $CriticalAt = 0.90
[float]$script:WarningAt = 0.85 
[float]$script:CriticalAt = 0.90
```

## test script

run a test and have a look on the output

```powershell
C:\local_checkmk_quota.ps1
0 FSRM-Abteilung-C - Usage:148 MB/200 MB Share:\\\\FSSRV01.test.local\\Abteilung-C Path:C:\\Share\\Abt_C
2 FSRM-Abteilung-B - Usage:99 MB/100 MB Share:\\\\FSSRV01.test.local\\Abteilung-B Path:C:\\Share\\Abt_B
1 FSRM-Abteilung-A - Usage:89 MB/100 MB Share:\\\\FSSRV01.test.local\\Abteilung-A Path:C:\\Share\\Abt_A
```

## info

the vbs script **local_check_quota.vbs** is only for nostalgic users :wink: