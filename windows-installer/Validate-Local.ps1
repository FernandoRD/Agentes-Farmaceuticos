[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PharmaceuticalSource,
    [Parameter(Mandatory)] [string]$OptimizationsSource,
    [string]$OutputPath,
    [string]$InstallerVersion,
    [switch]$AllowNonTemporaryOutput
)

$ErrorActionPreference = 'Stop'
function Test-ChildPath([string]$Child, [string]$Parent) {
    $childPath = [IO.Path]::GetFullPath($Child).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $parentPath = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    return $childPath.StartsWith($parentPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

$createdTemporaryOutput = [string]::IsNullOrWhiteSpace($OutputPath)
$temporaryRoot = [IO.Path]::GetTempPath()
if ($createdTemporaryOutput) {
    $OutputPath = Join-Path $temporaryRoot ('framework-installer-validation-' + [guid]::NewGuid().ToString('N'))
} elseif (-not (Test-ChildPath $OutputPath $temporaryRoot) -and -not $AllowNonTemporaryOutput) {
    throw "Refusing to replace non-temporary OutputPath '$OutputPath'. Use -AllowNonTemporaryOutput only for an intentional staging directory."
}

$version = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION must use semantic versioning; found '$version'." }
if ([string]::IsNullOrWhiteSpace($InstallerVersion)) { $InstallerVersion = $version }
if ($InstallerVersion -ne $version) { throw "InstallerVersion '$InstallerVersion' must match VERSION '$version'." }
$issPath = Join-Path $PSScriptRoot 'UnifiedFrameworkInstaller.iss'
$iss = Get-Content -LiteralPath $issPath -Raw
if ($iss -notmatch '#ifndef InstallerVersion' -or $iss -notmatch '#define AppVersion InstallerVersion') {
    throw 'UnifiedFrameworkInstaller.iss must require InstallerVersion through ISPP.'
}

try {
    & (Join-Path $PSScriptRoot 'Prepare-Payload.ps1') -PharmaceuticalSource $PharmaceuticalSource -OptimizationsSource $OptimizationsSource -OutputPath $OutputPath
    $catalog = Join-Path $OutputPath 'catalog.ini'
    if (-not (Test-Path -LiteralPath $catalog)) { throw 'catalog.ini was not generated.' }
    foreach ($product in 'farmaceuticos', 'otimizacoes') {
        $platforms = (Get-Content -LiteralPath $catalog | Where-Object { $_ -eq "[product.$product]" })
        if (-not $platforms) { throw "Catalog does not contain product $product." }
    }
    $installers = @(Get-ChildItem -LiteralPath $OutputPath -Recurse -Filter install.ps1 -File)
    if ($installers.Count -ne 8) { throw "Expected eight Windows installers in staging; found $($installers.Count)." }
    foreach ($installer in $installers) {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($installer.FullName, [ref]$null, [ref]$errors)
        if ($errors.Count) { throw "PowerShell parse error in $($installer.FullName): $($errors[0].Message)" }
    }

    $isccPath = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Path
    if (-not $isccPath) {
        $programFilesX86 = ${env:ProgramFiles(x86)}
        if ($programFilesX86) {
            $candidate = Join-Path $programFilesX86 'Inno Setup 6\ISCC.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { $isccPath = $candidate }
        }
    }
    if ($isccPath) {
        $compileOutput = Join-Path $OutputPath 'inno-output'
        Push-Location $PSScriptRoot
        try {
            & $isccPath "/DInstallerVersion=$InstallerVersion" "/DPayloadDir=$OutputPath" "/O$compileOutput" $issPath
            if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE." }
        } finally {
            Pop-Location
        }
        Write-Host 'ISCC compilation passed.'
    } else {
        Write-Host 'ISCC not found; skipped executable compilation.'
    }
    Write-Host "Validation passed: version $version, eight packages, catalog $catalog"
} finally {
    if ($createdTemporaryOutput -and (Test-Path -LiteralPath $OutputPath)) {
        Remove-Item -LiteralPath $OutputPath -Recurse -Force
        Write-Host "Removed temporary validation payload: $OutputPath"
    }
}
