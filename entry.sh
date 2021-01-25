#! /bin/bash
set -xe

if [ "$#" -lt 1 ]
then
    echo "ERROR: host required"
    echo "`basename $0` [host]"
    exit 1
fi

cron && tail -f /var/log/cron.log &

/opt/lomorage/bin/lomo-web --port 8001 --baseurl http://$1:8000 &
/opt/lomorage/bin/lomod -b /lomo --max-upload 1 --max-fetch-preview 3
