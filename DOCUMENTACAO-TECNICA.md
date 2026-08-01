# Documentação técnica — Leitor.md

Descreve o sistema **como implementado de fato** (spec §19). App iOS/iPadOS nativo
(Swift/SwiftUI, iOS 17+) para **ler** Markdown com tipografia e renderização
completa (GFM, código, LaTeX, Mermaid), com origens locais, iCloud Drive, Google
Drive, compartilhamento e GitHub. Não é editor (princípio 0.1).

Estado: MVP (épicos 8.1–8.9) implementado e verificado no Simulador. DOCX é
best-effort e ficou para a v1.1 (spec §24). Itens que exigem aparelho real estão
listados na seção "Divergências e pendências".

---

## 1. Modelo de dados (SwiftData) — spec §7

Persistência local **SwiftData**, sincronizada via **CloudKit privado** do usuário
(`cloudKitDatabase: .automatic`), com o store no container do **App Group**
`group.com.dablab.leitormd`. Convenção da spec §18: nomes de domínio em português;
as `properties` Swift espelham 1:1 os campos da spec, em português camelCase
(ex.: `abertoEm`, `compraDesbloqueada`). Arquivos em `Sources/ModeloDeDados/`.

### Tabela `documentos` (`Documento.swift`)
Histórico (Recentes) e Favoritos — a MESMA tabela, diferenciada pela flag
`favorito` (trade-off declarado na spec §7.2).

| Campo (property) | Tipo | Significado |
|---|---|---|
| `id` | UUID | Chave primária |
| `titulo` | String | Nome exibido nas listas |
| `origem` | `OrigemDocumento` | De onde o documento veio |
| `identificadorLocal` | Data? | Bookmark de segurança (`URL.bookmarkData`) para reabrir sem novo picker. Nulo quando GitHub |
| `identificadorRemoto` | String? | `owner/repo/path` da API do GitHub. Nulo quando não é GitHub |
| `favorito` | Bool | Se está em Favoritos |
| `favoritadoEm` | Date? | Quando favoritou (nulo se não favorito) |
| `abertoEm` | Date | Última abertura — ordena Recentes (§11) |
| `criadoEm` | Date | Primeira abertura |
| `tamanhoBytes` | Int? | Tamanho, quando conhecido |

Exclusão: **hard delete** (o app nunca é dono do arquivo). Unicidade de
`identificadorLocal`/`identificadorRemoto` é garantida **em código** (não por
`@Attribute(.unique)`, que é incompatível com CloudKit) — ver `DocumentoRepositorio`.

### Tabela `preferencias_usuario` (`PreferenciasUsuario.swift`) — singleton
Uma linha só, garantida em código por um `id` fixo
(`00000000-0000-0000-0000-000000000001`), via `PreferenciasRepositorio.buscarOuCriar`.

| Campo | Tipo | Default | Significado |
|---|---|---|---|
| `tema` | `TemaApp` | `.sistema` | Claro/escuro/segue o sistema |
| `temaSintaxe` | `TemaSintaxeCodigo` | `.github` | Tema de realce de código |
| `fonteLeitura` | `FonteLeitura` | `.sistema` | Família tipográfica do corpo |
| `tamanhoFonte` | Int | 17 | Tamanho base (pt) |
| `abrirUltimoArquivoAoIniciar` | Bool | false | Reabrir último ao iniciar |
| `compraDesbloqueada` | Bool | false | **Cache** do desbloqueio (fonte de verdade = StoreKit) |
| `dataCompra` | Date? | — | Cache local da data da compra |
| `atualizadoEm` | Date | agora | Última mudança |

### Enums (`Enums.swift`) — spec §7.4
String-backed com rawValue snake_case idêntico à spec:
- `OrigemDocumento`: `arquivo_local`, `icloud_drive`, `google_drive`, `github`, `compartilhado`
- `TemaApp`: `sistema`, `claro`, `escuro`
- `TemaSintaxeCodigo`: `github`, `dracula`, `monokai`, `solarized`
- `FonteLeitura`: `sistema`, `serifada`, `mono`

### 2. Relacionamento
**Não há relacionamento** entre `documentos` e `preferencias_usuario` — são
independentes por design (spec §7.1). O token OAuth do GitHub (v1.1) ficará no
Keychain, fora do modelo/CloudKit (spec §7.6).

