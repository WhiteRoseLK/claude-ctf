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

# ---------------------------------------------------------------------------
# OpenCodex (optionnel, --opencodex) : orchestrateur multi-provider pour les CTF.
#   - installe l'app desktop (runtime du proxy) + le CLI `ocx` (npm)
#   - configure 5 workers failover (combos) + le roster délégable par l'orchestrateur
#   - ajoute à ~/.zshrc le raccourci qui lance `ocx claude` sur l'orchestrateur $OCX_MODEL
# Suppose les providers OpenCodex nommés `anthropic` et `google-antigravity` (adapter sinon).
# Non destructif : l'OAuth des providers reste manuel (`ocx setup`), le raccourci n'écrase rien.
setup_opencodex() {
  echo "== OpenCodex (optionnel) =="

  # 1) App desktop (runtime du proxy) — macOS uniquement
  if [ "$OS" = Darwin ]; then
    if [ -d "/Applications/OpenCodex.app" ]; then
      info "OpenCodex.app : déjà installé"
    elif have brew; then
      if ask "Installer l'app OpenCodex (brew install --cask opencodex) ?"; then
        brew install --cask opencodex && info "OpenCodex.app : installé" || err "OpenCodex.app : échec"
      else
        warn "OpenCodex.app : ignoré"
      fi
    else
      warn "OpenCodex.app : Homebrew requis (https://opencodex.me)"
    fi
  else
    warn "OpenCodex cible macOS — app desktop ignorée sur $OS"
  fi

  # 2) CLI `ocx` (npm) — fournit la commande `ocx claude`
  have node || warn "Node.js absent — requis pour le CLI ocx (npm)."
  ensure_dep "OpenCodex CLI (ocx)" ocx \
    "npm install -g @bitkyc08/opencodex" \
    "npm install -g @bitkyc08/opencodex" \
    "Nécessite Node.js/npm."

  if ! have ocx; then
    warn "ocx indisponible — workers et raccourci sautés (installez-le puis relancez --opencodex)."
    echo; return 0
  fi

  # 3) Proxy + providers (OAuth interactif, non automatisé)
  ocx status >/dev/null 2>&1 || ocx start >/dev/null 2>&1 || true
  if ocx account list 2>/dev/null | grep -qiE "anthropic.*active"; then
    info "Provider Anthropic : connecté"
  else
    warn "Provider Anthropic non connecté — lancez 'ocx setup' (login OAuth)"
  fi
  if ocx account list 2>/dev/null | grep -qiE "google-antigravity.*active"; then
    info "Provider Google (antigravity) : connecté"
  else
    warn "Provider Google non connecté — lancez 'ocx setup' (login OAuth)"
  fi

  # 4) Workers failover (combos) + roster délégable — idempotent (upsert)
  echo "  Workers (combos failover + roster)…"
  _ocx_combo() {
    ocx combo set "$1" --targets "$2" --strategy failover --cooldown-reprobe on --display-name "$3" >/dev/null 2>&1 \
      && info "combo $1 ($3)" || warn "combo $1 : échec (providers configurés ?)"
  }
  _ocx_combo flash  "google-antigravity/gemini-3.8-flash,anthropic/claude-haiku-5-5" "flash→haiku"
  _ocx_combo haiku  "anthropic/claude-haiku-5-5,google-antigravity/gemini-3.8-flash" "haiku→flash"
  _ocx_combo sonnet "anthropic/claude-sonnet-5,google-antigravity/gemini-4-argon"    "sonnet→argon"
  _ocx_combo argon  "google-antigravity/gemini-4-argon,anthropic/claude-sonnet-5"    "argon→sonnet"
  _ocx_combo opus   "anthropic/claude-opus-5-5,google-antigravity/gemini-4-argon"    "opus→argon"
  ocx agent subagents set combo/flash,combo/haiku,combo/sonnet,combo/argon,combo/opus >/dev/null 2>&1 \
    && info "roster : flash, haiku, sonnet, argon, opus" \
    || warn "roster : échec (providers configurés ?)"

  # 5) Raccourci zsh : `ocx claude` -> orchestrateur $OCX_MODEL (sessions CTF)
  local marker_start="# >>> claude_ctf opencodex (ocx claude -> $OCX_MODEL) >>>"
  local marker_end="# <<< claude_ctf opencodex <<<"
  if grep -qF "$marker_start" "$ZSHRC" 2>/dev/null; then
    info "Raccourci zsh : déjà présent dans ${ZSHRC/#$HOME/~}"
  elif grep -q 'ocx()' "$ZSHRC" 2>/dev/null; then
    warn "Une fonction ocx() existe déjà dans ${ZSHRC/#$HOME/~} — raccourci NON ajouté (évite le conflit)"
  elif ask "Ajouter à ${ZSHRC/#$HOME/~} le raccourci 'ocx claude' (orchestrateur $OCX_MODEL) ?"; then
    cat >> "$ZSHRC" <<ZSHRC_OCX

$marker_start
# Force l'orchestrateur sur $OCX_MODEL pour 'ocx claude' (sessions CTF).
# N'affecte pas 'claude' direct, ni 'ocx claude config/desktop/intercept/integration',
# ni un --model/-m explicite. Retirer = supprimer ce bloc.
ocx() {
  if [ "\$1" = "claude" ]; then
    case "\$2" in
      config|desktop|intercept|integration) command ocx "\$@" ;;
      *)
        shift
        case " \$* " in
          *" --model "*|*" -m "*) command ocx claude "\$@" ;;
          *) command ocx claude --model $OCX_MODEL "\$@" ;;
        esac
        ;;
    esac
  else
    command ocx "\$@"
  fi
}
$marker_end
ZSHRC_OCX
    info "Raccourci zsh ajouté — ouvrez un nouveau terminal ou 'source ${ZSHRC/#$HOME/~}'"
  else
    warn "Raccourci zsh : ignoré"
  fi
  echo
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

if [ "$WANT_OCX" = 1 ]; then setup_opencodex; else echo "== OpenCodex ignoré (passez --opencodex pour l'activer) =="; fi

echo
info "Terminé. Testez avec : /ctf-connect <plateforme> <token>  puis  /ctf-list"
