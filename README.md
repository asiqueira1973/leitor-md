# Leitor.md

App iOS/iPadOS nativo para ler arquivos Markdown com boa tipografia e renderização completa (GFM, código, LaTeX e Mermaid). Não é um editor.

[Baixar na App Store](https://apps.apple.com/br/app/leitor-md/id6797046582)

## Principais funcionalidades

- Abre `.md`, `.markdown`, `.mdown` e `.mkd` do aparelho, do iCloud Drive, do Google Drive (pelo app Arquivos), recebidos de outros apps (Share Extension) e de URLs públicas do GitHub.
- Renderização de GitHub Flavored Markdown (tabelas, listas de tarefas, notas de rodapé), realce de sintaxe, fórmulas LaTeX (KaTeX) e diagramas Mermaid, tudo embarcado e offline.
- Modo claro/escuro/sistema, temas de realce de código, escolha de fonte e tamanho de leitura.
- Sumário automático a partir dos títulos.
- Recentes e Favoritos sincronizados via iCloud, sem conta própria do app.
- Exportação para PDF, HTML e Skill do Claude (arquivo `.skill`).
- Português do Brasil e inglês.
- Download grátis com 1 documento de teste e compra única para uso ilimitado (sem assinatura).

## Stack técnica

- Swift, SwiftUI, iOS/iPadOS 17+
- SwiftData com CloudKit (sincronização de Recentes/Favoritos)
- WKWebView com markdown-it, highlight.js, KaTeX e Mermaid empacotados localmente (`WebBundle/`)
- StoreKit 2 (compra única não-consumível)
- GitHub Contents API pública (sem login)
- XcodeGen (`project.yml`) para gerar o projeto Xcode; XCTest para testes

## Como foi construído

O app foi desenvolvido com Claude (Anthropic) a partir de uma especificação SDD, a [`spec-leitor-md.md`](spec-leitor-md.md), com o modelo de dados em [`modelo-leitor-md.dbml`](modelo-leitor-md.dbml). O sistema como foi construído de fato, com as divergências em relação à spec, está em [`DOCUMENTACAO-TECNICA.md`](DOCUMENTACAO-TECNICA.md).

O que existe no repositório para manter a qualidade:

- [`CLAUDE.md`](CLAUDE.md) com as instruções lidas pelo Claude Code em toda sessão: fontes de verdade, convenções obrigatórias, decisões de arquitetura fechadas e o protocolo de mudanças incrementais da spec.
- Testes automatizados (`Tests/`) das regras de negócio: extensões aceitas, ordenação e teto de Recentes, resolução de URL do GitHub, classificação de origem, handoff da Share Extension, regra de favoritar, portão do trial e geração do `SKILL.md`.

## Status

Publicado na App Store (iOS/iPadOS).

## Como rodar

Pré-requisitos: Xcode 26+ e [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). O `.xcodeproj` é gerado a partir do `project.yml` e não é versionado.

```bash
# Gerar o projeto Xcode
xcodegen generate

# Buildar para o Simulador
xcodebuild build -project LeitorMd.xcodeproj -scheme LeitorMd \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  CODE_SIGNING_ALLOWED=NO

# Rodar os testes
xcodebuild test -project LeitorMd.xcodeproj -scheme LeitorMd \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  CODE_SIGNING_ALLOWED=NO
```

Sempre que mexer no `project.yml` ou adicionar/remover arquivos, rode `xcodegen generate` de novo. Para assinar e rodar num aparelho, troque o time de desenvolvimento no `project.yml` pelo seu.

### Estrutura de pastas

```
project.yml            # XcodeGen — fonte de verdade do projeto Xcode
Sources/
  App/                 # ponto de entrada, Info.plist, entitlements
  ModeloDeDados/       # @Model SwiftData, enums, ModelContainer
  Abertura/            # pickers, handoff da Share Extension, fluxo GitHub
  Leitura/             # WebView, renderização, sumário, exportação
  Biblioteca/          # Recentes/Favoritos, onboarding
  Configuracoes/       # preferências, paywall, StoreKit
  Compartilhado/       # paleta, regras de negócio puras
ShareExtension/        # Share Extension
WebBundle/             # HTML/CSS/JS local de renderização (bibliotecas em vendor/)
Resources/             # Assets.xcassets, pt-BR/en.lproj
Tests/                 # testes das regras de negócio
```

## Créditos de terceiros

As bibliotecas abaixo estão empacotadas em `WebBundle/vendor/` e mantêm os avisos de copyright e licença originais nos próprios arquivos (ou nos repositórios de origem):

- [markdown-it](https://github.com/markdown-it/markdown-it) 14.1.0 — MIT
- [markdown-it-footnote](https://github.com/markdown-it/markdown-it-footnote) 4.0.0 — MIT
- [markdown-it-task-lists](https://github.com/revin/markdown-it-task-lists) 2.1.0 — ISC
- [markdown-it-texmath](https://github.com/goessner/markdown-it-texmath) — MIT, © Stefan Goessner
- [highlight.js](https://github.com/highlightjs/highlight.js) 11.10.0 e temas — BSD-3-Clause, © Josh Goebel e colaboradores
- [KaTeX](https://github.com/KaTeX/KaTeX) 0.16.11, incluindo as fontes woff2 — MIT
- [Mermaid](https://github.com/mermaid-js/mermaid) 11.3.0 — MIT

## Licença

O código está disponível apenas para leitura e estudo. Veja [LICENSE](LICENSE). Isso vale para o código da Dab Lab; as bibliotecas de terceiros listadas acima continuam sob as licenças delas.

## Contribuições

Issues são bem-vindas; pull requests não são aceitos. Veja [CONTRIBUTING.md](CONTRIBUTING.md).

---

Feito pela [Dab Lab](https://www.dablab.com.br/) — product studio de software e IA que constrói apps para pequenas empresas, startups e áreas dentro de grandes empresas, partindo de uma especificação (Spec-Driven Development) e com as disciplinas de engenharia de software robusta.
