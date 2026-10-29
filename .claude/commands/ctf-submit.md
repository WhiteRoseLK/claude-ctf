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
