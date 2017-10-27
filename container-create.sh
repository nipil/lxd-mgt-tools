#!/bin/sh

[ ${#} -eq 3 ] || { 1>&2 echo "Usage: ${0} dmz cnum cname"; exit 1 ; }

[ ${1} -ge 0 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

[ ${2} -ge 1 -a ${2} -le 255 ] || { 1>&2 echo "Invalid container number ${2}" ; exit 1 ; }

[ -n "${3}" ] || { 1>&2 echo "A name is required for the container" ; exit 1 ; }

DMZ_DEC=$(printf "%d" "${1}")
DMZ_DEC_PAD=$(printf "%03d" "${1}")
DMZ_HEX=$(printf "%02x" "${1}")

VM_DEC=$(printf "%d" "${2}")
VM_HEX=$(printf "%02x" "${2}")

lxc info ${3} 1>&- 2>&-
[ ${?} -ne 0 ] || { 1>&2 echo "VM ${3} does already exist" ; exit 1 ; }

TMP=$(mktemp)
[ ${?} -eq 0 ] || { 1>&2 echo "Impossible to create temporary file" ; exit 1 ; }

lxc init --network dmz${DMZ_DEC} images:debian/stretch ${3}
[ ${?} -eq 0 ] || { "Error while creating container (return code ${?}" ; rm -f ${TMP} ; exit 1 ; }

cat << EOF > ${TMP}
nameserver 194.132.32.32
nameserver 46.246.46.246
nameserver 2C0F:F930:DEAD:BEEF::32
nameserver 2001:67C:1350:DEAD:BEEF::246
EOF

lxc file push --uid=0 --gid=0 --mode=644 ${TMP} ${3}/etc/resolv.conf
[ ${?} -eq 0 ] || { "Error while pushing resolver configuration (return code ${?}" ; rm -f ${TMP} ; exit 1 ; }

cat << EOF > ${TMP}
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.0.${DMZ_DEC}.${VM_DEC}/24
    gateway 10.0.${DMZ_DEC}.254

iface eth0 inet6 static
    address fd00:0000:0000:00${DMZ_HEX}:0000:0000:0000:00${VM_HEX}/64
    gateway fd00:0000:0000:00${DMZ_HEX}:FFFF:FFFF:FFFF:FFFE
EOF

lxc file push --uid=0 --gid=0 --mode=644 ${TMP} ${3}/etc/network/interfaces
[ ${?} -eq 0 ] || { "Error while pushing network configuration (return code ${?}" ; rm -f ${TMP} ; exit 1 ; }

lxc start ${3}
[ ${?} -eq 0 ] || { "Error while starting container (return code ${?}" ; rm -f ${TMP} ; exit 1 ; }

rm -f ${TMP}

exit 0
