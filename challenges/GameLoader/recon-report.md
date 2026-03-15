# Recon Report — GameLoader
**Date** : 2026-03-15 19:41
**Cible** : Platformer 2D.exe + Platformer 2D.pck
**Plateforme** : HTB
**Catégorie** : Reverse Engineering
**Agent** : recon

---

## Résumé exécutif

Le challenge GameLoader se présente comme un jeu Windows 2D Platformer basé sur le moteur Godot Engine 4.1.1. Le fichier `.pck` contenant les ressources du jeu est protégé par un répertoire de fichiers chiffré (AES-256-ECB via `FileAccessEncrypted` de Godot), et les scripts GDScript compilés sont également chiffrés individuellement. La clé AES de 32 octets est compilée dans le binaire `.exe` mais n'est pas présente sous forme de séquence contiguë de 32 octets dans le fichier, rendant l'extraction statique directe impossible. Le point d'entrée le plus prometteur est l'analyse dynamique (exécution sous Wine ou VM Windows) pour intercepter la clé en mémoire lors du chargement du PCK, ou l'utilisation de GDRETools avec la clé extraite dynamiquement.

---

## Contenu de l'archive

| Fichier | Taille | Type |
|---------|--------|------|
| `Platformer 2D.exe` | 42.1 MB | PE32+ Windows GUI x86-64 (stripped to external PDB) |
| `Platformer 2D.pck` | 2.4 MB | Godot PCK v2 (Godot 4.1.1), répertoire chiffré |

L'archive ZIP (`GameLoader.zip`) est protégée par mot de passe mais les fichiers existaient déjà extraits dans `work/rev_gameloader/`.

---

## Type de binaire / protections

### Platformer 2D.exe

| Protection | Valeur |
|------------|--------|
| Format | PE32+ (x86-64) |
| Type | Windows GUI executable |
| Debug info | Stripped (external PDB, référence absente) |
| Packer | Non détecté (entropie normale) |
| Sections | 14 sections (.text, .data, .rdata, pck, .pdata, .xdata, .bss, .edata, .idata, .CRT, .tls, .rsrc, .reloc, .eh_fram) |
| Section `pck` | Présente mais vide (0x200 octets de zéros) |

### Platformer 2D.pck

| Champ | Valeur |
|-------|--------|
| Magic | `GDPC` |
| Pack version | 2 |
| Godot version | 4.1.1 |
| pack_flags | 0x01 = `PACK_ENCRYPTED` (répertoire chiffré) |
| file_base | 0x2F50 (12112 octets) |
| file_count | 126 fichiers |

**Structure du PCK :**
```
0x0000 - 0x0063 : Header PCK (100 octets)
0x0064 - 0x0073 : MD5 du répertoire déchiffré = 0906adf98c7afc12803ff335cf6b3cfa
0x0074 - 0x007B : Taille du répertoire déchiffré = 11956 octets
0x007C - 0x2F4F : Répertoire chiffré AES-256-ECB (11988 octets = ~749 blocs)
0x2F50 - EOF   : Section données fichiers (2,456,048 octets)
```

Le format du bloc chiffré correspond au format `FileAccessEncrypted` de Godot (MD5 + longueur + données chiffrées ECB).

---

## Technologies identifiées

- **Moteur** : Godot Engine 4.1.1
- **Langage scripts** : GDScript (compilé en `.gdc`, chiffré individuellement)
- **OS cible** : Windows (PE32+ x86-64)
- **Chiffrement** : AES-256-ECB via `FileAccessEncrypted` (mbedTLS)
- **Ressources** : WebP (textures), WAV (audio), OGG (musique), TTF (police)
- **Bibliothèques** : mbedTLS (crypto), ENet (réseau potentiel)
- **Base du jeu** : 2D Platformer Demo officiel de Godot Engine (modifié pour le CTF)

---

## Strings notables

### Dans Platformer 2D.exe (section .rdata, offset 0x202a757)

Deux chaînes hexadécimales de 64 caractères trouvées :
```
5715ECCE24583F7A7023C24164390586842E816D7280A49EF6DF4EAE6B280BF8
41A2B017516F6D254E1F002BCCBADD54BE30F8CEC737A0E912B4963B6BA74460
```

