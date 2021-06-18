#! /bin/bash
set -xe

if [ "$#" -lt 1 ]
then
    echo "ERROR: host required"
    echo "`basename $0` [host]"
    exit 1
fi

#/usr/bin/update-lomod.sh

HOST=$1
LOMOD_PORT=$2
LOMOW_PORT=$3

/opt/lomorage/bin/lomo-web --port $LOMOW_PORT --baseurl http://$HOST:$LOMOD_PORT &
/opt/lomorage/bin/lomod -p $LOMOD_PORT -b /lomo --max-upload 1 --max-fetch-preview 3
