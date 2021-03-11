
- [Install docker](#install-docker)
- [Get docker image](#get-docker-image)
  * [Pull from docker hub](#pull-from-docker-hub)
  * [Build by your self](#build-by-your-self)
- [Run](#run)
- [Update dockerhub](#update-dockerhub)

# Install docker

Please follow [instruction](https://docs.docker.com/engine/install/) on docker offical site to install docker

note: If you are using OMSC, you probably need to change "id=osmc" in /etc/os-release to "id=raspbain"

```
sudo apt install -y ca-certificates
sudo update-ca-certificates --fresh
curl -fSLs https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo docker info
```

# Get docker image

You can either pull docker image from docker hub, or build yourself.

## Pull from docker hub

If using arm:

```
sudo docker pull lomorage/raspberrypi-lomorage:latest
```

If using x86/amd64:

```
sudo docker pull lomorage/amd64-lomorage:latest
```

## Build by your self

```
# build for arm
sudo docker build --build-arg DEBIAN_FRONTEND=noninteractive -t lomorage/raspberrypi-lomorage .

# build for x86/amd64
sudo docker build -f Dockerfile.amd64 --build-arg DEBIAN_FRONTEND=noninteractive -t lomorage/amd64-lomorage .
```

# Run

You can specify the media home directory and lomo directory, otherwise it will use the default, you **MUST** specify the host.

```
run.sh [-m {media-dir} -b {lomo-dir} -d -p {lomod-port} -P {lomow-port} -i {image-name}] -t vlan-type -s subnet -g gateway -n network-interface -a vlan-address

Command line options:
    -m  DIR         Absolute path of media directory used for media assets, default to "/media", optional
    -b  DIR         Absolute path of lomo directory used for db and log files, default to "/home/jeromy/lomo", optional
    -s  SUBNET      Subnet of the host network(like 192.168.1.0/24), required
    -g  GATEWAY     gateway of the host network(like 192.168.1.1), required
    -n  NETWORK_INF network interface of the host network(like eth0), required
    -t  VLAN_TYPE   vlan type, can be "macvlan" or "ipvlan", required
    -a  VLAN_ADDR   vlan address to be used(like 192.168.1.99), required
    -p  LOMOD_PORT  lomo-backend service port exposed on host machine, default to "8000", optional
    -P  LOMOW_PORT  lomo-web service port exposed on host machine, default to "8001", optional
    -i  IMAGE_NAME  docker image name, for example "lomorage/raspberrypi-lomorage:[tag]", default "lomorage/raspberrypi-lomorage:latest", optional
    -d              Debug mode to run in foreground, default to 0, optional

Examples:
    # assuming your hard drive mounted in /media, like /media/usb0, /media/usb0
    ./run.sh -m /media -b /home/pi/lomo -s 192.168.1.0/24 -g 192.168.1.1 -n eth0 -t macvlan -a 192.168.1.99
```

You can add the command in "/etc/rc.local" before "exit 0" to make it run automatically after system boot.

# Update dockerhub

Retag and then push:

arm:

```
sudo docker tag lomorage/raspberrypi-lomorage:latest lomorage/raspberrypi-lomorage:latest
sudo docker push lomorage/raspberrypi-lomorage:latest
```

x86/amd64:

```
sudo docker tag lomorage/amd64-lomorage:latest lomorage/amd64-lomorage:latest
sudo docker push lomorage/raspberrypi-amd64:latest
```
