# Referência Técnica — Pharmaceutical AI Agent Framework v1

## 1. Escopo e Objetivos no Domínio Farmacêutico

A versão 5 (v1) do framework estabelece governança rigorosa para agentes de inteligência artificial aplicados à manipulação magistral, farmácia clínica e tecnologia farmacêutica. O objetivo é assegurar eficácia terapêutica, estabilidade físico-química e estrita conformidade com a legislação sanitária brasileira (**RDC 67/2007**, **Portaria 344/98**, **RDC 87/2008**, **Farmacopeia Brasileira 6ª Edição**).

O agente atua exclusivamente como assistente técnico e suporte à tomada de decisão da farmacêutica Responsável Técnica (RT) e aos prescritores habilitados, nunca substituindo a avaliação profissional humana nem emitindo prescrições autônomas.

---

## 2. Fluxo de Decisão e Classificação

```text
demanda/prescrição → classificação trivial/não trivial → matriz de risco 0-100
                   → checagem de pisos sanitários obrigatórios
                   → execução direta ou delegação especializada (fan-out / fan-in)
                   → revisão farmacêutica independente obrigatória
                   → relatório final de conformidade e rastreabilidade
```

### Critérios de Tarefa Trivial
Uma solicitação é classificada como **trivial** exclusivamente se **todas** as condições forem cumpridas:
- Possui um único objetivo pontual e bem delimitado (ex: conversão direta de unidades mg para g, ajuste de formatação de ficha);
- Não envolve cálculo de equivalência sal/base ou correção de teor/umidade;
- Não altera formulação mestre, excipientes ou embalagem primária;
- O ativo não pertence a classes de alta potência, hormônios, estéreis ou lista da Portaria 344/98;
- A causa e o resultado esperado são conhecidos e determinísticos;
- Uma falha tem impacto puramente cosmético ou local;
- É imediatamente reversível com uma alteração mínima.

Qualquer dúvida ou ausência de dados converte compulsoriamente a tarefa para **não trivial**.

### Gatilhos Não Triviais Farmacêuticos Compulsórios
Classifica-se compulsoriamente como não trivial o trabalho que envolva:
- Formulação contendo múltiplos ativos com potencial de interação química, física ou biológica;
- Investigação de instabilidade, turvação, precipitação, separação de fases ou alteração organoléptica;
- Cálculos estequiométricos de equivalência sal/base ou fator de correção de teor e umidade;
- Seleção de adjuvantes farmacotécnicos (conservantes, antioxidantes, agentes de suspensão, tensoativos);
- Determinação de Beyond-Use Date (BUD / prazo de uso) e estudos de estabilidade;
- Medicamentos estéreis (colírios, injetáveis, soluções para irrigação);
- Substâncias de baixo índice terapêutico ou alta potência;
- Substâncias sob controle especial da Portaria 344/98;
- Formas farmacêuticas de liberação modificada, implantes ou transdérmicos;
- Pacientes pertencentes a grupos vulneráveis (pediatria, neonatologia, geriatria, gestantes, insuficiência renal/hepática);
- Objeções clínicas médicas complexas ou treinamento de visitação médica especializada.

---

## 3. Matriz de Pontuação de Complexidade e Risco (0-100)

| Fator de Avaliação Farmacêutica | Peso Máx | Descrição e Impacto |
| --- | ---: | --- |
| Escopo e tamanho da mudança | 10 | Quantidade de ativos, componentes e operações unitárias na preparação |
| Complexidade das Matérias-Primas | 8 | Ativos sintéticos, fitoterápicos complexos, peptídeos, adjuvantes críticos |
| Incerteza físico-química e de bancada | 10 | pKa, perfil de solubilidade, polimorfismo, vias de degradação hidrolítica/oxidativa |
| Impacto farmacotécnico e biodisponibilidade | 10 | Transposição de vias, sistemas transdérmicos, permeação cutânea |
| Segurança do paciente e risco sanitário | 12 | Toxicidade intrínseca, janela terapêutica estreita, dosagens críticas |
| Estabilidade, conservação e BUD | 10 | Degradação microbiológica e físico-química, prazo de uso magistral |
| Controle de qualidade e esterilidade | 8 | Ensaios de bancada, pH, densidade, teste de esterilidade e endotoxinas bacterianas |
| Infraestrutura e contenção necessária | 10 | Habilitação ANVISA (Anexos I a VI), fluxo laminar, pressão negativa |
| Irreversibilidade / Desvio de lote | 6 | Perda de matérias-primas nobres, descarte de lote ou recolhimento |
| Dificuldade analítica de validação | 6 | Métodos analíticos indicativos de estabilidade, cromatografia, dissolução |
| Compatibilidade de excipientes | 5 | Força iônica, incompatibilidades iônicas (cátion-ânion), pH de precipitação |
| Relação prescritor / visitação médica | 5 | Clareza de evidências clínicas, fundamentação bibliográfica (PubMed/CFF/CFM) |

