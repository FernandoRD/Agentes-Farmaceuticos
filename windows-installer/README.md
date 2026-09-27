# Instalador Windows unificado

O executável reúne os pacotes Windows de **Agentes Farmacêuticos v1** e
**Otimizações IA v5**. A interface permite escolher produto, plataforma,
pasta de projeto e especialistas. A instalação é por projeto: ela nunca usa a
opção global dos scripts.

O instalador chama somente o `install.ps1` da plataforma selecionada, com
`-Target`, `-Apply` e os aliases `-with-<especialista>` obtidos do pacote. O
catálogo é gerado ao varrer `optional/*-specialist`; especialistas adicionados
no futuro aparecem automaticamente, desde que seu `install.ps1` exponha o
alias correspondente.

## Validação local

Com PowerShell 7 ou Windows PowerShell, a partir deste repositório:

```powershell
.\windows-installer\Validate-Local.ps1 `
  -PharmaceuticalSource . `
  -OptimizationsSource "..\Otimizações IA"
```

O comando monta um staging temporário exclusivo, exige os oito pacotes e seus
`install.ps1`, valida o catálogo e confere a sintaxe PowerShell; esse staging
é removido ao final, inclusive se a validação falhar. Para manter um staging
fora do diretório temporário, use `Prepare-Payload.ps1` diretamente. Caso use
`Validate-Local.ps1 -OutputPath` fora do temporário, adicione
`-AllowNonTemporaryOutput`: o diretório informado será substituído e preservado
para inspeção. Quando o ISCC estiver instalado, seu executável de validação é
gerado dentro desse mesmo staging, nunca no worktree.

## Releases

`VERSION` é a fonte da versão do executável. O release
`v1.0.2` usa o commit fixado `4fffa2622122dd5b45724d2653a9d7ff7622f617` de
`FernandoRD/ai-agent-framework-v5`; portanto, ele não depende da branch padrão
do segundo repositório.

1. Atualize `VERSION` e valide os dois repositórios localmente.
2. Publique a mudança normalmente nos dois repositórios que compõem o pacote.
3. Para uma nova versão, valide o commit desejado de Otimizações IA e atualize
   o `ref` fixado no workflow para esse SHA antes de criar a tag.
4. Crie e envie a tag `v<versão>` neste repositório, por exemplo `v1.0.2`.
5. O workflow **Release Windows installer** prepara o payload, compila com
   Inno Setup, publica o artefato e anexa o `.exe` à GitHub Release.

Se uma tag já publicada tiver o workflow rejeitado antes de executar, não
recrie nem mova a tag. Depois de publicar a correção do workflow na branch
`main`, abra **Actions > Release Windows installer > Run workflow** e informe
exatamente a tag original em `release_ref` (por exemplo, `v1.0.2`). A execução
faz checkout dessa mesma tag, exige que ela corresponda ao `VERSION` e atualiza
somente a GitHub Release daquela tag.

Para o checkout privado de `FernandoRD/ai-agent-framework-v5`, configure o
segredo `FRAMEWORK_REPOSITORIES_TOKEN` com permissão de leitura daquele
repositório. Pull requests, pushes relevantes e releases por tag falham com
uma mensagem explícita se ele estiver ausente; isso evita que uma validação
seja marcada como bem-sucedida sem montar o pacote completo. Nenhum token é
exibido nos logs.
