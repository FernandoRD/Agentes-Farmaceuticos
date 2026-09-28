# Validação

Execute `./scripts/validate.sh` (Bash) ou `./scripts/validate.ps1` (PowerShell). A checagem de sintaxe Fish é executada apenas quando Fish estiver instalado.

As duas validações também executam uma instalação temporária por projeto com
`WithAllSpecialists` e confirmam que todos os três especialistas farmacêuticos
foram criados em `.agents/skills/`.

Quando já houver `hooks.json`, a instalação e a remoção do hook exigem `jq` para preservar os hooks existentes; sem ele, os scripts falham antes de alterar o ambiente.
