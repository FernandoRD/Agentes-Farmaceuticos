<#
.SYNOPSIS
    Script de instalação do Pharmaceutical AI Agent Framework v1.
.DESCRIPTION
    Instala as políticas, agentes centrais e especialistas farmacêuticos.
    Por padrão executa em modo de auditoria. Use -Apply para efetivar.
.PARAMETER Target
    Caminho do diretório de destino da instalação.
.PARAMETER Global
    Realiza a instalação no perfil global.
.PARAMETER Apply
    Aplica as alterações no disco.
.PARAMETER WithPdFarmacotecnicoSpecialist
    Instala o especialista em P&D Farmacotécnico e Formulação Magistral.
.PARAMETER WithVisitacaoMedicaSpecialist
    Instala o especialista em Visitação Médica e Relacionamento Prescritor.
.PARAMETER WithInteligenciaDadosVisitacaoSpecialist
    Instala o especialista em Inteligência de Dados de Visitação Médica.
.PARAMETER WithAllSpecialists
    Instala todos os especialistas farmacêuticos disponíveis.
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$Target,

    [Alias("g")]
    [switch]$Global,

    [switch]$Apply,

    [Alias("with-pd-farmacotecnico-specialist", "with-farmacotecnica-specialist")]
    [switch]$WithPdFarmacotecnicoSpecialist,

    [Alias("with-visitacao-medica-specialist", "with-visitacao-specialist")]
    [switch]$WithVisitacaoMedicaSpecialist,

    [Alias("with-inteligencia-dados-visitacao-specialist", "with-inteligencia-dados-visitacao")]
    [switch]$WithInteligenciaDadosVisitacaoSpecialist,

    [Alias("with-all-specialists")]
    [switch]$WithAllSpecialists,

    [Alias("h")]
    [switch]$Help
)

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 0
}

if (-not $Target -and -not $Global) {
    Write-Error "Informe o parâmetro -Target ou utilize -Global."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackageDir = Split-Path -Parent $ScriptDir

$OptionalSpecs = @()
if ($WithPdFarmacotecnicoSpecialist -or $WithAllSpecialists) {
    $OptionalSpecs += "pd-farmacotecnico-specialist"
}
if ($WithVisitacaoMedicaSpecialist -or $WithAllSpecialists) {
    $OptionalSpecs += "visitacao-medica-specialist"
}
if ($WithInteligenciaDadosVisitacaoSpecialist -or $WithAllSpecialists) {
    $OptionalSpecs += "inteligencia-dados-visitacao-specialist"
}

Write-Host "Iniciando instalação PowerShell do Pharmaceutical Framework v1..."
$targetPath = if ($Global) { if ($Target) { [IO.Path]::GetFullPath($Target) } else { [Environment]::GetFolderPath('UserProfile') } } else { [IO.Path]::GetFullPath($Target) }
if ($targetPath -eq [IO.Path]::GetPathRoot($targetPath)) { throw "Recusando instalar no caminho raiz." }
$payloadDirs = @((Join-Path $PackageDir 'payload'))
foreach ($spec in $OptionalSpecs) { $payloadDirs += Join-Path $PackageDir ("optional/$spec/payload") }
foreach ($dir in $payloadDirs) { if (-not (Test-Path -LiteralPath $dir -PathType Container)) { throw "Pacote opcional não encontrado: $dir" } }
$toolDir = (Get-ChildItem -LiteralPath $payloadDirs[0] -Force -Directory | Where-Object { $_.Name.StartsWith('.') } | Select-Object -First 1).Name
$plan = @()
foreach ($payload in $payloadDirs) {
    foreach ($source in Get-ChildItem -LiteralPath $payload -Recurse -File -Force) {
        $relative = $source.FullName.Substring($payload.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $destination = if ($Global -and -not $relative.StartsWith('.')) { Join-Path $targetPath (Join-Path $toolDir $relative) } else { Join-Path $targetPath $relative }
        if (Test-Path -LiteralPath $destination) {
            if ((Get-Item -LiteralPath $destination).PSIsContainer -or (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) { throw "Conflito, preservar e mesclar manualmente: $destination" }
        } else { $plan += @{ Source = $source.FullName; Destination = $destination } }
    }
}
$mode = if ($Apply) { "Modo de execução: APPLY" } else { "Modo de execução: AUDIT" }
Write-Host $mode
foreach ($spec in $OptionalSpecs) { Write-Host "Especialista selecionado: $spec" }
if (-not $Apply) { Write-Host "Auditoria: $($plan.Count) arquivo(s) novo(s); nenhuma alteração."; exit 0 }
foreach ($item in $plan) { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $item.Destination) | Out-Null; Copy-Item -LiteralPath $item.Source -Destination $item.Destination -ErrorAction Stop }
Write-Host "Concluído com sucesso."
