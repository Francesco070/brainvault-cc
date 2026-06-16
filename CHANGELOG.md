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
