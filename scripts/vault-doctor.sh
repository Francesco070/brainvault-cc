#!/usr/bin/env bash
# BrainVault doctor — checks vault health, fixes what's safe, reports the rest.
#
# Usage:
#   ./scripts/vault-doctor.sh --vault /path/to/Vault/Memories           # report only
#   ./scripts/vault-doctor.sh --vault /path/to/Vault/Memories --fix     # + safe auto-fixes
#
# Design: never destructive. --fix only creates missing structure (folders,
# MEMORY.md/HISTORY.md skeletons, .brainvault-version) — it never edits,
# merges, splits or deletes existing memory content. Everything that needs
# judgment (broken frontmatter, duplicate slugs, oversized files, broken
# links, unindexed files) is reported only, for a human or Claude to fix
# with the brainvault-doctor skill. If --fix will touch anything, the whole
# vault is copied into a timestamped backup first.

set -uo pipefail

PLUGIN_VERSION="0.5.0"
TYPES="user project reference feedback solutions agents"

VAULT_PATH=""
DO_FIX=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT_PATH="$2"; shift 2 ;;
    --fix) DO_FIX=true; shift ;;
    *) echo "Unknown argument: $1"; echo "Usage: $0 --vault <path> [--fix]"; exit 1 ;;
  esac
done

if [ -z "$VAULT_PATH" ]; then
  echo "Error: --vault <path> is required."
  exit 1
fi

if [ ! -d "$VAULT_PATH" ]; then
  echo "Error: vault path does not exist: $VAULT_PATH"
  exit 1
fi

# shellcheck disable=SC2034
ERRORS=0
WARNINGS=0
FIXES_APPLIED=0
PENDING_FIXES=()

note_error()   { echo "  [ERROR]   $1"; ERRORS=$((ERRORS + 1)); }
note_warn()    { echo "  [WARN]    $1"; WARNINGS=$((WARNINGS + 1)); }
note_info()    { echo "  [INFO]    $1"; }
note_fixable() { PENDING_FIXES+=("$1"); }

echo "=== BrainVault Doctor ==="
echo "Vault: $VAULT_PATH"
echo "Mode:  $([ "$DO_FIX" = true ] && echo 'report + safe fixes' || echo 'report only')"
echo ""

# --- 1. Structure ---
echo "--- Structure ---"
for t in $TYPES history; do
  if [ ! -d "$VAULT_PATH/$t" ]; then
    note_error "Missing folder: $t/"
    note_fixable "mkdir:$t"
  fi
done
[ -f "$VAULT_PATH/MEMORY.md" ]  || { note_error "Missing MEMORY.md"; note_fixable "memory_md"; }
[ -f "$VAULT_PATH/HISTORY.md" ] || { note_error "Missing HISTORY.md"; note_fixable "history_md"; }
if [ ! -f "$VAULT_PATH/.brainvault-version" ]; then
  note_warn "Missing .brainvault-version (vault predates version tracking, or was never initialised by brainvault-cc)"
  note_fixable "version_file"
fi
echo ""

# --- 2. MEMORY.md size (File Size Discipline applies to the index too) ---
if [ -f "$VAULT_PATH/MEMORY.md" ]; then
  LINES=$(wc -l < "$VAULT_PATH/MEMORY.md" | tr -d ' ')
  echo "--- MEMORY.md size: $LINES lines ---"
  if [ "$LINES" -gt 200 ]; then
    note_error "MEMORY.md has $LINES lines (session-start read limit is ~200) — extract a dominant section into its own {topic}-index.md now"
  elif [ "$LINES" -gt 150 ]; then
    note_warn "MEMORY.md has $LINES lines, approaching the ~150-200 line guideline — consider extracting the largest section"
  fi
  echo ""
fi

# --- 3. Per-file checks in the five typed folders ---
echo "--- Frontmatter and content checks ---"
declare -A SEEN_NAMES  # name -> path, for duplicate detection
OVERSIZED=()
UNINDEXED=()

