---
name: brainvault-setup
description: >
  Interactive setup for BrainVault — initialises vault structure and writes CLAUDE.md config.
  Run after installing the plugin, or to apply updates/migrations. Safe to run repeatedly.
  Usage: /brainvault-setup [/absolute/path/to/Memories]
disable-model-invocation: true
---

# BrainVault Setup

Initialise or update the user's BrainVault.

**Arguments:** `$ARGUMENTS` — optional absolute path to the Memories folder. If empty, auto-detect.

---

## Step 1 — Find the plugin root

Run:

```bash
find ~/.claude/plugins -name "init-or-update-vault.sh" 2>/dev/null | sort | tail -1
```

The plugin root is two directories up from the found file (the script lives at `<plugin_root>/scripts/init-or-update-vault.sh`). Store this as `PLUGIN_ROOT`.

If nothing is found, tell the user:
> BrainVault plugin not found. Expected location: `~/.claude/plugins/cache/Francesco070/brainvault-cc/<version>/scripts/init-or-update-vault.sh`
> Please reinstall with: `claude plugin marketplace add Francesco070/brainvault-cc && claude plugin install brainvault-cc`

Then stop.

---

## Step 2 — Determine the vault (Memories) path

**If `$ARGUMENTS` is non-empty:** use it directly as `VAULT_PATH` and skip to Step 3. Expand `~` to the actual home directory if needed.

**Otherwise, auto-detect:**

Run:
```bash
find ~ -maxdepth 7 -name "MEMORY.md" -path "*/Claude/Memories/MEMORY.md" 2>/dev/null | head -5
```

Also check these standard locations:
- `~/Dokumente/Obsidian/Claude/Memories`
- `~/Documents/Obsidian/Claude/Memories`
- `~/Obsidian/Claude/Memories`
- `~/obsidian/Claude/Memories`

Collect all candidates that exist (via `test -d`). Then:

- **Exactly one candidate found:** Tell the user which path was detected and ask them to confirm or provide a different one. If they confirm, use it.
- **Multiple candidates found:** List them and ask the user to pick one or enter a custom path.
- **Nothing found:** Tell the user no Obsidian vault was detected and ask them to provide the absolute path to their Memories folder (the folder that will contain `MEMORY.md`). It does not have to exist yet.

The vault path is the **Memories folder** — not the Obsidian root and not the Claude folder. For example: `/home/alice/Obsidian/Claude/Memories`.

---

## Step 3 — Run the init script

```bash
bash "$PLUGIN_ROOT/scripts/init-or-update-vault.sh" --vault "$VAULT_PATH"
```

Show the full output. If the script exits non-zero, stop and report the error — do not continue to Step 4.

---

## Step 4 — Add vault permissions to ~/.claude/settings.json

So Claude never prompts for permission when reading or writing vault files, add the vault path to the user settings allow list.

Read `~/.claude/settings.json`. If the file does not exist yet, treat the current content as `{}`.

Check whether `permissions.allow` already contains a rule matching the vault path:
```bash
grep -q "$(echo "$VAULT_PATH" | sed 's|/[^/]*$||')" ~/.claude/settings.json 2>/dev/null && echo "ALREADY_SET" || echo "NOT_SET"
```

If `NOT_SET`: add (or create) the `permissions.allow` array with these three entries, replacing `VAULT_PATH` with the actual path:
```json
"permissions": {
  "allow": [
    "Read(VAULT_PATH/**)",
    "Edit(VAULT_PATH/**)",
    "Write(VAULT_PATH/**)"
  ]
}
```

If `permissions.allow` already exists with other entries, **merge** — do not replace the existing array. Append the three new entries.

Write the updated JSON back. Validate it with `jq . ~/.claude/settings.json` after writing.

> **Note:** Claude Code's auto-mode classifier blocks Claude from self-modifying its own settings. If you are running in auto mode and the write is blocked, tell the user to run this command manually:
> ```bash
> node -e "
> const fs = require('fs'), f = process.env.HOME+'/.claude/settings.json';
> const s = JSON.parse(fs.readFileSync(f,'utf8'));
> if (!s.permissions) s.permissions = {};
> if (!s.permissions.allow) s.permissions.allow = [];
> const vp = 'VAULT_PATH';
> ['Read','Edit','Write'].forEach(t => {
>   const r = t+'('+vp+'/**)';
>   if (!s.permissions.allow.includes(r)) s.permissions.allow.push(r);
> });
> fs.writeFileSync(f, JSON.stringify(s,null,2)+'\n');
> console.log('done');
> "
> ```
> (with `VAULT_PATH` replaced by the actual path)

---

## Step 5 — Configure CLAUDE.md

The target is `~/CLAUDE.md` (the user's home-level Claude config, loaded in every session).

**Check if BrainVault config is already present:**
```bash
grep -q "MEMORY.md" ~/CLAUDE.md 2>/dev/null && echo "CONFIGURED" || echo "NOT_CONFIGURED"
```

**If `NOT_CONFIGURED` (or `~/CLAUDE.md` does not exist yet):**

1. Read the template: `$PLUGIN_ROOT/CLAUDE.md.template`
2. Replace **every** `{{VAULT_PATH}}` with the actual `VAULT_PATH`
3. Remove the comment block at the top (lines starting with `#` before the first `---`)
4. If `~/CLAUDE.md` does not exist: write the result as `~/CLAUDE.md`
5. If `~/CLAUDE.md` exists but has no BrainVault config: append a blank line followed by the result to `~/CLAUDE.md`
6. Tell the user what was written and where.

**If `CONFIGURED`:**
Tell the user:
> `~/CLAUDE.md` already contains BrainVault config — skipped. To reconfigure, remove the BrainVault section and run `/brainvault-setup` again.

---

## Step 6 — Summary

Print a concise summary covering:
- Vault path used
- Whether this was a **fresh install** or an **update** (the init script output says which)
- Whether `CLAUDE.md` was **written**, **appended**, or **skipped**
- Next step: **restart Claude Code** (or open a new session) so the updated `~/CLAUDE.md` is loaded

Example:
```
BrainVault setup complete.

Vault:     /home/alice/Obsidian/Claude/Memories  (fresh install)
CLAUDE.md: appended to ~/CLAUDE.md

Restart Claude Code to activate Brain Mode.
```

---

## Notes

- This skill is safe to run repeatedly — the init script is idempotent and skips already-applied migrations.
- Do **not** create a solution memory for this run — it is infrastructure setup, not a development task.
- If the user later moves their vault, they must update `~/CLAUDE.md` manually and run `/brainvault-setup <new-path>` again to apply any pending migrations.
