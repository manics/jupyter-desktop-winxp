#!/bin/sh
set -eu

XSTARTUP=/opt/conda/lib/python3.12/site-packages/jupyter_remote_desktop_proxy/share/xstartup
LOCALHOST_ARGS="-localhost no --I-KNOW-THIS-IS-INSECURE"

/usr/bin/tigervncserver :1 -fg $LOCALHOST_ARGS -SecurityTypes None -xstartup "$XSTARTUP"
