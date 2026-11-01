Initialise un nouveau challenge CTF.

Arguments attendus : `<plateforme> <nom-du-challenge> [cible]`
Exemple : `/ctf-start htb Keeper 10.10.11.227`
Exemple : `/ctf-start rootme "SQL Injection - Authentication" https://challenge.root-me.org/...`

## Actions à réaliser

1. **Créer la structure du challenge dans le repo CTF privé** (jamais dans ce repo public) —
   `<CHAL>` = `$CTF_REPO/<Plateforme>/<Catégorie>/<Nom>/` (cf. CLAUDE.md § Structure des challenges) :
   `htb` → `HackTheBox`, `rootme` → `RootMe` ; CTF ponctuel → `<Événement>/<Année>` (ex. `THCon/2026`),
   en créant/complétant `<Événement>/<Année>/README.md` (synthèse, ligne du challenge en ⚠️ tenté),
   `<Événement>/README.md` et le tableau du `README.md` racine ; catégorie donnée par la
   plateforme (`ctf_cli.py list` / API), `_A-trier` si inconnue ; `<Nom>` avec underscores.
   ```bash
   CTF_REPO=~/Documents/CTF/CTF
   git -C "$CTF_REPO" pull -q --ff-only   # repo à jour avant d'écrire
   CHAL="$CTF_REPO/<Plateforme>/<Catégorie>/<Nom>"
   ```
   ```
   <CHAL>/
   ├── notes.md
   ├── recon-report.md
   ├── exploit-log.md
   ├── flag.txt
   ├── cleanup.sh       # supprime le conteneur Exegol (docker rm -f) + work/
   └── work/            # fichiers du challenge (monté sur /workspace dans Exegol)
   ```

2. **Initialiser notes.md** avec les infos de base :
   - Plateforme
   - Nom du challenge
   - Cible (IP/URL)
   - Date de début
   - Catégorie si connue
   - Chemin `<CHAL>` (les sous-agents travaillent là)

3. **Consulter la knowledge base par pertinence** :
   ```bash
   python3 tools/kb-search/kb_search.py "<nom-du-challenge> <catégorie si connue> <mots-clés>"
   ```
   Cela remonte les techniques, leçons et rétros les plus proches (mémoire du repo).
   Compléter si besoin par une lecture directe de `knowledge-base/techniques.md` et
   `lessons-learned.md`. Résumer les points pertinents dans notes.md.

4. **Télécharger les fichiers du challenge dans `work/`** (si le challenge en a) :
   ```bash
   python3 ~/.claude/ctf/ctf_cli.py download --id <ID>     # dépose dans ~/.claude/ctf/workspace/
   ```
   **Bug connu HTB** : le CLI renvoie souvent `"files": []` (HTTP 400). Contournement direct :
   ```bash
   TOKEN=$(python3 -c "import json;print(json.load(open('$HOME/.claude/ctf/config.json'))['active']['token'])")
   curl -sL -H "Authorization: Bearer $TOKEN" -H "User-Agent: Mozilla/5.0" \
     -o "$CHAL/work/challenge.zip" \
     "https://labs.hackthebox.com/api/v4/challenge/download/<ID>"
   ```
   Beaucoup de zips HTB sont protégés par le mot de passe `hackthebox`. L'archive est **non
   fiable** → l'extraire et l'analyser dans le conteneur Exegol, jamais sur l'hôte. Un challenge
   « container-only » (pas de download) n'a pas de fichier : attaquer l'instance live directement.

5. **Démarrer le conteneur Exegol** (environnement d'exécution — cf. CLAUDE.md § Exegol) :
   ```bash
   docker info >/dev/null 2>&1 || { open -a Docker; until docker info >/dev/null 2>&1; do sleep 3; done; }
   # `yes '' |` indispensable : Exegol bute encore sur un prompt « Press ENTER » (notice MAJ)
   # même avec --offline ; sans stdin il quitte sans créer le conteneur.
   yes '' | exegol start "ctf-<nom>" free --offline --accept-eula \
     --workspace "$CHAL/work" --disable-X11 -s bash
   # ajouter  --vpn ~/htb.ovpn  si cible réseau HTB
   # l'erreur « cannot attach stdin to a TTY » est normale : le conteneur tourne quand même
   docker ps --filter "name=ctf-<nom>" --format "{{.Names}}\t{{.Status}}"
   ```
   Générer `cleanup.sh` qui fait `docker rm -f exegol-ctf-<nom>` (pas `exegol stop`, qui bute
   sur le prompt de MAJ) puis `rm -rf work/`.

6. **Commit git dans le repo CTF** (`git -C "$CTF_REPO" add <CHAL> && git -C "$CTF_REPO" commit`) :
   `[init] <challenge-name>: initialisation du challenge`. Rien n'est commité dans ce repo-ci.

7. **Proposer le plan d'attaque** :
   - Recon → Exploit en séquence (recon charge `solve-challenge`, exploit le skill catégorie)
   - Challenge réseau → envisager Agent Teams (recon + exploit en parallèle)
   - Demander confirmation avant de lancer les agents
