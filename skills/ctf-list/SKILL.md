---
name: ctf-list
description: "List available CTF challenges with optional filters. Usage: /ctf-list [category] [--unsolved] [--sort points|solves]"
license: MIT
compatibility: Requires filesystem-based agent with bash, Python 3, and internet access.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch
metadata:
  user-invocable: "true"
---

# List CTF Challenges

You are listing challenges from the connected CTF platform.

## Steps

1. First check connection status:
```bash
python3 ~/.claude/ctf/ctf_cli.py status
```
If not connected, tell the user to run `/ctf-connect` first.

2. Parse optional filters from `$ARGUMENTS`:
   - Category name (e.g., `crypto`, `web`, `pwn`, `reverse`, `forensics`, `misc`, `stego`)
   - `--unsolved` or `--solved` to filter by solve status
   - `--sort points|solves|difficulty` to sort results

3. Build and run the list command:
```bash
python3 ~/.claude/ctf/ctf_cli.py list [--category <cat>] [--solved true|false] [--sort <field>]
```

4. Display results as a clean formatted table with columns:
   - ID | Name | Category | Points | Difficulty | Solved | Solves

5. If the user specified a category, also mention how many total challenges vs how many unsolved remain.

## Common categories
- **Web**: web, web-server, web-client
- **Crypto**: crypto, cryptanalysis, cryptography
- **Pwn/Binary**: pwn, binary, exploitation
- **Reverse**: reverse, reverse-engineering, reversing
- **Forensics**: forensics, forensic
- **Misc**: misc, miscellaneous, programming
- **Stego**: stego, steganography
- **OSINT**: osint, recon
- **Network**: network, networking
