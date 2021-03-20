#!/usr/bin/env python2
import urllib2 as u
import sys as s
import ssl, base64
####################################################################
# script from https://github.com/Mokkujin/checkmk-haproxy-localcheck
#
# @ mokkujin
####################################################################
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
    if WIPass != "":
        HARequest = u.Request(URL)
        base64str = base64.b64encode('%s:%s' % (WIUser,WIPass))
        HARequest.add_header("Authorization", "Basic %s" % base64str)
        HARequest = u.urlopen(HARequest, context=ssl._create_unverified_context())
    else:
        HARequest = u.urlopen(URL , context=ssl._create_unverified_context())
    HAContent = HARequest.read()
except:
    print 'error at haproxy status page - exit'
    s.exit(2)

for l in HAContent.splitlines():
    try:
        if l.startswith('#'):
            continue
        la = l.split(',')
        HaStatusName = la[0]
        HaStatusElement = la[1]
        HAStatusState = la[17]
        HASessionsCurrent = la[4]
        HASessionsMax = la[6]
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
        s.exit(3)

    if HAStatusState == "UP" or HAStatusState == "OPEN":
        if int(HASessionsCurrent) < ThresholdWarning and int(HASessionsCurrent) < ThresholdCritical:
            CheckStatus = "0"
        if int(HASessionsCurrent) >= ThresholdWarning:
            CheckStatus = "1"
        if int(HASessionsCurrent) >= ThresholdCritical:
            CheckStatus = "2"
        if int(HASessionsMax) == 0 or int(HASessionsCurrent) == 0 or int(HASessionsMax) == 1:
            CheckStatus = "0"
    else:
        CheckStatus = "2"
    
    print("{0} haproxy_{1}-{2} - {2} {3}/{4} Sessions Host is {5}".format(CheckStatus,HaStatusName,HaStatusElement,HASessionsCurrent,HASessionsMax,HAStatusState))
