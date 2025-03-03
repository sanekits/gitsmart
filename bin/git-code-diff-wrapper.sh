#!/bin/bash
# git-code-diff-wrapper.sh

PS4='\033[0;33m+$?( $( set +u; [[ -z "$BASH_SOURCE" ]] || realpath "${BASH_SOURCE[0]}"):${LINENO} ):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

scriptName="$(readlink -f "$0")"
scriptBase=$(basename -- "${scriptName}")


DEBUG_GIT_WRAPPER=${DEBUG_GIT_WRAPPER:-false}

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

main() {
    if $DEBUG_GIT_WRAPPER; then
        echo "git passed $# args to wrapper:"
        printf "  %s\n" "$@"
    fi >&2
    if [[ "$USE_VSCODE" == true ]]; then
        echo -e "\033[;33m${scriptBase} DIFF:\033[0m \033[;31m$2\033[0;33m <--> \033[0;32m$5\033[;0m" >&2
        ${GIT_EDITOR} --wait --diff "$2" "$5"
        return
    fi
    "${GIT_EDITOR}" "$@"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
