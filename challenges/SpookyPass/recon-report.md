# Recon Report — SpookyPass
**Date** : 2026-03-15 00:00
**Cible** : `/Users/mathieu/claude_ctf/challenges/SpookyPass/extracted/rev_spookypass/pass`
**Plateforme** : HTB
**Catégorie** : Reverse Engineering

---

## Résumé exécutif

Binaire ELF 64-bit non obfusqué (not stripped) qui affiche une invite de mot de passe. L'analyse statique révèle immédiatement deux artefacts critiques : le mot de passe de vérification en clair dans `.rodata` (`s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5`) et le flag HTB encodé sous forme de tableau d'entiers 32-bit (`parts`) dans `.data`. Le flag complet `HTB{un0bfu5c4t3d_5tr1ng5}` est récupérable sans exécution du binaire.

---

## Services découverts

| Port | Service | Version | Notes |
|------|---------|---------|-------|
| N/A  | Binaire local | ELF 64-bit x86-64 | Challenge de type crackme |

---

## Technologies identifiées

- **Type** : ELF 64-bit LSB PIE executable, x86-64
- **Compilateur** : GCC 14.2.1 (GNU) — deux builds : 20240805 et 20240910
- **OS cible** : GNU/Linux 4.4.0 (interpreter `/lib64/ld-linux-x86-64.so.2`)
- **Bibliothèques dynamiques** : `libc.so.6` (GLIBC 2.2.5, 2.4, 2.34)
- **Source** : compilé depuis `main.c` (symbole de debug présent)
- **Stripped** : Non (symboles présents)

### Protections binaires (analyse manuelle ELF)

| Protection | Etat |
|-----------|------|
| Stack Canary | Actif (`__stack_chk_fail@GLIBC_2.4` présent) |
| PIE | Actif (e_type = ET_DYN = 3) |
| NX (No-Execute) | Actif (PT_GNU_STACK flags = 0x6, sans PF_X) |
| RELRO | Partiel (PT_GNU_RELRO présent) |
| FORTIFY | Inactif |

---

## Analyse statique

### Symboles exportés (`nm pass`)

Fonctions et variables clés identifiées :

| Adresse | Type | Symbole |
|---------|------|---------|
| `0x1189` | T | `main` |
| `0x4060` | D | `parts` |
| U | extern | `fgets`, `strcmp`, `strchr`, `printf`, `puts` |
| U | extern | `__stack_chk_fail` |

### Sections ELF

| Section | Adresse virtuelle | Offset fichier | Taille |
|---------|------------------|----------------|--------|
| `.text`   | `0x1090` | `0x1090` | 604 octets |
| `.rodata` | `0x2000` | `0x2000` | 220 octets |
| `.data`   | `0x4040` | `0x3040` | 136 octets |

---

## Chaines identifiees (`strings pass`)

Toutes les chaînes extraites de `.rodata` (offset `0x2000`) :

```
/lib64/ld-linux-x86-64.so.2
fgets, stdin, puts, __stack_chk_fail, __libc_start_main, __cxa_finalize
strchr, printf, strcmp
libc.so.6 (GLIBC_2.4, GLIBC_2.2.5, GLIBC_2.34)
Welcome to the [1;3mSPOOKIEST[0m party of the year.
Before we let you in, you'll need to give us the password:
s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5       <-- MOT DE PASSE EN CLAIR
Welcome inside!
You're not a real ghost; clear off!
GCC: (GNU) 14.2.1 20240805
GCC: (GNU) 14.2.1 20240910
main.c
```

**Decouverte cle (2026-03-15)** : Le mot de passe de vérification `s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5` est stocké en clair dans `.rodata` à l'offset fichier `0x2080`.

---

## Analyse de la variable `parts` (adresse `0x4060`)

La variable `parts` est un tableau de 26 valeurs `int32` stocké dans `.data` à l'offset fichier `0x3060`. Le code `main` itère sur ce tableau (boucle `for i = 0; i <= 0x19; i++`) et reconstruit un buffer local caractère par caractère via `parts[i]`.

### Contenu du tableau `parts`

| Index | Valeur hex | ASCII |
|-------|-----------|-------|
| 0  | `0x48` | H |
| 1  | `0x54` | T |
| 2  | `0x42` | B |
| 3  | `0x7b` | { |
| 4  | `0x75` | u |
| 5  | `0x6e` | n |
| 6  | `0x30` | 0 |
| 7  | `0x62` | b |
| 8  | `0x66` | f |
| 9  | `0x75` | u |
| 10 | `0x35` | 5 |
| 11 | `0x63` | c |
| 12 | `0x34` | 4 |
| 13 | `0x74` | t |
| 14 | `0x33` | 3 |
| 15 | `0x64` | d |
| 16 | `0x5f` | _ |
| 17 | `0x35` | 5 |
| 18 | `0x74` | t |
| 19 | `0x72` | r |
| 20 | `0x31` | 1 |
| 21 | `0x6e` | n |
| 22 | `0x67` | g |
| 23 | `0x35` | 5 |
| 24 | `0x7d` | } |
| 25 | `0x00` | NUL |

