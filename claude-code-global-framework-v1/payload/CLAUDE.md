# Diretrizes de Engenharia e Manutenção — Pharmaceutical Framework v1

Este repositório contém as implementações do framework v1 para agentes farmacêuticos.

## Regras de Contribuição
1. **Preservação de Padrões:** Qualquer modificação nos instaladores ou políticas deve ser testada com `python3 scripts/test_install.py` em todas as variantes.
2. **Rigor Sanitário:** Nunca enfraquecer os pisos de risco estabelecidos para substâncias de alta potência, hormônios, estéreis e Portaria 344/98.
3. **Especialistas Farmacêuticos:** Manter a estrutura padrão de 7 arquivos por especialista.
4. **Relatório de Execução:** Ao executar subagentes, reportar a utilização de modelos estritamente conforme o padrão do framework.
