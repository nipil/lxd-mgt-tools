#!/bin/sh

[ ${1} -ge 1 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC_PAD=$(printf "%03d" "${1}")

lxc network delete dmz-${DMZ_DEC_PAD}
