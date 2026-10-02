#!/usr/bin/env bash
# Builds the three lomorage images from local lomo-backend-docker .debs, smoke-tests each one
# (lomod must start and answer HTTP), and pushes them to Docker Hub only if all three pass.
# Called by lomo-backend's scripts/release-all.sh; runs on Linux/WSL2 with Docker, logged in to
# Docker Hub as an account that can push to lomorage/*.
#
# Usage: release.sh <debs-dir> <version> [--no-push]
#   <debs-dir> holds lomo-backend-docker_<version>_{amd64,arm64,armhf}.deb (lomo-backend's
#   releases/, filled by scripts/cross-build-rpi/package-docker.sh).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

DEBS="${1:?usage: release.sh <debs-dir> <version> [--no-push]}"
VERSION="${2:?usage: release.sh <debs-dir> <version> [--no-push]}"
PUSH=1
[ "${3:-}" = --no-push ] && PUSH=0

# image, platform, Dockerfile, deb arch
IMAGES=(
  "amd64-lomorage linux/amd64 Dockerfile.amd64 amd64"
  "arm64-lomorage linux/arm64 Dockerfile.arm64 arm64"
  "raspberrypi-lomorage linux/arm/v7 Dockerfile armhf"
)

# Stage just this version's debs, so the build can't pick up an older one from <debs-dir>.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
for img in "${IMAGES[@]}"; do
  set -- $img
  deb="$DEBS/lomo-backend-docker_${VERSION}_$4.deb"
  [ -f "$deb" ] || { echo "missing $deb" >&2; exit 1; }
  cp "$deb" "$STAGE/"
done

# The arm images build under qemu. WSL drops binfmt registrations whenever its VM restarts,
# so register every time.
docker run --privileged --rm tonistiigi/binfmt --install arm,arm64 >/dev/null

smoke_test() {
  local image="$1" platform="$2" name="lomo-smoke-$1" i status installed
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --pull never --name "$name" --platform "$platform" "lomorage/$image:latest" 8000 >/dev/null
  # Up to 3 minutes: lomod starts slowly under qemu.
  for i in $(seq 1 90); do
    status=$(docker exec "$name" sh -c "wget -q -S -O /dev/null http://127.0.0.1:8000/ 2>&1 | head -1" 2>/dev/null || true)
    if [ -n "$status" ]; then
      installed=$(docker exec "$name" dpkg-query -W -f '${Version}' lomo-backend-docker)
      docker rm -f "$name" >/dev/null
      [ "$installed" = "$VERSION" ] || { echo "$image: installed lomo-backend-docker $installed, want $VERSION" >&2; return 1; }
      echo "$image: lomod $installed answered:$status"
      return 0
    fi
    sleep 2
  done
  echo "$image: lomod did not answer HTTP; last log lines:" >&2
  docker logs "$name" 2>&1 | tail -20 >&2
  docker rm -f "$name" >/dev/null
  return 1
}

# One image at a time: three parallel qemu builds can run WSL out of memory.
for img in "${IMAGES[@]}"; do
  set -- $img
  echo "=== build $1 ($2)"
  docker build --platform "$2" --build-context "debs=$STAGE" --build-arg "DUMMY=$(date +%s)" \
    -f "$3" -t "lomorage/$1:latest" .
  smoke_test "$1" "$2"
done

if [ $PUSH = 0 ]; then
  echo "--no-push: built and tested, not pushed"
  exit 0
fi
for img in "${IMAGES[@]}"; do
  set -- $img
  docker push -q "lomorage/$1:latest"
done
echo "Pushed lomorage/{amd64,arm64,raspberrypi}-lomorage:latest with lomod $VERSION"
