#!/usr/bin/env bash
#
# install.sh — bootstrap du workspace CTF sur une nouvelle machine.
#
# Lie (symlinks) les skills et le CLI vendorés dans ce repo vers les
# emplacements attendus par l'agent, puis prépare la config plateforme
# SANS jamais écraser un token existant.
#
#   ~/.agents/skills/<skill>   -> <repo>/skills/<skill>
#   ~/.claude/ctf/<fichier>    -> <repo>/tools/ctf-cli/<fichier>
#
# Idempotent : relançable sans effet de bord.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO/skills"
CLI_SRC="$REPO/tools/ctf-cli"
SKILLS_DST="$HOME/.agents/skills"
CTF_DST="$HOME/.claude/ctf"

info()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$1"; }

# Contenu de src et dst identique ? (dossier ou fichier)
same_content() {
  if [ -d "$1" ]; then diff -rq "$1" "$2" >/dev/null 2>&1; else cmp -s "$1" "$2"; fi
}

# Crée un symlink dst -> src, sans sauvegarde inutile.
#   - déjà lié au bon endroit        -> ne touche à rien
#   - contenu identique              -> remplace par un lien, PAS de sauvegarde
#   - contenu différent              -> sauvegarde .bak.* PUIS remplace (jamais destructif)
link() {
  local src="$1" dst="$2" name
  name="$(basename "$dst")"
  if [ -L "$dst" ]; then
    [ "$(readlink "$dst")" = "$src" ] && { info "$name : déjà lié, rien à faire"; return; }
    rm "$dst"                                   # ancien lien vers un autre endroit
  elif [ -e "$dst" ]; then
    if same_content "$src" "$dst"; then
      rm -rf "$dst"                             # identique : pas de sauvegarde inutile
      ln -s "$src" "$dst"
      info "$name : contenu identique, remplacé par un lien (sans sauvegarde)"
      return
    fi
    mv "$dst" "$dst.bak.$(date +%s)"            # divergent : on préserve l'existant
    warn "$name : contenu DIFFÉRENT, sauvegardé en $name.bak.* avant remplacement"
  fi
  ln -s "$src" "$dst"
  info "$name -> ${src#$REPO/}"
}

echo "== Installation des skills CTF =="
mkdir -p "$SKILLS_DST"
for skill in "$SKILLS_SRC"/*/; do
  link "${skill%/}" "$SKILLS_DST/$(basename "$skill")"
done

echo "== Installation du CTF CLI =="
mkdir -p "$CTF_DST"
for f in "$CLI_SRC"/*.py; do
  link "$f" "$CTF_DST/$(basename "$f")"
done

echo "== Config plateforme =="
if [ -f "$CTF_DST/config.json" ]; then
  info "config.json déjà présent — inchangé (token préservé)"
else
  cp "$CLI_SRC/config.example.json" "$CTF_DST/config.json"
  warn "config.json créé depuis le template — éditez-le ou lancez /ctf-connect"
fi

echo
info "Terminé. Testez avec : /ctf-connect <plateforme> <token>  puis  /ctf-list"
