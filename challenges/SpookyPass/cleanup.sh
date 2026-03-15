#!/usr/bin/env bash
# Supprime les fichiers de travail après le challenge
# Les fichiers de documentation (*.md, flag.txt) sont conservés

CHALLENGE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[cleanup] Suppression du dossier work/ ..."
rm -rf "$CHALLENGE_DIR/work/"

echo "[cleanup] Fait. Fichiers conservés :"
ls "$CHALLENGE_DIR"
