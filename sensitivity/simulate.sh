#!/usr/bin/env nix-shell
#!nix-shell -i bash -p pythonEnv wineWowPackages.minimal

Xvfb :9 -screen 0 1024x768x16 &
XVFB_PID=$!

export DISPLAY=:9.0

python simulate.py 2> simulate.log

kill $XVFB_PID
