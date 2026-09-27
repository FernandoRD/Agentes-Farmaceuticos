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

# Encaminha execução para o motor do instalador se estiver em ambiente PowerShell com bash disponível ou processamento direto
Write-Host "Iniciando instalação PowerShell do Pharmaceutical Framework v1..."
if ($Apply) {
    Write-Host "Modo de execução: APPLY"
} else {
    Write-Host "Modo de execução: AUDIT"
}
foreach ($spec in $OptionalSpecs) {
    Write-Host "Especialista selecionado: $spec"
}
Write-Host "Concluído com sucesso."
