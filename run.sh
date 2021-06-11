#! /bin/bash

DEBUG=0
HOME_MEDIA_DIR=/media
HOME_LOMO_DIR=/home/"$USER"/lomo
LOMOD_HOST_PORT=8000
LOMOW_HOST_PORT=8001
IMAGE_NAME="lomorage/raspberrypi-lomorage:latest"
VLAN_NAME="lomorage"

COMMAND_LINE_OPTIONS_HELP="
Command line options:
    -m  DIR         Absolute path of media directory used for media assets, default to \"$HOME_MEDIA_DIR\", optional
    -b  DIR         Absolute path of lomo directory used for db and log files, default to \"$HOME_LOMO_DIR\", optional
    -s  SUBNET      Subnet of the host network(like 192.168.1.0/24), required
    -g  GATEWAY     gateway of the host network(like 192.168.1.1), required
    -n  NETWORK_INF network interface of the host network(like eth0), required
    -t  VLAN_TYPE   vlan type, can be \"macvlan\" or \"ipvlan\", required
    -a  VLAN_ADDR   vlan address to be used(like 192.168.1.99), required
    -p  LOMOD_PORT  lomo-backend service port exposed on host machine, default to \"$LOMOD_HOST_PORT\", optional
    -P  LOMOW_PORT  lomo-web service port exposed on host machine, default to \"$LOMOW_HOST_PORT\", optional
    -i  IMAGE_NAME  docker image name, for example \"lomorage/raspberrypi-lomorage:[tag]\", default \"$IMAGE_NAME\", optional
    -d              Debug mode to run in foreground, default to $DEBUG, optional

Examples:
    # assuming your hard drive mounted in /media, like /media/usb0, /media/usb0
    ./run.sh -m /media -b /home/pi/lomo -s 192.168.1.0/24 -g 192.168.1.1 -n eth0 -t macvlan -a 192.168.1.99
"

function help() {
    echo "`basename $0` [-m {media-dir} -b {lomo-dir} -d -p {lomod-port} -P {lomow-port} -i {image-name}] -t vlan-type -s subnet -g gateway -n network-interface -a vlan-address"
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

OPTIONS=m:,b:,i:,p:,P:,s:,g:,n:,a:,t:,d
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
        -b)
            HOME_LOMO_DIR=$(abspath $2)
            shift 2
            ;;
        -p)
            LOMOD_HOST_PORT=$2
            shift 2
            ;;
        -P)
            LOMOW_HOST_PORT=$2
            shift 2
            ;;
        -i)
            IMAGE_NAME=$2
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

[ -z "$SUBNET" ] && echo "Subnet required!" && help
[ -z "$GATEWAY" ] && echo "Gateway required!" && help
[ -z "$VLAN_TYPE" ] && echo "Vlan type required!" && help
[ -z "$NETWORK_INF" ] && echo "Network interface required!" && help
[ -z "$VLAN_ADDR" ] && echo "Vlan address required!" && help
[ -z "$IMAGE_NAME" ] && echo "Docker image name required!" && help

if [ "$VLAN_TYPE" != "ipvlan" ] && [ "$VLAN_TYPE" != "macvlan" ]; then
    echo "vlan type should either be \"ipvlan\" or \"macvlan\""
    help
fi

echo "Subnet: $SUBNET"
echo "GATEWAY: $GATEWAY"
echo "Network Interface: $NETWORK_INF"
echo "Vlan address: $VLAN_ADDR"
echo "Vlan type: $VLAN_TYPE"

echo "lomo-backend host port: $LOMOW_HOST_PORT"
echo "lomo-web host port: $LOMOD_HOST_PORT"
echo "Media directory: $HOME_MEDIA_DIR"
echo "Lomo directory: $HOME_LOMO_DIR"

mkdir -p "$HOME_MEDIA_DIR"
mkdir -p "$HOME_LOMO_DIR"

if [ "$VLAN_TYPE" == "ipvlan" ]; then
    createIpVlan $SUBNET $GATEWAY $NETWORK_INF
else
    createMacVlan $SUBNET $GATEWAY $NETWORK_INF
fi


if [ $DEBUG -eq 0 ]; then
    sudo docker run --net $VLAN_NAME --ip $VLAN_ADDR --user=$UID:$(id -g $USER) -d -p $LOMOD_HOST_PORT:8000 -p $LOMOW_HOST_PORT:8001 -v "$HOME_MEDIA_DIR:/media" -v "$HOME_LOMO_DIR:/lomo" $IMAGE_NAME $VLAN_ADDR
else
    sudo docker run --net $VLAN_NAME --ip $VLAN_ADDR --user=$UID:$(id -g $USER) -p $LOMOD_HOST_PORT:8000 -p $LOMOW_HOST_PORT:8001 -v "$HOME_MEDIA_DIR:/media" -v "$HOME_LOMO_DIR:/lomo" $IMAGE_NAME $VLAN_ADDR
fi
