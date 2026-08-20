#!/usr/bin/env bash
# Migration 0002 — Add agents/ folder and MEMORY.md Agents section
#
# What changes: creates $VAULT_PATH/agents/, and inserts a "## Agents" section
#   into MEMORY.md (before "## Reference" if present, else appended) if the
#   heading is not already there.
# Why: v0.5.0 adds a sixth memory type ("agent") to record which agent or
#   subagent was dispatched for which task, so a similar future problem can
#   find and reuse/clone the same agent/prompt instead of re-deriving it.
#
# Idempotency: mkdir -p; MEMORY.md insertion only happens if "## Agents" is
#   not already present.
# Backup: Not needed — this migration only creates a new folder and adds a
#   new section header to MEMORY.md, never overwrites existing content.

set -euo pipefail

VAULT_PATH="${1:?Usage: $0 <vault-path>}"

echo "[0002] Adding agents/ folder at: $VAULT_PATH"
mkdir -p "$VAULT_PATH/agents"
echo "[0002] Directory created."

if [ -f "$VAULT_PATH/MEMORY.md" ]; then
  if grep -q '^## Agents' "$VAULT_PATH/MEMORY.md"; then
    echo "[0002] MEMORY.md already has an Agents section — skipped."
  elif grep -q '^## Reference' "$VAULT_PATH/MEMORY.md"; then
    awk '
      /^## Reference/ && !done { print "## Agents\n"; done=1 }
      { print }
    ' "$VAULT_PATH/MEMORY.md" > "$VAULT_PATH/MEMORY.md.tmp"
    mv "$VAULT_PATH/MEMORY.md.tmp" "$VAULT_PATH/MEMORY.md"
    echo "[0002] Inserted '## Agents' section before '## Reference' in MEMORY.md."
  else
    printf '\n## Agents\n' >> "$VAULT_PATH/MEMORY.md"
    echo "[0002] Appended '## Agents' section to MEMORY.md."
  fi
else
  echo "[0002] MEMORY.md not found — skipped (created by migration 0001 if it runs first)."
fi

echo "[0002] Done."
