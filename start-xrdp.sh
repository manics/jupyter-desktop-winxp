#!/bin/sh
set -eu

XRDP_DIR=/etc/xrdp/jovyan

if [ ! -f "$XRDP_DIR/key.pem" -o ! -f "$XRDP_DIR/cert.pem" ]; then
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$XRDP_DIR/key.pem" -out "$XRDP_DIR/cert.pem" -subj "/CN=xrdp" -days 3653
fi

if [ ! -f "$XRDP_DIR/xrdp.ini" ]; then
  if [ "${NO_PASSWORD:-}" = "1" ]; then
    if [ -z "${NEW_PASSWORD:-}" ]; then
      export NEW_PASSWORD=$(openssl rand -base64 33)
    fi
    /etc/xrdp/passwd.expect
    USERNAME=$(id -un)
    sed -e "s|username=ask|username=$USERNAME|" -e "s|password=ask|password=$NEW_PASSWORD|" /etc/xrdp/xrdp.ini > "$XRDP_DIR/xrdp.ini"
  elif [ -z "${NEW_PASSWORD:-}" ]; then
    echo "NEW_PASSWORD must be set unless NO_PASSWORD=1"
    exit 1
  else
    /etc/xrdp/passwd.expect
    cp /etc/xrdp/xrdp.ini "$XRDP_DIR/xrdp.ini"
  fi
fi

unset NEW_PASSWORD

sh /usr/local/bin/before-notebook.d/copy-home-config.sh

DISPLAY=:10 xrdp-sesman --nodaemon --config /etc/xrdp/sesman.ini &
exec xrdp --nodaemon --config "$XRDP_DIR/xrdp.ini"
