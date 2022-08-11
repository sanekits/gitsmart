#!/bin/bash
# gitsmart-help.sh

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

scriptName="$(canonpath $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

parse_help_items() {
    # Given a stream of shell text with #help markers, print a "help item" for
    # each.
    while read line; do
        echo -n $line | tr -d '(){' | sed -e 's/^function //'
        read helptext
        echo "$helptext" | sed -s 's/^\s*#help/\t/'
        read _
    done < <(command grep -E -B1 '\s*#help ')

}

main() {
    cat ${scriptDir}/gitsmart.bashrc | parse_help_items
}

[[ -z ${sourceMe} ]] && main "$@"

