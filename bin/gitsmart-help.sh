#!/bin/bash
# gitsmart-help.sh

scriptName="$(command readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

main() {
    "${scriptDir}/shellkit/shellkit-help.sh" "${scriptDir}/gitsmart.bashrc"
}

[[ -z ${sourceMe} ]] && main "$@"
