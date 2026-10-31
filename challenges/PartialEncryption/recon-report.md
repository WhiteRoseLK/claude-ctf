# Recon Report — Partial Encryption
**Date** : 2026-10-31
**Cible** : fichier local (pas de cible réseau)
**Plateforme** : HTB (#306, Easy)
**Catégorie détectée** : Reverse
**Skill à charger pour l'exploit** : `ctf-reverse`

## Résumé exécutif
`partialencryption.exe` est un petit PE64 console Windows (13 Ko, C/MSVC, non packé) sans aucune chaîne lisible. Son `main` appelle 4 fonctions (`fcn.140001130`, `1400012b0`, `1400013b0`, `1400011f0`) en leur passant le pointeur de `putchar`, ce qui indique un flag affiché caractère par caractère. Il importe `VirtualAlloc`/`VirtualProtect`/`VirtualFree`, donc probablement du code déchiffré ou généré à l'exécution (le « partial encryption »). Aucune exécution n'a été tentée.

## Artefacts
| Fichier | Détail |
|---------|--------|
| `challenge.zip` | ZIP chiffré, mot de passe `hackthebox` (standard HTB, confirmé par le coordinateur). Contient `rev_partialencryption/partialencryption.exe` |
| `partialencryption.exe` | PE32+ console x86-64, 13312 octets, compilé le 2022-01-24, sha256 `ae46c6efbb950f62a83a789cb4de515e5e511be6f8197c2e79a59e680b52afd4` |

Extraits dans `/workspace/extracted/rev_partialencryption/` (conteneur).

## Technologies identifiées
- Langage : C (MSVC, `cc ms`), CRT dynamique (VCRUNTIME140, api-ms-win-crt-*)
- OS cible : Windows x64, sous-système console
- Non strippé côté imports ; aucun symbole de fonctions utilisateur
- 5 sections : `.text` 0x1200 (R-X), `.rdata`, `.data` 0xa00 (RW, taille notable pour 13 Ko), `.pdata`, `.reloc`

## Protections (rabin2 -I)
canary oui, NX oui, PIC/ASLR oui, non signé, pas d'overlay. `crypto false` (pas de constante crypto standard détectée). Sans objet ici : il s'agit de reverse, pas de pwn.

## Observations de triage
- `strings -a` : uniquement des fragments d'opcodes, aucune chaîne utile. `strings -el` (UTF-16) : vide. Pas de « flag »/`HTB{`.
- Imports notables : `putchar` (sortie char par char), `VirtualAlloc`/`VirtualProtect`/`VirtualFree`, `IsDebuggerPresent` (anti-debug simple), `memset`.
- `main` @ 0x140001580 : appelle 4 routines avec `putchar`, `exit`, `argc`, `argv` et un pointeur de variable locale initialisé à 0. Chaque routine émet vraisemblablement une partie du flag.
- `.data` de 0xa00 octets : probable table de données chiffrées/encodées.

## Pistes d'attaque (par priorité)
1. **Analyse statique des 4 routines** (`0x140001130`, `0x1400011f0`, `0x1400012b0`, `0x1400013b0`) dans Ghidra/r2 : identifier la transformation (XOR/ADD/rotation sur un tableau de `.data`) et recalculer le flag hors exécution. Cela s'est révélé efficace pour SpookyPass (tableau en `.data`).
2. **Chiffrement partiel** : le nom suggère qu'une partie du flag est en clair ou déjà reconstruite et que le reste est chiffré. Confirmer le mode et la clé par reverse AVANT tout brute-force (règle KB, rétro GameLoader).
3. **Code dynamique** : si les routines utilisent `VirtualAlloc`/`VirtualProtect` pour déchiffrer du code, dumper la région après déchiffrement (debug sous wine/gdb dans Exegol, ou émulation `unicorn`/`speakeasy`).
4. **Exécution contrôlée** (dernier recours) : `wine partialencryption.exe` dans le conteneur uniquement ; le programme est petit et n'affiche vraisemblablement que le flag via `putchar`.
5. Contourner `IsDebuggerPresent` si on débogue (patch du retour).

## Commandes exécutées
```
2026-10-31  python3 tools/kb-search/kb_search.py "reverse partial encryption"
            -> rétros GameLoader (confirmer le mode avant brute-force) et SpookyPass (.data statique)
2026-10-31  docker exec exegol-ctf-PartialEncryption bash -c "cd /workspace && unzip -o challenge.zip -d extracted"
            -> échec sans mot de passe ("unable to get password"), rien deviné
2026-10-31  unzip -Z -v challenge.zip ; 7z l -slt challenge.zip
            -> entrée 2 chiffrée (Encrypted = +), 13312 octets
2026-10-31  [après confirmation du mot de passe par le coordinateur]
            unzip -o -P hackthebox challenge.zip -d extracted
            -> extrait rev_partialencryption/partialencryption.exe
2026-10-31  file ; sha256sum ; strings -a | head ; strings -el | head
            -> PE32+ console x86-64, 5 sections ; aucune chaîne utile
2026-10-31  rabin2 -I ; rabin2 -i ; rabin2 -zz ; rabin2 -S ; rabin2 -s ; rabin2 -e
            -> imports VirtualAlloc/Protect/Free, putchar, IsDebuggerPresent ; entry 0x1400018a4 ; compilé 2022-01-24
2026-10-31  r2 -q -c 'aaa; afl~main; pdf @ main'
            -> main @ 0x140001580 : 4 appels (0x140001130, 0x1400012b0, 0x1400013b0, 0x1400011f0) avec putchar
```
Culs-de-sac : `strings` (rien d'exploitable) ; aucune exécution tentée.

## Conclusion
Catégorie : **Reverse**. Skill à charger : **`ctf-reverse`**.
