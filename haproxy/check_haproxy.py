#!/usr/bin/env python3
import requests, urllib3, sys
####################################################################
# script from https://github.com/Mokkujin/Checks-for-Check_MK
#
# @ mokkujin
####################################################################
# disable ssl warning
urllib3.disable_warnings()
# define vars
URL = 'https://localhost/lbstatistik;csv'
WIUser = ''
WIPass = ''
# define thresholds
MWarnAt = 0.85
MCritAt = 0.90
HADefMax = 12000
# monitore Backend & Frontend too ? if true you have to configure the backends
# and frontends on the right way ;)
MonBackFront = False
# do check
try:
    if WIPass:
        HARequest = requests.get(URL , verify=False , auth=(WIUser,WIPass))
    else:
        HARequest = requests.get(URL , verify=False)
    HAContent = HARequest.content.splitlines()
except:
    print('error to connect to haproxy status page')
    sys.exit(2)
for Entry in HAContent:
    try:
        Line = Entry.decode("utf-8")
        if Line.startswith('#'):
            continue
        LineArray = Line.split(',')
        HaStatusName = LineArray[0]
        HaStatusElement = LineArray[1]
        HAStatusState = LineArray[17]
        HASessionsCurrent = LineArray[4]
        HASessionsMax = LineArray[6]
        # if max sessions 0 or not defined use the default vaule 
        if HASessionsMax == "" or HASessionsMax == "0":
            HASessionsMax = HADefMax
        # monitore only servers behind the backend
        if MonBackFront == False:
            if HaStatusElement == "BACKEND" or HaStatusElement == "FRONTEND":
                continue
        # calc thresholds
        ThresholdWarning = round(int(HASessionsMax) * MWarnAt)
        ThresholdCritical = round(int(HASessionsMax) * MCritAt)
    except:
        print('something went wrong check the output of your haproxy status page - could not declare vars')
        sys.exit(3)
    if HAStatusState == "UP" or HAStatusState == "OPEN":
        if int(HASessionsCurrent) < ThresholdWarning and int(HASessionsCurrent) < ThresholdCritical:
            CheckStatus = "0"
        if int(HASessionsCurrent) >= ThresholdWarning:
            CheckStatus = "1"
        if int(HASessionsCurrent) >= ThresholdCritical:
            CheckStatus = "2"
        if int(HASessionsMax) == 0 or int(HASessionsCurrent) == 0:
            CheckStatus = "0"
    else:
        CheckStatus = "2"
    print("{0} haproxy_{1}-{2} - {2} {3}/{4} Sessions Host is {5}".format(CheckStatus,HaStatusName,HaStatusElement,HASessionsCurrent,HASessionsMax,HAStatusState)) 
