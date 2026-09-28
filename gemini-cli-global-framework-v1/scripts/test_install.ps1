<#!
.SYNOPSIS
Offline smoke test for the native PowerShell installer.
.NOTES
Requires PowerShell. It checks the Windows installer parameter and mode
contract; the Bash regression suite performs filesystem conflict and symlink
checks for the shared payload layout.
#>
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installer = Join-Path $scriptDir 'install.ps1'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ("pharmaceutical-framework-" + [guid]::NewGuid())
try {
    $result = & $installer -Target $temporary 2>&1
    if (-not $?) { throw "audit invocation failed: $result" }
    if ($result -notmatch 'AUDIT') { throw 'installer did not report AUDIT mode' }
    if (Test-Path -LiteralPath $temporary) { throw 'audit invocation created target' }
    $cases = @(
        @{ Switch = 'WithPdFarmacotecnicoSpecialist'; Skills = @('pd-farmacotecnico-specialist') },
        @{ Switch = 'WithVisitacaoMedicaSpecialist'; Skills = @('visitacao-medica-specialist') },
        @{ Switch = 'WithInteligenciaDadosVisitacaoSpecialist'; Skills = @('inteligencia-dados-visitacao-specialist') },
        @{ Switch = 'WithAllSpecialists'; Skills = @('pd-farmacotecnico-specialist', 'visitacao-medica-specialist', 'inteligencia-dados-visitacao-specialist') }
    )
    foreach ($case in $cases) {
        $argument = $case.Switch
        $parameters = @{ Target = $temporary; Apply = $true; $argument = $true }
        $result = & $installer @parameters 2>&1
        if (-not $?) { throw "apply invocation failed for ${argument}: $result" }
        if ($result -notmatch 'APPLY') { throw "installer did not report APPLY mode for $argument" }
        $tool = Get-ChildItem -LiteralPath $temporary -Directory -Force | Where-Object { $_.Name.StartsWith('.') } | Select-Object -First 1
        foreach ($skill in $case.Skills) { if (-not (Test-Path -LiteralPath (Join-Path $tool.FullName "skills/$skill/SKILL.md"))) { throw "optional skill was not installed: $skill" } }
    }
    Write-Output "OK: $(Split-Path -Leaf (Split-Path -Parent $scriptDir)) native PowerShell installer"
}
finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
