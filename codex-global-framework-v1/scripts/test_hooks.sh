#!/usr/bin/env bash
# Regression checks for hooks.json preservation and preflight atomicity.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
install="$root/scripts/install.sh"
uninstall="$root/scripts/uninstall.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

home="$tmp/installed"
mkdir -p "$home/codex" "$home/skills"
printf '%s\n' '{"hooks":{"UserPromptSubmit":[{"name":"mixed","hooks":[{"type":"command","command":"echo before"},{"type":"command","command":"sh mandatory-router"},{"type":"command","command":"echo after"}]},{"name":"other","hooks":[{"type":"command","command":"echo other"}]}]}}' > "$home/codex/hooks.json"
"$install" --global --codex-home "$home/codex" --skills-home "$home/skills" >/dev/null
jq -e '[.hooks.UserPromptSubmit[].hooks[].command] as $commands | (($commands | index("echo before")) != null) and (($commands | index("echo after")) != null) and (($commands | index("echo other")) != null) and ([$commands[] | select(contains("mandatory-router"))] | length == 1)' "$home/codex/hooks.json" >/dev/null || fail 'install removed unrelated hooks'
"$uninstall" --codex-home "$home/codex" --skills-home "$home/skills" >/dev/null
jq -e '[.hooks.UserPromptSubmit[].hooks[].command] as $commands | (($commands | index("echo before")) != null) and (($commands | index("echo after")) != null) and (($commands | index("echo other")) != null) and ([$commands[] | select(contains("mandatory-router"))] | length == 0)' "$home/codex/hooks.json" >/dev/null || fail 'uninstall removed unrelated hooks'

invalid="$tmp/invalid"
mkdir -p "$invalid/codex" "$invalid/skills" "$invalid/temp"
printf 'personal instructions\n' > "$invalid/codex/AGENTS.md"
printf '{ invalid json\n' > "$invalid/codex/hooks.json"
if TMPDIR="$invalid/temp" "$install" --global --codex-home "$invalid/codex" --skills-home "$invalid/skills" >/dev/null 2>&1; then fail 'install accepted invalid hooks.json'; fi
grep -qx 'personal instructions' "$invalid/codex/AGENTS.md" || fail 'install changed AGENTS after invalid JSON'
grep -qx '{ invalid json' "$invalid/codex/hooks.json" || fail 'install changed invalid hooks.json'
[ -z "$(find "$invalid/temp" -type f -print -quit)" ] || fail 'install left a temporary hooks file'
if TMPDIR="$invalid/temp" "$uninstall" --codex-home "$invalid/codex" --skills-home "$invalid/skills" >/dev/null 2>&1; then fail 'uninstall accepted invalid hooks.json'; fi
grep -qx 'personal instructions' "$invalid/codex/AGENTS.md" || fail 'uninstall changed AGENTS after invalid JSON'
[ ! -e "$invalid/codex/backups" ] || fail 'invalid JSON failure created uninstall backup'

nojq="$tmp/nojq"
mkdir -p "$nojq/codex" "$nojq/skills"
printf '%s\n' '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"echo user"}]}]}}' > "$nojq/codex/hooks.json"
if /usr/bin/bash -c 'command() { if [ "$1" = "-v" ] && [ "${2:-}" = "jq" ]; then return 1; fi; builtin command "$@"; }; export -f command; exec /usr/bin/bash "$@"' -- "$uninstall" --codex-home "$nojq/codex" --skills-home "$nojq/skills" >/dev/null 2>&1; then fail 'uninstall accepted existing hooks.json without jq'; fi
[ -f "$nojq/codex/hooks.json" ] || fail 'uninstall changed hooks without jq'
[ ! -e "$nojq/codex/backups" ] || fail 'no-jq failure created uninstall backup'

printf 'OK: hooks preservation and atomic preflight\n'
