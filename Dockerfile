# hadolint global ignore=DL3003,DL3008,DL3009,DL3015
# DL3003: Use WORKDIR to switch to a directory
# DL3008: Pin versions in apt get install
# DL3009: Delete the apt-get lists after installing something
# DL3015: Avoid additional packages by specifying `--no-install-recommends`

FROM quay.io/jupyter/base-notebook:2025-06-02

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
        fonts-liberation2 \
        tigervnc-tools \
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
        sqlite3

USER $NB_USER
COPY --chown=$NB_UID:$NB_GID requirements.txt /tmp
# Not following: File not included in mock.
# hadolint ignore=SC1091
RUN . /opt/conda/bin/activate && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# https://github.com/rozniak/xfce-winxp-tc/tree/5aa075f95cd95c10d98e1751c7538ab77d8587cf
ARG XFCE_WINXP_TC_VERSION=5aa075f95cd95c10d98e1751c7538ab77d8587cf
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
    /home/jovyan/xfce-winxp-tc/packaging/xptc/*/deb/std/x86_64/fre/*deb && \
    fix-permissions "/home/${NB_USER}"

USER $NB_USER

COPY --chown=$NB_UID:$NB_GID _config /home/jovyan/.config
RUN cd .config/wintc/registry && \
    sqlite3 ntuser.db < registry.sql
