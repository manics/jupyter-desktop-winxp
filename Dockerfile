# hadolint global ignore=DL3003,DL3008,DL3009,DL3015
# DL3003: Use WORKDIR to switch to a directory
# DL3008: Pin versions in apt get install
# DL3009: Delete the apt-get lists after installing something
# DL3015: Avoid additional packages by specifying `--no-install-recommends`

FROM quay.io/jupyter/base-notebook:2025-06-30

# https://github.com/rozniak/xfce-winxp-tc/wiki/Manual-configuration-following-install/9ce456aacdf6d227fd42f71914a0a5776920e5ad

# ARG RECOMMENDS=
ARG RECOMMENDS=--no-install-recommends

USER root

RUN apt-get update -y -q && \
    apt-get install -y -q $RECOMMENDS \
        dbus-x11 \
        tigervnc-standalone-server \
        # xclip is added so Playwright can test the clipboard
        xclip \
        # Useful command line tools
        curl \
        less \
        tmux \
        vim \
        # Desktop
        desktop-base \
        fonts-liberation2 \
        tigervnc-tools \
        xdg-user-dirs \
        xfce4 \
        xfce4-terminal \
        # For building and configuring xfce-winxp-tc
        cmake \
        coreutils \
        fakeroot \
        gcc \
        git \
        make \
        patch \
        pkg-config \
        python3 \
        sqlite3 \
        # For runtime setup
        rsync

USER $NB_USER
COPY --chown=$NB_UID:$NB_GID requirements.txt /tmp
# Not following: File not included in mock.
# hadolint ignore=SC1091
RUN . /opt/conda/bin/activate && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# https://github.com/rozniak/xfce-winxp-tc/tree/93613cf6c81432d0f1c3bf3e2b088e955247edef
ARG XFCE_WINXP_TC_VERSION=93613cf6c81432d0f1c3bf3e2b088e955247edef
RUN git clone https://github.com/rozniak/xfce-winxp-tc/ && \
    cd xfce-winxp-tc && \
    git checkout $XFCE_WINXP_TC_VERSION

USER root
# Quote this to prevent word splitting, Set the SHELL option -o pipefail
# hadolint ignore=SC2046,DL4006
RUN apt-get install -y -q $RECOMMENDS \
    $(/home/jovyan/xfce-winxp-tc/packaging/chkdeps.sh -l | cut -d':' -f2 | tr '\n' ' ')

USER $NB_USER
# COPY to a relative destination without WORKDIR set
# hadolint ignore=DL3045
COPY --chown=$NB_UID:$NB_GID container-workarounds.patch .
RUN cd xfce-winxp-tc && \
    patch -p1 < ../container-workarounds.patch && \
    cd packaging && \
    ./buildall.sh -t deb

USER root
RUN apt-get install -y -q $RECOMMENDS \
    /home/jovyan/xfce-winxp-tc/packaging/xptc/*/deb/std/*/fre/*deb && \
    fix-permissions "/home/${NB_USER}"

COPY _config /etc/xfce-winxp-tc-config
COPY copy-home-config.sh /usr/local/bin/before-notebook.d/

# Run this script to start VNC without jupyter-server
COPY start-tigervnc.sh /usr/local/bin/
# This file is used by start-tigervnc.sh so check it exists:
RUN ls /opt/conda/lib/python3.12/site-packages/jupyter_remote_desktop_proxy/share/xstartup

RUN cd /etc/xfce-winxp-tc-config/wintc/registry && \
    sqlite3 ntuser.db < registry.sql

USER $NB_USER
