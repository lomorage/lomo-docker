#! /bin/bash

set -x

DEBUG=0
AUTOUPDATE=0
HOME_MEDIA_DIR=/media/primary
HOME_MEDIA_BAKUP_DIR=
HOME_LOMO_DIR=/home/"$USER"/lomo
LOMOD_HOST_PORT=8000
IMAGE_NAME="lomorage/raspberrypi-lomorage:latest"
AUTO_UPDATE_IMG="containrrr/watchtower:armhf-latest"
VLAN_NAME="lomorage"

COMMAND_LINE_OPTIONS_HELP="

You can use either use macvlan or ipvlan which makes MDNS service discovery work.
But macvlan and ipvlan are only support on Linux, so if you are on Windows or Mac, you can't use it.

Command line options:
    -m  DIR         path of media directory used for media assets, default to \"$HOME_MEDIA_DIR\", optional
    -k  DIR         path of media backup directory used for media assets, default to \"$HOME_MEDIA_BAKUP_DIR\", optional
    -b  DIR         path of lomo directory used for db and log files, default to \"$HOME_LOMO_DIR\", optional
    -s  SUBNET      Subnet of the host network(like 192.168.1.0/24), required when using vlan
    -g  GATEWAY     gateway of the host network(like 192.168.1.1), required when using vlan
    -n  NETWORK_INF network interface of the host network(like eth0), required when using vlan
    -t  VLAN_TYPE   vlan type, can be \"macvlan\" or \"ipvlan\", required when using vlan
    -a  VLAN_ADDR   vlan address to be used(like 192.168.1.99), required when using vlan
    -p  LOMOD_PORT  lomo-backend service port exposed on host machine, default to \"$LOMOD_HOST_PORT\", optional
    -i  IMAGE_NAME  docker image name, for example \"lomorage/raspberrypi-lomorage:[tag]\", default \"$IMAGE_NAME\", optional
    -e  ENV_FILE    environment variable file passed into container, optional
    -d              Debug mode to run in foreground, default to $DEBUG, optional
    -u              Auto upgrade lomorage docker images, default to $DEBUG, optional

Examples:
    # assuming your hard drive mounted in /media, like /media/usb0, /media/usb0
    ./run.sh -m /media -b /home/pi/lomo -s 192.168.1.0/24 -g 192.168.1.1 -n eth0 -t macvlan -a 192.168.1.99

    # or if you don't use vlan
    ./run.sh -m /media -b /home/pi/lomo -h 192.168.1.99
"

function help() {
    echo "`basename $0` [-m {media-dir} -k {backup-dir} -b {lomo-dir} -d -u -p {lomod-port} -P {lomow-port} -i {image-name}] -t vlan-type -s subnet -g gateway -n network-interface -a vlan-address"
    echo "$COMMAND_LINE_OPTIONS_HELP"
    exit 3;
}

function createIpVlan() {
    sudo docker network ls | grep $VLAN_NAME
    if [ $? -eq 0 ]; then
        sudo docker network rm $VLAN_NAME
    fi
    sudo docker network create -d ipvlan -o ipvlan_mode=l2 --subnet=$1 --gateway=$2 -o parent=$3 $VLAN_NAME
}

function createMacVlan() {
    sudo docker network ls | grep $VLAN_NAME
    if [ $? -eq 0 ]; then
        sudo docker network rm $VLAN_NAME
    fi
    sudo docker network create -d macvlan --subnet=$1 --gateway=$2 -o parent=$3 $VLAN_NAME
}

function abspath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

OPTIONS=m:,k:,b:,i:,e:,p:,P:,s:,g:,n:,a:,t:,h:,d,u
PARSED=$(getopt $OPTIONS $*)
if [ $? -ne 0 ]; then
    echo "getopt error"
    exit 2
fi

eval set -- "$PARSED"

while true; do
    case "$1" in
        -m)
            HOME_MEDIA_DIR=$(abspath $2)
            shift 2
            ;;
        -k)
            HOME_MEDIA_BAKUP_DIR=$(abspath $2)
            shift 2
            ;;
        -b)
            HOME_LOMO_DIR=$(abspath $2)
            shift 2
            ;;
        -p)
            LOMOD_HOST_PORT=$2
            shift 2
            ;;
        -i)
            IMAGE_NAME=$2
            shift 2
            ;;
        -e)
            ENV_FILE=$2
            shift 2
            ;;
        -P)
            echo "WARNING: -P is deprecated, lomo-web and lomod use the same port now"
            shift 2
            ;;
        -s)
            SUBNET=$2
            shift 2
            ;;
        -g)
            GATEWAY=$2
            shift 2
            ;;
        -n)
            NETWORK_INF=$2
            shift 2
            ;;
        -t)
            VLAN_TYPE=$2
            shift 2
            ;;
        -a)
            VLAN_ADDR=$2
            shift 2
            ;;
        -d)
            DEBUG=1
            shift
            ;;
        -u)
            AUTOUPDATE=1
            shift
            ;;
        -h)
            echo "WARNING:-h is deprecated, lomo-web is now integrated with lomod"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "ERROR: option not found!"
	    help
            ;;
    esac
