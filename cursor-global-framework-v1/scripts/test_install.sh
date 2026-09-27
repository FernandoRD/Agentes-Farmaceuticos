#!/usr/bin/env bash
# Offline regression checks for the native Bash installer. No external test framework.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
package_dir="$(cd "$script_dir/.." && pwd -P)"
installer="$script_dir/install.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
tool_dir() { find "$1" -maxdepth 1 -type d \( -name '.gemini' -o -name '.claude' -o -name '.cursor' \) -print -quit; }
run() { local target="$1"; shift; bash "$installer" --target "$target" "$@"; }

target="$tmp/base"
run "$target" >/dev/null
[ ! -e "$target" ] || fail 'audit mode created target'
run "$target" --apply >/dev/null
dot="$(tool_dir "$target")"
[ -n "$dot" ] || fail 'tool directory was not installed'
[ ! -e "$dot/skills/pd-farmacotecnico-specialist/SKILL.md" ] || fail 'PD specialist is not opt-in'
[ ! -e "$dot/skills/visitacao-medica-specialist/SKILL.md" ] || fail 'visitation specialist is not opt-in'
while IFS= read -r -d '' source; do
    relative="${source#"$package_dir/payload/"}"
    cmp -s "$source" "$target/$relative" || fail "payload file differs: $relative"
done < <(find "$package_dir/payload" -type f -print0)
run "$target" --apply >/dev/null
run "$target" --with-pd-farmacotecnico-specialist --apply >/dev/null
[ -f "$dot/skills/pd-farmacotecnico-specialist/SKILL.md" ] || fail 'PD specialist was not installed'

visit="$tmp/visit"
run "$visit" --with-visitacao-medica-specialist --apply >/dev/null
dot_visit="$(tool_dir "$visit")"
[ -f "$dot_visit/skills/visitacao-medica-specialist/SKILL.md" ] || fail 'visitation specialist was not installed'
[ ! -e "$dot_visit/skills/pd-farmacotecnico-specialist/SKILL.md" ] || fail 'PD specialist was installed unexpectedly'

all="$tmp/all"
run "$all" --with-all-specialists --apply >/dev/null
dot="$(tool_dir "$all")"
for specialist in pd-farmacotecnico-specialist visitacao-medica-specialist; do
    [ -f "$dot/skills/$specialist/SKILL.md" ] || fail "$specialist was not installed"
done

conflict="$tmp/conflict"
run "$conflict" --apply >/dev/null
dot="$(tool_dir "$conflict")"
first="$(find "$package_dir/payload" -type f -print -quit)"
relative="${first#"$package_dir/payload/"}"
printf 'user content\n' > "$conflict/$relative"
missing="$(find "$package_dir/payload" -type f -print | sed -n '2p')"
missing_relative="${missing#"$package_dir/payload/"}"
rm "$conflict/$missing_relative"
if run "$conflict" --apply >/dev/null 2>&1; then fail 'conflicting user file was overwritten'; fi
grep -qx 'user content' "$conflict/$relative" || fail 'conflicting user file changed'
[ ! -e "$conflict/$missing_relative" ] || fail 'preflight wrote missing file despite conflict'

link="$tmp/link"
mkdir "$tmp/outside"
ln -s "$tmp/outside" "$link"
if run "$link" --apply >/dev/null 2>&1; then fail 'symlink target was accepted'; fi
[ -z "$(find "$tmp/outside" -mindepth 1 -print -quit)" ] || fail 'symlink target was modified'

printf 'OK: %s native Bash installer\n' "$(basename "$package_dir")"
