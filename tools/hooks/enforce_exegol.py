#!/usr/bin/env python3
"""Hook PreToolUse (Bash) : empêche de lancer la RÉSOLUTION d'un challenge sur l'hôte.

Politique : **autoriser par défaut** ; ne demander une acceptation expresse QUE pour une
commande de résolution/attaque (outil CTF, exécution d'un binaire/artefact, script de solve)
lancée directement sur l'hôte au lieu du conteneur Exegol. Tout le reste — orchestration,
inspection (grep/find/sed/awk/git…), édition — passe sans friction.

Entrée : JSON sur stdin (contrat Claude Code PreToolUse) avec tool_input.command.
Sortie : hookSpecificOutput avec permissionDecision :
  - "ask"  → commande de résolution sur l'hôte (rappel : la lancer dans Exegol)
  - sinon  → on NE décide PAS (exit 0 sans JSON) : les permissions normales s'appliquent,
             donc aucun prompt ajouté par ce hook pour le reste.

Heuristique (liste noire) volontairement simple et ajustable (DENY_TOOLS / patterns).
"""

from __future__ import annotations

import json
import re
import shlex
import sys

# Déjà dans Exegol, ou pilotage d'Exegol/Docker : toujours OK.
EXEGOL_RE = re.compile(r"\b(docker\s+exec\s+exegol-|exegol\s+(exec|start|stop|info|restart|remove))")

# Outils de résolution/attaque/analyse : interdits sur l'HÔTE (doivent tourner dans Exegol).
DENY_TOOLS = {
    # scan / web / brute
    "nmap", "masscan", "gobuster", "dirb", "feroxbuster", "ffuf", "wfuzz", "nikto",
    "sqlmap", "hydra", "medusa", "patator", "whatweb", "wpscan",
    # crack / hash
    "john", "hashcat", "hashid", "hashcat-utils",
    # reverse / pwn
    "radare2", "r2", "rizin", "rabin2", "iaito", "gdb", "pwndbg", "gef", "objdump",
    "readelf", "nm", "strace", "ltrace", "ghidra", "ghidraRun", "wine", "wine64",
    "winedbg", "ropper", "ROPgadget", "one_gadget", "checksec", "patchelf",
    "apktool", "jadx", "dex2jar", "frida",
    # forensics / stego
    "binwalk", "foremost", "bulk_extractor", "volatility", "vol", "vol.py",
    "steghide", "zsteg", "stegsolve", "exiftool", "tshark", "tcpdump",
    # exploit frameworks / net attack
    "msfconsole", "msfvenom", "searchsploit", "socat", "aircrack-ng",
    "nc", "ncat", "netcat",
}

INTERP = ("python", "python3", "python2", "sage", "ruby", "perl")


def tokens(cmd: str) -> list[str]:
    try:
        return shlex.split(cmd)
    except ValueError:
        return cmd.split()


def first_cmd_token(toks: list[str]) -> str:
    i = 0
    while i < len(toks) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[i]):
        i += 1  # saute les VAR=val en tête
    if i < len(toks) and toks[i] in ("sudo", "command", "env"):
        i += 1
    return toks[i] if i < len(toks) else ""


def is_solving(cmd: str) -> bool:
    toks = tokens(cmd)
    if not toks:
        return False
    base = [t.rsplit("/", 1)[-1] for t in toks]  # nom de binaire sans chemin

    # 1) un outil d'attaque/analyse apparaît dans la commande
    if any(b in DENY_TOOLS for b in base):
        return True

    # 2) exécution d'un binaire/artefact local (./x, work/x, extracted/x)
    ft = first_cmd_token(toks)
    if ft.startswith("./") or re.search(r"(^|/)(work|extracted|solution)/", ft):
        return True

    # 3) script de solve lancé sur l'hôte : un interpréteur exécute un script HORS outils du repo
    if ft.rsplit("/", 1)[-1] in INTERP:
        joined = " ".join(toks)
        runs_repo_tool = ("tools/" in joined or "/.claude/ctf/" in joined
                          or "install.sh" in joined or "cleanup.sh" in joined)
        has_script = any(a.endswith((".py", ".sage", ".rb", ".pl")) for a in toks)
        if has_script and not runs_repo_tool:
            return True

    return False


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    cmd = (data.get("tool_input") or {}).get("command", "")
    if not cmd:
        return 0

    if EXEGOL_RE.search(cmd):
        return 0  # dans/vers Exegol : laisser passer (permissions normales)

    if is_solving(cmd):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": (
                    "⚠ Commande de résolution/attaque sur l'HÔTE. Elle doit tourner dans le "
                    "conteneur Exegol du challenge :\n"
                    "    docker exec exegol-ctf-<nom> bash -c \"cd /workspace && <commande>\"\n"
                    "…ou approuve pour l'exécuter sur l'hôte (acceptation expresse)."
                ),
            }
        }))
        return 0

    # Tout le reste (orchestration, inspection grep/find/sed/awk/git, édition…) :
    # pas de décision du hook → les permissions normales s'appliquent, aucun prompt ajouté.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
