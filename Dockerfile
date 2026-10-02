# Empty unless overridden with --build-context debs=<dir>.
FROM scratch AS debs

FROM arm32v7/debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -qy install ca-certificates wget systemd sudo

RUN install -d /etc/apt/keyrings && \
    wget -qO /etc/apt/keyrings/lomoware.asc https://raw.githubusercontent.com/lomoware/lomoware.github.io/master/debian/gpg.key && \
    echo "deb [signed-by=/etc/apt/keyrings/lomoware.asc] https://lomoware.lomorage.com/debian/trixie trixie main" > /etc/apt/sources.list.d/lomoware.list

RUN apt-get update && apt-get -qy install lomo-vips

RUN apt-get update && apt-get -qy install nfs-common ffmpeg util-linux rsync jq libimage-exiftool-perl avahi-utils avahi-daemon

RUN apt-get update && apt-get -qy install psmisc net-tools iproute2

ENV SUDO_USER=root

ARG DUMMY=unknown

# Installs lomo-backend-docker from the apt repo, or from a local .deb when built with
# --build-context debs=<dir> (release.sh does, so a release doesn't wait on the CDN).
RUN --mount=type=bind,from=debs,target=/debs \
    set -e; DUMMY=${DUMMY}; apt-get update; \
    deb=$(ls /debs/lomo-backend-docker_*_$(dpkg --print-architecture).deb 2>/dev/null | tail -1 || true); \
    apt-get -qy install ${deb:-lomo-backend-docker}; \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/local/lib

COPY entry.sh /usr/bin/entry.sh

ENTRYPOINT ["/usr/bin/entry.sh"]
