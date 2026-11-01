Lance la rétrospective et l'amélioration continue après un challenge.

Argument attendu : `<nom-du-challenge>`
Exemple : `/ctf-retro GameLoader`

## Actions à réaliser

1. **Localiser** le dossier du challenge dans le repo CTF privé :
   `find ~/Documents/CTF/CTF -type d -name '$ARGUMENTS' -not -path '*/work/*'` → `<CHAL>`.
   **Vérifier** qu'il existe et contient au minimum
   `recon-report.md` et `exploit-log.md`. Sinon, signaler ce qui manque et s'arrêter.

2. **Lancer l'agent `review`** (subagent) sur ce challenge. Il doit :
   - analyser `<CHAL>/`{recon-report.md, exploit-log.md, `<Nom>.md` (writeup)} (lui passer le chemin `<CHAL>`)
   - **ne recopier aucun flag** dans la KB ni la rétro (ce repo est public)
   - mettre à jour `knowledge-base/techniques.md` (nouvelles techniques réellement utilisées)
   - mettre à jour `knowledge-base/lessons-learned.md` (erreurs et règles)
   - générer `retrospectives/YYYY-MM-DD-$ARGUMENTS.md`

3. **Vérifier le résultat** : confirmer que la KB et `retrospectives/` ont bien été
   modifiés (ne pas se contenter de la parole de l'agent — vérifier les fichiers).

4. **Commit git dans ce repo** (KB + rétro uniquement) : `[retro] $ARGUMENTS: rétrospective et mise à jour knowledge base`
