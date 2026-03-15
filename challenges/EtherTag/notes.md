# EtherTag — Notes

## Informations

- **Plateforme** : HackTheBox
- **Nom** : Ether Tag
- **Cible** : 154.57.164.80:30375
- **Date de début** : 2026-03-15
- **Catégorie** : Web (challenge réseau — port non-standard, probablement web)
- **Difficulté** : inconnue

## Observations initiales

- Port 30375 sur une IP publique → service exposé sur port non-standard
- Nom "Ether Tag" → possiblement lié à Ethereum/blockchain, ou métaphore réseau (Ethernet)
- À déterminer lors du recon initial

## Points de la knowledge base pertinents

### Techniques à considérer (Web)
- SQL Injection : tester formulaires et paramètres
- XSS : si l'application affiche des données utilisateur
- Command Injection : si l'app exécute des commandes système
- LFI/Directory Traversal : si l'app lit des fichiers

### Erreurs à éviter
- Knowledge base vide pour l'instant (premier challenge)

## Plan d'attaque

1. Recon : identifier le service sur le port 30375 (HTTP ? autre protocole ?)
2. Enum web : gobuster, nikto, analyse de l'application
3. Exploit : selon découvertes du recon

## Flags

- User flag : _(à compléter)_
- Root flag : _(à compléter)_
