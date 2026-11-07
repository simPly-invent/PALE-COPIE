#!/bin/sh
# Capture d'écran d'une salle : tools/shot.sh sortie.png --room=z1_halls --depth=3 [--fidelity=40] [--overlay=1]
GODOT="${GODOT:-$HOME/Godot.app/Contents/MacOS/Godot}"
OUT="$1"; shift
"$GODOT" --resolution 640x480 -- --screenshot="$OUT" "$@" 2>&1 | grep -E "ERROR|SCRIPT" -A2 | head -30
