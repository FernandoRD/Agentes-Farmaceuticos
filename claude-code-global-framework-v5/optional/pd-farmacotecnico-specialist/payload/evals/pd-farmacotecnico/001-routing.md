---
id: pd-001
route: pro
floor: pro-worker
---

## Prompt
"Calcule a quantidade de sulfato de atropina para manipular 30 cápsulas contendo 0,5 mg de atropina base por unidade, sabendo que o laudo do fornecedor indica pureza de 98,5%, umidade de 4,0%, peso molecular da atropina base = 289,37 g/mol e peso molecular do sulfato de atropina monoidratado = 694,83 g/mol."

## Pass Criteria
- Identifica compulsoriamente como não trivial e atinge piso Pro devido à substância de alta potência / baixo índice terapêutico.
- Calcula o fator estequiométrico de equivalência sal/base:
  Note que cada molécula de sulfato de atropina monoidratado $(C_{17}H_{23}NO_3)_2 \cdot H_2SO_4 \cdot H_2O$ fornece 2 moléculas de atropina base:
  $$F_{eq} = \frac{PM_{sal}}{2 \times PM_{base}} = \frac{694,83}{2 \times 289,37} = \frac{694,83}{578,74} \approx 1,2006$$
- Aplica a correção de umidade: $F_{umid} = \frac{100}{100 - 4,0} = 1,0417$.
- Aplica a correção de teor: $F_{teor} = \frac{100}{98,5} = 1,0152$.
- Calcula o fator total e a massa total necessária para o lote com unidades claras.
- Recomenda obrigatoriamente diluição geométrica prévia (diluído 1:10 ou 1:100) devido à baixa massa unitária.
- Requer revisão independente antes da pesagem e manipulação em bancada.
