#!/usr/bin/env bash

#args:
# BUILD_NUMBER
# VERSION

#set -x
rm -rf ./vendor
rm -rf ./Godeps
#
chmod +x ./vendor.sh
./vendor.sh; if [ $? -ne 0 ]; then
    echo "#### Vendoring failed, exiting..."
    exit 1
fi
#
source ./script/setenv.sh

#
which cf; if [ $? -ne 0 ]; then
    echo "## cf not installed, exiting..."
    exit 1
fi

#check login
cf target; if [ $? -ne 0 ]; then
    exit 1
fi

export BUILD=$1_$(date "+%m%d%Y.%H%M.%S")
export VERSION=$2

if [ "x$VERSION" = "x" ]; then
    #default version to top commit hash
    which git; if [ $? -eq 0 ]; then
        export VERSION=$(git log -n 1 --pretty=format:%H)
    fi
fi

#
cd $WORKSPACE

#
# Predix ENV specific settings if any
if [ -f ./setenv-${ENV}.sh ]; then
   echo "Sourcing ./setenv-${ENV}.sh ..."
   source ./setenv-${ENV}.sh
fi

#
printenv

#
echo "#### Deploying to $ENV ..."

#
function set_app_url() {
    local domain_name=$(cf app $1|grep urls: |cut -d ' ' -f 2)
    export APP_URL="https://${domain_name}"
}

#
function deploy() {
    echo "Pushing service..."

    env_subst manifest_env.yml manifest.yml

    cat manifest.yml

#    cf bgd app-name-${ENV} #--smoke-test <path to test script>

    cf push -f manifest.yml; if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

rmdir ./vendor
rmdir ./Godeps

deploy; if [ $? -ne 0 ]; then
    echo "#### Deploy failed"
    exit 1
fi

set_app_url ${APP_EXE}-${ENV}

echo "#### Deploy successful"
echo "VERSION: $VERSION"
echo "BUILD: $BUILD"
echo "APP_URL: $APP_URL"
echo ""
exit 0
##
