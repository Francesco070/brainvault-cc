# brainvault-cc Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a publishable Claude Code plugin that packages an Obsidian-based persistent memory system with versioning, migration, and generic templates — installable by any Claude Code user.

**Architecture:** The plugin ships a skill (behaviour instructions), Bash-based templates and migration scripts, and a CLAUDE.md template. Versioning is tracked in a `.brainvault-version` file inside the user's vault; `scripts/init-or-update-vault.sh` bootstraps fresh vaults or runs numbered migrations to bring an existing vault up to the current plugin version. No runtime dependencies beyond `bash` and standard POSIX tools.

**Tech Stack:** Bash, Markdown (YAML frontmatter), Claude Code Plugin format (`.claude-plugin/plugin.json`, `skills/{name}/SKILL.md`), Git.

---

## File Map

```
brainvault-cc/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest (name, version, author, …)
│   └── marketplace.json     # Self-describing single-entry marketplace
├── skills/
│   └── brainvault/
│       └── SKILL.md         # Memory conventions — generic, no personal names
├── templates/
│   ├── user-memory.md
│   ├── project-memory.md
│   ├── solution-memory.md
│   ├── feedback-memory.md
│   └── reference-memory.md
├── migrations/
│   └── 0001-init-vault-structure.sh   # Idempotent init migration
├── scripts/
│   └── init-or-update-vault.sh        # Main entry point for users
├── CLAUDE.md.template       # Drop-in CLAUDE.md for end users
├── CHANGELOG.md
└── README.md
```

---

### Task 1: Plugin Manifest + Marketplace Entry

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Write `.claude-plugin/plugin.json`**

```json
{
  "name": "brainvault-cc",
  "description": "Obsidian-based persistent memory system for Claude Code — Brain Mode: versioned vault with migrations, solution memories and history tracking",
  "version": "0.1.0",
  "author": {
    "name": "YOUR_NAME",
    "email": "YOUR_EMAIL"
  },
  "homepage": "https://github.com/YOUR_GITHUB/brainvault-cc",
  "repository": "https://github.com/YOUR_GITHUB/brainvault-cc",
  "license": "MIT",
  "keywords": [
    "memory",
    "obsidian",
    "vault",
    "persistence",
    "knowledge",
    "brain"
  ]
}
```

- [ ] **Step 2: Write `.claude-plugin/marketplace.json`**

```json
{
  "name": "brainvault-cc-marketplace",
  "description": "Personal marketplace for brainvault-cc plugin",
  "owner": {
    "name": "YOUR_NAME",
    "email": "YOUR_EMAIL"
  },
  "plugins": [
    {
      "name": "brainvault-cc",
      "description": "Obsidian-based persistent memory system for Claude Code",
      "version": "0.1.0",
      "source": "./",
      "author": {
        "name": "YOUR_NAME",
        "email": "YOUR_EMAIL"
      }
    }
  ]
}
```

- [ ] **Step 3: Verify JSON syntax**

```bash
cd /home/fpa/PhpstormProjects/z_Schule/brainvault-cc
python3 -c "import json,sys; json.load(open('.claude-plugin/plugin.json')); json.load(open('.claude-plugin/marketplace.json')); print('OK')"
```
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add .claude-plugin/
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add plugin manifest and marketplace entry v0.1.0"
```

---

### Task 2: Main Skill — brainvault

**Files:**
- Create: `skills/brainvault/SKILL.md`

The skill must be 100% generic — no personal names, no hardcoded paths. It uses `{VAULT_PATH}` and `{USER_NAME}` as documentation placeholders where paths differ per installation. The actual path comes from the user's own `CLAUDE.md`.

- [ ] **Step 1: Create skills directory**

```bash
mkdir -p /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/skills/brainvault
```

- [ ] **Step 2: Write `skills/brainvault/SKILL.md`**

```markdown
---
name: brainvault
description: "Use at the start of every session and after completing any non-trivial task. Activates Brain Mode: reads the memory index, project context, and solution archive before acting; writes new memories and history entries after each task. Enforces the BrainVault convention system."
---

# BrainVault — Brain Mode

The vault is not just a store — it is the AI's working memory. Treat it accordingly.

## Core Principles

**Learn actively:** When something new is discovered (solution, pattern, project fact), write it to memory immediately.

**Link knowledge:** When two things belong together, note it in both files with `[[wikilinks]]`.

**Recognise patterns:** The same problem in multiple projects → one Solution Memory or a cross-reference note.

**Self-correct:** When a memory is wrong or stale, fix it on the spot.

---

## Vault Layout