**Note critique** : Ces chaînes sont entourées de noms de courbes elliptiques (`secp521r1`, `brainpoolP512r1`, `secp256r1`, `secp192r1`, etc.) et de vecteurs de test ECC connus (`555...55`, `7FFF...FF`, `4000...00`, etc.). Il s'agit de **vecteurs de test mbedTLS pour ECC**, PAS de la clé de chiffrement Godot.

### Configuration projet (ECFG, en clair dans le PCK)

```
application/config/name          = "2DPlatformer"
application/run/main_scene       = "res://game_singleplayer.tscn"
autoload/Music                   = "*res://music.tscn"
display/window/size/viewport_*   = 800x480
layer_names/2d_physics/layer_1   = "player"
layer_names/2d_physics/layer_2   = "enemies"
layer_names/2d_physics/layer_4   = "platforms"
layer_names/2d_physics/layer_5   = "ground"
```

Description du projet (en clair) :
```
"This demo is a pixel art 2D platformer with graphics and sound.
[...] the player can jump, walk on slopes, fire bullets, interact with
enemies [...] one closed level, and the player is invincible, unlike the enemies."
```

### Aucun HTB{} trouvé en clair

Ni dans le `.exe` ni dans le `.pck` (données en clair).

---

## Fonctions / Symboles clés

### Scripts GDScript identifiés (tous chiffrés dans le PCK)

| Chemin | Classe | Classe de base |
|--------|--------|----------------|
| `res://player/bullet.gd` | `Bullet` | `RigidBody2D` |
| `res://level/coin.gd` | `Coin` | `Area2D` |
| `res://gui/coins_counter.gd` | `CoinsCounter` | `Panel` |
| `res://enemy/enemy.gd` | `Enemy` | `CharacterBody2D` |
| `res://game.gd` | (logique principale) | — |
| `res://player/gun.gd` | — | — |
| `res://gui/pause_menu.gd` | — | — |
| `res://player/player.gd` | `Player` | `CharacterBody2D` |

### Scènes exportées (métadonnées [remap] lisibles, contenu chiffré)

```
export-5a17f01fb2432f51b17a4489a57742b5-game_singleplayer.scn
export-753d15e03e0182f9d550ac833b42bb41-player.scn
export-6dcf1f1cf49f4ecbd395fe92f3dd7400-level.scn
export-ff7a3e44be70b9087acd06591c2a4ad9-coins_counter.scn
export-7a7ef7eb2aa2d13d5f77526465e49dfc-enemy.scn
export-ccbd35e6f72058f9e5d89a0d1cb3e691-bullet.scn
export-b456f4f6ccab8612403f3d93f345b967-coin.scn
(+ 13 autres scènes/ressources exportées)
```

### Actions input (depuis project.binary)

- `input/jump`, `input/jump_p1`, `input/jump_p2`
- `input/move_left`, `input/move_right`
- `input/shoot`, `input/shoot_p1`, `input/shoot_p2`
- `input/toggle_fullscreen`, `input/toggle_pause`
- `input/splitscreen`

---

## Logique principale identifiée

### Structure générale du jeu

Jeu 2D platformer basé sur le demo officiel Godot Engine, **modifié** par l'auteur du challenge pour inclure un mécanisme de révélation du flag. La scène principale `game_singleplayer.tscn` contient :
- Joueur avec saut, tir, marche sur pentes
- Ennemis destructibles
- Pièces collectibles (`Coin` -> `Area2D`) suivies par `CoinsCounter` (GUI)
- Niveau fermé avec tileset
- Menu pause

### Hypothèse sur le mécanisme de flag

La présence de `CoinsCounter` (compteur dédié en GUI) et de `Coin` (collectibles de type `Area2D`) est très caractéristique des CTF-platformers où **collecter toutes les pièces** (ou une condition similaire) déclenche l'affichage du flag. Les scripts `game.gd` et `coins_counter.gd` sont les candidats principaux pour la logique de flag.

### Chiffrement PCK — Analyse détaillée

Le répertoire PCK est chiffré avec `FileAccessEncrypted` de Godot (AES-256-ECB) :
- **MD5 du répertoire** (non chiffré) : `0906adf98c7afc12803ff335cf6b3cfa`
- **Taille du répertoire** (non chiffré) : 11956 octets
- **Données de fichiers** : Certains fichiers en clair (audio WAV, images WebP), d'autres chiffrés (scripts compilés)

