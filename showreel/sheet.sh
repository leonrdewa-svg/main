#!/bin/sh
# usage: ./sheet.sh 1.0 2.0 ...   -> out/sheet.png contact sheet of those seconds
cd "$(dirname "$0")" && rm -rf out/stills && node render.mjs stills "$@" && \
ffmpeg -loglevel error -y -pattern_type glob -i 'out/stills/*.png' -vf "scale=432:768,tile=5x2:padding=6" -frames:v 1 out/sheet.png
