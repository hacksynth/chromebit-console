#!/bin/sh
# Force the verified 1920x1080@60 CEA timing, then start the frontend.
# X otherwise picks 1080p@120 (TMDS 297MHz) which this board cannot drive.
OUT=$(xrandr | awk "/ connected/{print \$1; exit}")
xrandr --newmode "1920x1080_60cea" 148.500 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync 2>/dev/null
xrandr --addmode "$OUT" "1920x1080_60cea" 2>/dev/null
xrandr --output "$OUT" --mode "1920x1080_60cea" 2>/dev/null || xrandr --output "$OUT" --mode 1920x1080 --rate 60

if [ -x /usr/local/bin/emulationstation ]; then
    exec /usr/local/bin/emulationstation
fi
exec retroarch --menu
