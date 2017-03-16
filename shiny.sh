#!/usr/bin/env bash

set -x

APP_DIR="$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)"

cd $APP_DIR

R --no-save --gui-none < startscript.R