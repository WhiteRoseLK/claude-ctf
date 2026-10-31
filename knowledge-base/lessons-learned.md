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

### 2026-10-31 — PartialEncryption
- **Problème 1 (process)** : le ZIP du challenge était protégé, le CLI HTB annonçait
  `file_password: None`, l'extraction a échoué et la recon a été bloquée jusqu'à confirmation
  manuelle du mot de passe (`hackthebox`).
- **Ce qu'on aurait dû faire** : tester directement `hackthebox` (mot de passe standard des archives HTB).
- **Règle** : **ne pas se fier à `file_password: None`** ; essayer `hackthebox` d'office avant de bloquer.
- **Problème 2 (technique)** : les instructions **AES-NI** (`aesenc`/`aesdec`/`aesdeclast`/
  `aeskeygenassist`) sont du « crypto maison », pas un XOR trivial. `rabin2 -I` disait `crypto false`
  (pas de constantes détectées) : cet indicateur est trompeur avec AES-NI.
- **Règle** : repérer `aes*` dans le désassemblage, puis réimplémenter en Python (S-box, RotWord=ROR8,
  InvShiftRows) plutôt que d'exécuter le binaire. Voir [[techniques]] § Reverse.
- **Problème 3 (leurres)** : 3 routines sur 4 ne font qu'imprimer un message d'usage via `putchar`.
  Le flag se lit dans les `cmp argv[1][i]` du vrai checker.
- **Règle** : **vérifier quel code est réellement atteint / compare l'entrée** ; ne pas supposer que la
  sortie `putchar` contient le flag.

### 2026-10-31 — SuspiciousThreat (Forensics, HTB #746)
- **Problème 1 (plateforme)** : le téléchargement du challenge a donné un faux « zip » (JSON d'erreur
  « Challenge file not found »). Le challenge est container-only (`play_methods: ["container"]`).
- **Ce qu'on aurait dû faire** : ne pas télécharger ; spawner via `POST /api/v4/container/start`
  (headers `Origin`/`Referer` = app.hackthebox.com) puis lire host/port/mot de passe (`hackthebox`).
- **Règle** : challenge sans fichier = spawn API, pas de download.
- **Problème 2 (outil)** : `objdump` d'Exegol est aarch64 (« can't disassemble for architecture
  UNKNOWN ») sur une lib x86-64. `strings`/`nm -D`/`objdump -s -j .rodata` ont suffi.
- **Règle** : sur binaire x86, ne pas compter sur `objdump -d` ; `strings`, `nm`, `readelf`, ou capstone Python.
- **Problème 3 (sécurité)** : `ctf_cli.py status` affiche le token HTB ; IP:port et identifiants de
  l'instance ont été écrits dans recon-report/notes committés.
- **Règle** : ne jamais lancer/logguer `status` ; placeholders `<HOST>:<PORT>` dans les fichiers committés.
- **Technique** : rootkit LD_PRELOAD qui hooke `readdir` = on ne désarme pas, on lit par chemin
  direct ou on réénumère en `getdents64`. Voir [[techniques]] § Forensics.
- **Process** : recon-report complet (règle NoiseCodex tenue), délégation et Exegol respectés.
  **Règle** : remplir `notes.md` « Mémoire pertinente » avec la sortie de kb-search dès l'init,
  même quand la KB ne remonte rien (noter « aucune entrée pertinente »).

---

## Règles accumulées (consultation rapide)

1. Confirmer le mode/format de chiffrement par reverse **avant** tout brute-force (GameLoader).
2. Vérifier la dispo d'un outil avant d'en dépendre ; sinon l'**installer** dans le conteneur
   (`apt install …`, ex. `python3-fpylll`), et ne réimplémenter en Python que le simple (protocole,
   parsing : EtherTag). En particulier **jamais de LLL/calcul lourd en pur-Python** (NoiseCodex : >120 s
   vs 0,05 s avec fpylll).
3. Analyse statique la moins coûteuse d'abord ; exécution/patch en recours (SpookyPass).
4. Un flag est souvent un tableau d'entiers (1 entier = 1 char ASCII) : vérifier `.data` / les tags.
5. Toujours charger le skill `ctf-<catégorie>` avant d'attaquer — ne pas réinventer la technique.
6. Remplir `recon-report.md` même quand le triage est rapide (NoiseCodex).
7. Archive protégée : essayer `hackthebox` d'office, ne pas croire `file_password: None` du CLI HTB (PartialEncryption).
8. Instructions `aes*` (AES-NI) dans un binaire = crypto maison : les réimplémenter en Python, ne pas exécuter (PartialEncryption).
9. Code décrypté au runtime : se méfier des routines leurres ; le flag peut être dans les `cmp argv[1][i]` du vrai checker.

10. Challenge HTB container-only (pas de fichier) : spawn via `POST /api/v4/container/start` (Origin/Referer), pas de download (SuspiciousThreat).
11. `objdump` d'Exegol = aarch64 : inutilisable sur du x86 ; `strings`/`nm -D`/`readelf` (SuspiciousThreat).
12. Jamais de token/IP/identifiants d'instance dans les fichiers committés ; ne pas lancer `ctf_cli.py status` (fuite du token).
13. Rootkit userland (hook `readdir`) : lire par chemin absolu ou `getdents64` brut, sans modifier la cible.

---

_Dernière mise à jour : 2026-10-31 (SuspiciousThreat)_
