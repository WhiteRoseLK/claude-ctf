# Retrospective — Suspicious Threat (2026-10-31)

## Score global : A

Flag obtenu en 1 tentative (le vecteur #1 du recon). Délégation et Exegol respectés, recon-report rempli. Points relevés pendant le run : IP/mot de passe d'instance écrits dans les fichiers committés, section « Mémoire pertinente » de notes.md non remplie, et plusieurs frictions d'outillage. **Les deux premiers ont été corrigés avant merge** (commit de scrub : IP/port remplacés par `<INSTANCE_IP>`/`<PORT>`, section kb-search renseignée).

## Métriques
| Métrique | Valeur | Tendance vs. précédent |
|----------|--------|----------------------|
| Catégorie | Forensics (HTB #746, Easy), 1re de ce type | nouvelle catégorie |
| Temps total | ~12 min (recon 20:54 → flag 21:06) | ↓ |
| Temps par phase | recon ~4 min de commandes (20:54 → 20:58), exploit ~1 min (21:06), writeup à venir | ↓ |
| Tentatives exploit | 1 (succès direct), 0 impasse | ↓ (vs 4 pour PartialEncryption) |
| Recon accuracy | Bon vecteur en #1 (lecture par chemin direct) | ↑ |
| Flag | *(dans le repo CTF privé)* | |

Note : le timing de la recon est approximatif. Seules 3 lignes du log ont une heure précise (20:54:21, 20:54:58, 21:06). Le trou entre 20:55 et 21:06 vient probablement de la latence orchestrateur et du re-spawn éventuel. Il n'est pas tracé.

## Ce qui a bien marché
- **Recon complet et directement exploitable** : mécanisme du rootkit (lib, hooks, chaînes), chemin du flag, 4 vecteurs classés, embûches. La règle « recon-report toujours rempli » (NoiseCodex) a été tenue.
- **Séparation des rôles propre** : la recon a localisé `/var/pr3l04d_/flag.txt` (stat, getdents) mais n'a pas lu le flag. L'exploit n'a eu qu'à lancer `cat`.
- **Analyse statique sans exécuter la lib** : `nm -D`, `strings`, `objdump -s -j .rodata` ont suffi pour déduire la logique des hooks. Pas de désassemblage nécessaire.
- **Vérification croisée** : `cat`, `wc -c` et `open(...,'rb')` en Python donnent le même contenu, 32 octets, cohérent avec le `stat` de la recon.
- **solve.sh paramétrable** (HOST/PORT/PASS en variables), pas d'IP en dur. Nettoyage de `/dev/shm/gd.py` après usage.

## Ce qui peut être amélioré
- **Secrets/éphémères dans des fichiers committés** _(corrigé avant merge)_ : `recon-report.md`, `notes.md` et `exploit-log.md` contenaient IP:port, identifiants et heure d'expiration de l'instance (les consignes du repo interdisent les secrets). Scrubés en `<INSTANCE_IP>`/`<PORT>`. Leçon : produire directement les livrables avec `<HOST>:<PORT>`, ne jamais écrire l'IP réelle.
- **`notes.md` « Mémoire pertinente (kb-search) »** _(corrigé avant merge)_ : la section est désormais renseignée (kb-search a bien tourné à l'init — requête « Suspicious Threat forensics… » ; résultat : aucune entrée Forensics, leçons transverses notées). Leçon : la remplir dès l'init, même quand la KB ne remonte rien.
- **Récupération du challenge** : le téléchargement a renvoyé un « zip » qui était en fait un JSON d'erreur (« Challenge file not found »). Un challenge HTB `play_methods: ["container"]` n'a pas de fichier. Il faut le détecter avant de télécharger et spawner via l'API.
- **Piège `objdump`** : celui d'Exegol est aarch64 (« can't disassemble for architecture UNKNOWN »), alors que la lib est x86-64. C'est le même défaut que sur l'hôte macOS : il est connu pour les binaires x86 sous Apple Silicon et reste non documenté. Ici sans conséquence, `strings` et `nm` ont suffi.
- **Piège zsh** : une variable contenant une commande n'est pas découpée. Contournement : `work/r.sh`. À mettre dans le helper standard de `/ctf-start` pour les cibles SSH.
- **Fuite de token** : `ctf_cli.py status` affiche le token HTB. À ne jamais lancer devant un log committé.
- **Recon qui anticipe l'exploit** : la recon a listé la commande `cat` et testé `ls /var/pr3l04d_` (lecture de métadonnées seulement). C'est la limite haute du rôle recon, acceptable car le contenu n'a pas été lu. Voir §6.

## Patterns récurrents (vs rétros précédentes)
- Recon-report rempli : tenu (régression NoiseCodex corrigée).
- Piège d'outil absent/inadapté dans Exegol (NoiseCodex fpylll, ici objdump aarch64) : récurrent. Les solutions de repli statiques fonctionnent, mais il faut les connaître.
- Pas d'erreur de fond sur la technique : vecteur trouvé immédiatement. Équipe forte sur l'analyse statique d'artefacts (Reverse x3, Forensics x1). Faible sur l'outillage plateforme (archives, spawn, tokens).
- Forensics : 1 seul échantillon, un challenge Easy très guidé par l'énoncé (« erreurs de linking », « dossiers manquants » = LD_PRELOAD). Ne pas généraliser.

## §6 Post-mortem process / cadre
- **Rôle orchestrateur** : respecté. Le chemin a été orchestrateur → recon → exploit, sans résolution inline visible dans les logs. L'orchestrateur a gardé l'init (spawn de l'instance via l'API) et la soumission.
- **Exegol / hook** : toutes les commandes loggées passent par `docker exec exegol-ctf-suspiciousthreat … ./r.sh` (ssh via sshpass, scp, nm/strings/objdump dans le conteneur). Aucune commande d'attaque sur l'hôte rapportée. Le hook n'a pas bloqué : cohérent. Cela dit, le log ne prouve pas l'absence de commande hôte. Il atteste seulement ce qui y est écrit.
- **Sorties de périmètre** :
  - Recon : a exécuté un script (getdents64) sur la cible, copié dans `/dev/shm` puis supprimé. C'est de l'énumération, donc dans le rôle. Elle n'a pas lu le flag, ce qui est exact.
  - Pas de modification de la cible (le `mv /etc/ld.so.preload` proposé en vecteur #3 n'a pas été fait). Bon réflexe, à garder : ne pas désarmer un rootkit sur la cible sans besoin.
- **Pièges** : (1) faux zip d'un challenge container-only ; (2) objdump aarch64 ; (3) zsh et variables-commandes ; (4) fuite du token par `ctf_cli.py status`. Aucun n'a coûté plus de quelques minutes, mais tous étaient évitables avec un « pré-vol » plateforme.
- **Coût** : faible. Pas d'étape refaite, pas d'outil réinstallé. Seul le trou non tracé de ~10 min entre recon et exploit est opaque.
- **Propositions concrètes** : voir ci-dessous.

## Actions pour le prochain challenge
- [ ] Container-only HTB : ne pas télécharger, spawner via `POST /api/v4/container/start` (headers Origin/Referer) et lire host/port/mot de passe.
- [ ] Mettre `<HOST>:<PORT>` (pas l'IP/mdp réels) dans recon-report/notes/exploit-log committés.
- [ ] Remplir « Mémoire pertinente » de notes.md avec la sortie de kb-search, même vide.
- [ ] Binaire x86 sous Exegol aarch64 : `strings`/`nm -D`/`readelf`, ou capstone Python, pas `objdump -d`.
- [ ] Horodater chaque commande du recon (heure par ligne).
- [ ] Forensics live (FS qui ment) : comparer `ls` à un listing `getdents64` brut, vérifier `/etc/ld.so.preload` par chemin direct, avant tout reverse de la lib.

## Modifications suggérées aux agents
- **recon** : (a) ajouter au triage Forensics/live-host « tester `cat /etc/ld.so.preload`, `env | grep LD_`, comparer `ls` vs getdents brut » ; (b) interdire d'écrire creds/IP d'instance dans le rapport (placeholders) ; (c) horodater chaque ligne de « Commandes exécutées ».
- **exploit** : si le recon donne un vecteur #1 à 1 commande, le tenter en premier (c'est ce qui s'est passé) et éviter toute modification de la cible (`mv`/`rm` sur `ld.so.preload`) sauf nécessité.
- **/ctf-start** : pour `play_methods` = container uniquement, sauter le téléchargement et créer un helper `r.sh` (ssh/sshpass) dans `work/`, avec protection zsh (`bash -c`). Ne jamais afficher le token (`status` du CLI à filtrer).
- **orchestrateur** : remplir la section kb-search de `notes.md` à l'init.

## KB mise à jour
- `techniques.md` § Forensics : rootkit userland LD_PRELOAD (readdir hook) — détection et contournement.
- `lessons-learned.md` : leçon SuspiciousThreat, règles 10 à 13.
