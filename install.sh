#!/usr/bin/env bash
#
# install.sh — bootstrap du workspace CTF sur une nouvelle machine.
#
# 1. Installe les dépendances si besoin (Docker, Exegol, Obsidian) — confirmation par défaut.
# 2. Lie (symlinks) les skills et le CLI vendorés vers les emplacements attendus.
# 3. Prépare la config plateforme SANS jamais écraser un token existant.
# 4. (Optionnel, --opencodex) Installe OpenCodex, configure les workers multi-provider
#    (Claude + Gemini, bascule quota auto) et le raccourci zsh « ocx claude » pour les CTF.
#
#   ~/.agents/skills/<skill>   -> <repo>/skills/<skill>
#   ~/.claude/ctf/<fichier>    -> <repo>/tools/ctf-cli/<fichier>
#
# Options : --no-deps (pas de dépendances)  ·  --opencodex (installe + configure OpenCodex)  ·  --yes (tout accepter)
# Idempotent : relançable sans effet de bord.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO/skills"
CLI_SRC="$REPO/tools/ctf-cli"
SKILLS_DST="$HOME/.agents/skills"
CTF_DST="$HOME/.claude/ctf"
OS="$(uname -s)"

# OpenCodex (optionnel) : modèle par défaut de l'orchestrateur en session `ocx claude`, et le ~/.zshrc visé.
OCX_MODEL="claude-sonnet-5-5"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

ASSUME_YES=0
INSTALL_DEPS=1
WANT_OCX=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)     ASSUME_YES=1 ;;
    --no-deps)    INSTALL_DEPS=0 ;;
    --opencodex)  WANT_OCX=1 ;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $arg" >&2; exit 2 ;;
  esac
done

info()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$1"; }
err()   { printf '  \033[31m✗\033[0m %s\n' "$1"; }
have()  { command -v "$1" >/dev/null 2>&1; }
ask()   { [ "$ASSUME_YES" = 1 ] && return 0; printf '  \033[33m?\033[0m %s [y/N] ' "$1"; local a; read -r a </dev/tty 2>/dev/null || return 1; [[ "$a" =~ ^[Yy] ]]; }

# Installe une dépendance manquante selon l'OS. Jamais bloquant (deps = prérequis d'usage).
# $1 nom lisible · $2 commande à tester · $3 install macOS · $4 install Linux · $5 note si manuel
ensure_dep() {
  local name="$1" probe="$2" mac="$3" lin="$4" note="${5:-}"
  if have "$probe"; then info "$name : déjà installé"; return; fi
  local cmd=""
  case "$OS" in
    Darwin) cmd="$mac" ;;
    Linux)  cmd="$lin" ;;
  esac
  if [ -z "$cmd" ]; then
    warn "$name : absent — installation manuelle requise. ${note}"
    return
  fi
  if ask "$name absent. Installer avec : $cmd ?"; then
    if eval "$cmd"; then info "$name : installé"; else err "$name : échec de l'installation ($cmd)"; fi
  else
    warn "$name : ignoré (install : $cmd). ${note}"
  fi
}

install_deps() {
  echo "== Dépendances =="
  # Homebrew (macOS) : prérequis des casks
  if [ "$OS" = Darwin ] && ! have brew; then
    warn "Homebrew absent — requis pour installer Docker/Obsidian sur macOS (https://brew.sh)"
  fi
  # pipx : requis pour Exegol
  ensure_dep "pipx" pipx \
    "brew install pipx && pipx ensurepath" \
    "sudo apt-get update && sudo apt-get install -y pipx || python3 -m pip install --user pipx" \
    "Puis: pipx install exegol"
  # Docker (Exegol en dépend)
  ensure_dep "Docker" docker \
    "brew install --cask docker" \
    "curl -fsSL https://get.docker.com | sh" \
    "Démarrer le démon après installation."
  # Exegol (environnement d'exécution des outils CTF)
  ensure_dep "Exegol" exegol \
    "pipx install exegol" \
    "pipx install exegol" \
    "Nécessite pipx."
  # Obsidian (vault des writeups) — sur macOS c'est une .app, pas une commande du PATH
  if { [ "$OS" = Darwin ] && [ -d "/Applications/Obsidian.app" ]; } || have obsidian; then
    info "Obsidian : déjà installé"
  else
    ensure_dep "Obsidian" obsidian \
      "brew install --cask obsidian" \
      "" \
      "Linux: AppImage/flatpak depuis https://obsidian.md (app GUI)."
  fi
  echo
}

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

[ "$INSTALL_DEPS" = 1 ] && install_deps || echo "== Dépendances ignorées (--no-deps) =="

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
