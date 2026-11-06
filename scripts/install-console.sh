#!/bin/sh
# One-shot installer for the Chromebit console.
# Run from a directory containing: emulationstation, kiosk.sh, es_systems.cfg,
# retroarch-kiosk.service
set -e

[ -x ./emulationstation ] || { echo "emulationstation binary missing"; exit 1; }
[ -f ./es_systems.cfg ] || { echo "es_systems.cfg missing"; exit 1; }

echo "== installing frontend"
install -m755 ./emulationstation /usr/local/bin/emulationstation
install -m755 ./kiosk.sh /usr/local/bin/kiosk.sh
install -m644 ./retroarch-kiosk.service /etc/systemd/system/retroarch-kiosk.service

echo "== installing emulationstation config"
mkdir -p /root/.emulationstation
[ -f /root/.emulationstation/es_systems.cfg ] || cp ./es_systems.cfg /root/.emulationstation/

echo "== enabling kiosk"
systemctl daemon-reload
systemctl enable retroarch-kiosk
systemctl restart retroarch-kiosk

echo "== done; check 'systemctl status retroarch-kiosk'"
