# NoiseCodex — Notes

| Champ | Valeur |
|---|---|
| Plateforme | HackTheBox (Challenges) |
| Challenge | Noise Codex (#1419) |
| Catégorie | Crypto |
| Difficulté | Easy (20 pts, 640 solves) |
| Date début | 2026-10-30 |

## Énoncé
> "This code once circulated through the cyber-underground circles of the crew known only as
> ECHO MIRAGE. Their doctrine was simple: *Let corporations hoard data, we'll bury truth
> beneath untrackable noise*. Don't trust it. Don't worship it. Just run it."

Zip protégé par mot de passe : `hackthebox`.

## Mémoire (kb-search)
- Règle n°1 : **confirmer le format/mode de chiffrement avant tout brute-force** (GameLoader).
- Si un outil manque de l'image Exegol `free`, réimplémenter en Python (EtherTag).

## Hypothèses
- "noise" + "just run it" → probablement un script (Python ?) qui encode/chiffre un flag ;
  reste à voir le contenu une fois extrait.

## Exécution
Tout dans le conteneur `exegol-ctf-NoiseCodex` (`/workspace` = ce dossier `work/`).
