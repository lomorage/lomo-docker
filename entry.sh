#! /bin/bash
set -xe

if [ "$#" -lt 1 ]
then
    echo "listen at 8000"
    LOMOD_PORT=8000
else
    LOMOD_PORT=$1
fi

#/usr/bin/update-lomod.sh

/opt/lomorage/bin/lomod -p $LOMOD_PORT -b /lomo --max-upload 1 --max-fetch-preview 3
