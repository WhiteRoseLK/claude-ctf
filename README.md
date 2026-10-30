# CTF Multi-Agent Workspace

Workspace Claude Code pour résoudre des challenges CTF (HackTheBox, Root-Me, CTFd…).
C'est une **couche d'orchestration + mémoire** par-dessus une suite de skills CTF vendorés :
les agents orchestrent, les skills fournissent la technique, et chaque challenge alimente
une knowledge base qui sert aux suivants.

## Prérequis

- **Claude Code** (`npm install -g @anthropic-ai/claude-code`), plan Max recommandé.
- **Docker**, **Exegol** (environnement d'exécution des outils) et **Obsidian** (vault des writeups).
  → `install.sh` tente d'installer ce qui manque (Homebrew sur macOS ; sur Linux : pipx pour
  Exegol, script officiel pour Docker). Sur Linux, Obsidian (appli GUI) reste manuel (AppImage/flatpak).

Les outils d'attaque (nmap, pwntools, ghidra, binwalk…) **ne s'installent pas sur l'hôte** :
ils vivent dans Exegol.

## Setup

```bash
git clone https://github.com/WhiteRoseLK/claude-ctf.git
cd claude-ctf
./install.sh            # installe les deps + symlinke skills/ et le CLI (idempotent)
claude                  # puis, dans Claude Code :  /ctf-connect htb <TOKEN>
```

`install.sh` ne touche jamais à un `config.json`/token existant. Options : `--no-deps`, `--yes`.
Les secrets (tokens, config plateforme) ne sont **jamais versionnés** (voir `.gitignore`).

## Comment ça marche

- **Exécution dans Exegol.** Les commandes d'attaque tournent dans un conteneur dédié au
  challenge (`challenges/<nom>/work/` monté sur `/workspace`). Un **hook** impose cette règle :
  toute commande hors orchestration lancée sur l'hôte demande une acceptation expresse.
- **Technique = skills.** `solve-challenge` (dispatcher) route vers `ctf-web`, `ctf-pwn`,
  `ctf-reverse`, `ctf-crypto`, `ctf-forensics`, `ctf-malware`, `ctf-osint`, `ctf-misc`, `ctf-ai-ml`.
  On ne duplique jamais une technique de skill dans le repo.
- **Mémoire.** `knowledge-base/` (journal expérientiel) + `retrospectives/`, interrogés par
  pertinence via `tools/kb-search/kb_search.py "<mots-clés>"` (TF-IDF, zéro dépendance).
- **Writeups → vault Obsidian perso** `~/Documents/CTF/CTF/<Plateforme>/<Catégorie>/<Nom>.md`,
  jamais dans le repo partagé (gabarit : `templates/writeup-template.md`).

## Workflow

1. `/ctf-connect <plateforme> <token>` — se connecter (puis `/ctf-list`, `/ctf-solve` au besoin).
2. `/ctf-start <plateforme> <challenge> [cible]` — structure le challenge, consulte la mémoire,
   démarre le conteneur Exegol.
3. **Recon** — l'agent `recon` charge `solve-challenge`, triage, produit `recon-report.md`
   (avec la catégorie détectée). Aucune exploitation.
4. **Exploit** — l'agent `exploit` charge le skill `ctf-<catégorie>`, attaque, logge tout dans
   `exploit-log.md`, extrait le flag.
5. `/ctf-submit <challenge> <flag>` — archive + soumet, puis propose writeup et rétro.
6. **Writeup** (agent `writeup` → vault) puis `/ctf-retro <challenge>` (agent `review` →
   met à jour la knowledge base).

> Pour un challenge réseau, `/ctf-start` peut proposer des **Agent Teams** (recon + exploit en
> parallèle) — activées via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` dans `.claude/settings.json`.

## Structure

```
claude-ctf/
├── CLAUDE.md                 # instructions du workspace
├── install.sh                # bootstrap : deps + symlinks skills/CLI
├── skills/                   # skills CTF vendorés (solve-challenge, ctf-*, intégration plateforme)
├── tools/
│   ├── ctf-cli/              # CLI plateforme : ctf_cli.py + sudocrypt_cli.py + config.example.json
│   ├── kb-search/            # recherche mémoire TF-IDF
│   └── hooks/                # enforce_exegol.py (politique d'exécution)
├── templates/                # gabarit de writeup (vault)
├── .claude/
│   ├── agents/               # recon, exploit, writeup, review
│   ├── commands/             # ctf-start, ctf-submit, ctf-retro
│   └── settings.json         # permissions, hook, MCP git
├── knowledge-base/           # mémoire : techniques.md, lessons-learned.md
├── challenges/<nom>/          # notes, recon-report, exploit-log, flag, cleanup.sh, work/ (gitignoré)
└── retrospectives/           # post-mortems <date>-<challenge>.md
```

## Amélioration continue

Après chaque challenge, `/ctf-retro` fait tourner l'agent `review` qui enrichit
`knowledge-base/techniques.md`, `lessons-learned.md` et `retrospectives/`. Plus on joue,
plus la mémoire sert — les agents la consultent (`kb-search`) avant chaque phase.
