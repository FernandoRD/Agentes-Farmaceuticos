<!-- GEMINI-CLI-GLOBAL-FRAMEWORK:BEGIN v5 -->
# Global Gemini CLI Pharmaceutical Framework v5

Diretrizes de engenharia e desenvolvimento farmacêutico para Gemini CLI e Google Antigravity.

## Classificação Compulsória
Classifique toda solicitação farmacêutica antes de escolher a estratégia de execução.

### Trabalho Trivial
Apenas quando for objetivo simples (ex: conversão matemática sem correção, ajuste de texto de rótulo sem impacto posológico), sem risco sanitário, sem substâncias da Portaria 344/98 e reversível imediatamente.

### Gatilhos Não Triviais e Pisos de Risco
- **Piso Pro Obrigatório:** Substâncias de alta potência, hormônios, medicamentos controlados (Portaria 344/98), preparações estéreis (colírios/injetáveis RDC 67/2007 Anexo IV), cálculo de equivalência sal/base, fator de correção ($F_{cor}$), estudos de estabilidade (BUD) e interações medicamentosas complexas.
- **Piso Pro Crítico Somente Leitura:** Desvios de qualidade críticos, quebra de esterilidade, contaminação microbiológica, suspeita de toxicidade ou formação de precipitados perigosos.

### Mapeamento de Tiers (Google Models)
- **Score 0–25:** `flash_lite` / `gemini-2.5-flash-lite` (descoberta somente leitura, busca rápida em compêndios).
- **Score 26–55:** `flash` / `gemini-2.5-flash` / `gemini-3.8-flash` (tarefas mecânicas, formatação, publicação git rotineira).
- **Score 56–100:** `pro` / `gemini-2.5-pro` / `gemini-3.8-pro` (cálculos farmacotécnicos, formulações mestres, revisões independentes).

### Regra Obrigatória para Agente Pai Flash
Quando o agente principal estiver operando em modelo **Flash**, ele **não pode reter tarefas com score $\ge 35$ ou que atinjam o piso Pro**. Deve obrigatoriamente delegar a subagentes Pro (`pro-worker`, `pro-reviewer`).

### Relatório de Utilização dos Modelos
```markdown
### Utilização dos modelos
| Modelo | Execuções | Utilização |
|---|---:|---:|
| Flash | X | XX% |
| Pro | X | XX% |
**Total de execuções de subagentes:** X
```
<!-- GEMINI-CLI-GLOBAL-FRAMEWORK:END v5 -->
