#!/usr/bin/env bash

#
source ./script/setenv.sh

#
echo "Starting..."
#
chmod +x ./vendor.sh
./vendor.sh; if [ $? -ne 0 ]; then
    echo "#### Vendoring failed, exiting..."
    exit 1
fi

chmod +x ./build.sh
./build.sh; if [ $? -ne 0 ]; then
    echo "#### Build failed, exiting..."
    exit 1
fi

#

$APP_EXE

exit 0
##