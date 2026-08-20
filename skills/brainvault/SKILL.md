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

**Stay atomic:** One file, one topic. A file that keeps growing forever costs more tokens every time it is read, and buries the parts relevant to the current task inside parts that aren't. Prefer several small linked files over one file that accumulates everything about a project or a theme.

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

Related memories: [[proj-{project-name}]], [[sol-{similar-topic}]]
```

**Do NOT include in Solution Memories:**
- Trivial changes (typos, simple config)
- Things directly readable from the code
- Details that belong in the commit message

---

## File Size Discipline

Large files are the main source of wasted tokens: reading one pulls in everything it has ever accumulated, most of it irrelevant to the task at hand.

**Guideline, not a hard limit:** if a file is pushing past roughly 100–150 lines, that's the signal to split it — not a reason to panic at 151.

**Before writing to an existing file:** check its current size. If it's already large, don't append — create a new, more specific file and link it instead.

**Project memories** (`project/proj-*.md`) drift into this the most. Keep them to current stack, current state, and quirks that don't fit anywhere else. When a project accumulates enough history to make the file long, split by sub-topic (e.g. `proj-fabbrica.md` stays the compact overview; `proj-fabbrica-billing.md`, `proj-fabbrica-mcp.md` etc. hold the deep detail) and link both directions with `[[wikilinks]]`. Detailed narrative belongs in Solution Memories, not in the project file.

**Solution memories** are one file per solution by design — don't turn one into a running log by appending new unrelated fixes to it. If a new problem is in the same area as an old solution, write a new `sol-*.md` and link it (`Related memories: [[sol-old-topic]]`) rather than growing the old one.

**Splitting an existing oversized file:** move detail out into new topic files, leave the original as a short pointer/summary with links to the new files, and update every place that linked to the old file (`MEMORY.md` index, other files' `[[wikilinks]]`) so nothing goes stale.

---

## History Format

**Path:** `history/YYYY-MM-DD.md` (one file per day)
**Index:** `HISTORY.md`

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
