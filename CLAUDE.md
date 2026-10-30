# CTF Multi-Agent Workspace

## Contexte

Ce workspace est dédié à la résolution de challenges CTF sur HackTheBox et Root-Me.
Nous travaillons en équipe multi-agent avec des rôles spécialisés.
Chaque action doit être documentée pour produire un writeup et alimenter l'amélioration continue.

## Agents disponibles

- **recon** : Reconnaissance et énumération (scans, fingerprinting, OSINT)
- **exploit** : Exploitation de vulnérabilités, privesc, extraction de flags
- **writeup** : Rédaction du writeup final pédagogique et reproductible
- **review** : Retrospective, analyse de performance, mise à jour knowledge base

## Couche skills (moteur technique)

Les techniques CTF viennent des skills vendorés dans `skills/` (installés via `install.sh`) :
- `solve-challenge` : dispatcher — triage puis routage vers la bonne catégorie
- `ctf-web`, `ctf-pwn`, `ctf-crypto`, `ctf-reverse`, `ctf-forensics`, `ctf-malware`,
  `ctf-osint`, `ctf-misc`, `ctf-ai-ml` : références profondes par catégorie
- `ctf-connect` / `ctf-list` / `ctf-solve` / `ctf-submit` / `ctf-writeup` : intégration plateforme

**Les agents orchestrent, les skills fournissent la technique.** On ne duplique jamais
une technique de skill dans un agent ou dans la knowledge base.

## Rôle de l'agent principal — ORCHESTRATEUR (il ne résout pas)

L'agent principal **orchestre, il ne résout jamais lui-même**. Il écoute l'utilisateur et délègue :

- Il **lance les sous-agents** `recon` puis `exploit` (spécialisés par catégorie via le skill
  `ctf-<catégorie>`) sur chaque challenge, chacun travaillant dans le **conteneur Exegol du challenge**.
- **Plusieurs challenges = plusieurs sous-agents en parallèle.** L'orchestrateur supervise et
  **reste disponible** pour de nouvelles instructions de l'utilisateur (lancer d'autres agents, autre chose).
