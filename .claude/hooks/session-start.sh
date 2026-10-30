#!/usr/bin/env bash
# SessionStart hook: make sure the malloyyo CLI is installed, then tell Claude
# what is and isn't set up. Prints only whether things are set, never values.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v malloyyo >/dev/null 2>&1; then
  npm install -g @malloydata/malloyyo >/dev/null 2>&1 || true
  installed_by_hook=1
fi

echo "Malloyyo session status (from .claude/bin/malloyyo-doctor):"
.claude/bin/malloyyo-doctor
if [ -n "${installed_by_hook:-}" ]; then
  echo "WARN malloyyo CLI was missing at session start and was installed by the hook (the environment has no setup script: README step 4)"
fi
echo "If anything is MISSING or WARN, or the person asks to set up, use the start skill."
exit 0
