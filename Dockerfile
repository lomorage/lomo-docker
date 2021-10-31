FROM balenalib/raspberrypi3-debian:buster

RUN apt-get update && \
    apt-get -qy install ca-certificates apt-transport-https wget systemd

RUN wget -qO - https://raw.githubusercontent.com/lomoware/lomoware.github.io/master/debian/gpg.key | sudo apt-key add -

RUN echo "deb https://lomoware.github.io/debian/buster buster main" | sudo tee /etc/apt/sources.list.d/lomoware.list

RUN apt-get update && apt-get -qy install lomo-vips

RUN apt-get update && apt-get -qy install nfs-common ffmpeg util-linux rsync jq libimage-exiftool-perl avahi-utils avahi-daemon

RUN apt-get update && apt-get -qy install psmisc net-tools iproute2

ARG DUMMY=unknown

RUN DUMMY=${DUMMY} apt-get update && apt-get -qy install lomo-backend-docker

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

COPY entry.sh /usr/bin/entry.sh

ENTRYPOINT ["/usr/bin/entry.sh"]
