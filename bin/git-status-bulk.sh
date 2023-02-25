#!/bin/bash
# git-status-bulk.sh
# Given a list of dirs:
#   - canonicalize and remove dupes
#   - preserve order of list
#   - Run 'git-status' with pretty output if terminal attached
#   - Page output if terminal attached and 'less' installed
#   - Options --color or --nocolor to force ansi state

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
PS4='+$?(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Recommend to call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    [[ -n $__stub_counter ]] && (( __stub_counter++  )) || __stub_counter=1
    {
        builtin printf "  <=< STUB(%d:%s)" $__stub_counter "$(basename $scriptName)"
        builtin printf "[%s] " "$@"
        builtin printf " >=> \n"
    } >&2
}

colorsinit() {
    local enable=$1
    if $enable; then
        HasTerminal=true
        function ttyEx {
            local cmd='script -qefc "$@" /dev/null'
            eval "$cmd"
        }
        function yellow {
            echo -en "\033[;33m"
            echo "$@"
            echo -en "\033[;0m"
        }
    else
        HasTerminal=false
        function ttyEx {
            eval "bash -c \"$@\""
        }
        function yellow {
            echo "$@"
        }
    fi
} # </colorsinit()>

pageinit() {
    if which less &>/dev/null; then
        function pager() {
            less -FRX
        }
    else
        function pager() {
            more
        }
    fi
}


VisitedDirs=  # Colon-delimited+canonicalized, to prevent dupes
visitedMunge ()
{
    [[ -n "$1" ]] || return;  # Return false because no arg provided
    case ":${VisitedDirs}:" in
        *:"$1":*) false; return ;;  # Return false because this dir is nothing new
        *)
            VisitedDirs=$VisitedDirs:$1;
        ;;
    esac
    true  # We didn't bail out so this is new
} # </visitedMunge()

do_gitstatus() {
    #echo "do_gitstatus called: $@" >&2
    yellow "# $1"
    ttyEx "cd \"$1\" && git status" | sed 's,^,   ,'
}

canonicalize_dir() {
    [[ -n "$@" ]] || return
    ( cd -- "$@" && readlink -f "$PWD" )
}

foreach_dir() {
    local dispatchTo="$1"; shift

    for thisDir in "$@"; do
        local c_path="$(canonicalize_dir ${thisDir})"
        [[ -n "$c_path" ]] || continue
        if visitedMunge "$c_path"; then
            $dispatchTo "$c_path"
        fi
    done
}


[[ -z ${sourceMe} ]] && {

    RawDirs=()

    # Default ansi color handling:
    [[ -t 1 ]] && colorsinit true || colorsinit false;
    pageinit

    while [[ -n $1 ]]; do
        case $1 in
            --color) colorsinit true;;
            --nocolor) colorsinit false;;
            *)
                RawDirs+=( $1 );;
        esac
        shift
    done

    foreach_dir do_gitstatus "${RawDirs[@]}" | pager

    builtin exit
}
command true
