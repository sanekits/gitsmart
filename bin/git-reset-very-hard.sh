#!/bin/bash
# git-reset-very-hard.sh

scriptName="$(readlink -f "$0")"
# scriptDir is unused, so it has been removed
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

DoForce=${DoForce:-false} 
die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

do_reset_very_hard() {
    local args=( "$@" )
    [[ ${#args[@]} -eq 0 ]] \
        && args=( HEAD )
    set -ue
    local wcRoot
    wcRoot=$( git rev-parse --show-toplevel 2> /dev/null )
    [[ -d $wcRoot ]] \
        || die "Failed looking for working-copy root"
    cd -- "$wcRoot"
    [[ -d .git ]] \
        || die "Not a .git working tree: $PWD"
    if git-dirty &>/dev/null; then :
    else
        echo "Nothing to do in $PWD" >&2
        exit 0  # Nothing to do here
    fi
    local dirty_files
    dirty_files=$( git status -s | grep \? | cut -c 4- )
    local commit_name
    commit_name="${args[0]}"
    local target_ref
    target_ref=$( git rev-parse --verify "${commit_name}^{commit}" )
    [[ -n "$target_ref" ]] \
        || die "${commit_name}:  not a valid commit"
    if [[ "$DoForce" != true ]]; then
        if [[ -n "$dirty_files" ]]; then
            {
            echo "These files will be deleted PERMANENTLY!:"
            #shellcheck disable=SC2001
            echo "${dirty_files[@]}" | sed 's/^/  /'
            } >&2
        fi
        local prompt_str="Are you sure you want to reset the working copy to \"${commit_name}\""
        [[ -n "$dirty_files" ]] \
            && prompt_str="$prompt_str AND permanently destroy tracked files"
        prompt_str="${prompt_str}? [y/N] "
        read -rn 1 -p "$prompt_str"
        [[ $REPLY =~ [yY] ]] \
            || { echo; die "User cancelled.  Probably for the best."; }
        echo
    fi
    if [[ -z ${notReally+no} ]]; then # Define notReally=1 to uber-protect
        while read -r item; do
            rm -rf "$item"
        done < <(git status -s | grep \? | cut -c 4-)
        git reset --hard "${target_ref}"
    fi
}


[[ -z ${sourceMe} ]] && {

    [[ $# -eq 0 ]] \
        && set -- --prompt
    case "$1" in
        -h|--help)
            echo "Reset working copy to given ref (default=HEAD)"
            echo "  ... and ...!"
            echo "Recursive removal of untracked files."
            echo
            echo " --force: skip confirmation prompt"
            exit 1
            ;;
        -p|--prompt) 
            shift; 
            DoForce="" do_reset_very_hard "$@" 
            exit ;;
        -f|--force) 
            shift; 
            DoForce=true  do_reset_very_hard "$@"
            exit ;;
        *) 
            DoForce="" do_reset_very_hard "$@"; 
            exit ;;
    esac
    
}
command true