The vault lives at the path configured in the user's `CLAUDE.md` (referred to below as `$VAULT`).

```
$VAULT/
├── MEMORY.md                  # Index — always loaded at session start
├── HISTORY.md                 # Index of daily history files
├── user/                      # Who the user is, preferences
├── project/                   # Per-project context files
├── reference/                 # External pointers and lookup tables
├── feedback/                  # Guidance on how to behave
├── solutions/                 # Non-trivial solutions archive
└── history/                   # YYYY-MM-DD.md daily change logs
```

---

## Session Lifecycle

### Session Start — ALWAYS

1. `MEMORY.md` is loaded automatically (it is the index).
2. When the user names a concrete task:
   - Read `project/proj-{project-name}.md` — stack, context, quirks.
   - Search `solutions/` for related past solutions.
3. No exceptions. Read first, act second.

### During Work

- New project information discovered → add to `project/proj-{project-name}.md` immediately.
- Memory found to be wrong → fix it immediately.
- Two things discovered to be connected → add `[[wikilinks]]` in both files.

### After Completing a Task — ALWAYS

1. **Create Solution Memory** (`solutions/sol-{project}-{topic}.md`) — problem, root cause, solution, insights.
2. **Update Project Memory** if new facts were discovered.
3. **Fix other memories** if errors were spotted.
4. **Write History entry** — one entry in `history/YYYY-MM-DD.md` summarising what changed in the memory system.
5. **Check MEMORY.md** — add new index entries if needed.

### Session End — ALWAYS

Check `MEMORY.md` → add new index entries if needed.

---

## Memory Types and Frontmatter

Every memory file starts with:

```yaml
---
name: kebab-case-slug
description: one line — what this is about
metadata:
  type: user | feedback | project | reference | solution
---
```

**Feedback memories** additionally require `**Why:**` and `**How to apply:**` lines in the body.

**Project memories** additionally require `**Why:**` and `**How to apply:**` lines.

---

## Solution Memory Format

**When to create:** Every time a bug is fixed, a feature implemented, or a non-trivial problem analysed.

**File name:** `sol-{project}-{topic}.md` — e.g. `sol-myapp-retry-logic.md`

**Only include what is non-obvious** — what would save time at the next similar problem.

```markdown
---
name: sol-{project}-{topic}
description: {problem in one sentence — what was broken / what was built}
metadata:
  type: solution
  project: {project-name}
  tags: [tag1, tag2]
  date: YYYY-MM-DD
---

## Problem
{What was broken / what needed to be built? Context: file, function, behaviour.}

## Root Cause / Analysis
{Why did it happen? What did the analysis reveal?}

## Solution
{How was it fixed? Code snippets where relevant. Which files were changed?}

## Insights
{What was non-obvious? What to watch for at the next similar problem?}

Related memories: [[proj-{project-name}]], [[sol-{similar-topic}]]
```

**Do NOT include in Solution Memories:**
- Trivial changes (typos, simple config)
- Things directly readable from the code
- Details that belong in the commit message

---

## History Format

**Path:** `history/YYYY-MM-DD.md` (one file per day)
**Index:** `HISTORY.md` (index only — links to daily files)

The history tracks **changes to the memory system**, not the task itself.

### Format

```markdown
## HH:MM — [Short description of the task that triggered these changes]

**New Files:**
- [[filename]] — why created, what it contains

**Corrected Files:**
- [[filename]] — Error: "what was wrong" → Fix: "what is correct now"

**Updated Files:**
- [[filename]] — what was added
```

Only include the sections that are relevant. `[[wikilinks]]` create Obsidian backlinks automatically.

---

## MEMORY.md Index Format

```markdown
# Memory Index

## User
- [Short Title](user/filename.md) — one-line hook

## Feedback
- [Short Title](feedback/filename.md) — one-line hook

## Project
- [Short Title](project/proj-name.md) — one-line hook

## Solutions
- [Short Title](solutions/sol-name.md) — one-line hook

## Reference
- [Short Title](reference/filename.md) — one-line hook
```

Each entry is one line, under ~150 characters.

---

## What NOT to save in memory

- Code patterns derivable by reading the project.
- Git history — `git log`/`git blame` are authoritative.
- Debugging steps that led to the fix (only the fix matters).
- Anything already in CLAUDE.md.
- Ephemeral task details that only matter in the current session.
```

- [ ] **Step 3: Verify skill frontmatter is valid YAML**

```bash
python3 -c "
import re, sys
content = open('skills/brainvault/SKILL.md').read()
m = re.match(r'^---\n(.+?)\n---', content, re.DOTALL)
if not m: sys.exit('No frontmatter found')
import yaml
yaml.safe_load(m.group(1))
print('Frontmatter OK')
" 2>/dev/null || python3 -c "
content = open('skills/brainvault/SKILL.md').read()
print('Has frontmatter' if content.startswith('---') else 'MISSING frontmatter')
"
```
Expected: `Frontmatter OK` (or `Has frontmatter` if pyyaml not installed)

- [ ] **Step 4: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add skills/
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add brainvault skill with full memory conventions"
```

