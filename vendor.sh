#!/usr/bin/env bash

#set -x

echo "#### Vendoring..."
#
source ./script/setenv.sh

#
which godep; if [ $? -ne 0 ]; then
    echo "godep not installed, getting it..."
    go get github.com/tools/godep
fi

echo

#
go get -d github.build.ge.com/unshut/goboot/web
go get -d github.build.ge.com/unshut/goboot/web/gorilla
go get -d github.build.ge.com/unshut/goboot/web/jsonrest
go get -d github.com/ant0ine/go-json-rest/rest
go get -d github.build.ge.com/unshut/goboot/web/restful
#
go get -d golang.org/x/sys/unix
#
go get -d github.com/kr/pty
go get -d golang.org/x/net/websocket

godep save; if [ $? -ne 0 ]; then
    echo "godev failed"
    exit 1
fi

echo "#### Vendoring done"

exit 0
##
