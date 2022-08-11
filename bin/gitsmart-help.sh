#!/bin/bash
# gitsmart-help.sh

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    ${scriptDir}/shellkit/shellkit-help.sh ${script}/gitsmart/gitsmart.bashrc
}

[[ -z ${sourceMe} ]] && main "$@"
