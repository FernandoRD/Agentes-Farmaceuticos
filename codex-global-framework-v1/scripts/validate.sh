#!/usr/bin/env bash
# Offline package validation using Bash and standard POSIX utilities.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
errors=0
fail() { printf 'FAIL: %s\n' "$*" >&2; errors=$((errors + 1)); }
check() { "$@" || fail "$*"; }
sha256() { sha256sum "$1" 2>/dev/null || shasum -a 256 "$1"; }

[ "$(tr -d '[:space:]' < "$root/VERSION")" = '1.0.0' ] || fail 'unexpected VERSION'
grep -q 'CODEX-GLOBAL-FRAMEWORK:BEGIN v1' "$root/.codex/AGENTS.md" || fail 'v1 AGENTS marker missing'
weights="$(awk -F'|' '/^\|/ && $3 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ { gsub(/[[:space:]]/, "", $3); total += $3; count++ } END { if (count >= 12) print total }' "$root/.codex/AGENTS.md")"
[ "$weights" = '100' ] || fail 'routing weights do not sum to 100'

while IFS='|' read -r role model effort sandbox; do
    file="$root/.codex/agent-configs/$role.toml"
    [ -f "$file" ] || { fail "missing layer $role"; continue; }
    grep -Fqx "model = \"$model\"" "$file" || fail "wrong model for $role"
    grep -Fqx "model_reasoning_effort = \"$effort\"" "$file" || fail "wrong reasoning effort for $role"
    grep -Fqx "sandbox_mode = \"$sandbox\"" "$file" || fail "wrong sandbox for $role"
    grep -q '^developer_instructions[[:space:]]*=' "$file" || fail "missing instructions for $role"
    ! grep -Eq '^(name|description)[[:space:]]*=' "$file" || fail "standalone-only fields in $role"
done <<'EOF'
luna_explorer|gpt-5.6-luna|medium|read-only
luna_worker|gpt-5.6-luna|low|workspace-write
terra_worker|gpt-5.6-terra|medium|workspace-write
terra_reviewer|gpt-5.6-terra|high|read-only
sol_specialist|gpt-5.6-sol|high|workspace-write
sol_reviewer|gpt-5.6-sol|xhigh|read-only
sol_critical|gpt-5.6-sol|max|read-only
EOF

for name in security-review code-review dependency-review documentation; do
    skill="$root/.agents/skills/$name/SKILL.md"
    meta="$root/.agents/skills/$name/agents/openai.yaml"
    [ -f "$skill" ] || fail "missing Skill $name"
    [ -f "$meta" ] || fail "missing Skill metadata $name"
    grep -Eq "^name:[[:space:]]*$name[[:space:]]*$" "$skill" || fail "invalid Skill $name"
    grep -Fq "\$$name" "$meta" || fail "invalid metadata $name"
    grep -Fq 'allow_implicit_invocation: true' "$meta" || fail "implicit invocation disabled for $name"
done
[ "$(find "$root/.agents/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 4 ] || fail 'unexpected Skills'

for spec in pd-farmacotecnico-specialist visitacao-medica-specialist inteligencia-dados-visitacao-specialist; do
    [ -f "$root/optional/$spec/.agents/skills/$spec/SKILL.md" ] || fail "optional $spec skill missing"
    [ -z "$(find "$root/optional/$spec/.codex/agents" -name '*.toml' -print -quit 2>/dev/null)" ] || fail "optional $spec ships native agents"
done

project_dir="$(mktemp -d)"
trap 'rm -rf "$project_dir"' EXIT
mkdir "$project_dir/project"
if ! "$root/scripts/install.sh" --target "$project_dir/project" --with-all-specialists --apply >/dev/null; then
    fail 'project installation with all specialists failed'
else
    for spec in pd-farmacotecnico-specialist visitacao-medica-specialist inteligencia-dados-visitacao-specialist; do
        [ -f "$project_dir/project/.agents/skills/$spec/SKILL.md" ] || fail "project optional $spec skill missing"
    done
    [ ! -e "$project_dir/project/SKILL.md" ] || fail 'project installation leaked optional SKILL.md to project root'
    [ "$(find "$project_dir/project/.agents/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 3 ] || fail 'project installation selected unexpected specialists'
fi

hook_output="$(sh "$root/.codex/hooks/mandatory-router.sh")" || fail 'hook execution failed'
printf '%s' "$hook_output" | grep -q 'hookSpecificOutput' || fail 'invalid hook output'
[ "${#hook_output}" -le 500 ] || fail 'hook output too long'

for script in install.sh diagnose.sh uninstall.sh validate.sh; do bash -n "$root/scripts/$script" || fail "bash syntax error in $script"; done
for script in install.fish diagnose.fish uninstall.fish; do
    [ -f "$root/scripts/$script" ] || fail "missing fish script $script"
    if command -v fish >/dev/null 2>&1; then fish -n "$root/scripts/$script" || fail "fish syntax error in $script"; fi
done

while IFS='  ' read -r digest relative; do
    [ -n "${relative:-}" ] || continue
    target="$root/$relative"
    [ -f "$target" ] || { fail "manifest target missing: $relative"; continue; }
    actual="$(sha256 "$target" | awk '{print $1}')"
    [ "$actual" = "$digest" ] || fail "manifest mismatch: $relative"
done < "$root/MANIFEST.sha256"

if [ "$errors" -gt 0 ]; then exit 1; fi
printf 'Validation OK: 7 registered agent layers, 4 Skills, weights=100\n'
