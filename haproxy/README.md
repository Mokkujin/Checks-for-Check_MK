# checkmk-haproxy-localcheck

## TL;DR

1. configure the check
2. place here  /usr/lib/check_mk_agent/local 
3. wait or restart the check_mk_agent
4. do an service discover in WATO

---

- [Information](#info)
- [Requirements](#requirements)
- [Install](#install)
- [Configure](#configure)
- [when will Alarms apear](#alarms)
- [Example HaProxy Config](#haproxy)

---

<a name="info"></a>
## info

a local check for check_mk to monitore haproxy

bash is slower then python but if you are on an old system you could use bash as well
last but not least i created the same job an powershell version Why :wink: ? Because i can :smirk:

---
<a name="requirements"></a>
## requirements

- **check_haproxy.py** .. for sure needs **python3** :smirk:

- **check_haproxy_py2.py** .. use python2 for those people who obviously dont updated to the last stable version 
> :warning: **check_haproxy_py2.py** : is an unsupported and untested version for the no longer supported Python 2.x branch. Use at your own risk.

- **check_haproxy.ps1** .. developed on powershell core for linux

- **haproxy_checkmk.sh** .. developed on an bash 4 machine 

- **src_go/check_haproxy.go** .. developed on go1.16

<a name="install"></a>
## choose your version and install

* its recommended to use the python version
* copy the file **check_haproxy.py** to **/usr/lib/check_mk_agent/local/**
* wait or restart the check_mk_agent
* do an **full scan** on the configured host in WATO

---

<a name="configure"></a>
## configure the check

all variables are explained in the script.

*example :*

```python
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
```
| variable   | description   |
| ---------- | ------------- |
| URL        | URL to request the statussite |
| WIUser     | WebInterface Username to connect |
| WIPass     | WebInterface Password to connect |
| MWarnAt    | threshold for check mean 85% of session limits is reached do an warning in checkmk |
| MCritAt    | threshold for check mean 90% of session limits is reached do an critical in checkmk |
| HADefMax   | default maxconn for haproxy normaly it configured in default or global section of the haproxy.conf |
| MonBackFront | monitore Backend & Frontend , if set to False then only the servers-nodes will be monitored |

<a name="alarms"></a>
## when will alarms appear

| alarm  | description |
| -------- | -------- |
| critical          | server-node is down or configured threshold ```MCritAt``` of session limits is greater or equal |
| warning           | the configured threshold ```MWarnAt``` of session limits is greater or equal but lower then ```MCritAt``` |
| ok                | server-node is UP or OPEN and **NO** threshold is reached |


<a name="haproxy"></a>
## sure you have to enable the status page on haproxy first

for example:
```bash
listen status
    bind *:9090
    mode http
    stats enable
    stats uri /haproxy
    acl localhost  src  127.0.0.1
    acl stats      path_beg  /haproxy
    http-request allow if stats localhost
    http-request deny  if stats !localhost
```

Contributor : [@jhochwald](https://github.com/jhochwald)
