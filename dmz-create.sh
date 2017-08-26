#!/bin/sh

[ ${1} -ge 1 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC=$(printf "%d" "${1}")
DMZ_DEC_PAD=$(printf "%03d" "${1}")
DMZ_HEX=$(printf "%02x" "${1}")

lxc network create dmz-${DMZ_DEC_PAD} \
  ipv4.address=10.0.${DMZ_DEC}.254/24 \
  ipv4.nat=false \
  ipv4.firewall=false \
  ipv4.dhcp=false \
  ipv6.address=fd00:0000:0000:00${DMZ_HEX}:FFFF:FFFF:FFFF:FFFE/64 \
  ipv6.nat=false \
  ipv6.firewall=false \
  ipv6.dhcp=false
