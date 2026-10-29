# CTF Multi-Agent Workspace

Workspace multi-agent pour résoudre des challenges CTF (HackTheBox, Root-Me) avec Claude Code.

## Prérequis

### Claude Code
- Claude Code installé (`npm install -g @anthropic-ai/claude-code`)
- Plan **Max** recommandé (pour Opus + Agent Teams)
- Node.js 18+ (pour les MCP servers)

### Outils CTF (à installer sur ta machine)

```bash
# Debian/Ubuntu/Kali
sudo apt update && sudo apt install -y \
  nmap gobuster dirb nikto sqlmap hydra \
  john hashcat netcat-openbsd curl wget \
  python3 python3-pip exiftool binwalk \
  smbclient enum4linux steghide

# Python tools
pip3 install pwntools

# Wordlists (si pas déjà présentes)
sudo apt install -y seclists wordlists
```

### MCP Git Server
Le serveur MCP Git est configuré dans `.claude/settings.json` et sera installé automatiquement via `npx` au premier lancement.

## Setup

```bash
# Cloner ce repo
git clone <url> ctf-workspace
cd ctf-workspace

# Installer les skills + le CTF CLI (symlinks vers ~/.agents/skills et ~/.claude/ctf)
./install.sh

# Se connecter à une plateforme (token perso, jamais committé)
#   via Claude Code : /ctf-connect htb <TOKEN>
# Lancer Claude Code
claude
```

`install.sh` est **idempotent** et ne touche jamais à un `config.json` existant
(ton token est préservé). Les secrets ne sont jamais versionnés (voir `.gitignore`).

## Utilisation

### Démarrer un challenge
```
> /ctf-start htb Keeper 10.10.11.227
```

### Lancer les agents manuellement
```
> Lance l'agent recon sur la cible
> Lance l'agent exploit avec le rapport recon
> Lance l'agent writeup pour documenter
```

### Utiliser les Agent Teams (pour les challenges réseau)
```
> Crée une agent team avec 3 teammates :
  - recon sur la cible 10.10.11.227
  - exploit qui attend les résultats recon
  - writeup qui observe et documente
```

### Faire la retrospective
```
> /ctf-retro Keeper
```

## Structure

```
ctf-workspace/
├── CLAUDE.md                    # Instructions globales
├── install.sh                   # Bootstrap (symlinks skills + CLI)
├── skills/                      # Skills CTF vendorés (moteur technique)
│   ├── solve-challenge/         #   dispatcher (triage + routage)
│   ├── ctf-web/ ctf-pwn/ ...    #   références par catégorie
│   └── ctf-connect/ ctf-submit/ #   intégration plateforme
├── tools/ctf-cli/               # CTF CLI (connect/list/solve/submit)
│   ├── ctf_cli.py
│   └── config.example.json      #   template — config.json réelle gitignorée
├── .claude/
│   ├── agents/                  # recon, exploit, writeup, review
│   ├── commands/                # ctf-start, ctf-submit, ctf-retro
│   └── settings.json            # Config MCP + permissions
├── knowledge-base/              # Mémoire : techniques.md, lessons-learned.md
├── challenges/<challenge>/       # notes, recon-report, exploit-log, flag, writeup
└── retrospectives/              # Post-mortems <date>-<challenge>.md
```

## Amélioration continue

L'agent review met à jour automatiquement :
- `knowledge-base/techniques.md` — nouvelles techniques apprises
- `knowledge-base/lessons-learned.md` — erreurs à ne pas répéter
- Les retrospectives permettent de suivre la progression dans le temps

Au bout de quelques challenges, la knowledge base devient un vrai avantage compétitif :
les agents consultent ces fichiers avant chaque action.

## Ajouter un MCP Server (optionnel)

Pour ajouter Brave Search (recherche web pendant les challenges) :

```json
// Dans .claude/settings.json > mcpServers
"brave-search": {
  "command": "npx",
  "args": ["-y", "@anthropic-ai/mcp-server-brave-search"],
  "env": {
    "BRAVE_API_KEY": "ta-clé-api"
  }
}
```

Pour ajouter Playwright (interaction navigateur pour challenges web) :

```json
"playwright": {
  "command": "npx",
  "args": ["-y", "@anthropic-ai/mcp-server-playwright"]
}
```
