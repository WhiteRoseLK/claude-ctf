Soumet un flag à la plateforme CTF connectée et l'archive localement.

Arguments attendus : `<nom-du-challenge> <flag>`
Exemple : `/ctf-submit SpookyPass HTB{...}`

Pour une soumission par ID de challenge sur la plateforme active, utilise directement
le skill `ctf-submit` (qui appelle `~/.claude/ctf/ctf_cli.py submit --id <id> --flag <flag>`).

## Actions à réaliser

1. **Archiver le flag** dans `<CHAL>/flag.txt` (repo CTF privé, cf. CLAUDE.md § Structure ;
   localiser avec `find ~/Documents/CTF/CTF -type d -name '<nom>' -not -path '*/work/*'`)
   — juste le flag, une ligne. **Jamais** de flag dans ce repo-ci (public).
   CTF ponctuel : passer la ligne du challenge à ✅ dans `<Événement>/<Année>/README.md` (synthèse).

2. **Soumettre à la plateforme** si une connexion est active. Vérifie d'abord :
   ```bash
   python3 ~/.claude/ctf/ctf_cli.py status
   ```
   - Si connecté et que le challenge a un ID connu → délègue au skill `ctf-submit`.
   - Sinon, archive seulement en local et signale qu'aucune plateforme n'est connectée
     (l'utilisateur peut lancer `/ctf-connect`).

3. **Avertir** si le format du flag paraît inhabituel (pas de wrapper type `HTB{...}`),
   mais soumettre quand même si l'utilisateur confirme.

4. **Sauver le solveur dans le record** (avant tout cleanup) : copier le(s) script(s) de solve
   de `work/` vers `<CHAL>/solution/` pour que le writeup reste reproductible
   même différé et après suppression de `work/`.

5. **Commit git dans le repo CTF** (`git -C ~/Documents/CTF/CTF add <CHAL> && … commit && … push`) :
   `[exploit] <nom-du-challenge>: flag soumis et archivé`.

6. **Clôturer selon le MODE** — uniquement si la soumission est un succès (flag confirmé correct).
   Lire le mode :
   ```bash
   MODE=$(cat .ctf-mode 2>/dev/null || echo training)   # défaut : training
   ```
   - **`training`** (défaut) → **enchaîner automatiquement** (sans redemander, c'est la boucle d'entraînement) :
     a. si `<CHAL>` est encore sous `_A-trier/`, le déplacer (`git -C ~/Documents/CTF/CTF mv`) vers la
        catégorie détectée par le recon ; puis déléguer le sous-agent `writeup` en lui passant le chemin exact `<CHAL>/<Nom>.md` ;
        puis commit `[writeup] <nom>: …` dans le repo CTF ;
     b. puis `/ctf-retro <nom-du-challenge>` → sous-agent `review` en **mode approfondi**
        (post-mortem méthodo/pièges/cadre + propositions, en plus de la KB/rétro).
   - **`competition`** → **s'arrêter là** : flag archivé + record committé (recon-report + exploit-log +
     flag + solution/). **Pas de writeup, pas de review** (réservés pour plus tard, économie de tokens).
     Signaler : « writeup différé + review sautée (mode compétition) ; régénérables via les logs ».
