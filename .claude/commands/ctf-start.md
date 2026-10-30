Initialise un nouveau challenge CTF.

Arguments attendus : `<plateforme> <nom-du-challenge> [cible]`
Exemple : `/ctf-start htb Keeper 10.10.11.227`
Exemple : `/ctf-start rootme "SQL Injection - Authentication" https://challenge.root-me.org/...`

## Actions à réaliser

1. **Créer la structure du challenge** :
   ```
   challenges/$ARGUMENTS[1]/
   ├── notes.md
   ├── recon-report.md
   ├── exploit-log.md
   ├── flag.txt
   └── writeup.md
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
   Cela remonte les techniques, leçons, writeups et rétros les plus proches (KB + mémoire).
   Compléter si besoin par une lecture directe de `knowledge-base/techniques.md` et
   `lessons-learned.md`. Résumer les points pertinents dans notes.md.

4. **Commit git** : `[init] <challenge-name>: initialisation du challenge`

5. **Proposer le plan d'attaque** :
   - Si challenge réseau/machine → recommander Agent Teams (recon + exploit en parallèle)
   - Si challenge web/crypto → recommander exécution séquentielle (recon puis exploit)
   - Demander confirmation avant de lancer les agents
