#!/usr/bin/env bash
set -euo pipefail

# Pure Bash uninstaller for Codex Global Framework v1
# No interpreter dependency.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
HOME_DIR="$(cd "$HOME" && pwd -P)"

CODEX_HOME="${CODEX_HOME:-$HOME_DIR/.codex}"
SKILLS_HOME="${SKILLS_HOME:-$HOME_DIR/.agents/skills}"

while [ $# -gt 0 ]; do
    case "$1" in
        --codex-home)
            [ $# -ge 2 ] || { echo "Uso: $0 [--codex-home <dir>] [--skills-home <dir>]" >&2; exit 1; }
            CODEX_HOME="$2"
            shift 2
            ;;
        --skills-home)
            [ $# -ge 2 ] || { echo "Uso: $0 [--codex-home <dir>] [--skills-home <dir>]" >&2; exit 1; }
            SKILLS_HOME="$2"
            shift 2
            ;;
        *)
            echo "Opção desconhecida: $1" >&2
            exit 1
            ;;
    esac
done

CODEX_HOME="${CODEX_HOME/#\~/$HOME_DIR}"
SKILLS_HOME="${SKILLS_HOME/#\~/$HOME_DIR}"

ROLES=(
    "luna_explorer" "luna_worker" "terra_worker"
    "terra_reviewer" "sol_specialist" "sol_reviewer" "sol_critical"
)

SKILLS=("security-review" "code-review" "dependency-review" "documentation")

agents_file="$CODEX_HOME/AGENTS.md"
config_file="$CODEX_HOME/config.toml"
hooks_file="$CODEX_HOME/hooks.json"
prepared_hooks=""

cleanup_prepared_hooks() {
    [ -z "$prepared_hooks" ] || rm -f "$prepared_hooks"
}
trap cleanup_prepared_hooks EXIT

prepare_hooks_uninstall() {
    local output
    output="$(mktemp "${TMPDIR:-/tmp}/codex-framework-hooks.XXXXXX")" || return 1
    if ! jq '
      def router_hook:
        (.type? == "command") and
        (((.command? // "") | contains("mandatory-router")) or
         ((.commandWindows? // "") | contains("mandatory-router")));
      if type != "object" then error("hooks.json must be an object") else . end |
      .hooks //= {} |
      if (.hooks | type) != "object" then error("hooks must be an object") else . end |
      .hooks.UserPromptSubmit //= [] |
      if (.hooks.UserPromptSubmit | type) != "array" then error("UserPromptSubmit must be an array") else . end |
      .hooks.UserPromptSubmit |= (
        map(if (.hooks? | type) == "array" then .hooks |= map(select(router_hook | not)) else . end) |
        map(select((.hooks? | type) != "array" or (.hooks | length) > 0))
      )
    ' "$hooks_file" > "$output"; then
        rm -f "$output"
        return 1
    fi
    prepared_hooks="$output"
}

# Validate and prepare every existing hooks.json before moving or deleting
# anything, including documents that do not currently contain mandatory-router.
if [ -f "$hooks_file" ]; then
    if ! command -v jq >/dev/null 2>&1; then
        echo "Erro: hooks.json existente requer jq para preservar hooks durante a desinstalação." >&2
        echo "Instale jq e execute novamente; nenhuma alteração foi aplicada." >&2
        exit 1
    fi
    if ! prepare_hooks_uninstall; then
        echo "Erro: hooks.json inválido ou não pôde ser transformado; nenhuma alteração foi aplicada." >&2
        exit 1
    fi
fi

# All preflight checks passed; backup creation is the first filesystem mutation.
timestamp="$(date +%Y%m%d-%H%M%S-%N | cut -b1-21)"
backup_dir="$CODEX_HOME/backups/framework-v1-uninstall-$timestamp"
mkdir -p "$backup_dir"

for f in "$agents_file" "$config_file" "$hooks_file"; do
    if [ -f "$f" ]; then
        cp "$f" "$backup_dir/$(basename "$f")"
    fi
done

if [ -f "$agents_file" ]; then
    cleaned="$(awk '
        /<!-- CODEX-GLOBAL-FRAMEWORK:BEGIN v1/ { in_block=1; next }
        /<!-- CODEX-GLOBAL-FRAMEWORK:END v1/ { in_block=0; next }
        !in_block { print }
    ' "$agents_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
    if [ -n "$cleaned" ]; then
        printf "%s\n" "$cleaned" > "$agents_file"
    else
        > "$agents_file"
    fi
fi

if [ -f "$config_file" ]; then
    cleaned="$(awk '
        /# BEGIN CODEX GLOBAL FRAMEWORK V1 AGENTS/ { in_block=1; next }
        /# END CODEX GLOBAL FRAMEWORK V1 AGENTS/ { in_block=0; next }
        !in_block { print }
    ' "$config_file" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"
    if [ -n "$cleaned" ]; then
        printf "%s\n" "$cleaned" > "$config_file"
    else
        > "$config_file"
    fi
fi

for r in "${ROLES[@]}"; do
    layer="$CODEX_HOME/agent-configs/$r.toml"
    if [ -f "$layer" ]; then
        mkdir -p "$backup_dir/agent-configs"
        mv "$layer" "$backup_dir/agent-configs/$r.toml"
    fi
done

for s in "${SKILLS[@]}"; do
    skill_dir="$SKILLS_HOME/$s"
    if [ -d "$skill_dir" ]; then
        mkdir -p "$backup_dir/skills"
        mv "$skill_dir" "$backup_dir/skills/$s"
    fi
done

if [ -f "$hooks_file" ]; then
    mv "$prepared_hooks" "$hooks_file"
    prepared_hooks=""
fi

for h in "$CODEX_HOME/hooks/mandatory-router.sh" "$CODEX_HOME/hooks/mandatory-router.ps1"; do
    if [ -f "$h" ]; then
        rm -f "$h"
    fi
done

echo "Framework v1 removed. Backup: $backup_dir"
