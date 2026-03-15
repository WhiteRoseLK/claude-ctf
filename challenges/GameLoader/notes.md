# GameLoader — Notes

## Informations

- **Plateforme** : HackTheBox
- **Nom** : GameLoader
- **Cible** : fichier binaire (challenge reverse)
- **Date de début** : 2026-03-15
- **Catégorie** : Reverse Engineering

## Observations initiales

- Pas de cible réseau — challenge basé sur un binaire à analyser
- "GameLoader" → probablement un loader/launcher de jeu, potentiellement obfusqué
- Le flag est typiquement extrait par : analyse statique, déobfuscation, ou exécution instrumentée

## Points de la knowledge base pertinents

### Techniques Reverse Engineering
- **Identification** : `file <bin>`, `strings <bin>`, `binwalk <bin>`
- **Analyse statique** : Ghidra, IDA Free, Binary Ninja, Radare2
- **Analyse dynamique** : `ltrace`, `strace`, GDB, Frida
- **Anti-debug** : ptrace checks, timing attacks → patcher ou bypasser
- **Obfuscation** : packing (UPX) → `upx -d <bin>`
- **Strings encodées** : XOR, ROT, base64 → CyberChef, script Python

### Erreurs à éviter
- Knowledge base vide pour l'instant

## Description officielle

> "Despite having an updated antivirus, my computer was compromised after running a game. Investigate the game and uncover the two-part flag."

→ Le jeu EST le malware. Flag en deux parties = deux actions malveillantes distinctes.

## Plan d'attaque (malware analysis)

### Priorité 1 — Analyse dynamique en sandbox (Windows VM)
- Exécuter le jeu dans un environnement isolé
- Monitor : Process Monitor, Regshot, Wireshark, API Monitor
- Chercher : fichiers déposés, clés registre, connexions réseau, processus lancés

### Priorité 2 — Extraction de la clé AES + décompilation GDScript
- Capturer la clé via breakpoint sur `mbedtls_aes_setkey_enc` (x64dbg/Frida)
- Décompiler avec GDRETools → lire le code malveillant dans `game.gd`

### Priorité 3 — Wine + monitoring macOS
- `wine "Platformer 2D.exe"` + `fs_usage`, `lsof`, Wireshark
- Risque : comportement malware peut différer sous Wine

## Fichiers

- Binaire : `work/<nom>` (à déposer dans work/)
- Flag : _(à compléter)_
