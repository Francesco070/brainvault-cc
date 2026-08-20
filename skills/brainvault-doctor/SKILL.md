---
name: brainvault-doctor
description: >
  Checks and repairs BrainVault vault health — structure, frontmatter, duplicate slugs,
  oversized files, broken MEMORY.md links — without ever losing memory content. Backs up
  before any write. Invoke on request ("/brainvault-doctor"), or proactively whenever you
  notice something looks off while using the vault (a wikilink that never resolves, a
  file that seems to duplicate another, a memory file that reads as corrupted or
  truncated) — don't wait to be asked.
---

# BrainVault Doctor

Diagnose and repair the vault at `$VAULT` (the path from the user's `CLAUDE.md`, the folder
containing `MEMORY.md`). Two kinds of findings, handled differently:

- **Mechanical/structural** (missing folders, missing index skeletons, missing version file)
  — the script fixes these itself, safely, after taking a backup.
- **Judgment calls** (duplicate slugs, broken frontmatter, oversized files, broken links,
  unindexed files) — the script only reports these. You fix them here, using the same care
  as any other memory edit, because they touch Francesco's actual memory content.

**Never delete a memory file in this skill.** If a finding looks like it needs a deletion
(e.g. a genuine duplicate), back it up and ask before removing anything — the same rule as
everywhere else in BrainVault: content is not disposable to me.

**Arguments:** `$ARGUMENTS` — optional `--fix` to also apply the safe structural fixes.
Without it, this runs as a report only.

---

## Step 1 — Find the plugin root and the vault path

Same detection as `/brainvault-setup`:

```bash
find ~/.claude/plugins -name "vault-doctor.sh" 2>/dev/null | sort | tail -1
```

Plugin root is two directories up from the result. If nothing is found, tell the user to run
`/brainvault-setup` first (it also creates the vault) and stop.

Read the user's `CLAUDE.md` for the configured Memories path (the folder containing
`MEMORY.md`). If it can't be determined, ask.

## Step 2 — Run the script

```bash
bash "$PLUGIN_ROOT/scripts/vault-doctor.sh" --vault "$VAULT_PATH" [--fix if $ARGUMENTS contains --fix]
```

Show the full output.

## Step 3 — Work through what the script could not fix itself

For each reported finding, in this order (highest-value first):

**Duplicate `name:` slugs.** Read both files. If one is clearly stale/superseded, propose
merging the useful content into the surviving file and tell the user what you'd remove —
don't act until they confirm. If both are legitimately different content that happens to
share a slug, rename one (update its `name:` field, its filename, and every `[[wikilink]]`
that points to it) instead.

**Missing/broken frontmatter.** If `name:` is missing, derive it from the filename. If
`metadata.type:` is missing or wrong, derive it from the folder the file lives in. These are
safe, mechanical inferences — apply them directly, no need to ask.

**Missing `**Why:**` / `**How to apply:**`** on feedback/project memories. Read the file's
content and existing description; if the reason and application are inferable from what's
already written, add the two sections yourself. If they're genuinely not inferable, ask the
user rather than inventing a rationale.

**Oversized files (over ~150 lines).** Don't split automatically — this needs the same
judgment as any File-Size-Discipline split (see `brainvault` skill). Report the list to the
user and ask whether to split now or leave it for later; only proceed once they say yes,
since splitting rewrites content and cross-links.

**Broken `MEMORY.md` links.** For each missing target: if the file was renamed/moved, find it
and fix the link. If the file is genuinely gone, ask before removing the index line — it may
mean content was lost and needs investigating, not just tidying.

**Unindexed files** (exist but not referenced in `MEMORY.md`). These are informational, not
errors — a file might be intentionally reachable only via `[[wikilink]]` from another memory.
Skim the list; add an index line for anything that looks like it should be discoverable at
session start, skip the rest.

## Step 4 — Summary

Report what was fixed automatically, what you fixed with judgment, and what's still open and
needs the user's decision. If any content-changing fix was made, note it in the day's
`history/YYYY-MM-DD.md` per the normal BrainVault history convention — this is a memory-system
change like any other.

## Notes

- Safe to run anytime, including mid-session if something looks corrupted. It's read-only
  unless `--fix` is passed, and even then only touches structure, never content.
- The script backs up the whole vault to `{vault-parent}/.brainvault-backups/<timestamp>-doctor/`
  before making any change. If something goes wrong, the backup is a plain folder copy —
  no restore tooling needed, just copy it back.
