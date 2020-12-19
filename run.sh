#! /bin/bash
set -e

DEBUG=0
HOME_MEDIA_DIR=/media
HOME_LOMO_DIR=/home/"$USER"/lomo
HOST=
LOMOD_HOST_PORT=8000
LOMOW_HOST_PORT=8001
IMAGE_NAME="lomorage/raspberrypi-lomorage:latest"

COMMAND_LINE_OPTIONS_HELP="
Command line options:
    -m  DIR         Absolute path of media directory used for media assets, default to \"$HOME_MEDIA_DIR\", optional
    -b  DIR         Absolute path of lomo directory used for db and log files, default to \"$HOME_LOMO_DIR\", optional
    -h  HOST        IP address or hostname of the host machine, required
    -p  LOMOD_PORT  lomo-backend service port exposed on host machine, default to \"$LOMOD_HOST_PORT\", optional
    -P  LOMOW_PORT  lomo-web service port exposed on host machine, default to \"$LOMOW_HOST_PORT\", optional
    -i  IMAGE_NAME  docker image name, for example \"lomorage/raspberrypi-lomorage:[tag]\", default \"$IMAGE_NAME\", optional
    -d              Debug mode to run in foreground, default to $DEBUG, optional

Examples:
    # assuming your hard drive mounted in /media, like /media/usb0, /media/usb0
    ./run.sh -m /media -b /home/pi/lomo -h 192.168.1.232
"

function help() {
    echo "`basename $0` [-m {media-dir} -b {lomo-dir} -d -p {lomod-port} -P {lomow-port} -i {image-name}] -h host"
    echo "$COMMAND_LINE_OPTIONS_HELP"
    exit 3;
}

OPTIONS=m:,b:,h:,i:,p:,P:,d
PARSED=$(getopt $OPTIONS $*)
if [ $? -ne 0 ]; then
    echo "getopt error"
    exit 2
fi

eval set -- "$PARSED"

while true; do
    case "$1" in
        -m)
            HOME_MEDIA_DIR=$2
            shift 2
            ;;
        -b)
            HOME_LOMO_DIR=$2
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
        -d)
            DEBUG=1
            shift
            ;;
        -h)
            HOST=$2
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

[ -z "$HOST" ] && echo "Host required!" && help
[ -z "$IMAGE_NAME" ] && echo "Docker image name required!" && help

echo "Host: $HOST"
echo "lomo-backend host port: $LOMOW_HOST_PORT"
echo "lomo-web host port: $LOMOD_HOST_PORT"
echo "Media directory: $HOME_MEDIA_DIR"
echo "Lomo directory: $HOME_LOMO_DIR"

mkdir -p "$HOME_MEDIA_DIR"
mkdir -p "$HOME_LOMO_DIR"

if [ $DEBUG -eq 0 ]; then
    docker run --user=$UID:$(id -g $USER) -d -p $LOMOD_HOST_PORT:8000 -p $LOMOW_HOST_PORT:8001 -v "$HOME_MEDIA_DIR:/media" -v "$HOME_LOMO_DIR:/lomo" $IMAGE_NAME $HOST
else
    docker run --user=$UID:$(id -g $USER) -p $LOMOD_HOST_PORT:8000 -p $LOMOW_HOST_PORT:8001 -v "$HOME_MEDIA_DIR:/media" -v "$HOME_LOMO_DIR:/lomo" $IMAGE_NAME $HOST
fi
