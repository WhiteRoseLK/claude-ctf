Soumet un flag à la plateforme CTF connectée et l'archive localement.

Arguments attendus : `<nom-du-challenge> <flag>`
Exemple : `/ctf-submit SpookyPass HTB{un0bfu5c4t3d_5tr1ng5}`

Pour une soumission par ID de challenge sur la plateforme active, utilise directement
le skill `ctf-submit` (qui appelle `~/.claude/ctf/ctf_cli.py submit --id <id> --flag <flag>`).

## Actions à réaliser

1. **Archiver le flag en local** dans `challenges/<nom-du-challenge>/flag.txt`
   (juste le flag, une ligne, pas de formatage). Crée le dossier si besoin.

2. **Soumettre à la plateforme** si une connexion est active. Vérifie d'abord :
   ```bash
   python3 ~/.claude/ctf/ctf_cli.py status
   ```
   - Si connecté et que le challenge a un ID connu → délègue au skill `ctf-submit`.
   - Sinon, archive seulement en local et signale qu'aucune plateforme n'est connectée
     (l'utilisateur peut lancer `/ctf-connect`).

3. **Avertir** si le format du flag paraît inhabituel (pas de wrapper type `HTB{...}`),
   mais soumettre quand même si l'utilisateur confirme.

4. **Commit git** : `[exploit] <nom-du-challenge>: flag soumis et archivé`

5. **Sauver le solveur dans le record** (avant tout cleanup) : copier le(s) script(s) de solve
   de `work/` vers `challenges/<nom>/solution/` (committé) pour que le writeup reste reproductible
   même différé et après suppression de `work/`.

6. **Clôturer selon le MODE** — uniquement si la soumission est un succès (flag confirmé correct).
   Lire le mode :
   ```bash
   MODE=$(cat .ctf-mode 2>/dev/null || echo training)   # défaut : training
   ```
   - **`training`** (défaut) → **enchaîner automatiquement** (sans redemander, c'est la boucle d'entraînement) :
     a. déléguer le sous-agent `writeup` → vault Obsidian `~/Documents/CTF/CTF/<Plateforme>/<Catégorie>/<Nom>.md` ;
     b. puis `/ctf-retro <nom-du-challenge>` → sous-agent `review` en **mode approfondi**
        (post-mortem méthodo/pièges/cadre + propositions, en plus de la KB/rétro).
   - **`competition`** → **s'arrêter là** : flag archivé + record committé (recon-report + exploit-log +
     flag + solution/). **Pas de writeup, pas de review** (réservés pour plus tard, économie de tokens).
     Signaler : « writeup différé + review sautée (mode compétition) ; régénérables via les logs ».
