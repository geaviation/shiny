#!/usr/bin/env bash

set -x

APP_DIR="$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)"

cd $APP_DIR

CACHE_DIR=tmp
mkdir $CACHE_DIR

bash r-build/compile $APP_DIR $CACHE_DIR