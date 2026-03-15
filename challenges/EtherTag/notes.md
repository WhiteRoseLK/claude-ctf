# EtherTag — Notes

## Informations

- **Plateforme** : HackTheBox
- **Nom** : Ether Tag
- **Cible** : 154.57.164.80:30375
- **Date de début** : 2026-03-15
- **Catégorie** : ICS (Industrial Control Systems)
- **Difficulté** : inconnue

## Hypothèse principale

**EtherNet/IP** — protocole industriel Allen-Bradley/Rockwell Automation.
- Le terme "Tag" est le concept central d'EtherNet/IP : variables nommées exposées par un PLC
- Port standard EtherNet/IP : 44818 (TCP), 2222 (UDP) → ici remappé sur 30375
- Protocole : CIP (Common Industrial Protocol) encapsulé sur TCP

## Protocoles ICS à connaître

| Protocole     | Port std | Outils          |
|---------------|----------|-----------------|
| EtherNet/IP   | 44818    | pycomm3, cpppo  |
| Modbus/TCP    | 502      | mbtget, pymodbus|
| S7comm        | 102      | python-snap7    |
| DNP3          | 20000    | OpenDNP3        |
| BACnet        | 47808    | BACpypes        |

## Outils ICS

- `nmap --script enip-info` → fingerprint EtherNet/IP
- `pycomm3` (Python) → lire/écrire des tags EtherNet/IP
- `cpppo` → EtherNet/IP client Python
- `mbtget` / `pymodbus` → Modbus
- Wireshark avec dissecteurs ICS

## Plan d'attaque

1. **Recon** : nmap avec scripts ICS, identifier le protocole exact
2. **Enumération** : lister les tags exposés (EtherNet/IP tag listing)
3. **Exploit** : lire les tags (le flag est probablement stocké dans un tag PLC)

## Notes ICS spécifiques

- Les PLCs EtherNet/IP exposent souvent une liste de tags lisibles sans auth
- Commande clé : lire tous les tags (`GetInstanceAttributeList` / tag browser)
- pycomm3 : `from pycomm3 import CIPDriver; plc = CIPDriver('ip'); plc.get_tag_list()`

## Flags

- Flag : _(probablement dans un tag PLC nommé "flag" ou similaire)_
