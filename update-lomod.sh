#!/bin/bash
set -e

sudo apt-get update
sudo apt-get --only-upgrade install -y lomo-base lomo-vips lomo-backend-beta lomo-web
killall lomo-web
killall lomod
