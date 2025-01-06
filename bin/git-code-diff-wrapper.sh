#!/bin/bash
# git-code-diff-wrapper.sh

scriptName="$(readlink -f "$0")"

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
    ${xcode} --wait --diff "$2" "$5"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
