# SpookyPass — Writeup

| Info | Détail |
|------|--------|
| **Plateforme** | HackTheBox |
| **Catégorie** | Reverse Engineering (crackme) |
| **Difficulté** | Very Easy |
| **OS** | Linux (ELF 64-bit) |
| **Flag** | `HTB{un0bfu5c4t3d_5tr1ng5}` |

## TL;DR

Binaire ELF 64-bit **non strippé et non obfusqué**. Le mot de passe de vérification est
en clair dans `.rodata`, et le flag est un tableau d'entiers 32-bit dans `.data`
(un entier = un caractère ASCII). Le flag s'extrait **sans exécuter** le binaire.

## Reconnaissance

```bash
file pass      # ELF 64-bit LSB PIE, x86-64, dynamically linked, not stripped
strings pass   # révèle "s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5" + messages
nm pass        # main@0x1189, parts@0x4060, strcmp/fgets/strchr extern
```

Deux artefacts sautent aux yeux : une chaîne qui ressemble à un mot de passe dans `.rodata`,
et un symbole `parts` dans `.data`.

## Exploitation

Le `main` lit l'entrée, la compare au mot de passe via `strcmp`, et en cas de succès
reconstruit le flag par une boucle `buffer[i] = (char)parts[i]` puis `puts(buffer)`.

`parts` est un tableau de 26 `int32` à l'offset fichier `0x3060`. Chaque entier est
directement une valeur ASCII. Parsing (macOS → pas d'`objdump` ELF, donc Python) :

```python
import struct
data = open('pass','rb').read()
parts = struct.unpack_from('<26i', data, 0x3060)
print(''.join(chr(c) for c in parts if c))   # HTB{un0bfu5c4t3d_5tr1ng5}
```

Alternative : exécuter et saisir `s3cr3t_p455_f0r_gh05t5_4nd_gh0ul5` → le binaire affiche le flag.

## Impasses

- Envisagé un patch du `jne 0x12c2` pour forcer la branche succès : **inutile**, le flag
  est statique. Leçon retenue : analyse statique la moins coûteuse d'abord.

## Apprentissages clés

- Flag fréquemment stocké comme tableau d'entiers (1 entier = 1 char) → lire `.data`.
- Sur un binaire not stripped, `strings` + `nm` suffisent souvent.
- Skill de référence : `ctf-reverse`.

## Références
- Skill `ctf-reverse` (extraction statique, parsing ELF)
