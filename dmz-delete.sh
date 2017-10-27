#!/bin/sh

[ ${UID} -eq 0 ] || { 1>&2 echo "This script must be run as root" ; exit 1 ; }

[ ${#} -eq 1 ] || { 1>&2 echo "Usage: ${0} DMZ_NUM" ; exit 1 ; }

[ ${1} -ge 0 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC=$(printf "%d" "${1}")
DMZ_HEX=$(printf "%02x" "${1}")
IF="dmz${DMZ_DEC}"

ifdown ${IF}
[ ${?} -eq 0 ] || { 1>&2 echo "Interface de-configuraiton exited with code ${?}"; }

rm /etc/network/interfaces.d/50-${IF}.conf
[ ${?} -eq 0 ] || { 1>&2 echo "Interface configuration deletion ended with code ${?}"; }

exit 0
