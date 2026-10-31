# Recon Report — Suspicious Threat
**Date** : 2026-10-31 20:55
**Cible** : SSH root@<INSTANCE_IP>:<PORT> (mot de passe `hackthebox`, instance container, pas de VPN)
**Plateforme** : HTB (Challenges #746, Easy)
**Catégorie détectée** : Forensics (rootkit userland LD_PRELOAD, sur une machine live)
**Skill à charger pour l'exploit** : `ctf-forensics`

## Résumé exécutif
Rootkit userland confirmé : `/etc/ld.so.preload` charge `/lib/x86_64-linux-gnu/libc.hook.so.6` (source `hider.c`), qui hooke `readdir`, `readdir64` et `fopen`. Il masque toute entrée de répertoire contenant `pr3l04d_` ainsi que `ld.so.preload`. Le répertoire caché `/var/pr3l04d_/` contient `flag.txt` (32 octets, root, 644). Le flag n'a pas été lu (réservé à exploit).

## Services découverts
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| <PORT> | SSH | OpenSSH (Ubuntu 24.04, kernel 6.18.24-talos) | root / hackthebox, accès confirmé |

## Technologies identifiées
- OS : Ubuntu 24.04 (conteneur), x86_64, python3.12 présent, `file` absent côté cible
- Rootkit : lib C compilée avec GCC 13.2.0 (Debian), non strippée, BuildID 515ea3f306c349f2ef11399cbebd3900fab188d1
- md5 de la lib : df5f6cda197ca8ec3368a66730853fa7
- Autres : `/etc/profile.d/01-locale-fix.sh` (eval de `/usr/bin/locale-check C.UTF-8`) et `~/.bashrc` examinés, rien de suspect. `/usr/bin/locale-check` est un ELF de 14 Ko daté d'avril 2024 comme le reste du système : non analysé, probablement légitime.

## Mécanisme du rootkit
- `/etc/ld.so.preload` (37 octets, daté Jul 24 2024) = `/lib/x86_64-linux-gnu/libc.hook.so.6`. `cat` fonctionne (le hook ne touche que `fopen`/`readdir`), mais `ls /etc` ne le liste pas.
- Lib : 15688 octets, mtime Jun 3 2024, visible dans `ls`. Elle n'est pas dans le répertoire du hook.
- Symboles exportés : `readdir`, `readdir64`, `fopen` ; `orig_readdir`, `orig_readdir64`, `orig_fopen` résolus par `dlsym(RTLD_NEXT)`. Importe `strcmp`, `strstr`, `__errno_location`.
- `.rodata` : `readdir`, `pr3l04d_`, `ld.so.preload`, `readdir64`, `fopen`.
- Logique déduite (symboles et chaînes ; désassemblage non fait, `objdump` du conteneur est aarch64) :
  - `readdir`/`readdir64` : saute les entrées dont `d_name` contient `pr3l04d_` (`strstr`) ou vaut `ld.so.preload` (`strcmp`).
  - `fopen` : renvoie NULL avec `errno` (ENOENT probable) si le chemin contient `ld.so.preload`, ce qui explique les « erreurs de linking » et les dossiers « manquants malgré leur existence confirmée ».
- Seul `readdir*` est hooké pour les listings, donc `stat`/`open`/accès direct par chemin complet fonctionnent sur les entrées cachées.

## Chemin du flag (pressenti, confirmé par existence)
- `/var/pr3l04d_/flag.txt` : 32 octets, root, 644. Le dossier `/var/pr3l04d_` est absent de `ls -la /var` mais visible via getdents brut (type 4 = dir).
- Le flag n'a PAS été lu.

## Vulnérabilités / pistes
### Rootkit userland LD_PRELOAD (ld.so.preload) ⭐ Probabilité: Haute (confirmé)
- **Service affecté** : tout processus dynamique sur la cible
- **Description** : hooks `readdir`/`readdir64`/`fopen` pour cacher `pr3l04d_*` et `ld.so.preload`
- **Exploit connu** : sans objet, c'est le mécanisme à contourner

## Vecteurs d'extraction recommandés pour exploit
1. **Lecture directe par chemin complet** : `cat /var/pr3l04d_/flag.txt`. Le hook n'agit que sur le listing ; `ls /var/pr3l04d_` liste même `flag.txt`, car son nom ne contient pas `pr3l04d_`. À essayer en premier.
2. **Si `cat` échoue** (`cat` utilise `open`, pas `fopen`) : lecture via `python3 -c "print(open('/var/pr3l04d_/flag.txt').read())"` ou `dd if=...` (python3 est présent).
3. **Neutraliser le hook** : `mv /etc/ld.so.preload /etc/ld.so.preload.bak` (le fichier est accessible par chemin direct) puis `ls -la /var` ; ou `LD_PRELOAD` n'a pas d'effet utile ici, car le chargeur lit `/etc/ld.so.preload`.
4. **Énumération brute** : script getdents64 via `ctypes.syscall(217, ...)` (voir `work/gd.py`, déjà testé), contourne le hook de `readdir`.
- Attention : flag à 32 octets, vérifier le format HTB{...} ; ne rien modifier sur la cible si possible.

## Embûches
- zsh ne découpe pas les variables contenant des commandes : utiliser le script `work/r.sh '<cmd distante>'` exécuté dans Exegol (`docker exec exegol-ctf-suspiciousthreat bash -c "cd /workspace && ./r.sh '<cmd>'"`).
- `challenge.zip` dans work/ n'était qu'un JSON d'erreur (« Challenge file not found », le challenge est container-only) : supprimé.
- `file` et `objdump` x86 indisponibles côté cible/Exegol : analyse faite via `nm -D`, `strings`, `objdump -s`.
- Le mot de passe expire éphémère, re-spawnable (instance re-spawnable via l'API).

## Commandes exécutées
(détail horodaté dans `exploit-log.md`, section Recon)
- 20:54:21 `ssh root@... 'id; uname -a; cat /etc/ld.so.preload; env | grep LD_; ls -la /etc/ld.so.*'` : preload = libc.hook.so.6 ; `ld.so.preload` absent du `ls`
- `ls -la /lib/x86_64-linux-gnu | grep hook` : lib de 15688 octets présente
- `scp` de la lib vers /workspace ; `nm -D`, `strings`, `objdump -s -j .rodata`
- `python3 gd.py` (getdents64 brut) sur `/etc`, `/`, `/var`... : révèle `ld.so.preload` et `/var/pr3l04d_`
- `stat` de `/var/pr3l04d_/flag.txt` (32 o, 644) et `ls /var/pr3l04d_` : `flag.txt` visible. Contenu non lu.
