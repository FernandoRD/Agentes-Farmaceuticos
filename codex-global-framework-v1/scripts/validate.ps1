<#!
.SYNOPSIS
Offline PowerShell validation for the Codex package.
.NOTES
Uses PowerShell built-ins only. Fish parsing is not available on Windows.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$errors = [Collections.Generic.List[string]]::new()
function Check($condition, $message) { if (-not $condition) { $errors.Add($message) } }

Check ((Get-Content (Join-Path $root VERSION) -Raw).Trim() -eq '1.0.0') 'unexpected VERSION'
$agents = Get-Content (Join-Path $root '.codex/AGENTS.md') -Raw
Check ($agents.Contains('CODEX-GLOBAL-FRAMEWORK:BEGIN v1')) 'v1 AGENTS marker missing'
$weights = [regex]::Matches($agents, '(?m)^\|[^|]+\|\s*(\d+)\s*\|') | ForEach-Object { [int]$_.Groups[1].Value }
Check (($weights | Select-Object -First 12 | Measure-Object -Sum).Sum -eq 100) 'routing weights do not sum to 100'

$expected = @{
    luna_explorer=@('gpt-5.6-luna','medium','read-only'); luna_worker=@('gpt-5.6-luna','low','workspace-write');
    terra_worker=@('gpt-5.6-terra','medium','workspace-write'); terra_reviewer=@('gpt-5.6-terra','high','read-only');
    sol_specialist=@('gpt-5.6-sol','high','workspace-write'); sol_reviewer=@('gpt-5.6-sol','xhigh','read-only'); sol_critical=@('gpt-5.6-sol','max','read-only')
}
foreach ($role in $expected.Keys) {
    $path = Join-Path $root ".codex/agent-configs/$role.toml"; $content = if (Test-Path $path) { Get-Content $path -Raw } else { '' }
    Check (Test-Path $path) "missing layer $role"
    Check ($content -match "(?m)^model = `"$($expected[$role][0])`"$") "wrong model for $role"
    Check ($content -match "(?m)^model_reasoning_effort = `"$($expected[$role][1])`"$") "wrong reasoning effort for $role"
    Check ($content -match "(?m)^sandbox_mode = `"$($expected[$role][2])`"$") "wrong sandbox for $role"
    Check ($content -match '(?m)^developer_instructions\s*=') "missing instructions for $role"
}
foreach ($script in 'install.ps1','diagnose.ps1','uninstall.ps1','validate.ps1') { Check (Test-Path (Join-Path $root "scripts/$script")) "missing PowerShell script: $script" }
$projectRoot = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
try {
    $project = Join-Path $projectRoot 'project'
    New-Item -ItemType Directory -Path $project -Force | Out-Null
    & (Join-Path $root 'scripts/install.ps1') -Target $project -WithAllSpecialists -Apply | Out-Null
    foreach ($specialist in 'pd-farmacotecnico-specialist','visitacao-medica-specialist','inteligencia-dados-visitacao-specialist') {
        Check (Test-Path (Join-Path $project ".agents/skills/$specialist/SKILL.md")) "project optional $specialist skill missing"
    }
    Check (-not (Test-Path (Join-Path $project 'SKILL.md'))) 'project installation leaked optional SKILL.md to project root'
    $installed = @(Get-ChildItem (Join-Path $project '.agents/skills') -Directory -ErrorAction SilentlyContinue)
    Check ($installed.Count -eq 3) 'project installation selected unexpected specialists'
} catch {
    Check $false "project installation with all specialists failed: $($_.Exception.Message)"
} finally {
    if (Test-Path $projectRoot) { Remove-Item -LiteralPath $projectRoot -Recurse -Force }
}
Get-Content (Join-Path $root MANIFEST.sha256) | ForEach-Object {
    if ($_ -match '^([0-9a-f]{64})  (.+)$') { $target = Join-Path $root $matches[2]; Check (Test-Path $target) "manifest target missing: $($matches[2])"; if (Test-Path $target) { Check ((Get-FileHash $target -Algorithm SHA256).Hash.ToLower() -eq $matches[1]) "manifest mismatch: $($matches[2])" } }
}
if ($errors.Count) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output 'Validation OK: 7 registered agent layers, 4 Skills, weights=100'
