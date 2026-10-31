# Retrospective — Partial Encryption (2026-10-31)

## Score global : A-

Flag obtenu et validé HTB, 4 tentatives sans impasse, aucune exécution du PE. Seul bémol : blocage initial sur le mot de passe d'archive.

## Métriques
| Métrique | Valeur | Tendance vs. précédent |
|----------|--------|----------------------|
| Catégorie | Reverse (HTB #306, Easy) | → (3e reverse) |
| Temps total | ~4 min d'exploit (10:01 → 10:04), recon non horodatée précisément | ↓ |
| Tentatives exploit | 4, 0 impasse (RE statique AES-NI) | ↓ vs NoiseCodex (2 dont 1 échec) |
| Recon accuracy | Bon vecteur en piste #1 (analyse statique des 4 routines) ; piste #3 (code dynamique) proche | → |
| Flag | `HTB{W3iRd_RUnT1m3_DEC}` | → |

## Ce qui a bien marché
- kb-search en début de recon : a remonté SpookyPass (statique d'abord) et GameLoader (confirmer le mode avant brute-force).
- Analyse statique pure : déchiffreur et primitive reversés, transformation réimplémentée en Python, aucune exécution/wine/debug nécessaire (anti-debug contourné de fait).
- Réimplémentation validée par un critère objectif : tous les blobs déchiffrés donnent du x86-64 valide.
- Recon-report complet (leçon NoiseCodex appliquée), exploit-log horodaté.

## Ce qui peut être amélioré
- **Blocage initial** : `file_password: None` côté CLI HTB, extraction échouée, attente d'une confirmation manuelle du mot de passe `hackthebox`.
- **Identifier AES-NI** : `rabin2 -I` indiquait `crypto false` ; la recon a vu `.data` et `VirtualAlloc` mais pas formulé l'hypothèse « code déchiffré par AES-NI ».
- **Leurres** : 3 routines sur 4 sont des branches d'usage via `putchar` ; le recon supposait que chacune émettait une partie du flag. Le flag est dans les `cmp argv[1][i]` du vrai checker.
- Recon non horodatée finement : temps par phase approximatif.

## Actions pour le prochain challenge
- [ ] Archive protégée : essayer `hackthebox` d'office, ne pas se fier à `file_password: None`.
- [ ] Reverse avec `.data` volumineuse + `VirtualAlloc/Protect` : chercher `aes*`/XOR par bloc dans le déchiffreur, dumper `.data`, réimplémenter en Python.
- [ ] Ne pas conclure sur `crypto false` de rabin2 : grepper `aes` dans le désassemblage.
- [ ] Après déchiffrement de shellcodes, trier leurre / vrai checker avant d'extraire le flag.
- [ ] Horodater aussi les commandes de la recon.

## Modifications suggérées aux agents
- **recon** : ajouter « Archive chiffrée : tester `hackthebox` avant de remonter un blocage ; le champ `file_password` du CLI HTB peut être faux (PartialEncryption #306) ». Ajouter aussi au triage reverse : `r2 -c 'aaa; /c aes'` (ou grep `aes` dans `pdf`) pour détecter AES-NI, et ne pas se fier à `rabin2 -I` `crypto`.
- **exploit (reverse)** : en cas de code chiffré au runtime, procéder statiquement (dump + réimplémentation) avant wine/debug ; et distinguer routines leurres vs checker.

## KB mise à jour
- `techniques.md` § Reverse : Partial runtime decryption via AES-NI.
- `lessons-learned.md` : leçon PartialEncryption, règles 7 à 9.
