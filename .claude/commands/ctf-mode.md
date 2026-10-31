Affiche ou change le mode du workspace CTF : **entraînement** ou **compétition**.

Argument optionnel : `training` | `competition` (alias tolérés : `entrainement`, `compet`).
Sans argument : affiche le mode courant.

Le mode est stocké dans `.ctf-mode` (gitignoré, perso au poste). **Défaut si le fichier est absent : `training`.**

## Actions à réaliser

1. **Sans argument** — lire et afficher le mode courant + son effet :
   ```bash
   cat .ctf-mode 2>/dev/null || echo training
   ```

2. **Avec un argument** — normaliser (`entrainement`→`training`, `compet`→`competition`) puis écrire :
   ```bash
   echo "training" > .ctf-mode      # ou : echo "competition" > .ctf-mode
   ```
   Confirmer le nouveau mode.

3. **Rappeler l'effet** (ce que fait `/ctf-submit` après un flag validé) :
   - **training** (défaut) → enchaîne automatiquement le **writeup** (vault) puis la **review approfondie**
     (post-mortem méthodo / pièges / respect du cadre + propositions d'amélioration). C'est la boucle d'entraînement.
   - **competition** → **s'arrête** après archivage du flag : writeup **différé**, review **sautée**
     (économie de tokens). Le record committé (recon-report + exploit-log + flag + solveur) reste complet,
     donc le writeup est régénérable plus tard sans perte.
