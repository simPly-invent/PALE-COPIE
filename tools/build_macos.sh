#!/bin/sh
# Construit PÂLE COPIE pour macOS directement sur ce Mac.
# Une application construite ici n'est pas « téléchargée » : macOS ne la bloque pas.
# Prérequis (une seule fois) : dans l'éditeur Godot, Éditeur → Gérer les modèles d'export → Télécharger et installer.
set -e
GODOT="${GODOT:-$HOME/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.."
OUT="build/macos"
rm -rf "$OUT"
mkdir -p "$OUT"
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless --export-release "macOS" "$OUT/export.zip"
cd "$OUT"
ditto -x -k export.zip .
rm export.zip
APP="$(find . -maxdepth 1 -name '*.app' | head -n 1)"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "Prêt : $(pwd)/${APP#./}"
open .
