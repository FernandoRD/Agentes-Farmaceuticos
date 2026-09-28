# Pharmaceutical AI Agent Framework v1

Framework de governança e roteamento de agentes de IA para engenharia e desenvolvimento no setor farmacêutico magistral, industrial e clínico. A v1 estabelece critérios objetivos para que o agente principal classifique cada solicitação, estime complexidade e risco sanitário/farmacotécnico e delegue cada unidade ao menor agente capaz de executá-la com segurança.

O repositório distribui uma implementação nativa para **Codex** e adaptações por projeto para **Gemini CLI (Google Antigravity)**, **Claude Code** e **Cursor**, incorporando as regulamentações sanitárias brasileiras (**ANVISA RDC 67/2007**, **Portaria SVS/MS nº 344/98**, **Farmacopeia Brasileira 6ª Edição** e resoluções do **CFF** e **CFM**).

```mermaid
flowchart TD
    Req[Demanda Farmacêutica / Prescrição] --> Class{Classificação}
    Class -->|Trivial: Conversão simples, ajuste cosmético, sem risco| Direct[Execução Direta pelo Principal]
    Class -->|Não Trivial: Multi-ativo, estéreis, hormônios, portaria 344| Scoring[Matriz de Risco 0-100 + Pisos Sanitários]
    Scoring --> FloorCheck{Atinge Piso Farmacêutico?}
    FloorCheck -->|Sim: Alta potência, Estéreis, Hormônios, BUD crítico| ProTier[Tier Pro: pro-worker / pro-reviewer]
    FloorCheck -->|Não: Busca bibliográfica, POP padrão, diluição| FlashTier[Tier Flash: flash-explorer / flash-worker]
    FlashTier --> Dispatch[Despacho Paralelo com Escopos Disjuntos]
    ProTier --> Dispatch
    Dispatch --> Review[Revisão Farmacêutica Independente Obrigatória]
    Review --> Publish[Registro / Publicação Isolada com Menor Worker]
    Publish --> FinalRep[Relatório de Conformidade e Modelos]
```

## Pacotes Disponíveis

| Pacote | Plataforma | Instalação Suportada | Mapeamento de Modelos |
| --- | --- | --- | --- |
| [gemini-cli-global-framework-v1](gemini-cli-global-framework-v1/) | Gemini CLI / Antigravity | Por projeto ou Global ($HOME) | Flash e Pro |
| [claude-code-global-framework-v1](claude-code-global-framework-v1/) | Claude Code | Por projeto ou Global ($HOME) | Haiku, Sonnet e Opus |
| [cursor-global-framework-v1](cursor-global-framework-v1/) | Cursor | Por projeto ou Global ($HOME) | Composer, Sonnet e Opus |
| [codex-global-framework-v1](codex-global-framework-v1/) | Codex | Global (padrão) ou Por projeto | Luna, Terra e Sol |

Os arquivos `.zip` na raiz do projeto (`gemini-cli-global-framework-v1.zip`, `claude-code-global-framework-v1.zip`, etc.) contêm as mesmas distribuições prontas para transporte e extração rápida.

## Especialistas Farmacêuticos Opcionais

O repositório fornece especialistas de domínio farmacêutico opcionais, empacotados como Skills modulares (arquitetura padrão de 7 arquivos):

1. **`pd-farmacotecnico-specialist` (Desenvolvimento Farmacotécnico e P&D Magistral)**:
   - Assistente sênior de IA parceira da farmacêutica Responsável Técnica (RT).
   - Avaliação físico-química (pKa, solubilidade, pH de estabilidade, polimorfismo, degradação).
   - Cálculos magistrais críticos: fator de correção ($F_{cor}$), equivalência sal/base, densidade aparente e escolha de cápsulas sem sobrequantidade arbitrária.
   - Resposta estruturada obrigatória em **8 seções** (Objetivo, Viabilidade, Proposta, Processo, Testes/Controles, Embalagem/Estabilidade, Conclusão, Referências).
   - Diferenciação epistemológica estrita: (1) Confirmado por fonte oficial; (2) Inferência farmacotécnica fundamentada; (3) Hipótese que exige teste de bancada; (4) Dado desconhecido.

2. **`visitacao-medica-specialist` (Especialista Sênior em Visitação Médica Magistral)**:
   - Propaganda médica e relacionamento técnico de alto nível com prescritores (endocrinologia, nutrologia, dermatologia, psiquiatria, etc.).
   - Racional clínico baseado em evidências (PubMed/SciELO, DOI, PMID).
   - Formas farmacêuticas diferenciadas (géis transdérmicos, filmes orodispersíveis, gomas, pastilhas sublinguais).
   - Protocolo estruturado de visita em **4 fases**: Pre-call (planejamento), Abordagem/Abertura (pitch de 30s + pergunta investigativa), Apresentação de Soluções e Fechamento/Next Steps (sem pressão, respeitando a livre escolha do paciente).
   - Módulo de contorno de objeções científicas e simulação interativa de **Roleplay**.

3. **`inteligencia-dados-visitacao-specialist` (Inteligência de Dados de Visitação Médica — BS Pharma)**:
   - Converte dados do Manda Visita em diagnóstico, oportunidade, prioridade e plano de ação comercial.
   - Analisa visitação, orçamentos, conversão, cobertura, território, tendência, churn e reativação sem inventar causas ou causalidade.
   - Inclui radar diário e matrizes Demanda × Conversão e Frequência × Resultado.

## Como Instalar

Os instaladores são 100% nativos em Shell Script (`.sh`, `.fish`) e PowerShell (`.ps1`), sem dependência externa:

### Instalação por Projeto (Claude Code):
```bash
./scripts/install.sh --target "/caminho/da/farmacia" --with-pd-farmacotecnico-specialist --apply
```

### Instalação Global no $HOME:
```bash
./scripts/install.sh --global --with-pd-farmacotecnico-specialist --apply
```

No Windows (PowerShell):
```powershell
.\scripts\install.ps1 -Target "C:\Caminho\Da\Farmacia" -WithPdFarmacotecnicoSpecialist -Apply
```

## Validação e Conformidade
Execute a suíte de testes de regressão offline:
```bash
./scripts/test_install.sh
```
