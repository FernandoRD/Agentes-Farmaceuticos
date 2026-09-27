# Guia de Cálculos Farmacotécnicos e Estudos de Estabilidade

## 1. Fatores de Correção Farmacêutica
O fator de correção de teor e umidade nunca deve ser aplicado de maneira intuitiva ou sem respaldo do Laudo de Análise (CoA):

### Fator de Correção de Umidade ($F_{umid}$):
$$F_{umid} = \frac{100}{100 - U(\%)}$$
Onde $U(\%)$ é a perda por dessecação ou teor de água (Karl Fischer) informado no laudo da matéria-prima.

### Fator de Correção de Teor / Pureza ($F_{teor}$):
$$F_{teor} = \frac{100}{T(\%)}$$
Onde $T(\%)$ é o teor do fármaco na matéria-prima obtido no ensaio de doseamento.

### Fator de Correção de Equivalência Sal/Base ($F_{eq}$):
Quando a prescrição especifica o fármaco em sua forma base, mas o laboratório manipula a forma salina (ou vice-versa):
$$F_{eq} = \frac{PM_{sal}}{PM_{base}}$$
Onde $PM_{sal}$ é o peso molecular do sal (considerando águas de cristalização) e $PM_{base}$ é o peso molecular da base livre.

$$F_{cor\_total} = F_{eq} \times F_{umid} \times F_{teor}$$

*Atenção:* Se o laudo já expressa o teor corrigido na base seca ou se a prescrição médica refere-se expressamente ao sal, o farmacêutico deve verificar criticamente para evitar dupla correção.

## 2. Escolha de Cápsulas por Densidade e Volume Aparente
1. Determinação da densidade aparente do pó ($d_{ap} = \frac{m}{V}$).
2. Cálculo do volume total ocupado pela dose: $V_{dose} = \frac{Massa_{ativos} + Massa_{excipiente}}{d_{ap}}$.
3. Comparação com o volume nominal das cápsulas padrão:
   - Cápsula nº 000: ~1,37 mL
   - Cápsula nº 00: ~0,91 mL
   - Cápsula nº 0: ~0,68 mL
   - Cápsula nº 1: ~0,50 mL
   - Cápsula nº 2: ~0,37 mL
   - Cápsula nº 3: ~0,30 mL
   - Cápsula nº 4: ~0,21 mL
4. **Vedação:** É estritamente vedado o uso de sobrequantidade arbitrária de ativo para compensar perdas de processo ou degradação química sem justificativa respaldada em farmacopeia.

## 3. Prazo de Utilização (Beyond-Use Date - BUD)
O prazo de uso magistral deve seguir a RDC 67/2007 e compêndios oficiais (Farmacopeia Brasileira / USP <795>):
- **Formas sólidas não aquosas (cápsulas, pós):** Máximo de 180 dias ou a data de validade mais próxima de qualquer insumo utilizado, mantido em recipiente hermético e seco.
- **Formulações aquosas orais (soluções, suspensões):** Máximo de 14 dias sob refrigeração (2 a 8 ºC), quando preservadas adequadamente.
- **Formulações semissólidas e tópicas com conservantes (géis, cremes, loções):** Máximo de 30 a 90 dias, dependendo do sistema conservante e ensaios de estabilidade.