done

[ -z "$IMAGE_NAME" ] && echo "Docker image name required!" && help

if [ "$VLAN_TYPE" != "ipvlan" ] && [ "$VLAN_TYPE" != "macvlan" ] && [ ! -z "$VLAN_TYPE" ]; then
    echo "vlan type should either be \"ipvlan\" or \"macvlan\" or empty"
    help
fi

if [ -z "$ENV_FILE" ]; then
    ENV_FILE_OPTION=""
else
    ENV_FILE_OPTION="--env-file $ENV_FILE"
fi

echo "lomo-backend host port: $LOMOD_HOST_PORT"
echo "Media directory: $HOME_MEDIA_DIR"
echo "Media backup directory: $HOME_MEDIA_BAKUP_DIR"
echo "Lomo directory: $HOME_LOMO_DIR"

mkdir -p "$HOME_MEDIA_DIR"
mkdir -p "$HOME_LOMO_DIR"

MAP_MEDIA_PARAMS="-v $HOME_MEDIA_DIR:/media/primary"
if [ -n "$HOME_MEDIA_BAKUP_DIR" ]; then
    mkdir -p "$HOME_MEDIA_BAKUP_DIR"
    MAP_MEDIA_PARAMS="-v $HOME_MEDIA_DIR:/media/primary -v $HOME_MEDIA_BAKUP_DIR:/media/backup"
fi

if [ "$IMAGE_NAME" != "lomorage/raspberrypi-lomorage:latest" ]; then
    AUTO_UPDATE_IMG="containrrr/watchtower"
fi

if [ $AUTOUPDATE -eq 1 ]; then
   sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock --rm $AUTO_UPDATE_IMG lomorage --cleanup
fi

if [ "$VLAN_TYPE" == "ipvlan" ] || [ "$VLAN_TYPE" == "macvlan" ]; then
    [ -z "$SUBNET" ] && echo "Subnet required!" && help
    [ -z "$GATEWAY" ] && echo "Gateway required!" && help
    [ -z "$NETWORK_INF" ] && echo "Network interface required!" && help
    [ -z "$VLAN_ADDR" ] && echo "Vlan address required!" && help
    echo "Subnet: $SUBNET"
    echo "GATEWAY: $GATEWAY"
    echo "Network Interface: $NETWORK_INF"
    echo "Vlan address: $VLAN_ADDR"
    echo "Vlan type: $VLAN_TYPE"
    if [ "$VLAN_TYPE" == "ipvlan" ]; then
        createIpVlan $SUBNET $GATEWAY $NETWORK_INF
    else
        createMacVlan $SUBNET $GATEWAY $NETWORK_INF
    fi


    if [ $DEBUG -eq 0 ]; then
        sudo docker run $ENV_FILE_OPTION --net $VLAN_NAME --ip $VLAN_ADDR --user=$UID:$(id -g $USER) -d --privileged --cap-add=ALL \
                -v /dev:/dev $MAP_MEDIA_PARAMS -v "$HOME_LOMO_DIR:/lomo" --rm \
                --name=lomorage $IMAGE_NAME $LOMOD_HOST_PORT
    else
        sudo docker run $ENV_FILE_OPTION --net $VLAN_NAME --ip $VLAN_ADDR --user=$UID:$(id -g $USER) --privileged --cap-add=ALL \
                -v /dev:/dev $MAP_MEDIA_PARAMS -v "$HOME_LOMO_DIR:/lomo" --rm \
                --name=lomorage $IMAGE_NAME $LOMOD_HOST_PORT
    fi
else
    if [ $DEBUG -eq 0 ]; then
        sudo docker run $ENV_FILE_OPTION --user=$UID:$(id -g $USER) -d --privileged --cap-add=ALL -p $LOMOD_HOST_PORT:$LOMOD_HOST_PORT \
                $MAP_MEDIA_PARAMS -v "$HOME_LOMO_DIR:/lomo" -v /dev:/dev --rm \
                --name=lomorage $IMAGE_NAME $LOMOD_HOST_PORT
    else
        sudo docker run $ENV_FILE_OPTION --user=$UID:$(id -g $USER) --privileged --cap-add=ALL -p $LOMOD_HOST_PORT:$LOMOD_HOST_PORT \
                $MAP_MEDIA_PARAMS -v "$HOME_LOMO_DIR:/lomo" -v /dev:/dev --rm \
                --name=lomorage $IMAGE_NAME $LOMOD_HOST_PORT
    fi
fi
