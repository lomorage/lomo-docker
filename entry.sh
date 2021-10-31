#! /bin/bash
set -xe

if [ "$#" -lt 1 ]
then
    echo "ERROR: port required"
    echo "`basename $0` [port]"
    exit 1
fi

#/usr/bin/update-lomod.sh

LOMOD_PORT=$1
/opt/lomorage/bin/lomod -p $LOMOD_PORT -b /lomo --max-upload 1 --max-fetch-preview 3
