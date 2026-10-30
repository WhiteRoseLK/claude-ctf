---
name: ctf-submit
description: "Submit a flag for a CTF challenge. Usage: /ctf-submit <challenge_id> <flag>"
license: MIT
compatibility: Requires filesystem-based agent with bash, Python 3, and internet access.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch
metadata:
  user-invocable: "true"
---

# Submit CTF Flag

You are submitting a flag to the connected CTF platform.

## Steps

1. Check connection status:
```bash
python3 ~/.claude/ctf/ctf_cli.py status
```

2. Parse `$ARGUMENTS` to extract:
   - **challenge_id**: The numeric challenge ID
   - **flag**: The flag string (everything after the ID)

3. Submit the flag:
```bash
python3 ~/.claude/ctf/ctf_cli.py submit --id <challenge_id> --flag "<flag>"
```

4. Report the result:
   - **Correct**: Congratulate and show points earned
   - **Incorrect**: Show the error, suggest the user double-check
   - **Already solved**: Note it was already submitted

5. If the flag format looks wrong (e.g., missing wrapper like `flag{}`), warn before submitting but still submit if the user confirms.
