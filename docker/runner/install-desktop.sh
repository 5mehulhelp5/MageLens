#!/usr/bin/env bash
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends xvfb x11vnc novnc websockify openbox x11-utils x11-xserver-utils
rm -rf /var/lib/apt/lists/*
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
