# Techniques CTF — Knowledge Base

> Ce fichier est mis à jour automatiquement par l'agent review après chaque challenge.
> Consulter AVANT chaque phase de recon et d'exploit.

---

## Web

### SQL Injection
- **Détection** : ajouter `'`, `"`, `1 OR 1=1` dans les champs de saisie et paramètres URL
- **Outils** : `sqlmap -u "<url>" --dbs`, `sqlmap --forms`
- **Bypass auth** : `' OR '1'='1' --`, `admin'--`
- **Quand l'utiliser** : formulaires de login, paramètres GET/POST, headers
- **Challenges résolus** : _(à compléter)_

### XSS (Cross-Site Scripting)
- **Détection** : injecter `<script>alert(1)</script>` dans les champs
- **Types** : Reflected, Stored, DOM-based
- **Payloads utiles** : `<img src=x onerror=alert(1)>`, `<svg onload=alert(1)>`
- **Quand l'utiliser** : champs affichés dans la page, commentaires, profils
- **Challenges résolus** : _(à compléter)_

### Directory Traversal / LFI
- **Payloads** : `../../../etc/passwd`, `....//....//etc/passwd`
- **Wrappers PHP** : `php://filter/convert.base64-encode/resource=index.php`
- **Outils** : `gobuster dir -u <url> -w <wordlist>`
- **Challenges résolus** : _(à compléter)_

### Command Injection
- **Détection** : `;id`, `|id`, `$(id)`, `` `id` ``
- **Bypass** : `${IFS}` pour les espaces, `\n` pour newlines
- **Challenges résolus** : _(à compléter)_

---

## Réseau

### Scan & Énumération
- **Scan rapide** : `nmap -sC -sV -T4 <target>`
- **Scan complet** : `nmap -p- -sV <target>`
- **Scan UDP** : `nmap -sU --top-ports 100 <target>`
- **Web discovery** : `gobuster dir -u <url> -w /usr/share/wordlists/dirb/common.txt`

### SMB
- **Énumération** : `enum4linux -a <target>`, `smbclient -L //<target>/`
- **Accès** : `smbclient //<target>/<share>`, `smbmap -H <target>`
- **Quand l'utiliser** : port 139/445 ouvert

### FTP
- **Anonymous** : `ftp <target>` → user: anonymous, pass: (vide)
- **Quand l'utiliser** : port 21 ouvert

---

## Privilege Escalation — Linux

### Énumération
- **Auto** : `linpeas.sh`, `linenum.sh`
- **Manuel** : `sudo -l`, `find / -perm -4000 2>/dev/null` (SUID)
- **Cron** : `cat /etc/crontab`, `ls -la /etc/cron.*`
- **Capabilities** : `getcap -r / 2>/dev/null`

### Techniques courantes
- **Sudo mal configuré** : GTFOBins pour chaque binaire avec `sudo -l`
- **SUID** : GTFOBins, race conditions
- **Kernel exploit** : `uname -r` puis `searchsploit linux kernel <version>`
- **Wildcard injection** : dans tar, chown, etc. via cron
- **PATH hijacking** : modifier PATH pour intercepter un binaire appelé par root

---

## Privilege Escalation — Windows

### Énumération
- **Auto** : `winpeas.exe`, `PowerUp.ps1`
- **Manuel** : `whoami /priv`, `net user`, `systeminfo`

### Techniques courantes
- **SeImpersonatePrivilege** : Juicy/Rogue Potato
- **Services mal configurés** : `sc qc <service>`, binpath modifiable
- **Unquoted service paths**
- **AlwaysInstallElevated**

---

## Crypto

### Bases
- **Identification** : CyberChef, `file`, `xxd`, entropie
- **Base64** : `echo "<str>" | base64 -d`
- **Hashes** : `hashid <hash>`, `hashcat -m <mode> <hash> <wordlist>`
- **John** : `john --wordlist=rockyou.txt <hash-file>`

### RSA
- **Petits facteurs** : factordb.com
- **Wiener attack** : si e est très grand
- **Common modulus** : si même n avec différents e

---

## Forensics / Stéganographie

### Analyse de fichiers
- **Type** : `file <fichier>`, `binwalk <fichier>`
- **Strings** : `strings <fichier>`, `strings -e l <fichier>` (UTF-16)
- **Metadata** : `exiftool <fichier>`

### Images
- **Stégo** : `steghide extract -sf <image>`, `zsteg <png>`
- **LSB** : scripts Python avec PIL

---

_Dernière mise à jour : à initialiser après le premier challenge_
