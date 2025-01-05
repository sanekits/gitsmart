#!/bin/bash
# git-make-child-clone.sh
#
#  Create a clone of the current working copy, in an alternate location.
#  Sets a `parent` remote on the clone which refers to the original source.
#
#  Destination dir can be command line argument, defaults to /tmp/{orig-basename}
#
#
#SCRIPT=$(basename $(readlink -f -- $0))

do_reset=false

die() {
    builtin echo "ERROR: $*" >&2
    exit 1
}

readymsg() {
    #local parent=$1
    local dest=$2
    local branch=$3

    (
        builtin cd -- "$dest" || die "203"
        command cat <<-EOF
Clone is open for business:
    destination: $dest
    branch: ${branch}
    parent: $(git  remote -v | grep parent | head -n 1)
EOF
    )

}

statusmsg() {
    local dest="$1"

    echo "====   Status of $dest: ===="
    git remote -v | sed 's/^/   /'
    git status | sed 's/^/   /'
    echo
    echo "OK: You may now safely do maintenance with 'code .':"
    echo "  cd $dest"
    echo "  code ."
    echo
    echo "  Be sure to commit + push when done."
}

do_help() {
    echo "$(basename "$0") <destination-dir> {--reset}"
    echo "   -> If destination-dir not specified, a temp dir is created."
    echo "   -> Remove and rewrite destination dir with --reset (DANGER)"
}


parseArgs() {
    ORIG_DIR=$PWD
    command git --version &>/dev/null || die "No git available"
    SOURCE_ROOT_DIR=$( command git rev-parse --show-toplevel 2>/dev/null )

    while [[ -n $1 ]]; do
        case $1 in
            -h|--help)
                 do_help "$@"
                exit 1
                ;;
            -r|--reset)
                do_reset=true
                ;;
            *)
                [[ -n $DEST_DIR ]] && die "Bad argument: $1"
                DEST_DIR=$1
                ;;
        esac
        shift
    done
    [[ -z $SOURCE_ROOT_DIR ]] && die "$PWD is not from a git working copy"
    [[ -z $DEST_DIR ]] && {
        DEST_DIR=/tmp/$(basename -- "$ORIG_DIR" )
        [[ -z $DEST_DIR ]] && die "Failed to create temp dest dir"
    }
}

main() {

    parseArgs "$@"

    [[ -d .git ]] || die "No .git in this dir"
    local branch
    branch=$(git symbolic-ref HEAD --short)

    $do_reset && {
        [[ -d "$DEST_DIR" ]] && {
            echo "$DEST_DIR exists, destroying because you said --reset!" >&2
            rm -rf "$DEST_DIR"
        }
    }

    command mkdir -p "$DEST_DIR"
    [[ -d $DEST_DIR ]] || die 102

    [[ -d ${DEST_DIR}/.git ]] && {
        readymsg "$SOURCE_ROOT_DIR" "$DEST_DIR" "${branch}"
        echo "Destination already exists."
        exit 0;
    }
    DEST_DIR="$(readlink -f "$DEST_DIR")"

    builtin cd "$DEST_DIR" || die 103

    command git clone  "$SOURCE_ROOT_DIR" . || die "Failed cloning $SOURCE_ROOT_DIR"

    command cp "${SOURCE_ROOT_DIR}/.git/config" .git/ || die 104
    command git remote remove parent &>/dev/null

    command git remote add parent "$SOURCE_ROOT_DIR" || die 105
    command git fetch parent

    [[ -n $branch ]] && {
        command git checkout "${branch}"
        command git branch -u "parent/${branch}"
    }

    statusmsg "$DEST_DIR"
    touch .ready
    readymsg "SOURCE_ROOT_DIR" "$DEST_DIR" "${branch}"
}

if [[ -z $sourceMe ]]; then
    main "$@"
fi
