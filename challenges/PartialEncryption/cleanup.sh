#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
docker rm -f exegol-ctf-PartialEncryption 2>/dev/null && echo "[cleanup] conteneur supprimé" || echo "[cleanup] pas de conteneur"
rm -rf "$DIR/work/" && echo "[cleanup] work/ supprimé"
