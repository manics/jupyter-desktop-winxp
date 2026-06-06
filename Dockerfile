# hadolint global ignore=DL3003,DL3008,DL3009,DL3015
# DL3003: Use WORKDIR to switch to a directory
# DL3008: Pin versions in apt get install
# DL3009: Delete the apt-get lists after installing something
# DL3015: Avoid additional packages by specifying `--no-install-recommends`

FROM quay.io/jupyter/base-notebook:2026-06-02

# https://github.com/rozniak/xfce-winxp-tc/wiki/Manual-configuration-following-install/25d39e0ee0b48f9a237a73ac2cef29b7a4b3aabd

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
        sqlite3 \
        # For runtime setup
        rsync \
        # For RDP
        expect \
        xorgxrdp \
        xrdp

USER $NB_USER
COPY --chown=$NB_UID:$NB_GID requirements.txt /tmp
# Not following: File not included in mock.
# hadolint ignore=SC1091
RUN . /opt/conda/bin/activate && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# https://github.com/rozniak/xfce-winxp-tc/
ARG XFCE_WINXP_TC_VERSION=89d4480e64b3ea5670bb30a6ca4a4f520ac75435
RUN git clone https://github.com/rozniak/xfce-winxp-tc/ && \
    cd xfce-winxp-tc && \
    git checkout $XFCE_WINXP_TC_VERSION

USER root
# Python deps are handled in conda environment
# Quote this to prevent word splitting, Set the SHELL option -o pipefail
# hadolint ignore=SC2046,DL4006
RUN apt-get install -y -q $RECOMMENDS \
    $(/home/jovyan/xfce-winxp-tc/packaging/chkdeps.sh -l | \
        grep -v python | \
        cut -d':' -f2 | tr '\n' ' ')

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

# This file is used by start-tigervnc.sh and sesman.ini so check it exists:
RUN ls /opt/conda/lib/python3.13/site-packages/jupyter_remote_desktop_proxy/share/xstartup

# XRDP
ARG JOVYAN_INITIAL_PASSWORD=jovyan123
# HOME may be mounted and shared amongst multiple containers so container
# specific initialisation must go somewhere else
# Set the SHELL option -o pipefail
# hadolint ignore=DL4006
RUN rm /etc/xrdp/cert.pem /etc/xrdp/key.pem && \
    chmod a+r /etc/xrdp/* && \
    install -o jovyan -d /run/xrdp && \
    install -o jovyan -d /etc/xrdp/jovyan && \
    echo "jovyan:$JOVYAN_INITIAL_PASSWORD" | chpasswd && \
    install -d /etc/vnc && \
    install -o jovyan -d /etc/vnc/jovyan
COPY start-xrdp.sh /usr/local/bin/
COPY xrdp.ini sesman.ini passwd.expect /etc/xrdp/

RUN cd /etc/xfce-winxp-tc-config/wintc/registry && \
    sqlite3 ntuser.db < registry.sql

USER $NB_USER