---

### Task 3: Memory Templates

**Files:**
- Create: `templates/user-memory.md`
- Create: `templates/project-memory.md`
- Create: `templates/solution-memory.md`
- Create: `templates/feedback-memory.md`
- Create: `templates/reference-memory.md`

Each template has a `template_version: 1` field in frontmatter so future format migrations can be detected.

- [ ] **Step 1: Create templates directory**

```bash
mkdir -p /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/templates
```

- [ ] **Step 2: Write `templates/user-memory.md`**

```markdown
---
name: user-{slug}
description: {one line — what aspect of the user this captures}
metadata:
  type: user
  template_version: 1
---

{Describe who the user is, their role, background, preferences relevant to collaboration.}

{Examples: technical level, primary programming language, OS, workflow preferences.}
```

- [ ] **Step 3: Write `templates/project-memory.md`**

```markdown
---
name: proj-{project-name}
description: {one line — project purpose and main tech}
metadata:
  type: project
  template_version: 1
---

## Overview
{What does this project do? Who uses it?}

**Why:** {Why does this project exist? What problem does it solve?}

**How to apply:** {What should the AI keep in mind when working on this project?}

## Tech Stack
- {Language/Framework}: {version if important}
- {Key libraries}: {purpose}

## Architecture
{2-3 sentences on how the code is structured. Main folders, key entry points.}

## Quirks & Gotchas
- {Non-obvious constraint or convention}

## Current Focus / Status
{What is actively being worked on? What is stable?}

Related memories: [[sol-{project-name}-{topic}]]
```

- [ ] **Step 4: Write `templates/solution-memory.md`**

```markdown
---
name: sol-{project}-{topic}
description: {problem in one sentence — what was broken / what was built}
metadata:
  type: solution
  project: {project-name}
  tags: []
  date: YYYY-MM-DD
  template_version: 1
---

## Problem
{What was broken / what needed to be built? Context: file, function, behaviour.}

## Root Cause / Analysis
{Why did it happen? What did the analysis reveal?}

## Solution
{How was it fixed? Code snippets where relevant. Which files were changed?}

## Insights
{What was non-obvious? What to watch for at the next similar problem?}

Related memories: [[proj-{project-name}]]
```

- [ ] **Step 5: Write `templates/feedback-memory.md`**

```markdown
---
name: feedback-{topic}
description: {one line — what behaviour this governs}
metadata:
  type: feedback
  template_version: 1
---

{State the rule or guidance clearly and concisely.}

**Why:** {The reason the user gave — often a past incident or strong preference.}

**How to apply:** {When and where this guidance kicks in. Edge cases.}
```

- [ ] **Step 6: Write `templates/reference-memory.md`**

```markdown
---
name: ref-{topic}
description: {one line — what external resource or lookup table this points to}
metadata:
  type: reference
  template_version: 1
---

## {Resource Name}

**Location:** {URL, path, or system name}

**Purpose:** {What information lives here? When to look here?}

**Notes:** {Access details, authentication, format quirks.}
```

- [ ] **Step 7: Verify all 5 templates exist**

```bash
ls /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/templates/
```
Expected: `feedback-memory.md  project-memory.md  reference-memory.md  solution-memory.md  user-memory.md`

- [ ] **Step 8: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add templates/
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add memory templates with template_version field"
```

---

### Task 4: Migration 0001 — Init Vault Structure

**Files:**
- Create: `migrations/0001-init-vault-structure.sh`

This is the only migration in v0.1.0. It creates the full folder structure, MEMORY.md skeleton, and HISTORY.md index. It is idempotent — safe to run multiple times.

- [ ] **Step 1: Create migrations directory**

```bash
mkdir -p /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/migrations
```

- [ ] **Step 2: Write `migrations/0001-init-vault-structure.sh`**

```bash
#!/usr/bin/env bash
# Migration 0001 — Init vault structure
#
# What changes: Creates the full BrainVault folder structure under $VAULT_PATH.
#   Folders: user/, project/, reference/, feedback/, solutions/, history/
#   Files:   MEMORY.md (index skeleton), HISTORY.md (history index skeleton)
# Why: v0.1.0 initial release — establishes the baseline directory layout.
#
# Idempotency: All mkdir calls use -p; file writes only happen if the file
#   does not already exist (checked with [ ! -f ... ]).
# Backup: Not needed — this migration only creates new files/dirs, never
#   overwrites existing content.

