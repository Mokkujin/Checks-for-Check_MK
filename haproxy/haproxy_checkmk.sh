#/!/bin/bash
####################################################################
# script from https://github.com/Mokkujin/checkmk-haproxy-localcheck
#
# @ mokkujin
####################################################################
# do not change get awk binary
awk_bin=$(which awk)
#
# Check Sessions of an HAPROXY under each Linux Machine
# needs awk for the check !
#
# script work with example configuration
#
# change you vars here
# status page over ssl
status_URL="https://localhost/lbstatistik;csv" # place your hhtps status url here
userpass="user:password" # user:password
# status page without ssl
#status_URL="http://localhost:9090/lbstatistik;csv" # place your http status url here

# thresholds for localcheck
warn="0.85" # = 85% 
crit="0.90" # = 90%
HADefMax="12000" # default session limits
MonBackFront=no #use yes no to configure
# if you dont know what you do .... do nothing below 
# check with user & password incl. ssl
for line in $(curl -s -k ${status_URL} -u "${userpass}" | grep -vE "#" ); do
# check without user and password run only from local ! without ssl
#for line in $(curl -s ${status_URL} | grep -vE "#" ); do
    _name=$(echo $line | ${awk_bin} -F',' '{ print $1; }' )
    _config=$(echo $line | ${awk_bin} -F',' '{ print $2; }' )
    _smax=$(echo $line | ${awk_bin} -F',' '{ print $7; }' )
    _scur=$(echo $line | ${awk_bin} -F',' '{ print $5; }' )
    _ol=$(echo $line | ${awk_bin} -F',' '{ print $18; }' )
    # set default session limits
    if [ "x$_smax" == "x" ] || [ "x$_smax" == "x0" ]; then
        _smax=$HADefMax
    fi
    # monitore back & frontends 
    if [ $MonBackFront == "no" ] || [ $MonBackFront == "NO" ]; then
        if [ $_config == "BACKEND" ] || [ $_config == "FRONTEND" ]; then
            continue
        fi
    fi
    STATUS="${_config} ${_scur}/${_smax} Sessions Host is ${_ol}"
    NOTIFY="haproxy_${_name}-${_config}"
    # use awk for math fucking bash could not handle float numbers
    th_warn=$(${awk_bin} '{print $1*$2}' <<< "${_smax} ${warn}")
    th_warn=$(${awk_bin} "BEGIN{printf \"%.0f\n\",${th_warn}}")
    th_warn=$((${th_warn}+0))
    th_crit=$(${awk_bin} '{print $1*$2}' <<< "${_smax} ${crit}")
    th_crit=$(${awk_bin} "BEGIN{printf \"%.0f\n\",${th_crit}}")
    th_crit=$((${th_crit}+0))
    # check if backend is online 
    if [ ${_ol} == "UP" ] || [ ${_ol} == "OPEN" ]; then
        # check thresholds
        _scur=$((${_scur}+0))
        _smax=$((${_smax}+0))
        if [[ ${_scur} -ge 0 ]]; then
            _chk="0"
        fi
        if [[ ${_scur} -ge ${th_warn} ]]; then
            _chk="1"
        fi
        if [[ ${_scur} -ge ${th_crit} ]]; then
            _chk="2"
        fi
    else
        _chk="2"
    fi
    echo "${_chk} ${NOTIFY} - ${STATUS}"
    th_warn=""
    th_crit=""
done
