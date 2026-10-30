#!/usr/bin/env python3
"""Hook PreToolUse (Bash) : impose l'exécution des commandes dans Exegol.

Politique : **toute commande doit tourner dans le conteneur Exegol du challenge**,
sauf acceptation expresse de l'utilisateur. Ce hook ne BLOQUE jamais en dur — il
demande une confirmation (`ask`) quand une commande d'attaque/analyse semble lancée
sur l'hôte plutôt que dans Exegol. L'orchestration (git, docker, exegol, outils du
repo) passe sans friction.

Entrée : JSON sur stdin (contrat Claude Code PreToolUse) avec tool_input.command.
Sortie : JSON hookSpecificOutput avec permissionDecision allow|ask.

Heuristique volontairement simple et ajustable (voir ALLOW_PREFIXES / ALLOW_TOKENS).
"""

from __future__ import annotations

import json
import re
import shlex
import sys

# Commande déjà dans Exegol, ou pilotage d'Exegol/Docker lui-même.
EXEGOL_RE = re.compile(r"\b(docker\s+exec\s+exegol-|exegol\s+(exec|start|stop|info|restart))")

# Préfixes de commande complets considérés comme orchestration sur l'hôte (autorisés).
ALLOW_PREFIXES = (
    "python3 tools/",
    "python3 ./tools/",
    "python3 ~/.claude/ctf/",
    "python ~/.claude/ctf/",
    "./install.sh",
    "bash install.sh",
    "./cleanup.sh",
    "bash cleanup.sh",
)

# Premiers tokens d'orchestration autorisés sur l'hôte (git, navigation, inspection repo…).
ALLOW_TOKENS = {
    "git", "gh", "docker", "exegol", "cd", "ls", "pwd", "cat", "head", "tail",
    "less", "echo", "mkdir", "cp", "mv", "rm", "chmod", "touch", "wc", "sort",
    "uniq", "test", "[", "diff", "open", "osascript", "which", "command",
    "basename", "dirname", "date", "env", "export", "true", "false", "sleep",
    "tee", "printf", "jq", "code", "mdfind", "brew", "pipx",
}


def first_token(cmd: str) -> str:
    try:
        parts = shlex.split(cmd)
    except ValueError:
        parts = cmd.strip().split()
    i = 0
    # saute les affectations d'env en tête (VAR=val cmd ...)
    while i < len(parts) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", parts[i]):
        i += 1
    return parts[i] if i < len(parts) else ""


def is_allowed(cmd: str) -> bool:
    c = cmd.strip()
    if EXEGOL_RE.search(c):
        return True
    if any(c.startswith(p) for p in ALLOW_PREFIXES):
        return True
    return first_token(c) in ALLOW_TOKENS


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0  # pas de JSON exploitable → ne pas gêner
    cmd = (data.get("tool_input") or {}).get("command", "")
    if not cmd:
        return 0

    if is_allowed(cmd):
        decision, reason = "allow", "Orchestration hôte ou commande Exegol — autorisé."
    else:
        decision = "ask"
        reason = (
            "⚠ Cette commande s'exécuterait sur l'HÔTE, pas dans Exegol.\n"
            "Politique du workspace : les commandes d'attaque/analyse tournent dans le "
            "conteneur du challenge. Relance-la via :\n"
            "    docker exec exegol-ctf-<nom> bash -c \"cd /workspace && <commande>\"\n"
            "…ou approuve ci-dessous pour l'exécuter sur l'hôte (acceptation expresse)."
        )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
