#!/usr/bin/env bash
# BrainVault init-or-update script
#
# Usage: ./scripts/init-or-update-vault.sh --vault /path/to/your/Vault/Memories
#
# Fresh install: creates full structure, writes .brainvault-version
# Update:        runs only migrations newer than current .brainvault-version

set -euo pipefail

PLUGIN_VERSION="0.5.0"
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

for migration in "$MIGRATIONS_DIR"/[0-9]*.sh; do
  [ -f "$migration" ] || continue
  MIGRATION_FILE=$(basename "$migration")
  # Extract the leading number: 0001-foo.sh -> 0001 -> 1
  MIGRATION_NUM=$(echo "$MIGRATION_FILE" | grep -oE '^[0-9]+' | sed 's/^0*//')
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
