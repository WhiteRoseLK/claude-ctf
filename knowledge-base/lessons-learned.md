# Lessons Learned — CTF

> Erreurs et pièges rencontrés, pour ne pas les répéter. Mis à jour par `/ctf-retro`.
> **Consulter avant chaque challenge.**

Format : **Date** / **Challenge** — **Problème** → **Cause** → **Solution** → **Règle**

---

## Leçons

### 2026-03-15 — GameLoader
- **Problème** : un scan brute-force de la clé AES dans tout le PE (42 Mo) a renvoyé 0 résultat,
  alors que la clé était bien dans le binaire.
- **Cause** : le critère de validation déchiffrait en **AES-ECB** (défaut Godot), mais le
  challenge utilisait un template patché en **AES-CFB avec IV**. Le bon mode n'était pas celui supposé.
- **Solution** : reverser `open_and_parse` d'abord pour établir le format/mode exact, PUIS
  localiser la clé via le pointeur global (plus fiable que le scan octet par octet).
- **Règle** : **confirmer le mode/format de chiffrement par reverse AVANT tout brute-force.**
  Un brute-force qui valide avec le mauvais mode ne converge jamais.

### 2026-03-15 — EtherTag
- **Problème** : `nmap --script enip-info` prévu dans le plan, mais `nmap` absent de la machine.
- **Cause** : poste macOS sans outils de pentest Linux installés.
- **Solution** : probe EtherNet/IP réimplémenté en **sockets Python** (List Identity, Register
  Session, ReadTag) — aucun outil externe requis.
- **Règle** : **vérifier la disponibilité d'un outil avant de bâtir un plan dessus** ; sinon
  réimplémenter le protocole en Python plutôt que de rester bloqué. (cf. [[techniques]] § Méta)

### 2026-03-15 — SpookyPass
- **Problème** : temps passé à envisager un bypass d'auth (strcmp patch) alors que le flag
  était extractible sans jamais exécuter le binaire.
- **Cause** : réflexe « crackme → patcher le saut » au lieu de vérifier d'abord le stockage statique.
- **Solution** : sur un binaire non strippé, lire `.rodata`/`.data` en premier (`strings`, `nm`).
- **Règle** : **commencer par l'analyse statique la moins coûteuse** ; l'exécution/patch est un recours, pas un réflexe.

### 2026-10-30 — NoiseCodex
- **Problème** : un LLL réimplémenté en pur-Python (`Fraction`) a dépassé 120 s sur une base de
  dim 11 avec des entiers de 3072 bits ; le solveur fpylll a ensuite résolu en 0,05 s.
- **Cause** : l'image Exegol `free` n'a pas fpylll/sage/pip, et on a appliqué à la lettre la règle
  « réimplémenter en Python » (EtherTag). Or le LLL recalculait tout le Gram-Schmidt à chaque
  étape sur des rationnels énormes. Pourtant `apt` fonctionnait dans le conteneur.
- **Solution** : `docker exec exegol-ctf-<nom> apt-get install -y python3-fpylll`.
- **Règle** : **si l'outil est installable (apt/pip) dans le conteneur, l'installer plutôt que de
  le réimplémenter.** Réimplémenter n'est valable que pour du simple (protocole, parsing), pas
  pour du calcul lourd (LLL, factorisation, Gröbner). Tester `apt-get install` en premier (1 min).
- **Process** : `recon-report.md` a été laissé vide (« à compléter ») car le triage était rapide.
  **Remplir recon-report.md même si le triage est court** (artefacts, analyse de la source,
  hypothèse de vecteur) : sert à l'agent exploit et à la rétro.

---

## Règles accumulées (consultation rapide)

1. Confirmer le mode/format de chiffrement par reverse **avant** tout brute-force (GameLoader).
2. Vérifier la dispo d'un outil avant d'en dépendre ; sinon l'**installer** dans le conteneur
   (`apt install`, NoiseCodex), et ne réimplémenter en Python que le simple (protocole, parsing : EtherTag).
3. Analyse statique la moins coûteuse d'abord ; exécution/patch en recours (SpookyPass).
4. Un flag est souvent un tableau d'entiers (1 entier = 1 char ASCII) : vérifier `.data` / les tags.
5. Toujours charger le skill `ctf-<catégorie>` avant d'attaquer — ne pas réinventer la technique.
6. Pas de LLL/calcul lourd en pur-Python : installer fpylll/sage (`apt install python3-fpylll`) (NoiseCodex).
7. Remplir `recon-report.md` même quand le triage est rapide (NoiseCodex).

---

_Dernière mise à jour : 2026-10-30 (NoiseCodex)_
