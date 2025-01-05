#!/bin/bash
# gitsmart-help.sh

scriptName="$(command readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

main() {
    "${scriptDir}/shellkit/shellkit-help.sh" "${scriptDir}/gitsmart.bashrc"
}

[[ -z ${sourceMe} ]] && main "$@"
