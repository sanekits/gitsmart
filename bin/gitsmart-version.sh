#!/bin/bash

# Running {Kitname}-version.sh is the correct way to
# get the home install path for the tool
Ps1FooVersion=0.5.0

set -e

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- $0)"; echo "$(command pwd -P)/$(command basename -- $0)" )
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")


if [ -z "$sourceMe" ]; then
    printf "%s\t%s" ${Scriptdir}/ps1-foo ${Ps1FooVersion}
fi
