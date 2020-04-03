#!/bin/bash
set -e

sudo apt-get update
sudo apt-get --only-upgrade install -y lomo-base lomo-backend lomo-web lomo-frame
