#!/usr/bin/env bash

set -x

APP_DIR="$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)"

cd $APP_DIR

BUILD_DIR=$TMPDIR/build
CACHE_DIR=$TMPDIR/cache

mkdir -p $BUILD_DIR
mkdir -p $CACHE_DIR

export BUILDPACK_DIR=$APP_DIR/r-build
cp init.r $BUILD_DIR/

bash r-build/compile $BUILD_DIR $CACHE_DIR
