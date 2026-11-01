---
name: ctf-solve
description: "Download and solve CTF challenges in dedicated Exegol containers via sub-agents. Usage: /ctf-solve <challenge_ids|category> [--limit N] [--image <exegol_image>] [--keep]"
license: MIT
compatibility: Requires filesystem-based agent with bash, Python 3, Docker, Exegol, and internet access.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch
metadata:
  user-invocable: "true"
---

# Solve CTF Challenges (Exegol via MCP)

You are downloading, solving, and submitting flags for CTF challenges. Each challenge is solved inside a **dedicated Exegol container** managed via the **exegol-mcp** tools.

## Step 1: Parse Arguments

From `$ARGUMENTS`, extract:
- **Target**: Either specific challenge IDs (comma-separated: `42,43,44`) or a category name (e.g., `crypto`)
- **--limit N**: Max number of challenges to attempt when using category mode (default: 5)
- **--unsolved**: Only pick unsolved challenges (default when using category)
- **--image NAME**: Exegol image to use (default: `free`)
- **--keep**: Keep Exegol containers alive after solving (default: remove them)
- **--no-vpn**: Disable the automatic HTB VPN (default: VPN is always enabled)

## Step 2: Resolve Challenge List

If IDs are given, use them directly. If a category is given:
```bash
python3 ~/.claude/ctf/ctf_cli.py list --category <category> --solved false --sort points
```
Take the first `--limit` challenges sorted by ascending points (easiest first).

## Step 3: Download Challenges

For each challenge:
```bash
python3 ~/.claude/ctf/ctf_cli.py download --id <challenge_id>
```
This saves files to `~/.claude/ctf/workspace/challenge_<id>/`.

**Known issue (HTB)**: `ctf_cli.py download` frequently returns `{"files": [], "error": "HTTP Error 400: Bad Request"}` even when `info.download` is `true`. The HTB download endpoint requires browser-like headers the CLI doesn't send. Work around it directly:
```bash
TOKEN=$(python3 -c "import json;print(json.load(open('$HOME/.claude/ctf/config.json'))['active']['token'])")
curl -sL -o ~/.claude/ctf/workspace/challenge_<id>/challenge_<id>.zip \
  "https://labs.hackthebox.com/api/v4/challenge/download/<id>" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" \
  -H "Referer: https://app.hackthebox.com/" \
  -H "Origin: https://app.hackthebox.com" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
```
`-sL` is required — the real file is served via a signed, redirected S3 URL (`302 Location: ...`).

HTB challenge zips are password-protected with the password **`hackthebox`**. Some are AES-encrypted (need v5.1+ zip support), which plain `unzip` can't handle — use `7z` instead, it handles both:
```bash
cd ~/.claude/ctf/workspace/challenge_<id> && 7z x -phackthebox -oextracted_<id> challenge_<id>.zip
```

**If `info.download` is `false`** (no files at all, `play_methods: ["container"]` only): this is a container-only challenge — there's nothing to extract, you must interact with the live instance directly (see the HTB container start/stop section below, do this *before* spawning the solving agent so it has a host:port to attack immediately).

## Step 3.5: Starting a live HTB Docker instance (for `docker: true` challenges)

Many "Pwn"/"Web"/"Misc" HTB challenges need a live remote instance for the *real* flag — a locally-tested exploit only proves the logic, it won't print the actual flag unless run against the live host. `challenge.json`'s `docker_ip`/`docker_ports`/`play_info` are `null` until an instance is spawned.

**HTB's REST API has no documented start-instance route.** Do NOT use `challenge/start` on `labs.hackthebox.com` (404) — that's what outdated third-party client libraries assume. The real, working endpoint (confirmed by reading `user0x1337/htb-operator`'s open-source client) is:
```bash
TOKEN=$(python3 -c "import json;print(json.load(open('$HOME/.claude/ctf/config.json'))['active']['token'])")
curl -s -X POST "https://labs.hackthebox.com/api/v4/container/start" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -H "Referer: https://app.hackthebox.com/" -H "Origin: https://app.hackthebox.com" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36" \
  -d '{"challenge_id": <id>}'
# -> {"message":"Instance Created!","id":...}
```
The `Origin`/`Referer` headers matching `app.hackthebox.com` are **required** — without them you get `{"message":"CSRF token mismatch."}` even with a valid bearer token. Then poll for the assigned host:port (usually ready within one poll):
```bash
for i in $(seq 1 15); do
  resp=$(curl -s "https://labs.hackthebox.com/api/v4/challenge/info/<id>" -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/json" -H "Referer: https://app.hackthebox.com/" -H "Origin: https://app.hackthebox.com" \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36")
  ip=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('challenge',{}).get('docker_ip'))")
  [ -n "$ip" ] && [ "$ip" != "None" ] && echo "READY: $ip" && break
  sleep 4
done
```
When done (flag submitted, or moving on): stop it the same way with `container/stop` (same headers, same `{"challenge_id": <id>}` body) to free the slot.

**Decoy flags in static downloads.** When a challenge's `play_methods` includes **both** `"download"` and `"container"`, the statically downloaded file can contain a deliberately fake/joke flag (e.g. one HTB reversing challenge's binary genuinely, deterministically prints `HTB{F4k3_f74g_4_t3s7ing}` on successful local auth — confirmed by direct execution, not a bug) as a troll for anyone who solves the logic purely offline without spawning the real instance. The actual per-user flag only appears when interacting with a live spawned container. If a fully-verified, ground-truth-executed exploit/solution produces a suspiciously joke-y or too-cute flag string and the platform rejects it, don't assume your reversing is wrong — check whether the challenge also supports `"container"` mode, spawn the live instance, and redo the *same* recovered logic (password/exploit/etc., which is usually identical across instances) against it instead of the static file.

