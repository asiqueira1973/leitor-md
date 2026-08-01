# Leitor.md — instruções para o Claude Code

Este arquivo é lido automaticamente pelo Claude Code em toda sessão neste repositório. Ele existe para que qualquer sessão — a primeira ou a centésima — retome o projeto com o mesmo contexto, sem precisar recolar a spec inteira.

## O que é este projeto

Leitor.md é um app iOS/iPadOS (nativo, Swift/SwiftUI) para **ler** arquivos Markdown com boa tipografia e renderização completa (GFM, código, LaTeX, Mermaid), com integração a iCloud Drive, Google Drive, compartilhamento de outros apps e GitHub. Não é um editor. A fonte de verdade completa do produto é:

- **`spec-leitor-md.md`** (na raiz do repositório) — a especificação funcional e técnica completa, com 29 seções numeradas. Toda decisão de UX, dado, regra de negócio e critério de aceite está lá.
- **`modelo-leitor-md.dbml`** (na raiz do repositório) — o modelo de dados (SwiftData) da seção 7 do spec, pronto para visualizar em dbdiagram.io.

**Sempre que uma tarefa envolver o produto, releia a seção relevante do `spec-leitor-md.md` antes de codar** — não trabalhe de memória de uma conversa anterior nem invente comportamento que não está lá.

## Estado atual do projeto

Ainda não implementado — este é o ponto de partida. A primeira sessão de implementação deve:

1. **Olhar a pasta `hora-do-remedio`** (outro app iOS do Alexandre, mesma máquina, mesma conta de desenvolvedor Apple) e reaproveitar o que fizer sentido: prefixo de bundle ID, team de assinatura, abordagem de projeto Xcode (xcodegen vs `.xcodeproj` manual) e convenções de estrutura de pastas — ver seção 4 do spec. Não copiar cegamente o que for específico do domínio daquele app (lembretes de remédio); só a parte de configuração/infraestrutura.
2. Montar um plano e lista de tarefas **antes de codar**, e mostrar para aprovação — incluindo o que precisa ser feito manualmente por fora (Xcode/App Store Connect/GitHub), não só o que o Claude Code vai codar.
3. Implementar primeiro o modelo de dados (seção 7 do spec), depois as telas (seção 10), seguindo a ordem dos épicos 8.1 → 8.9 (deixando o DOCX, dentro do 8.7, por último — é best-effort, ver seção 24).
4. Não implementar nada da seção 28 (Roadmap v1.1/v2) nesta fase — está fora do MVP por decisão explícita.

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
