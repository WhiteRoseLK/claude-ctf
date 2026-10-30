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

## Workflow standard

1. Initialiser le challenge avec `/ctf-start <plateforme> <challenge>`
2. **Phase Recon** → agent recon charge `solve-challenge`, triage, produit `recon-report.md` avec la **catégorie détectée**
3. **Phase Exploit** → agent exploit charge le skill `ctf-<catégorie>`, attaque, produit `exploit-log.md`
4. **Soumission** → `/ctf-submit <challenge> <flag>` archive dans `flag.txt` et soumet à la plateforme
5. **Writeup** → agent writeup publie dans le **vault Obsidian** `~/Documents/CTF/CTF/<Plateforme>/<Catégorie>/<Nom>.md` (via skill `ctf-writeup`), pas dans le repo
6. **Retrospective** → `/ctf-retro <challenge>` lance l'agent review (met à jour la knowledge base)

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
├── cleanup.sh          # Script de nettoyage (supprime work/, stoppe le conteneur Exegol)
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
exegol start "ctf-<nom>" free \
  --workspace "$(pwd)/challenges/<nom>/work" \
  --disable-X11 -s bash
# + --vpn ~/htb.ovpn  si le challenge a une cible réseau HTB (sinon omettre)

# Vérifier
docker ps --filter "name=ctf-<nom>" --format "{{.Names}}\t{{.Status}}"
```

Si `exegol start` échoue sur « Unable to connect to docker » : `open -a Docker` puis
`until docker info >/dev/null 2>&1; do sleep 3; done` avant de réessayer.

### Lancer une commande dans le conteneur

Le nom Docker réel est `exegol-ctf-<nom>`. Aucun `exegol-mcp` n'est configuré → on passe par :

```bash
docker exec exegol-ctf-<nom> bash -c "cd /workspace && <commande>"
```

Écrire un fichier pour le conteneur : l'écrire dans `challenges/<nom>/work/` (monté sur
`/workspace`). En fin de challenge, `cleanup.sh` stoppe le conteneur et supprime `work/`.

### Apple Silicon
Conteneur aarch64 + binaire x86 → `qemu-user-static` (`qemu-x86_64-static -L <sysroot> ./bin`),
**uniquement pour valider la logique** ; revérifier toute adresse de gadget avec `ropper`/`ROPgadget`
sur le vrai binaire. (détails : skill `ctf-pwn`)
