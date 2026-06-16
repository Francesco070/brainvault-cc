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

Option A — via marketplace (recommended):
```bash
# Register the marketplace, then install
claude plugin marketplace add Francesco070/brainvault-cc
claude plugin install brainvault-cc
```

Option B — local install from a cloned repo:
```bash
git clone https://github.com/Francesco070/brainvault-cc
claude plugin install ./brainvault-cc
```

### 2. Initialise your vault

```bash
# Replace the path with your Obsidian/Memories directory
~/.claude/plugins/cache/Francesco070/brainvault-cc/0.1.0/scripts/init-or-update-vault.sh \
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
cp ~/.claude/plugins/cache/Francesco070/brainvault-cc/0.1.0/CLAUDE.md.template ~/CLAUDE.md
# Edit ~/CLAUDE.md — replace all {{VAULT_PATH}} occurrences with your actual path
```

Or append it to an existing `~/CLAUDE.md`:
```bash
cat ~/.claude/plugins/cache/Francesco070/brainvault-cc/0.1.0/CLAUDE.md.template >> ~/CLAUDE.md
```

---

## Updating the Plugin

After a new plugin version is released:

```bash
claude plugin update brainvault-cc

# Then run the migration script — it detects your current vault version and
# applies only the missing migrations:
~/.claude/plugins/cache/Francesco070/brainvault-cc/0.1.0/scripts/init-or-update-vault.sh \
  --vault /path/to/your/Memories
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
