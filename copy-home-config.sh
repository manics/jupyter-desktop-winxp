#!/bin/sh
# $HOME may be a mounted volume, so copy in files but don't overwrite existing files
set -e
# set -eu currently fails:
# /usr/local/bin/start.sh: line 11: JUPYTER_DOCKER_STACKS_QUIET: unbound variable

rsync -av --ignore-existing /etc/xfce-winxp-tc-config/ $HOME/.config/
