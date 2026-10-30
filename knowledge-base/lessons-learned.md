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

---

## Règles accumulées (consultation rapide)

1. Confirmer le mode/format de chiffrement par reverse **avant** tout brute-force (GameLoader).
2. Vérifier la dispo d'un outil avant d'en dépendre ; sinon réimplémenter en Python (EtherTag).
3. Analyse statique la moins coûteuse d'abord ; exécution/patch en recours (SpookyPass).
4. Un flag est souvent un tableau d'entiers (1 entier = 1 char ASCII) : vérifier `.data` / les tags.
5. Toujours charger le skill `ctf-<catégorie>` avant d'attaquer — ne pas réinventer la technique.

---

_Dernière mise à jour : 2026-10-30 (backfill des 3 premiers challenges)_
