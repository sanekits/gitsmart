#!/bin/bash
# git-code-diff-wrapper.sh

scriptName="$(readlink -f "$0")"
scriptBase=$(basename -- "${scriptName}")

DEBUG_GIT_WRAPPER=${DEBUG_GIT_WRAPPER:-false}

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}


main() {
    local xcode
    {
        echo "git passed $# args to wrapper:"
        printf "  %s\n" "$@"
    } >&2
    xcode=$(which code-server code | head -n 1)
    [[ -z ${xcode} ]] && {
        run_terminal_editor "$@"
        exit
    }
    echo -e "\033[;33m${scriptBase} DIFF:\033[0m \033[;31m$2\033[0;33m <--> \033[0;32m$5\033[;0m" >&2
    ${xcode} --wait --diff "$2" "$5"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
