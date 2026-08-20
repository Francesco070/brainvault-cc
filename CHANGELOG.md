# Changelog

All notable changes to brainvault-cc are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

## [0.5.0] — 2026-08-20

### Added
- Sixth memory type: **agent**. `agents/agent-{topic}.md` records which agent/subagent
  (built-in role or bespoke one-off prompt) was dispatched for which kind of task, with
  the prompt kept close to verbatim so a similar future problem can reuse or clone it
  instead of re-deriving the setup. Same "only if non-trivial and worth reusing" bar as
  Solution Memories.
- `templates/agent-memory.md`, `migrations/0002-add-agents-folder.sh` (idempotent: creates
  `agents/`, adds a `## Agents` section to `MEMORY.md`), `scripts/vault-doctor.sh` now
  checks `agents/` alongside the other five typed folders.
- `skills/brainvault/SKILL.md` / `CLAUDE.md.template` — new "Agent Memory Format" section,
  `agent` added to the type enum, "After Completing a Task" now includes an agent-memory
  step when a dispatch happened.

## [0.4.1] — 2026-08-20

### Fixed
- `scripts/vault-doctor.sh` — skip `TEMPLATE.md` scaffolding files (intentional
  `{placeholder}` slugs, never indexed in `MEMORY.md` by design) instead of
  flagging them as naming/indexing violations.

## [0.4.0] — 2026-08-20

### Added
- `skills/brainvault-doctor/SKILL.md` + `scripts/vault-doctor.sh` — `/brainvault-doctor`:
  checks vault structure, frontmatter, duplicate `name:` slugs, File-Size-Discipline
  violations, and broken `MEMORY.md` links. Report-only by default; `--fix` applies only
  safe structural repairs (missing folders/index skeletons/version file) after backing up
  the whole vault to a timestamped folder. Never deletes or rewrites memory content —
  judgment-requiring findings (duplicates, oversized files, broken links) are reported for
  a human or Claude to fix deliberately. Meant to also run proactively, not just on request.
- `skills/brainvault/SKILL.md` / `CLAUDE.md.template` — documented an optional sibling
  folder convention (e.g. `Reports/`, `Validierung/{project}/`) for large working documents
  that don't fit the memory schema, referenced by path from project memories.
- `skills/brainvault/SKILL.md` — File Size Discipline now explicitly covers `MEMORY.md`
  itself: extract a dominant project's index entries into their own `{project}-solutions-index.md`
  once the file approaches ~150-200 lines.

## [0.3.0] — 2026-08-20

### Added
- `skills/brainvault/SKILL.md` — new "File Size Discipline" convention: files should stay small and
  topic-atomic (~100-150 lines guideline); project memories stay a compact overview with detail
  pushed into linked Solution Memories; Solution memories are one file per solution, never a running
  log. Large existing files cost tokens on every read regardless of task relevance.
- `CLAUDE.md.template` — condensed version of the same rule.

## [0.2.0] — 2026-06-17

### Added
- `skills/brainvault-setup/SKILL.md` — `/brainvault-setup [path]` skill: auto-detects Obsidian vault,
  runs `init-or-update-vault.sh`, configures `~/.claude/settings.json` permissions (no more prompts
  for vault file operations), and writes/appends `CLAUDE.md` config in one step.
  Safe to re-run (idempotent); replaces the manual shell-command setup flow.

### Changed
- `README.md` — Step 2 and 3 of Installation now show `/brainvault-setup` as the primary flow;
  manual shell commands moved to a collapsible alternative.
- `plugin.json` / `marketplace.json` — version bumped to `0.2.0`.

---

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
