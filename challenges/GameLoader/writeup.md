# GameLoader — Writeup

| Info | Détail |
|------|--------|
| **Plateforme** | HackTheBox |
| **Catégorie** | Reverse Engineering + Malware Analysis |
| **Difficulté** | Medium |
| **OS** | Windows (PE32+ · moteur Godot 4.1.1) |
| **Flag** | `HTB{GD_M@lw4r3_PCB29543}` |

## TL;DR

Un jeu Godot 4.1.1 Windows dont le `.pck` est chiffré. La clé AES-256 est dans le `.exe`,
mais le template Godot a été **patché pour utiliser AES-256-CFB (avec IV) au lieu du ECB
standard**. Une fois le PCK déchiffré, le script `player_player.gd` contient un **malware**
obfusqué ; le flag (en 2 parties) est encodé en base64 dans des tableaux d'entiers.

## Reconnaissance

```bash
file "Platformer 2D.exe" "Platformer 2D.pck"
#  .exe : PE32+ GUI x86-64 (stripped to external PDB)
#  .pck : GDPC v2, Godot 4.1.1, pack_flags=0x01 (PACK_ENCRYPTED), 126 fichiers
```

Description officielle : *« my computer was compromised after running a game […] uncover the
two-part flag »* → **le jeu est le malware**, flag en 2 parties.

Faux ami : deux chaînes hex de 64 car. dans `.exe` sont des **vecteurs de test ECC mbedTLS**,
pas la clé. Un scan brute-force de la clé a d'abord **échoué** (voir Impasses).

## Exploitation

**1 — Extraire la clé AES.** La clé n'est pas une constante contiguë trouvable par scan :
elle est référencée par un pointeur global chargé lors du check magique `GDPC`
(`mov r14, [rip+0x12391ea]` → pointeur en `.data` → 32 octets) :

```
AES-256 key = f2f44f0aaa282c6b66065b1ca437abae05e20a55a0f6b2fd85f5b90576f0c88f
```

**2 — Identifier le bon mode.** Reverse de `open_and_parse` : après `MD5(16) + size(8)`,
16 `get_8()` supplémentaires → **IV de 16 octets** → mode **AES-256-CFB** (segment_size=128),
pas ECB.

```python
from Crypto.Cipher import AES
iv = bytes.fromhex('fa550640b0f8b3eeb1d879b2379023bb')
cipher = AES.new(key, AES.MODE_CFB, iv=iv, segment_size=128)
directory = cipher.decrypt(enc_dir)        # MD5 vérifié ✓, 126 fichiers
```

**3 — Extraire les 126 fichiers** (chaque fichier chiffré a son propre IV), dont 10 scripts GDScript.

**4 — Analyser le malware.** `player_player.gd` : collecte d'infos système → POST C2
`http://g4m3l0ad3r-network.htb/enum` → download `p47l0ad_binary` → exécution PowerShell
`-ExecutionPolicy Bypass` avec le hash MD5 du flag en argument. Tout est obfusqué en
tableaux d'entiers encodés base64.

**5 — Décoder le flag** (2 parties concaténées) :

```python
import base64
zbxp = base64.b64decode("R0RfTUBsdzRyM19Q")   # GD_M@lw4r3_P
qiro = base64.b64decode("Q0IyOTU0M30=")        # CB29543}
# → GD_M@lw4r3_PCB29543}  →  HTB{GD_M@lw4r3_PCB29543}
```

## Impasses

- **Brute-force de la clé en AES-ECB → 0 résultat.** La validation utilisait le mauvais mode
  (ECB au lieu de CFB) : elle ne pouvait jamais converger. **Leçon : confirmer le mode par
  reverse avant de bruteforcer.**
- Chaînes hex 64-car. prises un temps pour la clé → en fait vecteurs de test ECC.

## Apprentissages clés

- Godot PCK : `FileAccessEncrypted` est ECB **par défaut**, mais un challenge peut patcher
  en CFB+IV. Toujours vérifier `open_and_parse`.
- Déobfuscation GDScript : tableaux d'entiers → `chr` → base64 → texte ; recoller les
  concaténations de variables avant de décoder.
- Outils : **GDRETools/gdsdecomp** pour le PCK. Skills : `ctf-reverse` + `ctf-malware`.

## Références
- Godot `FileAccessEncrypted`, GDRETools (`github.com/GDRETools/gdsdecomp`)
