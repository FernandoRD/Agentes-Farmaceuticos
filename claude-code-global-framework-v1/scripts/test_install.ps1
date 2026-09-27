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
    if ($LASTEXITCODE -ne 0) { throw "audit invocation failed: $result" }
    if ($result -notmatch 'AUDIT') { throw 'installer did not report AUDIT mode' }
    if (Test-Path -LiteralPath $temporary) { throw 'audit invocation created target' }
    foreach ($argument in @('-WithPdFarmacotecnicoSpecialist', '-WithVisitacaoMedicaSpecialist', '-WithAllSpecialists')) {
        $result = & $installer -Target $temporary $argument -Apply 2>&1
        if ($LASTEXITCODE -ne 0) { throw "apply invocation failed for $argument: $result" }
        if ($result -notmatch 'APPLY') { throw "installer did not report APPLY mode for $argument" }
    }
    Write-Output "OK: $(Split-Path -Leaf (Split-Path -Parent $scriptDir)) native PowerShell installer"
}
finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
