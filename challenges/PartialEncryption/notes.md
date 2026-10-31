# Partial Encryption — Notes

| Champ | Valeur |
|---|---|
| Plateforme | HackTheBox (Challenges) |
| Challenge | Partial Encryption (#306) |
| Catégorie | Reversing |
| Difficulté | Easy (2047 solves) |
| Date début | 2026-10-31 |

## Mémoire (kb-search, reverse)
- Règle : **confirmer le mode/format de chiffrement par reverse AVANT tout brute-force** (GameLoader).
- Analyse statique la moins coûteuse d'abord (`file`/`strings`/`nm`), exécution/patch en recours (SpookyPass).
- Outil manquant de l'image free → l'installer dans le conteneur (règle 2).

## Exécution
Tout dans le conteneur `exegol-ctf-PartialEncryption` (`/workspace` = `work/`).
