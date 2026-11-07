#!/bin/sh
# Lance les tests de cohérence (avec garde-fou de 150 s).
GODOT="${GODOT:-$HOME/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --headless res://tests/run_tests.tscn 2>&1 &
PID=$!
( sleep 150; kill $PID 2>/dev/null ) &
WATCH=$!
wait $PID
CODE=$?
kill $WATCH 2>/dev/null
exit $CODE
