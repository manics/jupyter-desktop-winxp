# Jupyter Desktop Win95

[![Build](https://github.com/manics/jupyter-desktop-win95/actions/workflows/build.yaml/badge.svg)](https://github.com/manics/jupyter-desktop-win95/actions/workflows/build.yaml)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/manics/jupyter-desktop-win95/HEAD?urlpath=desktop)

A container image providing a [XFCE4 WINXP themed Desktop](https://github.com/rozniak/xfce-winxp-tc) running in Jupyter, using [Jupyter Remote Desktop Proxy](https://github.com/jupyterhub/jupyter-remote-desktop-proxy/).

## Usage

```
docker pull ghcr.io/manics/jupyter-desktop-win95:latest
docker run -p8888:8888 ghcr.io/manics/jupyter-desktop-win95:latest
```

Open the `http://127.0.0.1:8888/lab?token=<TOKEN>` URL shown in the output.

## Currently broken

https://github.com/rozniak/xfce-winxp-tc/wiki/Manual-configuration-following-install/9ce456aacdf6d227fd42f71914a0a5776920e5ad#shell-setup

- `wintc-desktop` is hidden by `xfdesktop`, Run `xfdesktop --quit` in a terminal
- `wintc-taskband` which provides the main WinXP menu bar and start menu segfaults
