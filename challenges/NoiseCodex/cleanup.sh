#!/usr/bin/env bash
# Nettoyage fin de challenge : supprime le conteneur Exegol + les fichiers de travail.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
docker rm -f exegol-ctf-NoiseCodex 2>/dev/null && echo "[cleanup] conteneur supprimé" || echo "[cleanup] pas de conteneur"
rm -rf "$DIR/work/" && echo "[cleanup] work/ supprimé"
