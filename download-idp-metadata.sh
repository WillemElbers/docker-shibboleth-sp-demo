#!/bin/bash
set -e

URL="https://unity-idm:2443/saml-idp/metadata"
FILE="/data/metadata/idp-metadata.xml"

if [ ! -f ${FILE} ]; then
    printf "Waiting for IDP."
    until $(curl --output /dev/null --silent --head --fail --insecure ${URL}); do
        printf '.'
        sleep 1
    done
    printf " Done\n"

    printf "Downloading metadata."
    curl -o ${FILE} --insecure --silent ${URL}
    printf ' Done\n'

    printf "Restarting service provider."
    supervisorctl restart shibd  > /dev/null 2>&1
    printf " Done\n"
else
    echo "Metadata file [${FILE}] already exists"
fi