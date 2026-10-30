# Techniques éprouvées — Knowledge Base

> **Journal expérientiel**, pas une encyclopédie. Les techniques génériques vivent dans
> les skills `ctf-*` (`skills/`). Ici on consigne UNIQUEMENT ce qu'on a réellement
> appliqué sur un challenge : le piège clé, l'astuce qui a débloqué, et le skill à charger.
> Mis à jour par l'agent `review` / `/ctf-retro` après chaque challenge.
> **Consulter avant chaque recon et exploit.**

Format d'une entrée :
- **Technique** — nom court
- **Catégorie / skill** — quel skill `ctf-*` couvre le détail
- **Challenge(s)** — où ça a servi
- **Insight clé** — le truc non évident qui a fait gagner (ou perdre) du temps
- **Approche** — commande / méthode condensée

---

## Reverse Engineering

### Extraction statique de flag/mot de passe en clair (`.rodata` / `.data`)
- **Catégorie / skill** : reverse → `ctf-reverse`
- **Challenge(s)** : SpookyPass (HTB)
- **Insight clé** : sur un binaire **not stripped** et non obfusqué, le flag peut être un
  tableau d'`int32` dans `.data` (un entier = un caractère ASCII), reconstruit par une
  boucle `buffer[i] = (char)parts[i]`. Inutile d'exécuter : `strings` + parsing des sections suffit.
- **Approche** : `file`, `strings`, `nm` pour repérer les symboles (`main`, `parts`) → parser
  `.data` à l'offset fichier pour lire le tableau. Sur macOS, pas d'`objdump`/`gdb` ELF :
  parsing ELF + désassemblage via **Python (pwntools/capstone)**.

### Déchiffrement d'un PCK Godot (FileAccessEncrypted) — attention au mode AES
- **Catégorie / skill** : reverse + crypto → `ctf-reverse`, `ctf-crypto`
- **Challenge(s)** : GameLoader (HTB)
- **Insight clé** : Godot chiffre le PCK en **AES-256-ECB** par défaut, MAIS un challenge peut
  avoir **patché le template** pour utiliser **CFB avec un IV de 16 octets** inséré après
  `MD5(16) + plaintext_size(8)`. Un brute-force de clé qui valide avec le *mauvais mode*
  échoue toujours → **toujours confirmer le mode en reversant `open_and_parse` avant de bruteforcer**.
- **Approche** : localiser la clé via le pointeur global dans `.data` (suivre le `mov r14, [rip+...]`
  qui référence la clé lors du check magique `GDPC`). Puis `AES.new(key, MODE_CFB, iv, segment_size=128)`,
  vérifier via le MD5 du répertoire. Décompilation : **GDRETools / gdsdecomp**.

### Déobfuscation GDScript (tableaux d'entiers → base64 → texte)
- **Catégorie / skill** : malware → `ctf-malware`
- **Challenge(s)** : GameLoader (HTB) — flag en 2 parties concaténées
- **Insight clé** : l'obfuscation = variables à noms aléatoires contenant des tableaux
  d'entiers (mix décimal/hex/binaire), assemblés en chaîne puis décodés base64. Le flag
  et les IOC (domaine C2, chemin de payload) sont tous encodés pareil. Reconstituer les
  concaténations de variables (`loap = zbxp + qiro`) avant de décoder.
- **Approche** : extraire chaque tableau → `''.join(chr(c))` → `base64.b64decode`.

---

## Crypto

### Approximate-GCD (ACD) par SDA + LLL
- **Catégorie / skill** : crypto → `ctf-crypto`
- **Challenge(s)** : Noise Codex (HTB #1419, Easy) — flag en 0,05 s une fois fpylll installé
- **Insight clé** : chiffrement bit par bit `c = p*distortion + 2*entropy + b` avec `p` (premier
  1024 bits) NON fourni. Comme `2*entropy + b < 2^514 ≪ p`, on a `c mod p = bruit` donc
  `b = (c mod p) & 1`. Tout le problème se réduit à retrouver `p` : c'est de l'approximate-GCD
  (`c_i = p*q_i + r_i`, `r_i` petit). Signal de reconnaissance : un « bruit » additif borné
  très inférieur à un modulus secret + plusieurs centaines d'échantillons.
- **Approche** : attaque SDA (simultaneous Diophantine approximation). Avec `x0..xt` échantillons
  et `ρ` = taille du bruit (514), base de dimension t+1 :
  ligne 0 = `[2^(ρ+1), x1, …, xt]`, ligne i = `-x0` en colonne i. LLL → le vecteur court
  `v[0] = q0*2^(ρ+1)` donne `q0 = |v[0]| / 2^(ρ+1)` puis `p = x0 // q0`. t=11 (dim 12) = marge
  large (le gap est assuré dès t>4). Vérifier : `p` fait 1024 bits et `c_i % p < 2^514`.
  Puis les 328 bits `b_i` → 41 caractères ASCII.
- **Piège outillage** : image Exegol `free` sans fpylll/sage → `apt-get install -y python3-fpylll`
  (cf. [[lessons-learned]] 2026-10-30). Un LLL pur-Python sur `Fraction` n'est pas viable
  (>120 s, vs 0,05 s en C).

---

## ICS / Systèmes industriels

### Lecture non authentifiée de tag EtherNet/IP (CIP)
- **Catégorie / skill** : misc/réseau industriel → `ctf-misc` (+ recherche CVE)
- **Challenge(s)** : EtherTag (HTB) — Allen-Bradley 1756-L61/B
- **Insight clé** : EtherNet/IP v1/v2 **n'a aucune authentification** (CIP Security seulement
  en v3.21+). Le flag était dans un tag `flag` (INT[100], 1 entier = 1 caractère ASCII),
  lisible via service CIP **ReadTag (0x4c)**. Réf : CVE-2012-6435, ICSA-12-146-01.
- **Approche** : `Register Session (0x65)` → `SendRRData (0x6f)` + ReadTag avec path ANSI
  Extended Symbolic `\x91\x04flag\x00`, count=100. Outil dédié : **pycomm3** / **cpppo**
  (`CIPDriver(ip).get_tag_list()`), mais ici fait à la main en sockets Python.
- **Fingerprint** : `List Identity (0x63)` donne vendor/device/révision du PLC.

---

## Méta / environnement

### macOS sans outils Linux natifs → sockets & parsing Python
- **Challenge(s)** : SpookyPass, EtherTag, GameLoader
- **Insight clé** : sur ce poste macOS, `nmap`, `objdump` ELF, `gdb` ne sont pas dispo.
  Ne pas bloquer : **réimplémenter en Python** (parsing ELF/PE, sockets bruts pour
  EtherNet/IP, capstone pour le désassemblage). Toujours vérifier la dispo d'un outil
  avant de baser un plan dessus.

---

_Dernière mise à jour : 2026-10-30 (NoiseCodex : ACD par SDA + LLL)_
