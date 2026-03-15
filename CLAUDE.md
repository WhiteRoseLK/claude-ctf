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

## Workflow standard

1. Initialiser le challenge avec `/ctf-start <plateforme> <challenge>`
2. **Phase Recon** → agent recon produit `challenges/<challenge>/recon-report.md`
3. **Phase Exploit** → agent exploit lit le rapport recon, tente les attaques, produit `challenges/<challenge>/exploit-log.md`
4. **Soumission** → le flag est sauvé dans `challenges/<challenge>/flag.txt`
5. **Writeup** → agent writeup génère `challenges/<challenge>/writeup.md`
6. **Retrospective** → `/ctf-retro` lance l'agent review

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
