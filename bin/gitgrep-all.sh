#!/bin/bash
# gitgrep_all.sh <pattern> [dir [dir..]] --f|--file --t|--text
#
#  Recursively search working copies of root dirs specified.
#  Mode is --file (match name) or --text (match text)
#
#  Options:
#    -f, --file:  search for file by name

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

TopDirs=()
SearchMode=FILE  # --file or --text?
Pattern=  # 1st non-switch arg is always the pattern


die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}


parseArgs() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--text) SearchMode=TEXT ;;
            -f|--file) SearchMode=FILE ;;
            -*) die "Unknown switch: $1" ;;
            *)
                [[ -z "$Pattern" ]] && {
                    Pattern="$1"
                    shift
                    continue
                }
                [[ -d $1 ]] && TopDirs+=($1) || {
                    echo "WARNING: unknown argument or not a dir: $1" >&2
                }
                ;;
        esac
        shift
    done
    [[ ${#TopDirs[@]} -eq 0 ]] && TopDirs=( $PWD )
}

# DEPENDENCY: We need gitgrep_t() and gitgrep_f() from gitsmart.bashrc:
source ${HOME}/.local/bin/gitsmart/gitsmart.bashrc || die "Can't find gitsmart.bashrc"

do_search() {
    local top="$1"
    local pattern="$2"
    local mode="$3"
    (
        cd $top || die "Can't cd into $top"  # We want an error, but not a script termination
        while read git_cur; do
            (
                wc_cur=$(dirname ${git_cur})
                cd $wc_cur || die "Can't cd to $PWD/$wc_cur"
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
        done < <( find -type d -name .git 2>/dev/null )
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
