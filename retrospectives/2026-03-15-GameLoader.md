# Retrospective — GameLoader (2026-03-15)

> Rétro établie en backfill le 2026-10-30 à partir de recon-report.md + exploit-log.md.

## Score global : B+

## Métriques
| Métrique | Valeur |
|----------|--------|
| Catégorie | Reverse + Malware (Godot PCK) |
| Tentatives | 7 |
| Chemin | Clé AES (pointeur global) → PCK AES-CFB → GDScript → base64 |

## Ce qui a bien marché
- Persévérance sur le format : reverse de `open_and_parse` qui a révélé le mode CFB+IV.
- Localisation de la clé via le pointeur global (fiable), pas le scan brute-force.
- Déobfuscation méthodique des tableaux d'entiers → base64.

## Ce qui peut être amélioré
- **Tentative 1→2 : brute-force de la clé en ECB = 0 résultat**, pur temps perdu car le mode
  était supposé au lieu d'être confirmé. C'est l'enseignement central du challenge.
- Chaînes hex ECC confondues un temps avec la clé.

## Actions pour le prochain challenge
- [x] Règle KB (prioritaire) : confirmer le mode/format de chiffrement par reverse AVANT tout brute-force.
- [ ] Ajouter GDRETools au toolkit reverse.

## KB mise à jour
- `techniques.md` § Reverse : déchiffrement PCK Godot (piège ECB vs CFB) ; § malware : déobfuscation GDScript.
- `lessons-learned.md` : brute-force avec mauvais mode (règle n°1).
