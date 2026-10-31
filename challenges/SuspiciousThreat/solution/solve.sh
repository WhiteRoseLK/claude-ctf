#!/usr/bin/env bash
# Suspicious Threat — HTB #746 (Forensics, Easy)
#
# Mécanisme :
#   /etc/ld.so.preload charge /lib/x86_64-linux-gnu/libc.hook.so.6 (compilée depuis hider.c),
#   un rootkit userland qui hooke readdir/readdir64/fopen pour masquer, DANS LES LISTINGS,
#   toute entrée dont le nom contient "pr3l04d_" ainsi que le fichier "ld.so.preload".
#   Seuls les listings (readdir*) sont filtrés : l'accès par chemin complet via open()/stat()
#   n'est PAS intercepté. cat utilise open(), pas fopen() => la lecture directe fonctionne.
#
# Le flag vit dans le répertoire caché /var/pr3l04d_/flag.txt.
#
# Paramètres d'instance (instance HTB éphémère ; renseigner avant usage) :
#   HOST, PORT : cible SSH ; PASS : mot de passe (ici le "hackthebox" standard des instances HTB).
set -euo pipefail

HOST="${HOST:?export HOST=<ip instance>}"
PORT="${PORT:-22}"
PASS="${PASS:-hackthebox}"
FLAG_PATH="/var/pr3l04d_/flag.txt"

ssh_cmd() {
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -p "$PORT" "root@${HOST}" "$1"
}

# 1) Révéler le répertoire caché malgré le hook readdir (syscall getdents64 brut, non hooké).
echo "[*] Contenu réel de /var (getdents64, contourne readdir) :"
ssh_cmd "python3 - <<'PY'
import ctypes, os
libc = ctypes.CDLL(None, use_errno=True)
fd = os.open('/var', os.O_RDONLY | os.O_DIRECTORY)
buf = ctypes.create_string_buffer(32768)
import struct
n = libc.syscall(217, fd, buf, len(buf))  # SYS_getdents64
off = 0
while off < n:
    ino, nxt, reclen, dtype = struct.unpack('qqHB', buf.raw[off:off+19])
    name = buf.raw[off+19:off+reclen].split(b'\x00',1)[0].decode()
    if name not in ('.','..'):
        print(('d' if dtype==4 else '-'), name)
    off += reclen
os.close(fd)
PY"

# 2) Lire le flag par chemin direct (open(), non hooké).
echo "[*] Flag :"
ssh_cmd "cat ${FLAG_PATH}"