## Step 4: Start Exegol Container

For each challenge, create a dedicated Exegol container via Bash (MCP doesn't support creation with workspace/image options):
```bash
exegol start "ctf-<challenge_id>" <image> \
  --workspace ~/.claude/ctf/workspace/challenge_<challenge_id> \
  --disable-X11 \
  --vpn ~/htb.ovpn \
  -s bash
```

- Container name: `ctf-<challenge_id>` (e.g., `ctf-42`)
- Image: use the `--image` argument or default to `free`
- Workspace: the challenge directory is mounted at `/workspace` inside the container
- Disable X11: not needed for automated solving
- **VPN**: always include `--vpn ~/htb.ovpn` by default so the container can reach HTB's private network (blockchain, machines, etc.). Omit only if `--no-vpn` was specified.

**Docker Desktop may need to be (re)started first.** If `exegol start` fails with "Unable to connect to docker", run `docker info` to check, and if it errors with a missing socket, the Docker Desktop app isn't running — `open -a Docker` and poll `until docker info >/dev/null 2>&1; do sleep 3; done` before retrying. If Docker Desktop shows an unresponsive/error state (a stray `--name=error-dialog` process), do a full clean restart rather than fighting it: `osascript -e 'quit app "Docker"'`, `pkill -f "Docker Desktop"`, `pkill -f "com.docker.backend"`, wait a few seconds, then `open -a Docker` again.

**Verify the container is running**:
```bash
docker ps --filter "name=ctf-<challenge_id>" --format "{{.Names}}\t{{.Status}}"
```
(The `exegol-mcp` MCP server referenced below may not be registered in every environment — check with a tool search first. If it isn't available, every `execute_command_in_container(...)` call in this skill and in solving-agent prompts should be replaced with plain `docker exec exegol-ctf-<challenge_id> <command>` via Bash — tell solving agents this explicitly in their prompt so they don't waste time looking for a nonexistent MCP tool.)

## Step 5: Solve Challenges

### Running commands inside Exegol

All solving commands MUST be executed inside the Exegol container using the **MCP tool**:
→ Use `mcp__exegol-mcp__execute_command_in_container` with:
  - `container_name`: `ctf-<challenge_id>`
  - `command`: the command to run

Examples:
- Run a simple command: `execute_command_in_container(container_name="ctf-42", command="id")`
- Run a script: `execute_command_in_container(container_name="ctf-42", command="cd /workspace && python3 solve.py")`
- Multi-step: `execute_command_in_container(container_name="ctf-42", command="file /workspace/* && strings /workspace/binary | head -50")`

To write files inside the container, either:
- Write them to the workspace directory on the host using the **Write** tool (it's mounted at `/workspace` inside the container)
- Use `execute_command_in_container` with echo/heredoc commands

### Getting help on tools
→ Use `mcp__exegol-mcp__get_tool_help` to check usage of any tool installed in the container.
→ Use `mcp__exegol-mcp__list_installed_tools` to discover available tools.

### Cross-architecture binaries (Apple Silicon host)
If the Exegol container is aarch64 (Apple Silicon Docker Desktop) but the target binary is x86/x86-64, it won't run natively. Install `qemu-user-static` and, for missing loaders, extract the matching architecture's `libc6` package (`dpkg --add-architecture amd64/i386` + `apt-get install`) to build a minimal sysroot, then run via `qemu-x86_64-static`/`qemu-i386-static -L <sysroot> ./binary`. **Only use this for validating exploit *logic* locally** — cross-arch qemu emulation has been observed to be unreliable for exact values (e.g. it can make register/gadget behavior look subtly different from the real target). Always re-verify any ROP gadget address with a static tool (`ropper --file <bin> --search '<pattern>'`, `ROPgadget`) against the real binary before trusting it for the final remote exploit — don't source gadget addresses from emulated runs alone.

### Interactive protocols: watch for extra prompts
When scripting a multi-step menu/prompt-driven service (common in Pwn/Misc), don't assume the obvious `sendlineafter(b'>', ...)` pattern captures every checkpoint. Some services show an extra sub-menu or confirmation prompt between the option you select and the actual vulnerable input point. Manually step through the protocol first with a throwaway interactive script (`io.sendline(...)`, `io.recvrepeat(timeout=2)`, print `repr(data)`) to see every raw prompt before writing the automated exploit — a missed prompt silently desyncs the byte stream and produces confusing failures that look like a wrong offset or wrong gadget.

### CRITICAL RULE: Always Use Sub-Agents

**The main agent MUST NEVER solve challenges directly.** Every challenge MUST be delegated to at least one sub-agent via the **Agent tool** (task tool with `agent_type: "general-purpose"`). The main agent's role is strictly orchestration: parsing arguments, downloading files, starting containers, spawning solving agents, collecting results, submitting flags, generating writeups, and cleaning up.

### How many sub-agents per challenge?

You decide. Use your judgment based on the challenge complexity and category:
- **Minimum 1** sub-agent per challenge (mandatory).
- You MAY spawn **multiple sub-agents for the same challenge** if it benefits the solving strategy (e.g., one agent for static analysis + one for dynamic exploitation, or multiple agents trying different approaches in parallel).
- When solving **multiple challenges**, you MAY launch all their sub-agents **simultaneously in a single message block** so they run in parallel — or solve them one after another. Choose the approach that makes the most sense.

### Main agent workflow

For each challenge:
1. Download files and start the Exegol container (main agent)
2. Read the challenge metadata and files to build the sub-agent prompt (main agent)
3. Spawn one or more solving sub-agents with full context using the Agent Prompt Template below (main agent)
4. Collect the result(s) from the sub-agent(s) (main agent)
5. Submit the flag if found (main agent)
6. Generate writeup via ctf-writeup-generator agent (main agent)
7. Cleanup container unless `--keep` (main agent)

IMPORTANT: Start all Exegol containers BEFORE spawning their solving agents.
IMPORTANT: When launching multiple sub-agents simultaneously, do it in a single message block.

## Step 6: Submit Flags

For each flag found:
```bash
python3 ~/.claude/ctf/ctf_cli.py submit --id <challenge_id> --flag "<flag>"
```
Report results: which challenges were solved, which failed.

## Step 6.5: Generate Obsidian Writeup

For each successfully solved challenge, use the **ctf-writeup-generator** agent to produce a writeup, then save it to the Obsidian vault.

### Invoke the agent
Use the Agent tool with `subagent_type: "ctf-writeup-generator"`. Pass all available context in the prompt:
- Challenge metadata (name, category, points, description, platform)
- List of downloaded files and their content
- All commands run inside Exegol (with their output)
- The exploit/solution scripts written
- The flag found

The agent will return the writeup as markdown content.

### Save to Obsidian
Use the **MCP obsidian `write_note`** tool to save the writeup directly into the CTF vault:
- **path**: `<PLATFORM>/<CATEGORY>/<CHALLENGE_NAME>/<CHALLENGE_NAME>.md`, or for a one-off CTF event
  `<EVENT>/<YEAR>/<CATEGORY>/<CHALLENGE_NAME>/<CHALLENGE_NAME>.md` (then update `<EVENT>/<YEAR>/README.md`, the edition summary)
- `<PLATFORM>`: `HackTheBox` or `RootMe`; `<CATEGORY>`: the platform's category
- `<CHALLENGE_NAME>`: challenge name, spaces replaced with underscores (e.g., `Buffer_Overflow_101`)

The vault root is `/Users/mathieu/Documents/CTF/CTF` — paths are relative to it.

## Step 7: Cleanup Exegol Containers

Unless `--keep` was specified, remove each container entirely using Bash:
```bash
docker rm -f exegol-ctf-<challenge_id>
```

If `--keep` was specified, inform the user which containers are still running so they can clean up later.

---

## Solving Methodology by Category

**REMINDER**: All commands below must be run inside the Exegol container via `mcp__exegol-mcp__execute_command_in_container`.
The Exegol container has a pentest toolkit pre-installed (Python3 + libs, pwntools, john, hashcat, binwalk, radare2, gdb+gef, etc.).
Use `mcp__exegol-mcp__list_installed_tools` to discover what's available in the container.

### Crypto
1. Read challenge description and files
2. Identify the cipher/algorithm (RSA, AES, XOR, substitution, Vigenere, etc.)
3. Look for weak parameters (small RSA modulus, reused nonce, ECB mode, etc.)
4. Write Python exploit in the workspace dir on host, run via: `execute_command_in_container(container_name="ctf-<id>", command="cd /workspace && python3 solve.py")`
5. Available in Exegol: `python3` with `pycryptodome`, `sympy`, `gmpy2`, `pwntools`, `hashlib`, `base64`
6. Try: factordb for RSA, frequency analysis for classical ciphers, known-plaintext attacks

### Web
1. Read the source code if provided
2. Identify vulnerabilities: SQLi, XSS, SSTI, LFI, command injection, SSRF, deserialization
3. Craft payloads and test locally if source is available
4. Use `curl`, `httpie`, `sqlmap` from inside the container via MCP

### Pwn / Binary Exploitation
1. `execute_command_in_container(command="file /workspace/<binary> && checksec /workspace/<binary>")`
2. Disassemble with `objdump -d`, `r2 -A`, or `ghidra` (headless)
3. Identify vulnerability: buffer overflow, format string, use-after-free, ROP
4. Write pwntools exploit, run via: `execute_command_in_container(command="cd /workspace && python3 exploit.py")`
5. GDB with GEF is available for dynamic analysis

### Reverse Engineering
1. `file`, `strings`, `ltrace`, `strace` via `execute_command_in_container`
2. Disassemble with `r2 -A` or use Ghidra headless
3. For .NET: use `monodis`; for Java: use `javap -c`
4. Analyze control flow, find flag validation logic
5. Write a keygen or extract the flag directly

### Forensics
1. `file` to identify file type
2. `binwalk` for embedded files
3. `exiftool` for metadata
4. `volatility` for memory dumps
5. `tshark` for pcap analysis
6. Look for hidden data, deleted files, steganography

### Steganography
1. `file` and `exiftool` for metadata
2. `strings` for embedded text
3. `binwalk` for hidden files
4. `zsteg` for PNG, `steghide` for JPEG
5. Check LSB encoding, color channels
6. Analyze with Python PIL/Pillow

### Misc / Programming
1. Read the challenge description carefully
2. Often involves scripting, math, or automation
3. Write Python solution in workspace, run inside container via MCP
4. May involve connecting to a remote service with sockets/pwntools

### OSINT
1. Analyze provided information (images, usernames, domains)
2. Use web searches and public databases
3. Check EXIF data, reverse image search hints

---

## Agent Prompt Template

When spawning a solving agent, use this template:

```
You are solving a CTF challenge inside a dedicated Exegol container.

**Name**: {name}
**Category**: {category}
**Points**: {points}
**Description**: {description}

**Exegol container name**: ctf-{challenge_id}
**Workspace on host**: {workspace_dir}
**Workspace inside container**: /workspace
**Files**: {file_list}

CRITICAL RULES:
- ALL analysis and exploit commands MUST be run inside the Exegol container via the MCP tool.
- To run a command: use mcp__exegol-mcp__execute_command_in_container with container_name="ctf-{challenge_id}" and command="<your command>"
- To run a script: write it to {workspace_dir} on the host with the Write tool, then:
  mcp__exegol-mcp__execute_command_in_container(container_name="ctf-{challenge_id}", command="cd /workspace && python3 solve.py")
- To discover available tools: use mcp__exegol-mcp__list_installed_tools(container_name="ctf-{challenge_id}")
- To get help on a tool: use mcp__exegol-mcp__get_tool_help(container_name="ctf-{challenge_id}", tool_name="<tool>")
- The container has a pentest toolkit: pwntools, pycryptodome, binwalk, radare2, gdb+gef, sqlmap, john, hashcat, etc.
- You can write files to {workspace_dir} directly with the Write tool (it's mounted as /workspace in the container).
- Do NOT use `exegol exec` bash commands. ALWAYS use the MCP tools.

Your task:
1. Analyze all challenge files (via execute_command_in_container)
2. Identify the vulnerability or puzzle
3. Write exploit/solution scripts to the workspace directory
4. Execute them inside the Exegol container via MCP
5. Extract the flag (usually in format flag{{...}} or similar)
6. Return the flag AND a full summary of all commands run (with their outputs) and scripts written, so a writeup can be generated.

Use the appropriate methodology for {category} challenges.
If you find the flag, end your response with:
FLAG: <the_flag>
COMMANDS_LOG:
<ordered list of all commands run and their key outputs>
SCRIPTS:
<any exploit/solution scripts written, with file names>

If you cannot solve it, end with: UNSOLVED: <reason>
```
