# Leitor.md — instruções para o Claude Code

Este arquivo é lido automaticamente pelo Claude Code em toda sessão neste repositório. Ele existe para que qualquer sessão — a primeira ou a centésima — retome o projeto com o mesmo contexto, sem precisar recolar a spec inteira.

## O que é este projeto

Leitor.md é um app iOS/iPadOS (nativo, Swift/SwiftUI) para **ler** arquivos Markdown com boa tipografia e renderização completa (GFM, código, LaTeX, Mermaid), com integração a iCloud Drive, Google Drive, compartilhamento de outros apps e GitHub. Não é um editor. A fonte de verdade completa do produto é:

- **`spec-leitor-md.md`** (na raiz do repositório) — a especificação funcional, com 29 seções numeradas. É a **intenção de produto**: critérios de aceite (seção 8), regras de negócio (seção 11), princípios (seção 0). Use como referência de *o que o produto deve fazer*.
- **`DOCUMENTACAO-TECNICA.md`** (na raiz) — descreve o sistema **como foi construído de fato**, com a seção 6 "Divergências" onde a implementação difere do spec. É a referência de *como está feito*. **Onde o spec e a realidade divergirem, vale a doc técnica.**
- **`modelo-leitor-md.dbml`** (na raiz do repositório) — o modelo de dados (SwiftData) da seção 7 do spec, pronto para visualizar em dbdiagram.io.

**Sempre que uma tarefa envolver o produto, releia a seção relevante do `spec-leitor-md.md` (intenção) E confirme o "como está" na `DOCUMENTACAO-TECNICA.md`** — não trabalhe de memória de uma conversa anterior nem invente comportamento que não está lá.

## Estado atual do projeto

**O app está implementado e publicado.** Todo o MVP (épicos 8.1 a 8.9, com o DOCX adiado para a v1.1 por ser best-effort — seção 24) foi construído, testado no Simulador e submetido à App Store (versão 1.0). **NÃO recomece do zero, não re-scaffolde o projeto, e não olhe o `hora-do-remedio` como ponto de partida** (ele é Expo/React Native — só o prefixo de bundle `com.dablab.*` e o team `XGZW6Y6K25` foram reaproveitados; o projeto aqui usa XcodeGen).

Para **evoluir com segurança** (não quebrar o que já funciona):

1. **Leia a `DOCUMENTACAO-TECNICA.md` antes de mexer** — principalmente a seção 6 (Divergências): XcodeGen em vez de espelhar o hora-do-remedio, CloudKit local-first com fallback, Share Extension com handoff App-Store-safe (abre na próxima abertura, sem truque de openURL), detecção de Google Drive best-effort, DOCX adiado, etc.
2. **Siga o protocolo da seção 29 do spec**: commit de checkpoint antes de mexer, peça/aprove a lista de arquivos antes de codar, diga explicitamente o que **não** deve mudar, e reverta o que passar do escopo.
3. **Rode os testes** (`Tests/`, ~36 casos das regras da seção 11) antes e depois — guardam ordenação/teto de Recentes, extensões aceitas, kebab-case do Skill, portão de trial, resolução de URL do GitHub, handoff, favoritar.
4. **Regenere o projeto com `xcodegen generate`** após adicionar/remover arquivos `.swift` ou mexer no `project.yml` (o `.xcodeproj` é gerado, não versionado; `brew install xcodegen`).
5. **Atualize a `DOCUMENTACAO-TECNICA.md` no mesmo commit** de qualquer mudança de modelo de dados ou lógica de tela (Definition of Done, seção 26).
6. Nada da seção 28 (Roadmap v1.1/v2 — DOCX, login GitHub, árvore de repo, anotações, widget) entra sem pedido explícito.

## Convenções não-negociáveis (seção 18 do spec)

- **Modelo de dados (SwiftData) em português, `snake_case`** — nomes de tabela/campo/enum exatamente como estão na seção 7 do spec (`documentos`, `preferencias_usuario`, `origem_documento`, etc.). Não traduza para inglês.
- **Código, variáveis, funções e nomes de arquivo Swift em inglês** — padrão da comunidade iOS. A fronteira de idioma fica nos nomes que espelham o modelo de dados.
- **Toda função, `ViewModel`, extensão de API e rotina de importação leva comentário de cabeçalho em português**, explicando o que faz, o que recebe, o que devolve, e qual seção do spec implementa (ex.: `// Busca o conteúdo de um arquivo no GitHub via Contents API (spec 13)`).
- Organização de pastas por feature: `Sources/Abertura`, `Sources/Leitura`, `Sources/Biblioteca`, `Sources/Configuracoes`, `Sources/ModeloDeDados`, `Sources/Compartilhado`.

## Princípios de produto (seção 0 do spec) — usar como critério de desempate

1. **Leitura, não edição.** Nunca implementar um campo de edição do conteúdo do markdown.
2. **Simplicidade antes de complexidade prematura.** Nenhuma tela deveria pedir mais de 2 toques para abrir um documento.
3. **Fiel ao arquivo original.** Nenhuma ação do app grava no arquivo fonte.
4. **Local-first, nuvem por escolha.** O app funciona 100% offline para qualquer conteúdo já aberto.
5. **Tipografia como diferencial.** Tratar o texto renderizado — incluindo português — como parte central do produto.

## Decisões de arquitetura já fechadas (seção 4 do spec — não reabrir sem motivo)

- iOS/iPadOS 17.0+, Swift/SwiftUI.
- Persistência: **SwiftData + CloudKit automático** (`cloudKitDatabase: .automatic`) — sem backend próprio.
- Renderização: **WKWebView** com parser GFM + highlight.js + KaTeX + Mermaid.js embarcados localmente (sem rede).
- iCloud Drive e Google Drive: só `UIDocumentPickerViewController` — **não implementar OAuth/API própria do Google Drive**, o app Google Drive já se registra como Document Provider.
- GitHub no MVP: Contents API pública, sem login (login/Device Flow é v1.1, conta GitHub `asiqueira1973` para o OAuth App).
- Monetização: download grátis, trial de 1 documento, compra única não-consumível via **StoreKit 2** (épico 8.9) — não é assinatura, não é paywall de funcionalidade.
- Exportação: PDF e HTML no pipeline de renderização já existente; Skill do Claude gera `.skill` (zip com `SKILL.md`); **DOCX é best-effort, pode sair da release 1 sem bloquear o lançamento**.

## Regras de ouro para esta sessão (e todas as seguintes)

- **Pergunte em vez de assumir** ao esbarrar em qualquer item da seção 25 (Perguntas abertas) do spec.
- Siga literalmente as tabelas de regras de negócio (seção 11) e critérios de aceite (seção 8) — não invente valor, limite ou comportamento que não esteja explícito.
- Valide cada épico contra seus critérios de aceite antes de seguir para o próximo.
- Ao final da implementação (ou de cada mudança relevante), gere/atualize `DOCUMENTACAO-TECNICA.md` na raiz, em português, conforme a seção 19 do spec — isso faz parte da Definition of Done (seção 26), não é opcional.
- Para mudanças pequenas depois da v1 pronta, siga o protocolo da seção 29 do spec (checkpoint de commit, diff em vez de recomeço, lista de arquivos aprovada antes de codar).