Recherche exhaustive de la clé AES dans le binaire :
- Scan octet par octet de tout le PE (42 MB, pas à pas de 4 octets)
- Test : critère fort = déchiffrement produit path_len valide (10-200) + prefix "res://"
- Test de dérivations : SHA256, MD5, clé zéro, inversions
- **Résultat : 0 correspondance**

La clé est probablement initialisée via le code d'exécution (non stockée comme constante contiguë).

---

## Vulnérabilités potentielles

### [VULN-1 — Clé AES en mémoire] Probabilité: Haute
- **Service affecté** : `Platformer 2D.exe` (lors du chargement du PCK)
- **Description** : La clé AES-256 est en mémoire lors de l'appel à `mbedtls_aes_setkey_enc` ou `FileAccessEncrypted::open_and_parse`. Un breakpoint dynamique permet de la capturer.
- **Exploit connu** : Oui — technique standard Godot CTF

### [VULN-2 — GDScript chiffré déchiffrable] Probabilité: Haute
- **Service affecté** : Scripts dans le PCK
- **Description** : Une fois la clé obtenue, les scripts peuvent être déchiffrés et décompilés avec GDRETools.
- **Exploit connu** : Oui — GDRETools (https://github.com/GDRETools/gdsdecomp)

---

## Vecteurs d'attaque recommandés

1. **Analyse dynamique Windows (prioritaire)** — Exécuter sous x64dbg/WinDbg, poser un breakpoint sur `mbedtls_aes_setkey_enc`. La clé de 32 octets est passée en argument. Alternative : Cheat Engine + scan de la mémoire pour trouver un pattern déchiffrant les données PCK connues.

2. **GDRETools + clé extraite** — Importer le PCK et la clé dans GDRETools pour extraire et décompiler tous les scripts GDScript. Analyser `game.gd` et `coins_counter.gd` pour la condition de flag.

3. **Jouer le jeu directement** — Exécuter sous Wine (UTM/Parallels disponibles) et collecter toutes les pièces. Si le flag apparaît en GUI, pas besoin de reverse engineering des scripts.

4. **Frida/DynamoRIO** — Hooker `mbedtls_aes_crypt_ecb` pour capturer les blocs déchiffrés en temps réel.

---

## Commandes exécutées (chronologie complète)

```bash
# 19:41 - Vérification répertoire
ls -lah /Users/mathieu/claude_ctf/challenges/GameLoader/work/
# -> GameLoader.zip (18MB), rev_gameloader/ déjà extrait

# Identification des fichiers
file "rev_gameloader/Platformer 2D.exe" "rev_gameloader/Platformer 2D.pck"
# -> .exe: PE32+ executable (GUI) x86-64 (stripped to external PDB), for MS Windows
# -> .pck: data

# Analyse header PCK (hexdump)
xxd "Platformer 2D.pck" | head -40
# -> Magic GDPC, ver 4.1.1, flags=0x01, file_base=0x2F50, file_count=126

# Recherche de strings dans .exe
strings "Platformer 2D.exe" | grep -E "^[0-9a-fA-F]{64}$"
# -> 5715ECCE... et 41A2B017... (+ vecteurs ECC)
strings "Platformer 2D.exe" | grep -i "htb\|flag\|ctf\|pass\|key"
# -> Résultats liés au moteur, aucun flag

# Recherche de strings dans .pck
strings "Platformer 2D.pck" | grep "res://"
# -> 98 chemins de ressources en clair (dans les fichiers de données)

# Analyse Python - Parsing PCK
# -> Structure FAE confirmée: MD5(16) + size(8) + AES-ECB(11988 octets) à 0x64

# Scan exhaustif du PE pour la clé AES (42 MB, critère: déchiffre en path_len valide + "res://")
# -> 0 correspondance

# Extraction config projet (ECFG)
# -> 40 paramètres extraits, structure du jeu documentée

# Recherche flag HTB{} dans tous les fichiers
# -> Non trouvé en clair

# Analyse des ressources RSRC en clair (AudioStreamWAV, WebP)
# -> 6 ressources WAV, 31 images WebP, 7 blocs Zstd
# -> Aucun GDSC (scripts compilés visibles = tous chiffrés)
```
