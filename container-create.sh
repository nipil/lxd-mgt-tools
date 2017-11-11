#!/usr/bin/env bash

#####################################################################
# CONFIGURATION
#####################################################################

STORAGE="files"

#####################################################################
# ARGS
#####################################################################

[ ${#} -ge 3 ] || { 1>&2 echo "Usage: ${0} dmz cnum cname"; exit 1 ; }

[ ${1} -ge 0 -a ${1} -le 255 ] || { 1>&2 echo "Invalid DMZ number ${1}" ; exit 1 ; }

DMZ_DEC=$(printf "%d" "${1}")
DMZ_DEC_PAD=$(printf "%03d" "${1}")
DMZ_HEX=$(printf "%02x" "${1}")

[ ${2} -ge 1 -a ${2} -le 255 ] || { 1>&2 echo "Invalid container number ${2}" ; exit 1 ; }

VM_DEC=$(printf "%d" "${2}")
VM_HEX=$(printf "%02x" "${2}")

[ -n "${3}" ] || { 1>&2 echo "A name is required for the container" ; exit 1 ; }

CONTAINER="${3}"

shift 3

PACKAGES="${@}"

#####################################################################
# FUNCTIONS
#####################################################################

function __log {
        local __SCRIPT_PID=${$} __LEVEL=${1}

        # verify that we have a level
        [[ -n "${__LEVEL}" ]] || >&2 echo "No log level provided"

        # remove level
        shift

        # add timestamp and level
        echo "$(date +'%F %X %Z') ${__LEVEL}: ${@}"
}

function info {
        __log "INFO" "$@"
}

function err {
        __log "ERROR" "$@"
}

function check_return_code_success {
    [ ${?} -eq 0 ] || { err "${1:-Expected zero return code, got non-zero}" ; exit 1 ; }
}

function check_return_code_fail {
    [ ${?} -ne 0 ] || { err "${1:-Expected non-zero return code, got zero}" ; exit 1 ; }
}

function store_content {
    local __FILE="${1}"
    local __CONTENT="${2}"
    local __UID="${3:-0}"
    local __GID="${4:-0}"
    local __MODE="${5:-664}"

    local __LOCAL_FILE="${STORAGE}${__FILE}"
    local __DIR=$(dirname "${__LOCAL_FILE}")

    mkdir -p "${__DIR}"
    check_return_code_success "Could not create directory ${__DIR}"

    echo "${__CONTENT}" > "${__LOCAL_FILE}"
    check_return_code_success "Could not save content to ${__LOCAL_FILE}"

    lxc file push --uid=${__UID} --gid=${__GID} --mode=${__MODE} ${__LOCAL_FILE} ${CONTAINER}${__FILE}
    check_return_code_success "Could not store ${__LOCAL_FILE} into ${CONTAINER}"
}

function container_exec {
    lxc exec ${CONTAINER} -- "${@}"
    check_return_code_success "Command ${@} returned ${?}"
}

#####################################################################
# MAIN SCRIPT
#####################################################################

info "Check that container does not exist"
lxc info "${CONTAINER}" 1>&- 2>&-
check_return_code_fail "Container ${CONTAINER} already exists"

info "Create container (without starting it)"
lxc init --network dmz${DMZ_DEC} images:debian/stretch ${CONTAINER}
check_return_code_success "Creating container failed (return code ${?})"

info "Setup resolver"
store_content "/etc/resolv.conf" \
"# IPRED DNS
nameserver 194.132.32.32
nameserver 46.246.46.246
nameserver 2C0F:F930:DEAD:BEEF::32
nameserver 2001:67C:1350:DEAD:BEEF::246"

info "Setup networking"
store_content "/etc/network/interfaces" \
"auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
    address 10.0.${DMZ_DEC}.${VM_DEC}/24
    gateway 10.0.${DMZ_DEC}.254
iface eth0 inet6 static
    address fd00:0000:0000:00${DMZ_HEX}:0000:0000:0000:00${VM_HEX}/64
    gateway fd00:0000:0000:00${DMZ_HEX}:FFFF:FFFF:FFFF:FFFE"

info "Setup apt-get behaviour"
store_content "/etc/apt/apt.conf.d/99no-recommends" \
'APT::Install-Recommends "false";
APT::Install-Suggests "false";'

info "Setup apt-up script"
store_content "/usr/local/sbin/apt-up" \
'apt-get update && apt-get upgrade "${@}" && apt-get dist-upgrade "${@}" && apt-get autoremove "${@}" && apt-get clean' \
0 0 775

info "Start container"
lxc start ${CONTAINER}
check_return_code_success "Could not start ${CONTAINER}"

info "Give it some time to start"
sleep 5

info "Persist journald on disk"
container_exec sed -i -e 's,.*Storage=.*,Storage=persistent,' -e 's,.*SystemMaxUse=.*,SystemMaxUse=100M,' /etc/systemd/journald.conf
container_exec systemctl restart systemd-journald
container_exec systemctl status systemd-journald.service

info "Turn off unused console"
container_exec systemctl stop console-getty
container_exec systemctl disable console-getty

info "Upgrade packages"
container_exec apt-up --assume-yes

info "Install requested packages"
container_exec apt-get install --assume-yes inetutils-ping ${PACKAGES}

info "Clean"
find "${STORAGE}" -delete

info "Finish"
exit 0