- Il ne lance **JAMAIS** lui-même une commande de recon/exploitation (pas de `docker exec` d'outils,
  pas de solveur inline, pas d'analyse de binaire). Si l'envie de « juste résoudre » surgit : **déléguer**.
- Il ne garde en propre que : l'init (`/ctf-start`), la **soumission** (`/ctf-submit`), et le
  **déclenchement** des sous-agents `writeup` et `review`.

## Workflow standard (tout est délégué par l'orchestrateur)

1. **Init** → l'orchestrateur lance `/ctf-start <plateforme> <challenge>` (structure, mémoire, conteneur Exegol)
2. **Phase Recon** → l'orchestrateur **délègue au sous-agent `recon`** : charge `solve-challenge`, triage, produit `recon-report.md` avec la **catégorie détectée**
3. **Phase Exploit** → l'orchestrateur **délègue au sous-agent `exploit`** : charge le skill `ctf-<catégorie>`, attaque dans le conteneur Exegol, produit `exploit-log.md` + `flag.txt`
4. **Soumission** → l'orchestrateur lance `/ctf-submit <challenge> <flag>` (archive + soumet)
5. **Writeup** → l'orchestrateur **délègue au sous-agent `writeup`** → vault Obsidian `~/Documents/CTF/CTF/<Plateforme>/<Catégorie>/<Nom>.md` (via skill `ctf-writeup`), pas dans le repo
6. **Retrospective** → l'orchestrateur lance `/ctf-retro <challenge>` → **sous-agent `review`** (met à jour la knowledge base)

## Conventions obligatoires

### Documentation
- **Chaque commande exécutée** doit être loggée avec son output dans `exploit-log.md`
- **Chaque découverte** va dans `recon-report.md` avec la commande qui l'a produite
- Les timestamps sont obligatoires pour mesurer le temps par phase

### Knowledge Base
- **TOUJOURS** consulter la mémoire par pertinence avant de tenter une technique :
  `python3 tools/kb-search/kb_search.py "<mots-clés>"` (indexe KB + writeups + rétros, TF-IDF, zéro dépendance)
- Compléter au besoin par la lecture de `knowledge-base/techniques.md` et `lessons-learned.md`
- La KB est un **journal expérientiel** (ce qu'on a appris), pas une copie des skills
- Après chaque challenge, mettre à jour ces fichiers (via `/ctf-retro`)

### Git
- Commit à chaque fin de phase (recon, exploit, writeup, retro)
- Messages de commit : `[phase] challenge-name: description`
- Exemples : `[recon] Keeper: scan initial nmap`, `[exploit] Keeper: privesc via CVE-2023-xxxxx`

## Structure des challenges

```
challenges/<nom-challenge>/
├── notes.md            # Notes libres de l'orchestrateur
├── recon-report.md     # Rapport de reconnaissance structuré
├── exploit-log.md      # Journal chronologique des tentatives
├── flag.txt            # Le flag extrait
├── cleanup.sh          # Script de nettoyage (supprime le conteneur Exegol et work/)
├── .gitignore          # Ignore work/
└── work/               # Fichiers de travail temporaires (montés dans Exegol sur /workspace)
                        # → NON commités, supprimés par cleanup.sh après le challenge
```

> **Writeup** : publié dans le vault Obsidian perso `~/Documents/CTF/CTF/<Plateforme>/<Catégorie>/<Nom>.md`,
> **jamais** dans le repo (gitignoré). Le repo partagé garde KB + rétros comme mémoire.

## Environnement d'exécution — Exegol

**Les agents orchestrent sur l'hôte macOS ; les outils CTF tournent dans un conteneur
Exegol dédié au challenge** (c'est là que vivent nmap, pwntools, ghidra, binwalk, john…).
L'hôte macOS n'a pas ces outils → ne pas lancer les commandes d'attaque directement dessus.

> **Politique OBLIGATOIRE (appliquée par un hook `PreToolUse`)** : toute commande qui n'est
> pas de l'orchestration (git, docker, exegol, outils du repo) ni un `docker exec exegol-ctf-*`
> déclenche une demande d'acceptation expresse. Par défaut : exécuter dans Exegol.
> Hook : `tools/hooks/enforce_exegol.py`.

### Cycle de vie du conteneur (un par challenge)

```bash
# Démarrage (fait par /ctf-start) — work/ monté sur /workspace
# --offline --accept-eula : évite les prompts interactifs d'Exegol (notice de MAJ, EULA)
#   qui bloqueraient l'automatisation. Image : toujours `free` (les autres sont payantes).
exegol start "ctf-<nom>" free --offline --accept-eula \
  --workspace "$(pwd)/challenges/<nom>/work" \
  --disable-X11 -s bash
# + --vpn ~/htb.ovpn  si le challenge a une cible réseau HTB (sinon omettre)

# Vérifier
docker ps --filter "name=ctf-<nom>" --format "{{.Names}}\t{{.Status}}"
```

En non-interactif, `exegol start` affiche « cannot attach stdin to a TTY-enabled container » :
c'est **sans conséquence**, le conteneur est créé et tourne — on interagit via `docker exec`.
Si `exegol start` échoue sur « Unable to connect to docker » : `open -a Docker` puis
`until docker info >/dev/null 2>&1; do sleep 3; done` avant de réessayer.

**Image `free` uniquement** (les images `full`/`ad` sont payantes). Si un outil manque du
conteneur (ex. binwalk, ghidra, john), l'installer dedans à la volée
(`docker exec exegol-ctf-<nom> bash -c "apt-get install -y <pkg> || pipx install <pkg>"`)
ou le réimplémenter en Python — **ne pas changer d'image**.

### Lancer une commande dans le conteneur

Le nom Docker réel est `exegol-ctf-<nom>`. Aucun `exegol-mcp` n'est configuré → on passe par :

```bash
docker exec exegol-ctf-<nom> bash -c "cd /workspace && <commande>"
```

Écrire un fichier pour le conteneur : l'écrire dans `challenges/<nom>/work/` (monté sur
`/workspace`). En fin de challenge, `cleanup.sh` supprime le conteneur via
`docker rm -f exegol-ctf-<nom>` (fiable, sans prompt — `exegol stop/remove` bute sur le
prompt de MAJ) puis supprime `work/`.

### Apple Silicon
Conteneur aarch64 + binaire x86 → `qemu-user-static` (`qemu-x86_64-static -L <sysroot> ./bin`),
**uniquement pour valider la logique** ; revérifier toute adresse de gadget avec `ropper`/`ROPgadget`
sur le vrai binaire. (détails : skill `ctf-pwn`)
