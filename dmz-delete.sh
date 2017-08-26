#!/bin/sh

[ ${1} -ge 1 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC_PAD=$(printf "%03d" "${1}")

lxc network show dmz-${DMZ_DEC_PAD} 1>&- 2>&-
[ ${?} -eq 0 ] || { 1>&2 echo "Network ${1} does not exist" ; exit 1 ; }

lxc network delete dmz-${DMZ_DEC_PAD}

RES=${?}
[ ${RES} -ne 0 ] || { 1>&2 echo "Network deletion exited with code ${RES}" ; }

exit 0
