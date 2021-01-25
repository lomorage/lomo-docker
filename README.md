
- [Install docker](#install-docker)
- [Get docker image](#get-docker-image)
  * [Pull from docker hub](#pull-from-docker-hub)
  * [Build by your self](#build-by-your-self)
- [Run](#run)
- [Update dockerhub](#update-dockerhub)

You can use the docker image to install Lomorage on your existing Raspberry Pi setup.

Raspberry Pi zero and 1 **NOT** supported now.

**MDNS doesn't work in this case, so the phone APP won't be able to find the service automatically. You have to input host and port manually**

# Install docker

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

```
sudo docker pull lomorage/raspberrypi-lomorage:latest
```

## Build by your self

```
docker build --build-arg DEBIAN_FRONTEND=noninteractive -t lomorage/raspberrypi-lomorage .
```

# Run

You can specify the media home directory and lomo directory, otherwise it will use the default, you **MUST** specify the host.

```
run.sh [-m {media-dir} -b {lomo-dir} -d -p {lomod-port} -P {lomow-port} -i {image-name}] -h host -s subnt -g gateway -n network-interface -a vlan-address

Command line options:
    -m  DIR         Absolute path of media directory used for media assets, default to "/media", optional
    -b  DIR         Absolute path of lomo directory used for db and log files, default to "/home/jeromy/lomo", optional
    -h  HOST        IP address or hostname of the host machine, required
    -s  SUBNET      Subnet of the host network(like 192.168.1.0/24), required
    -g  GATEWAY     gateway of the host network(like 192.168.1.1), required
    -n  NETWORK_INF network interface of the host network(like eth0), required
    -a  VLAN_ADDR   vlan address to be used(like 192.168.1.99), required
    -p  LOMOD_PORT  lomo-backend service port exposed on host machine, default to "8000", optional
    -P  LOMOW_PORT  lomo-web service port exposed on host machine, default to "8001", optional
    -i  IMAGE_NAME  docker image name, for example "lomorage/raspberrypi-lomorage:[tag]", default "lomorage/raspberrypi-lomorage:latest", optional
    -d              Debug mode to run in foreground, default to 0, optional

Examples:
    # assuming your hard drive mounted in /media, like /media/usb0, /media/usb0
    ./run.sh -m /media -b /home/pi/lomo -h 192.168.1.232 -s 192.168.1.0/24 -g 192.168.1.1 -n eth0 -a 192.168.1.99
```

# Update dockerhub

Retag and then push:

```
docker tag lomorage lomorage/raspberrypi-lomorage:latest
docker push lomorage/raspberrypi-lomorage:latest
```
