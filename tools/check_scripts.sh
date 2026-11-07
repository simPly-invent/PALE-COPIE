#!/bin/sh
# Vérifie qu'aucun script ne contient d'erreur de parsing (lancer depuis la racine du projet).
GODOT="${GODOT:-$HOME/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --headless --import >/dev/null 2>&1
"$GODOT" --headless --quit 2>&1 | grep -E -A2 "SCRIPT ERROR|^ERROR|Parse Error" | grep -v "^--$"
exit 0
