#!/usr/bin/env bash

#set -x

#
source ./script/setenv.sh

#
printenv

#
echo "#### Building ..."
#
function build_module() {
    echo "## Cleaning ..."
    go clean -x

    echo "## Building ..."
    go build -x

    echo "## Testing ..."
    go test -x

    echo "## Installing ..."
    go install -x

    if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

build_module; if [ $? -ne 0 ]; then
    echo "#### Build failded"
    exit 1
fi

echo "#### Build successful"

exit 0
##

