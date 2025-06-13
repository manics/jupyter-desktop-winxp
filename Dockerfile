# hadolint global ignore=DL3003,DL3006,DL3008,DL3009,DL3015
# DL3003: Use WORKDIR to switch to a directory
# DL3006: Always tag the version of an image explicitly
# DL3008: Pin versions in apt get install
# DL3009: Delete the apt-get lists after installing something
# DL3015: Avoid additional packages by specifying `--no-install-recommends`
ARG BASE_IMAGE=quay.io/jupyter/base-notebook:2025-06-02
FROM $BASE_IMAGE as build

# https://github.com/rozniak/xfce-winxp-tc/wiki/Manual-configuration-following-install/9ce456aacdf6d227fd42f71914a0a5776920e5ad

# Last USER should not be root
# hadolint ignore=DL3002
USER root

RUN apt-get update -y -q && \
    apt-get install -y -q --no-install-recommends \
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

WORKDIR /xfce-winxp-tc

# https://github.com/rozniak/xfce-winxp-tc/tree/5aa075f95cd95c10d98e1751c7538ab77d8587cf
ARG XFCE_WINXP_TC_VERSION=5aa075f95cd95c10d98e1751c7538ab77d8587cf
RUN git clone https://github.com/rozniak/xfce-winxp-tc/ . && \
    git checkout $XFCE_WINXP_TC_VERSION

# Quote this to prevent word splitting, Set the SHELL option -o pipefail
# hadolint ignore=SC2046,DL4006
RUN apt-get install -y -q $RECOMMENDS \
    $(./packaging/chkdeps.sh -l | cut -d':' -f2 | tr '\n' ' ')

COPY container-workarounds.patch .
RUN patch -p1 < container-workarounds.patch && \
    cd packaging && \
    ./buildall.sh -t deb

RUN mkdir /packages && \
    cp packaging/xptc/*/deb/std/x86_64/fre/*deb /packages


######################################################################

FROM $BASE_IMAGE

# ARG RECOMMENDS=
ARG RECOMMENDS=--no-install-recommends

USER root
COPY --from=build /packages /packages

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
        # For configuring xfce-winxp-tc
        sqlite3 \
        # xfce-winxp-tc
        /packages/*.deb

# fix-permissions "/home/${NB_USER}"

USER $NB_USER
COPY --chown=$NB_UID:$NB_GID requirements.txt /tmp
# Not following: File not included in mock.
# hadolint ignore=SC1091
RUN . /opt/conda/bin/activate && \
    pip install --no-cache-dir -r /tmp/requirements.txt

COPY --chown=$NB_UID:$NB_GID _config /home/jovyan/.config
RUN cd .config/wintc/registry && \
    sqlite3 ntuser.db < registry.sql
