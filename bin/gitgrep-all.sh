#!/bin/bash

do_help() {
    cat <<-"EOF"
gitgrep_all.sh "<pattern>" [dir [dir..]] --f|--file --t|--text

Recursively search working copies of root dir(s) specified.

Options:
    -f, --file:  search for file by name
    -t, --text:  search for text in files
EOF
}

scriptName="$(readlink -f "$0")"
#scriptDir=$(command dirname -- "${scriptName}")

TopDirs=()
SearchMode=FILE  # --file or --text?
Pattern=  # 1st non-switch arg is always the pattern


die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}


parseArgs() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--text) SearchMode=TEXT ;;
            -f|--file) SearchMode=FILE ;;
            -h|--help) do_help; exit ;;
            -*) die "Unknown switch: $1" ;;
            *)
                [[ -z "$Pattern" ]] && {
                    Pattern="$1"
                    shift
                    continue
                }
                if [[ -d $1 ]]; then
                    TopDirs+=("$1") 
                else
                    echo "WARNING: unknown argument or not a dir: $1" >&2
                fi
                ;;
        esac
        shift
    done
    [[ ${#TopDirs[@]} -eq 0 ]] && {
        #shellcheck disable=SC2207
        TopDirs=( $(git rev-parse --show-toplevel) )
    }
}

# DEPENDENCY: We need gitgrep_t() and gitgrep_f() from gitsmart.bashrc:
#shellcheck disable=SC1091
source "${HOME}/.local/bin/gitsmart/gitsmart.bashrc" || die "Can't find gitsmart.bashrc"

do_search() {
    local top="$1"
    #local pattern="$2"
    local mode="$3"
    (
        cd "$top" || die "Can't cd into $top"  # We want an error, but not a script termination
        while read -r git_cur; do
            (
                wc_cur=$(dirname "${git_cur}")
                cd "$wc_cur" || die "Can't cd to $PWD/$wc_cur"
                case $mode in
                    TEXT)
                        gitgrep_t "${Pattern}" | sed "s,^,${PWD}/,"
                        ;;
                    FILE)
                        gitgrep_f "${Pattern}" | sed "s,^,${PWD}/,"
                        ;;
                    *) die Error 119
                esac
            )
        done < <( find . -type d -name .git 2>/dev/null )
    )
}

[[ -z ${sourceMe} ]] && {
    parseArgs "$@"
    for top in "${TopDirs[@]}"; do
        do_search "${top}" "${Pattern}" "${SearchMode}"
    done
    builtin exit
}
command true
