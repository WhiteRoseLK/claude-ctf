#!/usr/bin/env bash
# Nettoyage du challenge Suspicious Threat : supprime le conteneur Exegol + work/
set -euo pipefail
docker rm -f exegol-ctf-suspiciousthreat 2>/dev/null || true
rm -rf "$(dirname "$0")/work"
echo "cleanup SuspiciousThreat : conteneur + work/ supprimés"
