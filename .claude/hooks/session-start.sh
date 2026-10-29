#!/usr/bin/env bash
# SessionStart hook: make sure the malloyyo CLI is installed, then tell Claude
# what is and isn't set up. Prints only whether things are set, never values.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v malloyyo >/dev/null 2>&1; then
  npm install -g @malloydata/malloyyo >/dev/null 2>&1 || true
fi

echo "Malloyyo session status (from .claude/bin/malloyyo-doctor):"
.claude/bin/malloyyo-doctor
echo "If anything is MISSING or WARN, or the person asks to set up, use the start skill."
exit 0