---

## 3. Lógica que roda fora da UI

| Onde | Arquivo | O que faz |
|---|---|---|
| Container SwiftData | `ModeloDeDados/ContainerModelo.swift` | Tenta CloudKit + App Group; cai para local se indisponível (Simulador sem provisionamento / sem conta iCloud) — spec §6/§8.6 |
| Escrita em `documentos` | `ModeloDeDados/DocumentoRepositorio.swift` | Registrar abertura (local/GitHub) com dedup em código (§7.2), favoritar (§11), apagar, e as consultas do portão de trial (total, existeLocal, existeGitHub) |
| Bookmark de segurança | `Abertura/AberturaArquivoServico.swift` | Abrir/reabrir arquivo com security scope, criar/atualizar bookmark, classificar origem, aviso de >5MB (§11) |
| URL do GitHub | `Abertura/ResolvedorURLGitHub.swift` | Parse puro de `github.com/.../blob`, `raw.githubusercontent.com` e repo-raiz→README (§8.4/§11) |
| API do GitHub | `Abertura/GitHubContentsAPI.swift` | Contents API pública; `interpretar` (função pura) trata 200/403-rate-limit/404 (§12/§13) |
| Cache do GitHub | `Abertura/CacheGitHub.swift` | Cacheia o último conteúdo por `identificador_remoto` (offline, §17/§23) |
| Handoff da Share Extension | `Compartilhado/Handoff.swift` + `Abertura/HandoffServico.swift` | Extensão grava arquivo/URL no App Group; app consome no foreground e devolve pendências (§8.3) |
| Regras de negócio | `Compartilhado/RegrasDeNegocio.swift` | Extensões aceitas, ordenação/teto de Recentes, kebab-case do Skill (§11) |
| Portão de trial | `Configuracoes/PortaoTrial.swift` | Decide se o Paywall interrompe a abertura (§8.9) |
| Compra | `Configuracoes/LojaStoreKit.swift` | StoreKit 2: carregar produto, comprar, restaurar, checar `Transaction.currentEntitlements` (§8.9) |
| Render p/ exportar | `Leitura/RenderizadorExportacao.swift` | WKWebView escondido: renderiza (aguarda Mermaid) e gera PDF (§8.7/§14) |
| Exportações | `Leitura/ExportadorHTML.swift`, `ExportadorSkill.swift` | HTML autocontido (fontes base64) e `.skill` (zip via NSFileCoordinator) |

