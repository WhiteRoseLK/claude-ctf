# Suspicious Threat

- **Plateforme** : HackTheBox (Challenges)
- **ID** : 746
- **Catégorie** : Forensics
- **Difficulté** : Easy
- **Cible** : instance container live (`play_methods: ["container"]`, pas de download)
  - SSH `<INSTANCE_IP>:<PORT>`, creds `root:hackthebox` (instance éphémère, re-spawnable via l'API)
  - Accessible via Internet (pas de VPN HTB)
- **Énoncé** : SSH server avec erreurs de linking de libs + dossiers « manquants » malgré leur
  existence confirmée. Investiguer les anomalies de chargement de libs + FS. **Rootkit userland** (LD_PRELOAD probable).
- **Date de début** : 2026-10-31
- **Mode** : training
- **Spawn API** : `POST /api/v4/container/start` (headers Origin/Referer app.hackthebox.com), stop idem via `container/stop`

## Mémoire pertinente (kb-search)

Requête : `Suspicious Threat forensics pcap memory dump event log`. Aucune entrée Forensics
dédiée (1ʳᵉ du genre dans la KB). Leçons transverses applicables :
- Archives HTB souvent protégées par le mot de passe générique `hackthebox`.
- Règle accumulée : toujours remplir `recon-report.md`, même si le triage est rapide.

## Plan

1. Recon (sous-agent `recon`) → `solve-challenge`, triage, catégorie confirmée → `recon-report.md`
2. Exploit (sous-agent `exploit`) → skill `ctf-forensics` dans Exegol → `exploit-log.md` + `flag.txt` + `solution/`
