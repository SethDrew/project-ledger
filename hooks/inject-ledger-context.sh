#!/usr/bin/env bash
# Hook: UserPromptSubmit — inject relevant ledger entries as context.
# Reads {"prompt": "..."} from stdin, searches the ledger, prints results to stdout.
#
# Setup:
#   1. Update VENV_PYTHON to point to your project's venv
#   2. Update SEARCH_SCRIPT to point to your search_ledger.py
#   3. Register in .claude/settings.local.json (see README)

set -euo pipefail

# ── Customize these paths ──
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_PYTHON="$PROJECT_ROOT/venv/bin/python"
SEARCH_SCRIPT="$PROJECT_ROOT/tools/search_ledger.py"

# Read stdin (hook provides JSON with prompt)
INPUT=$(cat)

# Extract prompt text — try jq first, fall back to python
if command -v jq &>/dev/null; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || true)
else
    PROMPT=""
fi

if [ -z "$PROMPT" ]; then
    PROMPT=$("$VENV_PYTHON" -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get('prompt', ''))
except Exception:
    pass
" <<< "$INPUT" 2>/dev/null || true)
fi

if [ -z "$PROMPT" ]; then
    exit 0
fi

# Fast gate: skip search for short follow-ups.
# Only run TF-IDF search when the prompt looks substantive.
WORD_COUNT=$(echo "$PROMPT" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 25 ]; then
    # Short message — check for implementation keywords before skipping
    # ── Customize this keyword list for your domain ──
    if ! echo "$PROMPT" | grep -qiE '(build|implement|add|create|fix|design|write|refactor|debug|test|deploy|configure|optimize|update|change|modify)'; then
        exit 0
    fi
fi

# Run search
"$VENV_PYTHON" "$SEARCH_SCRIPT" "$PROMPT" 2>/dev/null || true

exit 0