**FLAG : `HTB{un0bfu5c4t3d_5tr1ng5}`**

---

## Logique de verification (desassemblage `main` — capstone)

```asm
0x1189: push rbp
0x118a: mov  rbp, rsp
0x118d: sub  rsp, 0xc0          ; Alloue 192 octets sur la pile
0x1194: mov  rax, [fs:0x28]     ; Stack canary
0x119d: mov  [rbp-8], rax
; --- Affichage du message de bienvenue ---
0x11cf: lea  rax, [rip+0xe32]   ; "Welcome to the SPOOKIEST..."
0x11d9: call puts
; --- Demande du mot de passe ---
0x11de: lea  rax, [rip+0xe5b]   ; "Before we let you in..."
0x11ed: call printf
; --- Lecture de l'input ---
0x11f2: mov  rdx, [rip+stdin]
0x11f9: lea  rax, [rbp-0x90]    ; Buffer local (128 octets)
0x1200: mov  esi, 0x80          ; Taille max = 128
0x1208: call fgets
; --- Suppression du newline ---
0x120d: lea  rax, [rbp-0x90]
0x1214: mov  esi, 0xa           ; '\n'
0x121c: call strchr
0x1239: mov  byte [rax], 0      ; Remplace '\n' par NUL
; --- Comparaison avec le mot de passe ---
0x1243: lea  rdx, [rip+0xe36]   ; "s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5"
0x1250: call strcmp             ; Compare input vs mot de passe
0x1255: test eax, eax
0x1257: jne  0x12c2             ; Si different -> "You're not a real ghost"
; --- Branche succes : reconstruction du flag ---
0x1259: call puts               ; "Welcome inside!"
0x1268: mov  dword [rbp-0xbc], 0 ; i = 0
; --- Boucle for(i=0; i<=0x19; i++) ---
0x1284: lea  rax, [rip+0x2dd5] ; rax -> parts[]
0x128b: mov  eax, [rdx+rax]    ; eax = parts[i]
0x1298: mov  [rbp+rax-0xb0], dl ; buffer[i] = (char)parts[i]
0x12af: jbe  0x1274             ; i <= 25
; --- Affichage du flag ---
0x12bb: call puts               ; Affiche le flag reconstruit
; --- Branche echec ---
0x12c2: lea  rax, [rip+0xdef]  ; "You're not a real ghost; clear off!"
0x12cc: call puts
```

---

## Vulnerabilites potentielles

### [Stockage du flag en clair dans .data] — Probabilite: Certaine
- **Service affecté** : Binaire `pass`
- **Description** : Le flag est stocké sous forme d'un tableau d'entiers 32-bit dans la section `.data`. Chaque entier contient directement la valeur ASCII d'un caractère. Aucune obfuscation, chiffrement ou protection n'est appliquée.
- **Exploit connu** : Extraction directe par `strings`, analyse binaire, ou débogage.

### [Mot de passe en clair dans .rodata] — Probabilite: Certaine
- **Service affecté** : Binaire `pass`
- **Description** : Le mot de passe `s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5` est stocké en texte clair dans `.rodata` à l'offset `0x2080`. La comparaison se fait via `strcmp` sans hashage ni transformation.
- **Exploit connu** : Visible directement avec `strings pass`.

---

## Vecteurs d'attaque recommandés

1. **Extraction directe du flag via analyse binaire** — Le flag et le mot de passe sont tous deux stockés en clair. Aucune exécution du binaire n'est requise. Commande suffisante : `strings pass`.

2. **Exécution du binaire avec le mot de passe valide** — Entrer `s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5` comme mot de passe déclenche la reconstruction du flag et son affichage via `puts`.

3. **Patch du saut conditionnel** — Modifier l'instruction `jne 0x12c2` (offset `0x1257`) en `nop` ou `je` force la branche succès sans connaître le mot de passe (non nécessaire ici).

---

## Commandes executees

```
# 2026-03-15 - Analyse initiale du type de fichier
file /path/to/pass
# ELF 64-bit LSB pie executable, x86-64, dynamically linked, not stripped

# Extraction des chaines lisibles
strings pass
# Decouverte: "s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5" et messages de bienvenue

# Listage des symboles
nm pass
# Symboles: main@0x1189, parts@0x4060, fgets/strcmp/strchr/puts/printf extern

# Analyse ELF manuelle via Python (macOS - objdump non disponible pour ELF)
# - Parsing section headers -> .text(0x1090), .rodata(0x2000), .data(0x4040)
# - Protections: Stack Canary=oui, PIE=oui, NX=oui, RELRO=Partiel, FORTIFY=non

# Localisation du mot de passe dans le binaire
python3 -> offset 0x2080, contexte confirme le stockage en clair

# Analyse de parts[] via parsing ELF Python
python3 -> tableau int32[26] à offset 0x3060 -> HTB{un0bfu5c4t3d_5tr1ng5}

# Desassemblage de main() via capstone (python3)
# Confirme: boucle for(i=0;i<=25;i++) { buffer[i] = (char)parts[i]; } puis puts(buffer)
```