set -euo pipefail

VAULT_PATH="${1:?Usage: $0 <vault-path>}"

echo "[0001] Creating vault structure at: $VAULT_PATH"

# Create directory structure
mkdir -p \
  "$VAULT_PATH/user" \
  "$VAULT_PATH/project" \
  "$VAULT_PATH/reference" \
  "$VAULT_PATH/feedback" \
  "$VAULT_PATH/solutions" \
  "$VAULT_PATH/history"

echo "[0001] Directories created."

# Create MEMORY.md index skeleton if not present
if [ ! -f "$VAULT_PATH/MEMORY.md" ]; then
  cat > "$VAULT_PATH/MEMORY.md" <<'EOF'
# Memory Index

Vault managed by [brainvault-cc](https://github.com/YOUR_GITHUB/brainvault-cc).
**Changelog:** [HISTORY.md](HISTORY.md)

## User

## Feedback

## Project

## Solutions

## Reference
EOF
  echo "[0001] Created MEMORY.md"
else
  echo "[0001] MEMORY.md already exists — skipped."
fi

# Create HISTORY.md index if not present
if [ ! -f "$VAULT_PATH/HISTORY.md" ]; then
  cat > "$VAULT_PATH/HISTORY.md" <<'EOF'
# History Index

Each entry links to a daily change log for the memory system.

<!-- Format: - [YYYY-MM-DD](history/YYYY-MM-DD.md) — one-line summary -->
EOF
  echo "[0001] Created HISTORY.md"
else
  echo "[0001] HISTORY.md already exists — skipped."
fi

echo "[0001] Done."
```

- [ ] **Step 3: Make executable**

```bash
chmod +x /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/migrations/0001-init-vault-structure.sh
```

- [ ] **Step 4: Test migration against a temp directory**

```bash
TMPVAULT=$(mktemp -d)
/home/fpa/PhpstormProjects/z_Schule/brainvault-cc/migrations/0001-init-vault-structure.sh "$TMPVAULT"
echo "--- Directory structure ---"
find "$TMPVAULT" -type d | sort
echo "--- Files ---"
find "$TMPVAULT" -type f | sort
# Run a second time to verify idempotency
/home/fpa/PhpstormProjects/z_Schule/brainvault-cc/migrations/0001-init-vault-structure.sh "$TMPVAULT"
echo "--- Idempotency: OK if no errors above ---"
rm -rf "$TMPVAULT"
```

Expected output (trimmed):
```
[0001] Creating vault structure at: /tmp/...
[0001] Directories created.
[0001] Created MEMORY.md
[0001] Created HISTORY.md
[0001] Done.
--- Directory structure ---
/tmp/.../
/tmp/.../feedback
/tmp/.../history
/tmp/.../project
/tmp/.../reference
/tmp/.../solutions
/tmp/.../user
--- Files ---
/tmp/.../HISTORY.md
/tmp/.../MEMORY.md
[0001] Creating vault structure at: /tmp/...
[0001] Directories created.
[0001] MEMORY.md already exists — skipped.
[0001] HISTORY.md already exists — skipped.
[0001] Done.
--- Idempotency: OK if no errors above ---
```

- [ ] **Step 5: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add migrations/
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add migration 0001 — idempotent vault structure init"
```

---

### Task 5: Setup/Update Script

**Files:**
- Create: `scripts/init-or-update-vault.sh`

This is the main entry point. It:
1. Accepts `--vault <path>` argument (required).
2. Checks if `.brainvault-version` exists inside the vault.
3. **Fresh install:** runs all migrations in order, writes `.brainvault-version`.
4. **Existing vault:** reads current version, runs only missing migrations in order, updates `.brainvault-version`.
5. Never deletes user content — only additive structure changes.
6. Prints a clear summary of what was done.

- [ ] **Step 1: Create scripts directory**

```bash
mkdir -p /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/scripts
```

- [ ] **Step 2: Write `scripts/init-or-update-vault.sh`**

```bash
#!/usr/bin/env bash
# BrainVault init-or-update script
#
# Usage: ./scripts/init-or-update-vault.sh --vault /path/to/your/Vault/Memories
#
# Fresh install: creates full structure, writes .brainvault-version
# Update:        runs only migrations newer than current .brainvault-version

set -euo pipefail

PLUGIN_VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="$PLUGIN_ROOT/migrations"

# --- Parse arguments ---
VAULT_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      VAULT_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 --vault /path/to/vault/memories"
      exit 1
      ;;
  esac
done

if [ -z "$VAULT_PATH" ]; then
  echo "Error: --vault <path> is required."
  echo "Usage: $0 --vault /path/to/vault/memories"
  exit 1
fi

VERSION_FILE="$VAULT_PATH/.brainvault-version"

# --- Helper: compare semver numbers ---
# Returns 0 if $1 < $2 (migration needed), 1 otherwise
migration_is_needed() {
  local migration_num="$1"
  local current_num="$2"
  # Migration filenames: 0001-..., 0002-...
  # current_num is the last applied migration number stored in .brainvault-version
  [ "$migration_num" -gt "$current_num" ]
}

# --- Determine current state ---
if [ ! -f "$VERSION_FILE" ]; then
  echo "=== BrainVault: Fresh install ==="
  echo "Vault:          $VAULT_PATH"
  echo "Plugin version: $PLUGIN_VERSION"
  echo ""
  LAST_APPLIED=0
  IS_FRESH=true
else
  STORED=$(cat "$VERSION_FILE")
  LAST_APPLIED=$(echo "$STORED" | grep "^last_migration=" | cut -d= -f2 | tr -d '[:space:]')
  STORED_PLUGIN=$(echo "$STORED" | grep "^plugin_version=" | cut -d= -f2 | tr -d '[:space:]')
  echo "=== BrainVault: Update check ==="
  echo "Vault:              $VAULT_PATH"
  echo "Current version:    $STORED_PLUGIN (migration $LAST_APPLIED)"
  echo "Plugin version:     $PLUGIN_VERSION"
  echo ""
  IS_FRESH=false
fi

# --- Run pending migrations ---
MIGRATIONS_RUN=0

for migration in $(ls "$MIGRATIONS_DIR"/*.sh 2>/dev/null | sort); do
  MIGRATION_FILE=$(basename "$migration")
  # Extract the leading number: 0001-foo.sh -> 0001 -> 1
  MIGRATION_NUM=$(echo "$MIGRATION_FILE" | grep -oE '^[0-9]+' | sed 's/^0*//' )
  MIGRATION_NUM=${MIGRATION_NUM:-0}

  if [ "$MIGRATION_NUM" -gt "$LAST_APPLIED" ]; then
    echo "--- Running migration: $MIGRATION_FILE"
    bash "$migration" "$VAULT_PATH"
    LAST_APPLIED=$MIGRATION_NUM
    MIGRATIONS_RUN=$((MIGRATIONS_RUN + 1))
    echo ""
  else
    echo "--- Skipping migration: $MIGRATION_FILE (already applied)"
  fi
done

# --- Write version file ---
cat > "$VERSION_FILE" <<EOF
plugin_version=$PLUGIN_VERSION
last_migration=$LAST_APPLIED
updated=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

# --- Summary ---
echo "=== Done ==="
if [ "$IS_FRESH" = true ]; then
  echo "Fresh vault initialised at: $VAULT_PATH"
else
  if [ "$MIGRATIONS_RUN" -gt 0 ]; then
    echo "Applied $MIGRATIONS_RUN migration(s). Vault is now at plugin version $PLUGIN_VERSION."
  else
    echo "Already up to date — no migrations needed."
  fi
fi
echo "Version file: $VERSION_FILE"
```

- [ ] **Step 3: Make executable**

```bash
chmod +x /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/scripts/init-or-update-vault.sh
```

- [ ] **Step 4: Test fresh install**

```bash
TMPVAULT=$(mktemp -d)
/home/fpa/PhpstormProjects/z_Schule/brainvault-cc/scripts/init-or-update-vault.sh --vault "$TMPVAULT"
echo ""
echo "=== Version file contents ==="
cat "$TMPVAULT/.brainvault-version"
echo ""
echo "=== Directory structure ==="
find "$TMPVAULT" | sort
rm -rf "$TMPVAULT"
```

Expected: Fresh install message, migration 0001 runs, `.brainvault-version` written, all 6 subdirs created.

- [ ] **Step 5: Test update (already up to date)**

```bash
TMPVAULT=$(mktemp -d)
/home/fpa/PhpstormProjects/z_Schule/brainvault-cc/scripts/init-or-update-vault.sh --vault "$TMPVAULT"
echo ""
echo "--- Running again (should skip all migrations) ---"
/home/fpa/PhpstormProjects/z_Schule/brainvault-cc/scripts/init-or-update-vault.sh --vault "$TMPVAULT"
rm -rf "$TMPVAULT"
```

Expected second run: `Already up to date` or `Skipping migration: 0001-init-vault-structure.sh`

- [ ] **Step 6: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add scripts/
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add init-or-update-vault.sh with versioned migration runner"
```

---

### Task 6: CLAUDE.md Template

**Files:**
- Create: `CLAUDE.md.template`

This is the drop-in `CLAUDE.md` for end users. It uses `{{VAULT_PATH}}` as a placeholder that users replace with their actual path. It is a direct generalisation of the reference CLAUDE.md — no personal names, no personal paths.

- [ ] **Step 1: Write `CLAUDE.md.template`**

```markdown
# Claude Code — BrainVault Configuration
#
# SETUP: Replace {{VAULT_PATH}} with the absolute path to your Memories folder.
# Example: /home/alice/Obsidian/Claude/Memories
# Then remove this comment block and copy this file to ~/CLAUDE.md
# (or append it to your existing ~/CLAUDE.md).

---

## BRAIN MODE: Memory is My Working Memory

The vault is not just a store — it is the AI's brain. Treat it accordingly.

### What This Means

**Learn actively:** When something new is discovered (solution, pattern, project fact), write it to the appropriate memory file immediately.

**Link knowledge:** When two things belong together, note it in both files with `[[wikilinks]]`.

**Recognise patterns:** The same problem in multiple projects → one Solution Memory or a cross-reference note.

**Self-correct:** When a memory is wrong or stale, fix it on the spot.

---

## Memory Behaviour During Sessions

### Session Start — ALWAYS
1. `MEMORY.md` is loaded automatically (it is the index).
2. When a concrete task is named:
   - Read `project/proj-{project-name}.md` — stack, context, quirks.
   - Search `solutions/` for related past solutions.
3. No exceptions. Read first, act second.

### During Work
- New project information discovered → add to `project/proj-{project-name}.md` immediately.
- Memory found to be wrong → fix it immediately.
- Two things discovered to be connected → add `[[wikilinks]]` in both files.

### After Completing a Task — ALWAYS
1. **Create Solution Memory** (`solutions/sol-{project}-{topic}.md`) — problem, root cause, solution, insights.
2. **Update Project Memory** if new facts were discovered.
3. **Fix other memories** if errors were spotted.
4. **Write History entry** — one entry in `history/YYYY-MM-DD.md` summarising what changed in the memory system.
5. **Check MEMORY.md** — add new index entries if needed.

### Session End — ALWAYS
Check `MEMORY.md` → add new index entries if needed.

---

## Vault (Memory System)

### Paths

| Purpose | Path |
|---|---|
| Memory Index | `{{VAULT_PATH}}/MEMORY.md` |
| User Memories | `{{VAULT_PATH}}/user/` |
| Feedback Memories | `{{VAULT_PATH}}/feedback/` |
| Project Memories | `{{VAULT_PATH}}/project/` |
| Reference Memories | `{{VAULT_PATH}}/reference/` |
| Solution Memories | `{{VAULT_PATH}}/solutions/` |
| History (daily files) | `{{VAULT_PATH}}/history/` |
| History Index | `{{VAULT_PATH}}/HISTORY.md` |

### Memory Types and Frontmatter

```yaml
---
name: kebab-case-slug
description: one line — what this is about
metadata:
  type: user | feedback | project | reference | solution
---
```

**Feedback memories** additionally require `**Why:**` and `**How to apply:**` lines.
**Project memories** additionally require `**Why:**` and `**How to apply:**` lines.

---

## Solution Memories — When and How

**When to create:** Every time a bug is fixed, a feature is implemented, or a non-trivial problem is analysed.

**What to include:** Only what is non-obvious — what would save time at the next similar problem.

**File name:** `sol-{project}-{topic}.md`

**Format:**
\```markdown
---
name: sol-{project}-{topic}
description: {problem in one sentence}
metadata:
  type: solution
  project: {project-name}
  tags: [tag1, tag2]
  date: YYYY-MM-DD
---

## Problem
## Root Cause / Analysis
## Solution
## Insights

Related memories: [[proj-{project-name}]]
\```

---

## HISTORY.md — Memory System Changelog

**Path:** `history/YYYY-MM-DD.md` (one file per day)
**Index:** `HISTORY.md`

One entry per completed task/session, written after all memory changes are done.

### Format

\```markdown
## HH:MM — [Task description]

**New Files:**
- [[filename]] — why created

**Corrected Files:**
- [[filename]] — Error: "what was wrong" → Fix: "what is correct now"

**Updated Files:**
- [[filename]] — what was added
\```
```

- [ ] **Step 2: Verify placeholder is present**

```bash
grep -c '{{VAULT_PATH}}' /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/CLAUDE.md.template
```
Expected: `9` (or any number > 0)

- [ ] **Step 3: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add CLAUDE.md.template
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "feat: add generic CLAUDE.md.template for end users"
```

---

### Task 7: CHANGELOG + README

**Files:**
- Create: `CHANGELOG.md`
- Create: `README.md`

- [ ] **Step 1: Write `CHANGELOG.md`**

```markdown
# Changelog

All notable changes to brainvault-cc are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

## [0.1.0] — 2026-06-16

### Added
- Initial plugin release.
- `skills/brainvault/SKILL.md` — full Brain Mode memory convention system.
- `templates/` — five memory templates (user, project, solution, feedback, reference) with `template_version: 1` field.
- `migrations/0001-init-vault-structure.sh` — idempotent vault structure bootstrap.
- `scripts/init-or-update-vault.sh` — versioned migration runner with fresh-install and update detection.
- `CLAUDE.md.template` — generic drop-in CLAUDE.md for end users.
- `.brainvault-version` file format: `plugin_version`, `last_migration`, `updated`.

### Migration Guide (from no vault)
Run: `./scripts/init-or-update-vault.sh --vault /path/to/your/Memories`
```

- [ ] **Step 2: Write `README.md`**

```markdown
# brainvault-cc

**Obsidian-based persistent memory system for Claude Code.**

BrainVault turns your Claude Code assistant into a learning system. After each session, it writes structured memory files — solution archives, project context, feedback on its own behaviour — into an Obsidian vault. At the start of the next session, it reads them back. Over time, Claude stops repeating mistakes and builds genuine project knowledge.

---

## Philosophy

**Solution Files, not bloated Project Files.** Non-trivial solutions get their own file (`sol-{project}-{topic}.md`) with problem, root cause, fix, and insights. Project memory files stay lean — they describe the project, not every past fix.

**Wikilinks for backlinks.** `[[wikilinks]]` between memory files create Obsidian backlinks automatically. You can see which solutions relate to which project without maintaining a manual index.

**History as a memory changelog.** The `history/YYYY-MM-DD.md` files track what *changed in the memory system* — new files, corrections, additions. Not the task itself, but what was learned.

---

## Installation

### Prerequisites
- [Claude Code](https://claude.ai/code) installed
- An Obsidian vault (or any directory you want to use as the memory store)
- `bash` (macOS/Linux/WSL)

### 1. Add the plugin

Option A — via marketplace URL (once published):
```bash
claude plugin install https://github.com/YOUR_GITHUB/brainvault-cc
```

Option B — local install from this repo:
```bash
git clone https://github.com/YOUR_GITHUB/brainvault-cc
claude plugin install ./brainvault-cc
```

### 2. Initialise your vault

```bash
# Replace the path with your Obsidian/Memories directory
~/.claude/plugins/cache/YOUR_MARKETPLACE/brainvault-cc/VERSION/scripts/init-or-update-vault.sh \
  --vault /path/to/your/Obsidian/Claude/Memories
```

This creates:
```
Memories/
├── MEMORY.md          ← auto-loaded by Claude Code (put it in CLAUDE.md context)
├── HISTORY.md
├── user/
├── project/
├── reference/
├── feedback/
├── solutions/
└── history/
```

### 3. Configure CLAUDE.md

Copy the template and replace `{{VAULT_PATH}}`:
```bash
cp ~/.claude/plugins/cache/YOUR_MARKETPLACE/brainvault-cc/VERSION/CLAUDE.md.template ~/CLAUDE.md
# Edit ~/CLAUDE.md — replace all {{VAULT_PATH}} occurrences with your actual path
```

Or append it to an existing `~/CLAUDE.md`:
```bash
cat ~/.claude/plugins/cache/YOUR_MARKETPLACE/brainvault-cc/VERSION/CLAUDE.md.template >> ~/CLAUDE.md
```

---

## Updating the Plugin

After pulling a new plugin version:

```bash
claude plugin update brainvault-cc

# Then run the migration script — it detects your current vault version and
# applies only the missing migrations:
scripts/init-or-update-vault.sh --vault /path/to/your/Memories
```

Migrations are **additive only** — they never delete or overwrite your existing memory files.

---

## Memory Types

| Type | File pattern | When to write |
|------|-------------|---------------|
| `user` | `user/{slug}.md` | User preferences, background, expertise |
| `project` | `project/proj-{name}.md` | Per-project stack, quirks, current focus |
| `solution` | `solutions/sol-{project}-{topic}.md` | After each non-trivial fix or implementation |
| `feedback` | `feedback/feedback-{topic}.md` | Guidance on AI behaviour — corrections and confirmations |
| `reference` | `reference/{slug}.md` | External links, system pointers, lookup tables |

---

## Using Templates

Templates are in `templates/`. Copy the relevant one when creating a new memory file:

```bash
cp templates/solution-memory.md /path/to/Memories/solutions/sol-myproject-my-bug.md
```

---

## Version File

Each vault contains a `.brainvault-version` file:
```
plugin_version=0.1.0
last_migration=1
updated=2026-06-16T10:00:00Z
```

This tells the migration runner what has already been applied.

---

## License

MIT
```

- [ ] **Step 3: Verify both files exist**

```bash
ls /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/CHANGELOG.md \
   /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/README.md
```
Expected: both paths printed without error.

- [ ] **Step 4: Commit**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc add CHANGELOG.md README.md
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc commit -m "docs: add README and CHANGELOG for v0.1.0"
```

---

### Task 8: Git Init + Initial Tag

**Files:** none (git state only)

- [ ] **Step 1: Verify git was initialised (it was created in Task 0)**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc log --oneline
```
Expected: 6 commits (Tasks 1–7).

- [ ] **Step 2: Verify no private content leaked**

```bash
grep -r "fpa\|Francesco\|Palazzo\|/home/fpa\|Exigo\|exigo" \
  /home/fpa/PhpstormProjects/z_Schule/brainvault-cc/ \
  --include="*.md" --include="*.json" --include="*.sh" \
  --exclude-dir=".git" \
  --exclude-dir="docs" \
  -l 2>/dev/null || echo "Clean — no private content found"
```
Expected: `Clean — no private content found`

- [ ] **Step 3: Tag v0.1.0**

```bash
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc tag -a v0.1.0 -m "Initial release — BrainVault v0.1.0"
git -C /home/fpa/PhpstormProjects/z_Schule/brainvault-cc tag
```
Expected: `v0.1.0`

- [ ] **Step 4: Final structure verification**

```bash
find /home/fpa/PhpstormProjects/z_Schule/brainvault-cc -not -path '*/.git/*' | sort
```
Expected tree:
```
brainvault-cc/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── CHANGELOG.md
├── CLAUDE.md.template
├── README.md
├── docs/superpowers/plans/2026-06-16-brainvault-cc.md
├── migrations/
│   └── 0001-init-vault-structure.sh
├── scripts/
│   └── init-or-update-vault.sh
├── skills/
│   └── brainvault/
│       └── SKILL.md
└── templates/
    ├── feedback-memory.md
    ├── project-memory.md
    ├── reference-memory.md
    ├── solution-memory.md
    └── user-memory.md
```

---

## Self-Review

### Spec Coverage

| Requirement | Task |
|-------------|------|
| plugin.json with semver version | Task 1 |
| `.brainvault-version` in vault | Task 5 (init-or-update-vault.sh writes it) |
| `migrations/` folder, numbered, idempotent | Tasks 4–5 |
| Migration script with backup note | Task 4 (comment says additive only — no destructive ops in 0001) |
| init-or-update-vault.sh: fresh vs update detection | Task 5 |
| No deletion of user content | Tasks 4–5 (mkdir -p, file create only if not exists) |
| CHANGELOG.md | Task 7 |
| `skills/brainvault/SKILL.md` generic | Task 2 |
| Templates with frontmatter + template_version | Task 3 |
| Generic CLAUDE.md template | Task 6 |
| README: install + update + philosophy | Task 7 |
| Git repo, first commit = v0.1.0 | Task 8 |
| No private names/paths in plugin files | Task 8 Step 2 |
| Project at /home/fpa/PhpstormProjects/z_Schule/brainvault-cc | All tasks use this path |

### Placeholder scan
- All shell scripts use `$VAULT_PATH` variable, not hardcoded paths. ✓
- All markdown templates use `{slug}` or `{project-name}` style placeholders. ✓
- `CLAUDE.md.template` uses `{{VAULT_PATH}}`. ✓
- `plugin.json` and `marketplace.json` use `YOUR_NAME`, `YOUR_EMAIL`, `YOUR_GITHUB`. ✓ (These are intentional — users fill them in)

### Type consistency
- Migration number format: 4-digit leading zeros (`0001`). Consistent across migration filename and `init-or-update-vault.sh` parsing. ✓
- Version file fields: `plugin_version`, `last_migration`, `updated`. Consistent between writer (init-or-update-vault.sh) and reader (same script). ✓
