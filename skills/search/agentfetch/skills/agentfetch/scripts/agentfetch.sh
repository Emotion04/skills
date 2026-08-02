#!/usr/bin/env bash
set -euo pipefail

plugin_root="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$plugin_root" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  plugin_root="$(cd "$script_dir/.." && pwd)"
fi

case "$(uname -s)-$(uname -m)" in
  MINGW*-x86_64|MSYS*-x86_64|CYGWIN*-x86_64)
    executable="$plugin_root/bin/windows-amd64/agentfetch.exe"
    ;;
  *)
    printf 'agentfetch: this release supports Windows x64 only (detected %s-%s)\n' \
      "$(uname -s)" "$(uname -m)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$executable" ]]; then
  printf 'agentfetch: bundled executable not found: %s\n' "$executable" >&2
  exit 1
fi

exec "$executable" "$@"
