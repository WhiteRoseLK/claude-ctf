# CTF Multi-Agent Workspace

## Contexte

Ce workspace est dédié à la résolution de challenges CTF sur HackTheBox et Root-Me.
Nous travaillons en équipe multi-agent avec des rôles spécialisés.
Chaque action doit être documentée pour produire un writeup et alimenter l'amélioration continue.

## Agents disponibles

- **recon** : Reconnaissance et énumération (scans, fingerprinting, OSINT)
- **exploit** : Exploitation de vulnérabilités, privesc, extraction de flags
- **writeup** : Rédaction du writeup final pédagogique et reproductible
- **review** : Retrospective, analyse de performance, mise à jour knowledge base

## Couche skills (moteur technique)

Les techniques CTF viennent des skills vendorés dans `skills/` (installés via `install.sh`) :
- `solve-challenge` : dispatcher — triage puis routage vers la bonne catégorie
- `ctf-web`, `ctf-pwn`, `ctf-crypto`, `ctf-reverse`, `ctf-forensics`, `ctf-malware`,
  `ctf-osint`, `ctf-misc`, `ctf-ai-ml` : références profondes par catégorie
- `ctf-connect` / `ctf-list` / `ctf-solve` / `ctf-submit` / `ctf-writeup` : intégration plateforme

**Les agents orchestrent, les skills fournissent la technique.** On ne duplique jamais
une technique de skill dans un agent ou dans la knowledge base.

## Workflow standard

1. Initialiser le challenge avec `/ctf-start <plateforme> <challenge>`
2. **Phase Recon** → agent recon charge `solve-challenge`, triage, produit `recon-report.md` avec la **catégorie détectée**
3. **Phase Exploit** → agent exploit charge le skill `ctf-<catégorie>`, attaque, produit `exploit-log.md`
4. **Soumission** → `/ctf-submit <challenge> <flag>` archive dans `flag.txt` et soumet à la plateforme
5. **Writeup** → agent writeup génère `challenges/<challenge>/writeup.md`
6. **Retrospective** → `/ctf-retro <challenge>` lance l'agent review (met à jour la knowledge base)

## Conventions obligatoires

### Documentation
- **Chaque commande exécutée** doit être loggée avec son output dans `exploit-log.md`
- **Chaque découverte** va dans `recon-report.md` avec la commande qui l'a produite
- Les timestamps sont obligatoires pour mesurer le temps par phase

### Knowledge Base
- **TOUJOURS** consulter `knowledge-base/techniques.md` avant de tenter une technique
- **TOUJOURS** consulter `knowledge-base/lessons-learned.md` pour éviter les erreurs connues
- Après chaque challenge, mettre à jour ces fichiers

### Git
- Commit à chaque fin de phase (recon, exploit, writeup, retro)
- Messages de commit : `[phase] challenge-name: description`
- Exemples : `[recon] Keeper: scan initial nmap`, `[exploit] Keeper: privesc via CVE-2023-xxxxx`

## Structure des challenges

```
challenges/<nom-challenge>/
├── notes.md            # Notes libres de l'orchestrateur
├── recon-report.md     # Rapport de reconnaissance structuré
├── exploit-log.md      # Journal chronologique des tentatives
├── flag.txt            # Le flag extrait
├── writeup.md          # Writeup final
├── cleanup.sh          # Script de nettoyage (supprime work/)
├── .gitignore          # Ignore work/
└── work/               # Fichiers de travail temporaires (zips, binaires, extractions)
                        # → NON commités, supprimés par cleanup.sh après le challenge
```

## Outils disponibles

Les outils CLI suivants sont attendus sur le système :
nmap, gobuster, dirb, nikto, sqlmap, hydra, john, hashcat,
burpsuite, curl, wget, netcat, python3, pwntools, linpeas,
winpeas, searchsploit, msfconsole

Si un outil manque, le signaler plutôt que d'improviser.
