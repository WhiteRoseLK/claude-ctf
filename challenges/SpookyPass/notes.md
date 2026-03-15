# SpookyPass — Notes Orchestrateur

## Informations de base

| Champ       | Valeur                        |
|-------------|-------------------------------|
| Plateforme  | HackTheBox (HTB)              |
| Challenge   | SpookyPass                    |
| Cible       | _(non fournie — à compléter)_ |
| Date début  | 2026-03-15                    |
| Catégorie   | _(inconnue — à déterminer)_   |
| Difficulté  | _(inconnue)_                  |

## Hypothèses initiales

- Nom "SpookyPass" suggère un challenge lié à l'authentification / bypass de mot de passe
- Catégories probables : Web (auth bypass), Reverse Engineering, Crypto
- Piste : vérifier s'il s'agit d'un challenge Web ou d'un binaire à reverser

## Knowledge Base — Points pertinents

### Techniques applicables (à confirmer selon catégorie)

**Si Web :**
- SQL Injection pour bypass auth : `' OR '1'='1' --`, `admin'--`
- Tester les formulaires de login avec sqlmap

**Si Reverse/Crypto :**
- Analyse de fichier : `file`, `strings`, `binwalk`
- Identification de hash : `hashid`, `hashcat`

**Lessons Learned :**
- Aucune leçon disponible (premier challenge) — documenter soigneusement pour alimenter la base

## Plan d'attaque

1. Identifier la catégorie du challenge (web, RE, crypto...)
2. Lancer la phase recon adaptée
3. Exploiter la vulnérabilité identifiée

## Journal

- **2026-03-15** : Initialisation du challenge
