#!/bin/bash
# git-remote-show-urls.sh

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

FILE_ARGS=()

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}


match_subst_urls() {
    # match entries are [pattern] [result]
    command sed  \
        -e 's%git@bbgithub\.dev\.bloomberg\.com:%https://bbgithub.dev.bloomberg.com/%' \
        -e 's%git@github\.com:%https://github.com/%' \
        -e 's% bbgithub:% https://bbgithub.dev.bloomberg.com/%'
}

append_file_args() {
    [[ ${#FILE_ARGS[@]} -eq 0 ]] && {
        cat
        return
    }
    local gitroot=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -n "$gitroot" ]] || die 19
    local root_start=$(( ${#gitroot} + 1 ))
    while read line; do
        for file_arg in ${FILE_ARGS[@]}; do
            local rel_path=$(readlink -f $file_arg | cut -c ${root_start}- )
            echo "${line}${rel_path}"
        done
    done
}

append_tree_branch() {
    # Append the tree/<branch> suffix if the URL is not a gist:
    local branch="$1"
    while read line; do
        if [[ "${line}" == */gist/* ]]; then
            echo "${line}"
            continue
        fi
        echo "${line}" | sed -e "s,\$,/tree/$branch," 
    done
}

transform_entry() {
    local branch="$1"
    local remote_name="$2"
    local host_entry="$3"

    # Transform sequence:
    #   1.  Replace ssh host entries with https (match_subst_urls())
    #   2.  Trim off any trailing '.git' for the repo name
    #   3.  Append the tree/<branch> suffix 
    #   4.  append_file_args()
    echo "$remote_name $host_entry" \
        | match_subst_urls  \
        | sed -e "s,\.git\$,," \
        | append_tree_branch "$branch" \
        | append_file_args

}

main() {
    command -V git &>/dev/null || die "No git installed"

    FILE_ARGS=( "$@" )

    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    while read remote_name entry mode; do
        transform_entry "$branch" "$remote_name" "$entry"
    done < <( command git remote -v | command grep -E '\(fetch\)' )
}

[[ -z ${sourceMe} ]] && main "$@"