for t in $TYPES; do
  DIR="$VAULT_PATH/$t"
  [ -d "$DIR" ] || continue
  while IFS= read -r -d '' f; do
    REL="${f#"$VAULT_PATH"/}"
    BASENAME=$(basename "$f" .md)

    # TEMPLATE.md files are intentional copy-paste scaffolding, not real
    # memories — they use placeholder {slugs} on purpose. Skip all checks.
    if [ "$BASENAME" = "TEMPLATE" ]; then
      continue
    fi

    # Frontmatter presence
    if ! head -1 "$f" | grep -q '^---$'; then
      note_error "$REL: missing YAML frontmatter (no leading ---)"
      continue
    fi

    NAME=$(sed -n '2,/^---$/p' "$f" | grep -m1 '^name:' | sed 's/^name: *//' | tr -d '"' | tr -d "'")
    TYPE=$(sed -n '2,/^---$/p' "$f" | grep -m1 '^  type:' | sed 's/^  type: *//' | tr -d '"' | tr -d "'")

    [ -n "$NAME" ]  || note_error "$REL: frontmatter missing 'name:'"
    [ -n "$TYPE" ]  || note_error "$REL: frontmatter missing 'metadata.type:'"
    if [ -n "$NAME" ] && [ "$NAME" != "$BASENAME" ]; then
      note_warn "$REL: name '$NAME' does not match filename '$BASENAME'"
    fi
    if [ -n "$TYPE" ]; then
      EXPECTED_TYPE="$t"
      [ "$t" = "solutions" ] && EXPECTED_TYPE="solution"
      [ "$t" = "agents" ] && EXPECTED_TYPE="agent"
      if [ "$TYPE" != "$EXPECTED_TYPE" ]; then
        note_warn "$REL: metadata.type '$TYPE' does not match its folder ($t, expected '$EXPECTED_TYPE')"
      fi
    fi

    if [ -n "$NAME" ]; then
      if [ -n "${SEEN_NAMES[$NAME]:-}" ]; then
        note_error "Duplicate name '$NAME': ${SEEN_NAMES[$NAME]} and $REL"
      else
        SEEN_NAMES["$NAME"]="$REL"
      fi
    fi

    if [ "$t" = "feedback" ] || [ "$t" = "project" ]; then
      grep -q '\*\*Why:\*\*' "$f"           || note_warn "$REL: missing required '**Why:**' section"
      grep -q '\*\*How to apply:\*\*' "$f"  || note_warn "$REL: missing required '**How to apply:**' section"
    fi

    LC=$(wc -l < "$f" | tr -d ' ')
    if [ "$LC" -gt 150 ]; then
      OVERSIZED+=("$REL ($LC lines)")
    fi

    if [ -f "$VAULT_PATH/MEMORY.md" ] && ! grep -qF "$REL" "$VAULT_PATH/MEMORY.md"; then
      UNINDEXED+=("$REL")
    fi
  done < <(find "$DIR" -maxdepth 1 -name '*.md' -print0)
done
echo "  Checked $(( ${#SEEN_NAMES[@]} )) memory files with a valid 'name:' across $TYPES/"
echo ""

if [ ${#OVERSIZED[@]} -gt 0 ]; then
  echo "--- Files over the ~150-line File Size Discipline guideline (split candidates, report only) ---"
  for o in "${OVERSIZED[@]}"; do note_warn "$o"; done
  echo ""
fi

if [ ${#UNINDEXED[@]} -gt 0 ]; then
  echo "--- Files not referenced anywhere in MEMORY.md (report only — may be intentionally reached only via wikilink) ---"
  for u in "${UNINDEXED[@]}"; do note_info "$u"; done
  echo ""
fi

# --- 4. Broken links from MEMORY.md ---
if [ -f "$VAULT_PATH/MEMORY.md" ]; then
  echo "--- MEMORY.md link targets ---"
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in http*|https*) continue ;; esac
    if [ ! -f "$VAULT_PATH/$target" ]; then
      note_error "MEMORY.md links to missing file: $target"
    fi
  done < <(grep -oE '\]\([^)]+\.md\)' "$VAULT_PATH/MEMORY.md" | sed -E 's/^\]\(//; s/\)$//')
  echo ""
fi

# --- Apply safe fixes ---
if [ "$DO_FIX" = true ] && [ ${#PENDING_FIXES[@]} -gt 0 ]; then
  BACKUP_ROOT="$(dirname "$VAULT_PATH")/.brainvault-backups"
  BACKUP_DIR="$BACKUP_ROOT/$(date -u +%Y-%m-%dT%H%M%SZ)-doctor"
  mkdir -p "$BACKUP_DIR"
  cp -r "$VAULT_PATH" "$BACKUP_DIR/Memories"
  echo "--- Backup before fixing: $BACKUP_DIR ---"
  echo ""

  echo "--- Applying safe fixes ---"
  for fix in "${PENDING_FIXES[@]}"; do
    case "$fix" in
      mkdir:*)
        d="${fix#mkdir:}"
        mkdir -p "$VAULT_PATH/$d"
        echo "  created folder: $d/"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        ;;
      memory_md)
        cat > "$VAULT_PATH/MEMORY.md" <<'EOF'
# Memory Index

## User

## Feedback

## Project

## Solutions

## Reference
EOF
        echo "  created MEMORY.md skeleton"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        ;;
      history_md)
        cat > "$VAULT_PATH/HISTORY.md" <<'EOF'
# History Index

Each entry links to a daily change log for the memory system.
EOF
        echo "  created HISTORY.md skeleton"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        ;;
      version_file)
        LAST_MIGRATION=$(find "$(dirname "$0")/../migrations" -maxdepth 1 -name '[0-9]*.sh' 2>/dev/null | wc -l | tr -d ' ')
        cat > "$VAULT_PATH/.brainvault-version" <<EOF
plugin_version=$PLUGIN_VERSION
last_migration=${LAST_MIGRATION:-0}
updated=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
        echo "  created .brainvault-version"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
        ;;
    esac
  done
  echo ""
fi

# --- Summary ---
echo "=== Summary ==="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
if [ "$DO_FIX" = true ]; then
  echo "Fixes applied: $FIXES_APPLIED"
fi
if [ "$DO_FIX" = false ] && [ ${#PENDING_FIXES[@]} -gt 0 ]; then
  echo "Safe auto-fixes available — re-run with --fix to apply them (a backup is made first)."
fi
if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
  echo ""
  echo "Findings that are not auto-fixable (duplicate names, broken frontmatter,"
  echo "oversized files, broken MEMORY.md links) need judgment — use the"
  echo "brainvault-doctor skill or fix by hand. Nothing was deleted."
fi

exit 0
