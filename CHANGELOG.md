# Changelog

All notable changes to brainvault-cc are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

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
