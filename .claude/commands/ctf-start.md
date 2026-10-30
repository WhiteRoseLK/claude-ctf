Initialise un nouveau challenge CTF.

Arguments attendus : `<plateforme> <nom-du-challenge> [cible]`
Exemple : `/ctf-start htb Keeper 10.10.11.227`
Exemple : `/ctf-start rootme "SQL Injection - Authentication" https://challenge.root-me.org/...`

## Actions à réaliser

1. **Créer la structure du challenge** (PAS de writeup.md : il ira dans le vault Obsidian) :
   ```
   challenges/$ARGUMENTS[1]/
   ├── notes.md
   ├── recon-report.md
   ├── exploit-log.md
   ├── flag.txt
   ├── cleanup.sh       # stoppe le conteneur Exegol + supprime work/
   ├── .gitignore       # ignore work/
   └── work/            # fichiers du challenge (monté sur /workspace dans Exegol)
   ```

2. **Initialiser notes.md** avec les infos de base :
   - Plateforme
   - Nom du challenge
   - Cible (IP/URL)
   - Date de début
   - Catégorie si connue

3. **Consulter la knowledge base par pertinence** :
   ```bash
   python3 tools/kb-search/kb_search.py "<nom-du-challenge> <catégorie si connue> <mots-clés>"
   ```
   Cela remonte les techniques, leçons et rétros les plus proches (mémoire du repo).
   Compléter si besoin par une lecture directe de `knowledge-base/techniques.md` et
   `lessons-learned.md`. Résumer les points pertinents dans notes.md.

4. **Démarrer le conteneur Exegol** (environnement d'exécution — cf. CLAUDE.md § Exegol) :
   ```bash
   docker info >/dev/null 2>&1 || { open -a Docker; until docker info >/dev/null 2>&1; do sleep 3; done; }
   exegol start "ctf-<nom>" free \
     --workspace "$(pwd)/challenges/<nom>/work" --disable-X11 -s bash
   # ajouter  --vpn ~/htb.ovpn  si cible réseau HTB
   docker ps --filter "name=ctf-<nom>" --format "{{.Names}}\t{{.Status}}"
   ```
   Générer `cleanup.sh` qui fait `exegol stop "ctf-<nom>"` puis `rm -rf work/`.

5. **Commit git** : `[init] <challenge-name>: initialisation du challenge`

6. **Proposer le plan d'attaque** :
   - Recon → Exploit en séquence (recon charge `solve-challenge`, exploit le skill catégorie)
   - Challenge réseau → envisager Agent Teams (recon + exploit en parallèle)
   - Demander confirmation avant de lancer les agents
