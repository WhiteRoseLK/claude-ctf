# Retrospective — SpookyPass (2026-03-15)

> Rétro établie en backfill le 2026-10-30 à partir de recon-report.md + exploit-log.md.

## Score global : A

## Métriques
| Métrique | Valeur |
|----------|--------|
| Catégorie | Reverse (crackme) |
| Chemin | Extraction statique `.data` (tableau int32 → ASCII) |
| Exécution nécessaire ? | Non |

## Ce qui a bien marché
- Triage `file`/`strings`/`nm` immédiat → mot de passe et symbole `parts` repérés tout de suite.
- Parsing ELF en Python (pas d'`objdump` sur macOS).

## Ce qui peut être amélioré
- Temps perdu à envisager un patch de saut conditionnel alors que le flag était statique.

## Actions pour le prochain challenge
- [x] Règle KB : analyse statique la moins coûteuse d'abord (ajoutée à lessons-learned).

## KB mise à jour
- `techniques.md` § Reverse : extraction statique de flag en tableau d'entiers.
- `lessons-learned.md` : réflexe « patcher le saut » à éviter.
