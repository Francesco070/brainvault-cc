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
