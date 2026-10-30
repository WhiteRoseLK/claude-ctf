# Retrospective — Noise Codex (2026-10-30)

## Score global : B

Flag obtenu et validé HTB, mais temps perdu sur un LLL maison et recon-report laissé vide.

## Métriques
| Métrique | Valeur | Tendance vs. précédent |
|----------|--------|----------------------|
| Catégorie | Crypto (HTB #1419, Easy, 640 solves) | première crypto pure |
| Temps total | non horodaté (exploit-log sans timestamps) | → |
| Tentatives exploit | 2 (LLL pur-Python ❌, fpylll ✅) | → |
| Vecteur | 1 seul : approximate-GCD par SDA + LLL | → |
| Recon accuracy | Bon vecteur identifié dès l'analyse de source.py | → |
| Flag | `HTB{LLL_r3c0V3R_7H3_tRu7H_fR0m_7H3_n0153}` | → |

## Ce qui a bien marché
- Analyse de la source rapide et juste : `2*entropy + b < 2^514 ≪ p` donc `b = (c mod p) & 1`, et
  réduction au problème ACD pour retrouver `p`.
- Le vecteur n'a jamais changé ; seule l'implémentation a été corrigée.
- Une fois fpylll installé : résolution en 0,05 s.
- kb-search consulté en début de challenge.

## Ce qui peut être amélioré
- **Perf** : LLL réimplémenté en pur-Python (`Fraction`, Gram-Schmidt recalculé à chaque swap)
  a dépassé 120 s. Mauvaise généralisation de la règle EtherTag « réimplémenter » : ici `apt`
  fonctionnait et suffisait.
- **recon-report.md vide** (section Artefacts « à compléter ») : la source, la structure du
  chiffrement et l'hypothèse ACD n'ont été consignées que dans exploit-log.
- Pas de timestamps dans exploit-log : impossible de mesurer le temps par phase.
- Le skill `ctf-crypto` n'a pas été cité comme point de départ pour la SDA/LLL.

## Actions pour le prochain challenge
- [ ] Après le triage, tester `apt-get install` (fpylll, sage, gmpy2, pycryptodome) avant toute réimplémentation.
- [ ] Remplir recon-report.md (artefacts, analyse de source, vecteur pressenti) même si le triage est rapide.
- [ ] Ajouter des timestamps dans exploit-log.
- [ ] Crypto à bruit borné / modulus secret : penser ACD (SDA + LLL) ; voir [[techniques]] § Crypto.

## Modifications suggérées aux agents
- **recon** : ajouter une règle « le rapport doit contenir au minimum Artefacts, Analyse, Vecteur
  pressenti avant de passer la main ; un rapport avec un placeholder est incomplet ».
- **recon / exploit (catégorie crypto)** : en début de phase, vérifier la présence de fpylll/sage/gmpy2
  et les installer via apt si absents. Exemple : le LLL maison a coûté une tentative entière.
- **Docs repo** : nuancer la règle « réimplémenter en Python » (EtherTag) : valable pour protocole/parsing,
  pas pour les calculs lourds.

## KB mise à jour
- `techniques.md` § Crypto : Approximate-GCD par SDA + LLL.
- `lessons-learned.md` : installer plutôt que réimplémenter (règles 2, 6, 7).
