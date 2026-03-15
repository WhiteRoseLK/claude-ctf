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

## Plan d'attaque

1. **Static analysis** : `file`, `strings`, `binwalk` → identifier le type de binaire
2. **Décompilation** : Ghidra/Radare2 → rechercher la logique de vérification du flag
3. **Dynamic analysis** : exécuter avec `ltrace`/`strace`, GDB si nécessaire
4. **Extract flag** : déobfusquer si nécessaire

## Fichiers

- Binaire : `work/<nom>` (à déposer dans work/)
- Flag : _(à compléter)_