### Mapeamento das Faixas de Roteamento
- **Score 0–34 (Tier Flash / Luna / Haiku):** Tarefas de busca rápida de monografias, leitura de certificados analíticos de fornecedores, formatação de laudos padrão e publicação de documentos.
- **Score 35–100 (Tier Pro / Terra / Sonnet / Sol / Opus):** Desenvolvimento farmacotécnico, cálculos de formulações, avaliação de compatibilidade, estabilidade e planejamento de visitação médica.

---

## 4. Pisos de Risco Farmacêuticos (Risk Floors)

Os pisos sanitários sobrepõem a nota numérica:

### Piso Pro / Terra (Mínimo Obrigatório):
1. **Substâncias de Alta Potência / Baixo Índice Terapêutico:** Levotiroxina, digoxina, varfarina, lítio, clonidina, carbamazepina, imunossupressores. Exige dupla checagem de pesagem e diluição geométrica prévia.
2. **Substâncias Controladas (Portaria SVS/MS nº 344/98):** Notificação de receita A, B1, B2, receita de controle especial C1 e C5. Exige registro em livro de receituário e controle rigoroso de perdas.
3. **Preparações Estéreis (RDC 67/2007 Anexo IV):** Injetáveis, oftálmicos e soluções estéreis. Obrigatoriedade de manipulação em cabine de fluxo laminar ISO 5 dentro de sala limpa ISO 7, testes de esterilidade e ensaios de endotoxinas (LAL).
4. **Hormônios e Citostáticos (RDC 67/2007 Anexos II e III):** Exige cabine de segurança biológica ou pressão negativa com exaustão total e controle de contaminação cruzada.
5. **Cálculos de Equivalência Sal/Base e Fator de Correção:** Cálculo estequiométrico fundamentado com pesos moleculares oficiais e fatores analíticos do laudo da matéria-prima.
6. **Determinação de Prazo de Uso (BUD):** Baseado estritamente em Farmacopeia Brasileira, USP ou literatura indexada, vedada a extrapolação arbitrária.

### Piso Sol / Pro com Análise Prévia Crítica Somente Leitura:
1. **Investigação de Desvio Grave de Qualidade:** Reclamações envolvendo reações adversas graves, suspeita de contaminação microbiana em produto estéril, precipitação massiva de ativo potente ou desvio extremo de teor.
2. **Suspeita de Incompatibilidade Tóxica:** Formação de subprodutos de degradação potencialmente carcinogênicos, mutagênicos ou tóxicos.
3. **Auditorias Sanitárias Críticas:** Preparação de defesas técnicas e adequações estruturais perante autuações de vigilância sanitária.

---

## 5. Arquitetura das Skills Especialistas

Cada especialista de domínio segue a arquitetura canônica de 7 arquivos:
1. `SKILL.md`: Manifesto com objetivos, limites operacionais, persona e conformidade v1.
2. `guia-1.md`: Procedimentos técnicos e fundamentos teóricos do primeiro pilar do domínio.
3. `guia-2.md`: Práticas analíticas, cálculos ou farmacologia clínica aplicada.
4. `guia-3.md`: Requisitos regulatórios, conformidade ANVISA e ética médica/farmacêutica.
5. `troubleshooting.md`: Matriz de resolução de desvios, falhas de bancada ou objeções críticas.
6. `knowledge/<especialista>/README.md`: Repositório de referências consolidadas, dados validados e monografias.
7. `evals/<especialista>/001-routing.md`: Casos de teste de roteamento, pisos de risco e limites de segurança.
