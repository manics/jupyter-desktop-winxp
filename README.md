# Jupyter Desktop WinXP

[![Build](https://github.com/manics/jupyter-desktop-winxp/actions/workflows/build.yaml/badge.svg)](https://github.com/manics/jupyter-desktop-winxp/actions/workflows/build.yaml)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/manics/jupyter-desktop-winxp/HEAD?urlpath=desktop)

A container image providing a [XFCE4 WINXP themed Desktop](https://github.com/rozniak/xfce-winxp-tc) running in Jupyter, using [Jupyter Remote Desktop Proxy](https://github.com/jupyterhub/jupyter-remote-desktop-proxy/).

![Screenshot of jupyter-desktop-winxp](https://raw.githubusercontent.com/manics/jupyter-desktop-winxp/main/tests/reference/desktop.png)

## Usage

```
docker pull ghcr.io/manics/jupyter-desktop-winxp:latest
docker run -p8888:8888 ghcr.io/manics/jupyter-desktop-winxp:latest
```

Open the `http://127.0.0.1:8888/lab?token=<TOKEN>` URL shown in the output.

## Development

The `.config/` directory was manually copied out after following
https://github.com/rozniak/xfce-winxp-tc/wiki/Manual-configuration-following-install/9ce456aacdf6d227fd42f71914a0a5776920e5ad#shell-setup