### Renderização (spec §8.5)
`WebBundle/` é um bundle local (sem rede) carregado num `WKWebView`
(`Leitura/RenderizadorWebView.swift`). `bridge.js` orquestra **markdown-it** (GFM:
tabelas, tachado, task-lists, notas de rodapé), **highlight.js** (código),
**KaTeX** via texmath (`$...$`/`$$...$$`) e **Mermaid** (```mermaid). Expõe à
camada Swift: `renderMarkdown`, `aplicarPreferencias` (tema/fonte ao vivo),
`obterTOC`/`irPara` e `renderParaExportacao`. Bibliotecas vendorizadas em
`WebBundle/vendor/` (incl. 20 fontes woff2 do KaTeX). `linkify` fuzzy desligado
(para "arquivo.md" não virar link).

---

## 4. Mapa tela → dados (spec §10)

| Tela | Arquivo | Lê | Escreve |
|---|---|---|---|
| Início | `Biblioteca/InicioView.swift` | `documentos`, `preferencias_usuario` (compra) | — (aciona aberturas) |
| Onboarding | `Biblioteca/OnboardingView.swift` | — | `AppStorage("onboarding_visto")` |
| Seletor de arquivo | `Abertura/SeletorDocumento.swift` | — | — |
| Abrir do GitHub | `Abertura/AberturaGitHubView.swift` + VM | GitHub Contents API | cache; a Início registra |
| Leitura | `Leitura/LeituraView.swift` (+ VM) | arquivo/cache, `preferencias_usuario` | `documentos` (`abertoEm`, `favorito`) |
| Sumário (TOC) | `Leitura/SumarioTOCView.swift` | headings do WebView | — |
| Exportar | `Leitura/ExportacaoView.swift` | conteúdo renderizado/markdown | só arquivo temporário → folha de compartilhamento |
| Configurações | `Configuracoes/ConfiguracoesView.swift` | `preferencias_usuario` | `preferencias_usuario` |
| Paywall | `Configuracoes/PaywallView.swift` | StoreKit (`Product`) | `preferencias_usuario` (`compra_desbloqueada`) |

---

## 5. Lógica das principais funcionalidades por tela

- **Início:** `@Query` de `documentos` ordenado por `abertoEm` desc; Recentes aplica
  o teto de 50 (§11), Favoritos filtra `favorito`. Abrir (arquivo/GitHub/handoff)
  passa pelo **portão de trial** (`abrirComPortao`): 1º documento livre; reabrir é
  sempre livre; 2º distinto sem compra → Paywall, concluindo a abertura pendente
  após a compra. Revalida bookmarks em background para marcar linhas com erro (§8.1).
- **Leitura:** máquina de estados (`carregando`/`pronto`/`erro`, §12). Arquivo usa
  bookmark; GitHub usa cache-first e senão a API. Aviso de >5MB antes de renderizar
  (§11). Barra: favoritar, sumário, aparência (tema/fonte/tamanho ao vivo, sem
  perder rolagem), exportar.
- **Configurações:** edita o singleton (@Bindable); "Restaurar compra" sempre
  acessível (guideline §23).
- **Paywall:** carrega o produto, comprar/restaurar; cancelar não repete (§8.9).

---

## 6. Divergências em relação ao spec e pendências

- **Projeto de referência era Expo:** `hora-do-remedio` é React Native/Expo, não
  Swift nativo — então a §4 ("espelhar a abordagem de projeto Xcode") não se aplicou
  literalmente. Reaproveitados só o prefixo `com.dablab.*` e o team `XGZW6Y6K25`; a
  geração do projeto passou a ser **XcodeGen** (`project.yml`, `.xcodeproj` no
  `.gitignore`). Decisão do Alexandre.
- **Nomes do modelo em português** (§18 delegava ao time): properties camelCase pt.
- **CloudKit local-first com fallback:** o container tenta CloudKit e cai para local
  quando indisponível; unicidade da §7.2 garantida em código (não `.unique`, que é
  incompatível com CloudKit).
- **Share Extension (§8.3):** comportamento App-Store-safe escolhido pelo Alexandre —
  a extensão importa o arquivo e o app abre na **próxima abertura** (consumo no
  foreground), **sem** o truque de esquema-URL/`openURL` (evita risco de revisão do
  §23), mesmo o §8.3 sugerindo auto-foreground.
- **Detecção da origem Google Drive (§8.2):** best-effort por marcador no caminho do
  File Provider; um arquivo do Drive sem o marcador cai como `arquivo_local` (não
  quebra nenhum critério — a reabertura offline via bookmark funciona igual).
- **DOCX (§8.7):** adiado para a v1.1 (§24 já prevê), por ser best-effort e caro
  (OOXML do zero). PDF/HTML/Skill entregues.
- **Frontmatter do SKILL.md:** confirmado `name` + `description` (spec §25).
- **Pendências que exigem aparelho real (§22):** picker de iCloud/Google Drive, sync
  CloudKit entre 2 aparelhos, compra StoreKit em sandbox, VoiceOver no WebView.
- **Pré-submissão:** política de privacidade + Privacy Nutrition Label ("Dados não
  coletados", §20), e tier de preço exato do IAP (§25).

---

## 7. Testes automatizados

`Tests/` (36 testes, verdes): regras da §11 (extensões, ordenação/teto de Recentes,
kebab-case), resolução de URL do GitHub, classificação de origem, round-trip do
handoff, interpretação da resposta do GitHub (200/403/404), regra de favoritar,
portão de trial, geração do SKILL.md. Rodar:

```bash
xcodebuild test -project LeitorMd.xcodeproj -scheme LeitorMd \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  CODE_SIGNING_ALLOWED=NO
```

Renderização/exportação verificadas no Simulador (incl. teste de carga do WKWebView:
~41k chars com 200 fórmulas/tabelas + Mermaid em ~83ms).
