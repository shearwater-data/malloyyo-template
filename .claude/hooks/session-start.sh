#!/usr/bin/env bash
# SessionStart hook: make sure the malloyyo CLI is installed, then tell Claude
# what is and isn't set up. Prints only whether things are set, never values.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v malloyyo >/dev/null 2>&1; then
  npm install -g @malloydata/malloyyo >/dev/null 2>&1 || true
fi

echo "Malloyyo session status:"
if command -v malloyyo >/dev/null 2>&1; then
  echo "- malloyyo CLI: $(malloyyo --version 2>/dev/null)"
else
  echo "- malloyyo CLI: NOT installed (npm install -g @malloydata/malloyyo failed)"
fi

if [ -n "${MALLOYYO_URL:-}" ]; then
  echo "- MALLOYYO_URL: set ($MALLOYYO_URL)"
else
  echo "- MALLOYYO_URL: not set"
fi

if [ -f malloy-config.json ] && command -v jq >/dev/null 2>&1; then
  for name in $(jq -r '[.. | objects | select(has("env")) | .env] | unique[]' malloy-config.json); do
    if [ -z "${!name:-}" ]; then
      echo "- $name: not set"
    elif [[ "$name" == *_JSON ]] &&
         ! printf '%s' "${!name}" | jq -e . >/dev/null 2>&1 &&
         ! printf '%s' "${!name}" | base64 -d 2>/dev/null | jq -e . >/dev/null 2>&1; then
      echo "- $name: set, but not valid JSON or base64 JSON (line breaks in a pasted key get mangled; store it base64-encoded)"
    else
      echo "- $name: set"
    fi
  done
fi

if [ -f malloy-config-local.json ]; then
  echo "- malloy-config-local.json: present (it replaces malloy-config.json while building here)"
fi
if command -v gcloud >/dev/null 2>&1 &&
   gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "- Google sign-in: active"
else
  echo "- Google sign-in: none in this session"
fi
echo "Run the start skill (/start) to walk the person through anything missing."
exit 0
