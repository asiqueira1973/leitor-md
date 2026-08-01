# Leitor.md

App iOS/iPadOS nativo (Swift/SwiftUI) para **ler** arquivos Markdown com boa tipografia e
renderização completa (GFM, código, LaTeX, Mermaid). Não é um editor. Fonte de verdade do
produto: [`spec-leitor-md.md`](spec-leitor-md.md) (29 seções) e
[`modelo-leitor-md.dbml`](modelo-leitor-md.dbml) (modelo de dados da §7).

## Pré-requisitos

- **Xcode 26+** (testado com 26.1.1) e iOS 17.0+ como alvo mínimo.
- **XcodeGen** (`brew install xcodegen`) — o projeto Xcode é gerado, não versionado.

## Setup local

O `.xcodeproj` é gerado a partir de [`project.yml`](project.yml) e fica no `.gitignore`.

```bash
# 1. Gerar o projeto Xcode
xcodegen generate

# 2. Abrir no Xcode
open LeitorMd.xcodeproj

# ou, pela linha de comando, buildar para o Simulador:
xcodebuild build -project LeitorMd.xcodeproj -scheme LeitorMd \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  CODE_SIGNING_ALLOWED=NO

# 3. Rodar os testes das regras de negócio (spec 11 / 22)
xcodebuild test -project LeitorMd.xcodeproj -scheme LeitorMd \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  CODE_SIGNING_ALLOWED=NO
```

> Sempre que mexer no `project.yml` ou adicionar/remover arquivos, rode `xcodegen generate` de novo.

## Estrutura de pastas (spec 18)

```
project.yml            # XcodeGen — fonte de verdade do projeto Xcode
Sources/
  App/                 # ponto de entrada, Info.plist, entitlements, raiz
  ModeloDeDados/       # @Model SwiftData (spec 7), enums, ModelContainer
  Abertura/            # pickers, handoff da Share Extension, fluxo GitHub
  Leitura/             # WebView, renderização, TOC, exportação
  Biblioteca/          # Recentes/Favoritos
  Configuracoes/       # preferências, restaurar compra
  Compartilhado/       # UI reutilizável, paleta, regras de negócio puras
ShareExtension/        # Share Extension (spec 8.3)
WebBundle/             # HTML/CSS/JS local de renderização (spec 8.5)
Resources/             # Assets.xcassets (ícone + cores), pt-BR/en.lproj
Tests/                 # testes das regras puras (spec 11)
```

## Convenções de código (spec 18)

- Modelo de dados em **português `snake_case`** nos nomes de tabela/enum (spec 7); as
  properties Swift espelham 1:1 os campos da spec, em português camelCase
  (ex.: `abertoEm`, `compraDesbloqueada`).
- Código/tipos/arquivos Swift em inglês idiomático; a fronteira de idioma fica no modelo.
- Toda função/`ViewModel`/rotina leva comentário de cabeçalho em português citando a seção
  da spec que implementa.

## Estado atual

Implementado: **scaffolding (Fase 0)** + **modelo de dados SwiftData (spec 7, Fase 1)** +
testes das regras da spec 11. Próximos: épicos 8.1 → 8.9 na ordem da spec (DOCX por último).

**Local-first agora:** o `ModelContainer` roda com store local (sem exigir setup de
CloudKit/App Group no portal Apple). A sincronização iCloud (spec 8.6) e o App Group da
Share Extension (spec 8.3) são ativados nos respectivos épicos — ver comentários em
`Sources/ModeloDeDados/ContainerModelo.swift`.

## Passos manuais pendentes (fora do código)

Ver `spec-leitor-md.md` §27. Em resumo, ainda faltam: habilitar capabilities no App ID,
criar App Group + App ID da extensão (no épico 8.3), enviar ícone de marketing, política de
privacidade. Bundle ID do app: `com.dablab.leitormd`; team de assinatura: `XGZW6Y6K25`.
