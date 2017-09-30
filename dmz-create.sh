#!/bin/sh

[ ${UID} -eq 0 ] || { 1>&2 echo "This script must be run as root" ; exit 1 ; }

[ ${#} -eq 1 ] || { 1>&2 echo "Usage: ${0} DMZ_NUM" ; exit 1 ; }

[ ${1} -ge 0 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC=$(printf "%d" "${1}")
DMZ_HEX=$(printf "%02x" "${1}")
IF="dmz${DMZ_DEC}"

cat << EOF | tee /etc/network/interfaces.d/50-${IF}.conf
auto ${IF}
iface ${IF} inet static
	bridge_ports none
        address 10.0.${DMZ_DEC}.254/24

iface ${IF} inet6 static
	bridge_ports none
        address fd00:0000:0000:00${DMZ_HEX}:FFFF:FFFF:FFFF:FFFE/64
EOF
[ ${?} -eq 0 ] || { 1>&2 echo "Interface configuraiton exited with code ${?}"; exit 1; }

ifup ${IF}
[ ${?} -eq 0 ] || { 1>&2 echo "Interface configuraiton exited with code ${?}"; exit 1; }

exit 0
