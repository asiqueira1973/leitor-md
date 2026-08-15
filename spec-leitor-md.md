# Spec — Leitor.md (leitor de Markdown para iOS)

**Versão do documento:** 1.5
**Responsável de produto:** Alexandre Siqueira
**Status:** implementado — v1.0 (épicos 8.1–8.9) construída e submetida à App Store
**Data (spec original):** 2026-08-01

> **Nota pós-implementação:** este documento permanece como a **intenção de produto** (critérios de aceite da seção 8, regras da seção 11, princípios da seção 0). O sistema **como foi construído de fato** — e onde ele diverge deste spec — está em **`DOCUMENTACAO-TECNICA.md`** (ver a seção 6, "Divergências"). **Onde houver conflito entre este spec e a doc técnica, vale a doc técnica.** Para qualquer mudança, siga o protocolo da seção 29.

## Como usar este documento

Este documento é a fonte única de verdade do produto "Leitor.md" (nome de trabalho — ver seção 24) para quem for implementá-lo, incluindo um agente de código. Toda decisão de UX, dado, regra ou fluxo que o time de implementação precisar já está — ou deveria estar — resolvida aqui; quando não está, ela foi movida deliberadamente para a seção 24 (Assunções declaradas) ou 25 (Perguntas abertas).

**Antes de gerar qualquer código a partir deste spec, revise a seção 24.** Assunção não revisada vira verdade no momento em que o agente de código começa a implementar — e reverter uma decisão depois de codada custa muito mais do que revisar uma frase agora.

---

## 0. Princípios não-negociáveis

1. **Leitura, não edição.** O app nunca abre um teclado para editar o conteúdo de um documento. Não existe campo de edição de texto do markdown em lugar nenhum do produto.
2. **Simplicidade antes de complexidade prematura.** Cada tela resolve uma tarefa. Abrir um documento a partir de qualquer origem suportada nunca leva mais de 2 toques depois da tela inicial.
3. **Fiel ao arquivo original.** Abrir, favoritar, mudar tema ou exportar nunca grava no arquivo fonte. O app é só um espectador do conteúdo.
4. **Local-first, nuvem por escolha.** O app funciona 100% offline para qualquer conteúdo já aberto. iCloud Drive, Google Drive e GitHub são origens adicionais, nunca dependências obrigatórias.
5. **Tipografia como diferencial.** O texto renderizado — incluindo acentuação e pontuação do português — é tratado como parte central do produto, nunca deixado no padrão cru de um WebView.

---

## 1. Visão e problema

Leitor.md é um app iOS (iPhone + iPad) para abrir e ler arquivos Markdown com boa tipografia e renderização completa (GFM, código, LaTeX, Mermaid), com integração nativa às origens onde as pessoas hoje realmente recebem esses arquivos: iCloud Drive, Google Drive, compartilhamento vindo de outros apps (ChatGPT, Notion, GitHub, WhatsApp, Mail) e repositórios do GitHub. É o primeiro app da categoria pensado desde o início com identidade e ASO em português do Brasil (ver pesquisa de mercado no projeto "Leitor de Markdown").

**Anti-escopo** — o que este produto explicitamente não é:
- Não é um editor de texto (não edita o conteúdo do markdown).
- Não é um app de notas/PKM com links bidirecionais (não é um Obsidian).
- Não versiona nem faz commit no GitHub — só lê.
- Não hospeda nem sincroniza arquivos próprios (não é um Dropbox).
- Não tem colaboração em tempo real nem múltiplos usuários no mesmo documento.

---

## 2. Personas e cenários de uso

- **Dev/PM brasileiro** que recebe um README ou documento técnico e quer ler bem no celular, sem precisar abrir o notebook — cenário que hoje força a pessoa a usar o app "Arquivos" cru ou um app em inglês.
- **Estudante/pesquisador** que recebe material em `.md` de colegas ou de ferramentas de IA e quer ler com boa formatação, inclusive fórmulas (LaTeX).
- **Usuário de ChatGPT/Notion/GitHub** que exporta ou compartilha conteúdo em markdown e só quer abrir e ler — sem instalar um app pesado de notas.

O cenário mais difícil de uso, e que mais define a arquitetura, é: a pessoa está no meio de outro app (Mail, WhatsApp, GitHub, ChatGPT), toca em "Compartilhar" num arquivo ou link `.md`, e espera cair direto na leitura renderizada — sem passos extras, sem login, sem tela de boas-vindas no caminho.

---

## 3. Escopo do MVP

### Dentro do MVP

- Abrir arquivo `.md`/`.markdown`/`.mdown`/`.mkd` a partir de: armazenamento local do aparelho, iCloud Drive, Google Drive (via Files provider), Share Extension (recebido de outro app) e GitHub (URL de arquivo/README público).
- Renderização completa: GitHub Flavored Markdown (tabelas, listas de tarefas, tachado, notas de rodapé), realce de sintaxe de código (40+ linguagens), fórmulas matemáticas (LaTeX via KaTeX), diagramas Mermaid.
- Modo claro/escuro/sistema, temas de realce de código (GitHub, Dracula, Monokai, Solarized), escolha de fonte de leitura (sistema/serifada/monoespaçada) e tamanho.
- Sumário automático (TOC) a partir dos headings, com navegação rápida.
- Recentes e Favoritos, sincronizados via iCloud (CloudKit privado do usuário) entre iPhone e iPad do mesmo Apple ID — sem conta própria do app.
- Funcionamento 100% offline para qualquer documento já aberto.
- Exportar/compartilhar o documento renderizado em **PDF, HTML** e como **Skill do Claude** (arquivo `.skill`) — ver seção 14. **DOCX é best-effort na release 1** (ver nota abaixo e seção 24): tentar implementar, mas não é bloqueante para o lançamento — se a geração de `.docx` se mostrar complexa (ver risco da biblioteca de terceiros, seção 23), sai da release 1 sem culpa e vira o primeiro item da v1.1 (seção 28).
- Layout adaptado para iPad (mais respiro, tipografia maior; não é escopo deste MVP um modo multi-coluna tipo split-view interno).
- Localização completa em português do Brasil (idioma principal) e inglês (fallback).
- **Download gratuito, com trial de leitura de 1 documento** — a pessoa abre e lê o primeiro documento (qualquer origem) sem restrição nenhuma; ao tentar abrir um segundo documento diferente, o app pede a compra única (IAP não-consumível) para desbloquear uso ilimitado (ver épico 8.9 e seção 24). Sem assinatura.
- Onboarding de 3 telas na primeira abertura, explicando as origens suportadas.

### Fora do MVP

| Item | Destino | Motivo / dependência |
|---|---|---|
| Login GitHub (OAuth Device Flow) para repositórios privados e rate limit maior | Adiado — v1.1 | Depende de registrar um OAuth App no GitHub (seção 27) antes de implementar |
| Navegação de árvore de repositório GitHub (múltiplas pastas/arquivos) | Adiado — v1.1 | Construído em cima do login acima; no MVP só abre um arquivo/README por vez via URL |
| Anotações/marcações (highlight) no documento | Adiado — v2 | Exige modelagem de dados adicional e decisão de UX ainda não tomada |
| Widget de tela de bloqueio / Hoje | Adiado — v2 | Não é crítico para o caso de uso principal (abrir e ler um documento específico) |
| macOS / Mac Catalyst | Descartado | Decisão do usuário: produto é iOS-only |
| Edição de markdown | Descartado | Contraria diretamente o princípio 0.1 |
| Assinatura / freemium | Descartado no MVP | Ver seção 24 — modelo escolhido foi pago único |

---

## 4. Arquitetura

**Projeto de referência:** o Alexandre já tem outro app iOS publicado, "Hora do Remédio" (pasta local `hora-do-remedio`, na mesma máquina), feito com a mesma conta de desenvolvedor Apple. O Leitor.md deve **reaproveitar ao máximo** o que já existe lá: prefixo de bundle ID, team de assinatura (signing), abordagem de projeto Xcode (se for `xcodegen`, usar `xcodegen` aqui também; se for `.xcodeproj` manual, seguir o mesmo padrão) e convenções de estrutura de pastas — sempre que fizerem sentido para as particularidades do Leitor.md (ex.: SwiftData+CloudKit e Share Extension podem não existir no Hora do Remédio, e aí a decisão da tabela abaixo prevalece). Isso evita reconfigurar do zero e mantém os dois apps fáceis de manter em paralelo.

| Decisão | Escolha | Por quê | Alternativa descartada |
|---|---|---|---|
| Plataforma-alvo | iOS/iPadOS 17.0+ | SwiftData (persistência escolhida abaixo) exige iOS 17+; em ago/2026 a versão vigente é iOS 26, então 17+ ainda cobre a grande maioria dos aparelhos ativos | Suportar iOS 15+ com Core Data puro — mais boilerplate para um público residual pequeno em 2026 |
| Linguagem/UI | Swift + SwiftUI | Padrão atual da Apple para apps novos, menor código para UI adaptactiva iPhone/iPad | UIKit — mais verboso, sem ganho para este produto |
| Persistência local + sync | SwiftData com sincronização automática via CloudKit (`ModelContainer` com `cloudKitDatabase: .automatic`) | Sincroniza recentes/favoritos/preferências entre os aparelhos do mesmo iCloud sem precisar de conta própria nem backend — o volume de dados é pequeno (algumas dezenas/centenas de linhas) | Core Data + `NSPersistentCloudKitContainer` manual (mais boilerplate sem ganho real) e backend próprio tipo Supabase/Firebase (adiciona custo de infra e uma superfície de conta/senha que o produto não precisa) |
| Renderização do markdown | `WKWebView` carregando um bundle local (sem rede) com um parser GFM (ex.: markdown-it ou marked.js) + biblioteca de realce de código (ex.: highlight.js) + KaTeX + Mermaid.js, com folha de CSS própria por tema | Nenhuma biblioteca nativa Swift cobre GFM + código + LaTeX + Mermaid junto hoje — `swift-markdown-ui`, a opção nativa mais madura, está em **modo de manutenção** e não suporta LaTeX nem Mermaid nativamente. Todo concorrente relevante identificado na pesquisa de mercado usa a mesma abordagem de WebView | Renderização 100% nativa com `swift-markdown-ui` + soluções nativas separadas para LaTeX/Mermaid — mais esforço de integração/manutenção para um ganho de performance que não é crítico num app de leitura (sem digitação em tempo real) |
| Acesso a arquivo local / iCloud Drive | `UIDocumentPickerViewController` + security-scoped bookmark (`URL.bookmarkData`) persistido para reabrir sem novo picker | API nativa padrão da Apple para isso | — |
| Acesso ao Google Drive | Mesmo `UIDocumentPickerViewController` acima — o app Google Drive se registra como Document Provider no Files app desde 2017 | **Não é necessário implementar OAuth nem a API REST do Google Drive no MVP** — basta o usuário ter o app Google Drive instalado com a opção "Arquivos" ativada nas configurações dele. Isso reduz drasticamente o escopo técnico do MVP | Integração direta com `Google Sign-In` + `Google Drive REST API` própria — exigiria tela de login, gestão de token e aprovação OAuth do Google; deixado como possível v1.2 caso o Files provider se mostre insuficiente |
| Recebimento de arquivos de outros apps | Share Extension (`NSExtensionActivationRule` para `public.file-url`/`public.plain-text` com extensão de markdown, e também texto simples de URL para o fluxo do GitHub) + declaração de tipo de documento (`CFBundleDocumentTypes`, `LSSupportsOpeningDocumentsInPlace`) para aparecer em "Abrir com"/"Copiar para" | Cobre os apps citados (ChatGPT, Notion, GitHub, WhatsApp, Mail) sem exigir integração individual com cada um | — |
| Leitura de GitHub | `GET /repos/{owner}/{repo}/contents/{path}` da REST API pública do GitHub, sem autenticação no MVP (60 requisições/hora por IP) | Cobre o caso de uso "colar/compartilhar um link de arquivo ou README público" sem exigir conta nem backend | Login obrigatório desde o MVP — adiado para v1.1 (ver seção 3), porque adiciona complexidade (OAuth Device Flow) para um ganho que só importa em uso pesado ou repositório privado |
| Exportação DOCX | Biblioteca Swift open-source de geração de OOXML (ex.: `shinjukunian/DocX` ou equivalente pure-Swift), gerando o `.docx` a partir da estrutura do documento (não do HTML renderizado) | A API nativa `NSAttributedString.DocumentType.officeOpenXML` para **escrita** de `.docx` é, historicamente, uma capacidade documentada como disponível no macOS — a disponibilidade real para escrita no iOS não pôde ser confirmada com certeza nesta pesquisa e fica como premissa a validar (seção 23) antes de descartar a biblioteca em favor da API nativa | Depender só da API nativa sem validar antes — risco de descobrir tarde que não escreve `.docx` em iOS |
| Exportação HTML | Serialização direta do HTML já usado internamente para renderizar (mesmo pipeline do épico 8.5), com CSS inline (sem depender de arquivo externo) | Reaproveita o pipeline de renderização já existente — nenhuma conversão adicional | Gerar HTML "do zero" a partir da árvore de markdown de novo — trabalho duplicado sem necessidade |
| Trial e compra | StoreKit 2 (`Product`, `Transaction`, um produto de IAP **não-consumível**), gerenciado nativamente pela Apple | Padrão atual da Apple para compra única de desbloqueio de funcionalidade; sincroniza automaticamente entre aparelhos do mesmo Apple ID via `Transaction.currentEntitlements`, sem precisar de backend próprio nem de guardar estado de compra no CloudKit como fonte de verdade (só cacheia localmente para checagem offline, ver seção 7) | Backend próprio validando recibo — desnecessário; StoreKit 2 já resolve validação e sincronização |
| Exportação "Skill do Claude" | Gera um `SKILL.md` com frontmatter YAML (`name`, `description`) + o corpo do documento, empacotado como arquivo `.skill` (zip) — mesmo formato usado pelas skills da própria Anthropic | Aproveita que o produto do usuário já é o formato de entrada (markdown) — a transformação é essencialmente adicionar metadado e compactar | — |
| Distribuição | App Store, sem servidor próprio, sem conta de usuário do app | A única "conta" envolvida é o iCloud nativo do aparelho (para sync) e, futuramente (v1.1), o login do GitHub | — |

**Premissa técnica a validar antes de fechar a arquitetura de renderização:** desempenho do `WKWebView` em documentos muito longos (>50 mil caracteres) ou com diagramas Mermaid complexos. Recomenda-se um teste de carga cedo na implementação (ver seção 22) antes de considerar a decisão definitiva.

**Risco de plataforma conhecido, não bloqueante:** não existe um UTI (Uniform Type Identifier) oficial único para `.md` no iOS — vários apps declaram UTIs próprias para a mesma extensão, o que pode gerar concorrência no menu "Abrir com" se o usuário tiver outro app de markdown instalado. Isso não impede o funcionamento do Share Extension nem do document picker; só significa que o app pode não conseguir ser o "handler padrão" exclusivo em todos os cenários.

---

## 5. Perfis de usuário

Não aplicável: o app tem um único perfil (a pessoa que está lendo), sem papéis diferenciados nem multiusuário no mesmo aparelho.

---

## 6. Autenticação e identidade

O app **não tem tela de login, conta, senha nem cadastro no MVP**. A identidade usada para sincronizar dados é o Apple ID já autenticado no aparelho (via CloudKit privado — o usuário nunca vê nem digita nada relacionado a isso; se o aparelho não estiver logado num Apple ID, o app simplesmente funciona sem sync, sem erro nem bloqueio).

**Roadmap v1.1 — login GitHub (OAuth Device Flow):**
- O app solicita um código de dispositivo ao GitHub usando apenas o `client_id` público do app (sem `client_secret` — o Device Flow foi desenhado justamente para apps sem backend, como confirma a documentação oficial do GitHub).
- O app mostra o código de usuário e direciona para `https://github.com/login/device`, onde a pessoa autoriza pelo navegador (Safari/SFSafariViewController).
- O app faz polling até o GitHub confirmar a autorização e recebe o token de acesso.
- **O token de acesso fica exclusivamente no Keychain do iOS — nunca no SwiftData/CloudKit.** Dado sensível não deve sincronizar em texto legível entre aparelhos por essa via.
- Não há recuperação de senha nem expiração de sessão para gerenciar: revogar o acesso é feito pelo próprio usuário nas configurações da conta GitHub, ou apagando o token local nas Configurações do app ("Sair da conta GitHub").

---

## 7. Modelo de dados

### 7.1 Diagrama de relacionamento (texto)

```
documentos            (tabela independente — histórico e favoritos do usuário)
preferencias_usuario  (tabela singleton — uma linha só por instalação/iCloud)
```

Não há relacionamento (`Ref`) entre as duas tabelas — são independentes por design (ver trade-off abaixo).

### 7.2 Tabela `documentos`

| Campo | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | uuid | não | gerado | Chave primária |
| `titulo` | texto | não | — | Nome do arquivo/documento exibido nas listas |
| `origem` | enum `origem_documento` | não | — | De onde o documento veio |
| `identificador_local` | blob (bookmark de segurança) | sim | — | Bookmark do `URL` (`URL.bookmarkData`) para reabrir sem novo picker. Nulo quando `origem = github` |
| `identificador_remoto` | texto | sim | — | `owner/repo/path` da API do GitHub. Nulo em qualquer origem que não seja `github` |
| `favorito` | booleano | não | `false` | Se está na lista de Favoritos |
| `favoritado_em` | datetime | sim | — | Nulo enquanto `favorito = false` |
| `aberto_em` | datetime | não | — | Data/hora da última abertura — usada para ordenar "Recentes" |
| `criado_em` | datetime | não | agora | Quando o registro foi criado (primeira abertura) |
| `tamanho_bytes` | inteiro | sim | — | Nulo quando o tamanho não pôde ser determinado (ex.: GitHub antes do primeiro download) |

**Constraints:** `identificador_local` único quando não nulo; `identificador_remoto` único quando não nulo (evita duplicar o mesmo documento na lista se reaberto pela mesma origem).

**Estratégia de exclusão:** hard delete. Remover um item de "Recentes" ou desfavoritar não afeta o arquivo original em nenhum lugar — o app nunca é dono do arquivo, só de uma referência a ele — então não há motivo para manter histórico do próprio registro.

**Trade-off de modelagem declarado:** "Recentes" e "Favoritos" usam a mesma tabela (`favorito = true/false` como flag) em vez de duas tabelas separadas, para simplicidade — princípio 0.2. Isso impede, por exemplo, guardar um "histórico de vezes que foi favoritado/desfavoritado"; se essa necessidade aparecer no futuro, vira uma tabela de eventos separada.

### 7.3 Tabela `preferencias_usuario` (singleton)

| Campo | Tipo | Nullable | Default | Descrição |
|---|---|---|---|---|
| `id` | uuid | não | valor fixo constante | Sempre o mesmo valor, para garantir uma única linha |
| `tema` | enum `tema_app` | não | `sistema` | Claro/escuro/segue o sistema |
| `tema_sintaxe` | enum `tema_sintaxe_codigo` | não | `github` | Tema de realce de código no preview |
| `fonte_leitura` | enum `fonte_leitura` | não | `sistema` | Família tipográfica do corpo do texto |
| `tamanho_fonte` | inteiro | não | `17` | Tamanho base da fonte, em pontos |
| `abrir_ultimo_arquivo_ao_iniciar` | booleano | não | `false` | Se o app deve reabrir o último documento lido ao iniciar |
| `compra_desbloqueada` | booleano | não | `false` | Se a compra única (IAP não-consumível) já foi feita — desbloqueia abrir mais de 1 documento (ver épico 8.9) |
| `data_compra` | datetime | sim | — | Nulo enquanto `compra_desbloqueada = false`. Este campo é só um **cache local** para checagem offline — a fonte de verdade da compra é o StoreKit/Apple (`Transaction.currentEntitlements`), não este campo |
| `atualizado_em` | datetime | não | agora | Última vez que alguma preferência mudou |

### 7.4 Enums

- `origem_documento`: `arquivo_local`, `icloud_drive`, `google_drive`, `github`, `compartilhado`
- `tema_app`: `sistema`, `claro`, `escuro`
- `tema_sintaxe_codigo`: `github`, `dracula`, `monokai`, `solarized`
- `fonte_leitura`: `sistema`, `serifada`, `mono`

### 7.5 Lógica que vive fora do banco

Não há triggers/funções/políticas — não é um banco relacional com servidor (é SwiftData local + CloudKit). Toda regra de negócio das seções 11/12 é aplicada em código Swift no próprio app.

### 7.6 Dado sensível fora do modelo de dados

O token OAuth do GitHub (v1.1, ver seção 6) **não é um campo de tabela** — fica no Keychain do iOS, fora do escopo de sincronização do CloudKit.

---

## 8. Épicos e critérios de aceite

### 8.1 Abrir arquivo local / iCloud Drive
Objetivo: permitir abrir qualquer `.md` já salvo no aparelho ou no iCloud Drive.
Fluxo: tela inicial → botão "Abrir arquivo" → `UIDocumentPickerViewController` filtrado pelas extensões aceitas → seleção → renderização.
Critérios de aceite:
- Ao tocar "Abrir arquivo" e escolher um `.md` local, o documento renderizado aparece em até 1s (para arquivo <200KB) sem tela intermediária.
- Extensão fora da lista aceita (seção 11) não aparece selecionável no picker.
- Reabrir o mesmo arquivo depois de fechado o app não pede permissão de novo (usa o bookmark salvo).
- Se o bookmark salvo não resolver mais (arquivo movido/apagado), a lista de Recentes mostra o item com um indicador de erro e, ao tocar, oferece re-selecionar via picker.

### 8.2 Abrir via Google Drive
Objetivo: abrir um `.md` armazenado no Google Drive do usuário.
Fluxo: mesmo picker do épico 8.1, escolhendo a origem "Google Drive" dentro do seletor de locais do Files provider.
Critérios de aceite:
- Se o app Google Drive não está instalado ou não tem "Arquivos" ativado, a origem simplesmente não aparece no picker (comportamento nativo do sistema) — o app não precisa tratar esse caso com uma mensagem própria.
- Arquivo aberto via Google Drive é baixado localmente e funciona offline nas aberturas seguintes.

### 8.3 Receber arquivo compartilhado de outro app
Objetivo: permitir compartilhar um `.md` (ou um link do GitHub) de outro app direto para o Leitor.md.
Fluxo: usuário está em ChatGPT/Notion/GitHub/WhatsApp/Mail → toca Compartilhar → escolhe "Leitor.md" → app abre já na tela de leitura.
Critérios de aceite:
- "Leitor.md" aparece na folha de compartilhamento ao compartilhar um arquivo `.md` de qualquer app testado (Arquivos, Mail, WhatsApp).
- Compartilhar uma URL de texto simples que aponte para um arquivo/README do GitHub aciona o fluxo do épico 8.4 em vez de tentar renderizar a URL como markdown puro.
- Compartilhar um tipo de arquivo não suportado não faz "Leitor.md" aparecer na lista de apps de destino.

### 8.4 Abrir arquivo/README do GitHub por URL
Objetivo: ler um markdown público do GitHub colando ou compartilhando o link.
Fluxo: tela inicial → "Abrir do GitHub" → colar URL (ou já vem preenchido se veio de compartilhamento) → app extrai `owner/repo/path` → busca via Contents API → renderiza.
Critérios de aceite:
- Uma URL no formato `https://github.com/{owner}/{repo}/blob/{branch}/{path}` ou uma URL "crua" (`raw.githubusercontent.com`) resolve corretamente para o conteúdo do arquivo.
- Uma URL de repositório sem caminho de arquivo (`https://github.com/{owner}/{repo}`) busca o `README.md` da raiz.
- Repositório privado ou inexistente mostra mensagem clara ("repositório não encontrado ou privado — login em breve") em vez de erro técnico cru.
- Ao atingir o limite de 60 req/hora, mostra quando o limite reseta (ver seção 11) em vez de uma mensagem genérica de erro.

### 8.5 Renderização e leitura
Objetivo: exibir o markdown com boa tipografia e todos os recursos do escopo (GFM, código, LaTeX, Mermaid).
Critérios de aceite:
- Tabelas, listas de tarefas (com checkbox visualmente marcado/desmarcado), tachado e notas de rodapé renderizam conforme o spec do GFM.
- Bloco de código com linguagem declarada (```swift, ```python, etc.) aplica realce de sintaxe correspondente.
- Bloco `$$...$$` ou `$...$` renderiza como fórmula matemática via KaTeX.
- Bloco ` ```mermaid ` renderiza como diagrama.
- Trocar o tema (claro/escuro/sistema) ou a fonte nas Configurações reflete imediatamente no documento aberto, sem precisar reabrir.
- TOC lateral (ou em folha, no iPhone) lista todos os headings do documento e navega até a seção ao tocar.

### 8.6 Recentes e Favoritos com sync iCloud
Objetivo: manter um histórico de leitura e uma lista de favoritos, disponíveis nos aparelhos do mesmo iCloud.
Critérios de aceite:
- Todo documento aberto entra em "Recentes", ordenado pela regra da seção 11.
- Favoritar/desfavoritar reflete imediatamente na lista de Favoritos.
- Abrir o app num segundo aparelho com o mesmo Apple ID mostra os mesmos Recentes/Favoritos em até alguns segundos de sincronização (tempo exato depende do CloudKit, fora do controle do app).
- Sem Apple ID logado no aparelho, o app funciona normalmente, só sem sync entre aparelhos.

### 8.7 Exportar/compartilhar em outros formatos
Objetivo: permitir levar o conteúdo lido para fora do app, em PDF, HTML, DOCX ou como Skill do Claude.
Fluxo: botão "Exportar" na tela de Leitura → escolher formato → (só no caso de Skill do Claude, revisar/editar nome e descrição sugeridos) → gera o arquivo → abre a folha de compartilhamento nativa do iOS.
Critérios de aceite:
- Ação "Exportar → PDF" gera um arquivo cujo nome é o título do documento + `.pdf`, em tema claro (independente do tema de leitura ativo na tela), com o documento inteiro (não só a parte visível na tela).
- Ação "Exportar → HTML" gera um `.html` autocontido (CSS inline, sem dependência externa), abrindo corretamente em qualquer navegador sem precisar de internet.
- **(Best-effort, não bloqueia a release 1 — ver seção 24)** Ação "Exportar → DOCX" gera um `.docx` que abre corretamente no Word/Pages/Google Docs, preservando ao menos: títulos, negrito/itálico, listas, tabelas e blocos de código (sem realce de sintaxe colorido — DOCX não precisa replicar 100% da fidelidade visual do preview). Se a implementação (biblioteca de terceiros, seção 4) se mostrar mais complexa do que o esperado dentro do prazo da release 1, a opção "DOCX" simplesmente não aparece no menu de exportação até a v1.1 — as demais opções (PDF/HTML/Skill do Claude) não podem ficar bloqueadas por causa disso.
- Ação "Exportar → Skill do Claude" abre uma tela curta pedindo **nome** (sugerido a partir do título do documento, convertido para `kebab-case`) e **descrição** (sugerida a partir do primeiro parágrafo ou do primeiro heading, editável, limite de caracteres a definir na implementação seguindo a convenção vigente da Anthropic — ver premissa na seção 23); ao confirmar, gera um arquivo `.skill` contendo `SKILL.md` com o frontmatter preenchido e o corpo do documento.
- Em todos os casos, após gerado, abre a folha de compartilhamento nativa do iOS — o app nunca decide sozinho "para onde" o arquivo exportado vai.

### 8.9 Trial (1 documento grátis) e compra única
Objetivo: permitir experimentar o app com 1 documento antes de pedir a compra, sem fricção na primeira leitura.
Esta regra **se aplica sobre os épicos 8.1 a 8.4** (todo fluxo de abertura de documento) — não é um fluxo isolado, é um portão (gate) que intercepta a abertura de um documento novo quando aplicável.
Fluxo: usuário abre o primeiro documento normalmente (qualquer origem) → app cria o registro em `documentos` e marca a leitura como livre → ao tentar abrir um **segundo documento diferente** sem ter comprado, o app mostra a tela de Paywall em vez de abrir → usuário compra (StoreKit) ou toca "Restaurar compra" → app libera e completa a abertura do documento que estava pendente.
Critérios de aceite:
- O primeiro documento aberto por uma instalação nova é sempre livre, em qualquer origem (local, iCloud, Google Drive, GitHub, compartilhado), sem exigir tela de paywall antes.
- Reabrir esse mesmo primeiro documento depois (a partir de Recentes/Favoritos) continua livre indefinidamente, mesmo sem compra — a restrição é sobre abrir documentos **novos e distintos**, não sobre reler o que já foi liberado.
- Tentar abrir um segundo documento diferente sem `compra_desbloqueada = true` interrompe o fluxo de abertura e mostra a tela de Paywall, com o preço e um botão de comprar e um botão "Restaurar compra".
- Após compra bem-sucedida (ou restauração), `compra_desbloqueada` vira `true`, a tela de Paywall fecha, e a abertura do documento que estava pendente é concluída automaticamente — sem precisar tocar duas vezes no mesmo documento.
- Todas as funcionalidades do app (temas, exportação em qualquer formato, favoritar) funcionam normalmente no documento do trial — a restrição é só sobre a **quantidade de documentos distintos**, não sobre funcionalidade.
- Botão "Restaurar compra" está sempre acessível pelas Configurações também (não só na tela de Paywall) — exigência do guideline de revisão da App Store (seção 23).
- Se a compra falhar ou for cancelada pelo usuário, o app volta para onde estava (não trava, não fecha, não repete o paywall automaticamente sem nova tentativa de abrir documento).

### 8.8 Onboarding e localização pt-BR
Objetivo: primeira abertura explica as origens suportadas; todo o app está em português do Brasil.
Critérios de aceite:
- Onboarding de 3 telas aparece só na primeira abertura, com opção de pular.
- Nenhuma string em inglês aparece na interface quando o idioma do aparelho é português (revisão manual antes do lançamento — ver seção 26).
- Textos de erro, estado vazio e onboarding são conteúdo final, não placeholder (ver seção 15).

---

## 9. Fluxos principais ponta a ponta

**Fluxo A — de "compartilhar em outro app" até a leitura:**
1. Usuário está em outro app com um `.md` ou link do GitHub na tela.
2. Toca em Compartilhar → escolhe "Leitor.md".
3. iOS invoca a Share Extension do Leitor.md com o conteúdo recebido.
4. Se for arquivo `.md`: app principal abre direto na tela de leitura (épico 8.5), documento entra em Recentes.
5. Se for URL de GitHub: app extrai `owner/repo/path` e segue o fluxo do épico 8.4.
6. Se for qualquer outro tipo de conteúdo: este caso não deveria ocorrer, pois a Share Extension só se ativa para os tipos aceitos (seção 4); se ocorrer por alguma falha de UTI, mostra mensagem de "tipo não suportado" em vez de travar.

**Fluxo B — primeira abertura do app (sem nunca ter aberto nada):**
1. Onboarding de 3 telas (pode pular).
2. Tela inicial vazia: "Recentes" e "Favoritos" mostram um estado vazio com botão de atalho para "Abrir arquivo" e "Abrir do GitHub".
3. Usuário abre o primeiro documento por qualquer origem → cai automaticamente em Recentes.

---

## 10. Inventário de telas

| Tela | Acesso | Mostra | Lê | Escreve |
|---|---|---|---|---|
| Início | Abertura do app | Recentes, Favoritos, atalhos de abrir | `documentos` | — |
| Seletor de origem | Botão "Abrir" na Início | Opções: Arquivo local/iCloud, Google Drive, GitHub | — | — |
| Abrir do GitHub | Seletor de origem ou compartilhamento de link | Campo de URL, estado de busca/erro | GitHub Contents API | `documentos` (ao concluir) |
| Leitura/Preview | Ao abrir qualquer documento | Conteúdo renderizado, TOC, barra de ferramentas (tema, fonte, favoritar, exportar) | Arquivo local/remoto, `preferencias_usuario` | `documentos` (atualiza `aberto_em`, `favorito`) |
| Exportar | Botão "Exportar" na tela de Leitura | Escolha de formato (PDF/HTML/DOCX/Skill do Claude); para Skill do Claude, campos de nome e descrição | Conteúdo já renderizado/carregado | Nenhuma tabela — só gera arquivo temporário e abre a folha de compartilhamento |
| Configurações | Aba/botão dedicado | Tema, fonte, tamanho, idioma, sobre, avaliar na App Store, política de privacidade | `preferencias_usuario` | `preferencias_usuario` |
| Onboarding | Só na primeira abertura | 3 telas explicando origens suportadas | — | — |
| Paywall | Ao tentar abrir um 2º documento sem compra (épico 8.9), ou manualmente pelas Configurações | Preço, botão de comprar, botão "Restaurar compra" | StoreKit (`Product`) | `preferencias_usuario` (`compra_desbloqueada`, `data_compra`) |

---

## 11. Regras de negócio

| Regra | Condição | Resultado | Onde é aplicada |
|---|---|---|---|
| Ordenação de Recentes | Lista de "Recentes" | Ordenado por `aberto_em` decrescente, exibindo no máximo 50 itens | App (query SwiftData) — itens além do 50º continuam no banco, só não aparecem na lista |
| Extensões aceitas | Qualquer picker/Share Extension | Só `.md`, `.markdown`, `.mdown`, `.mkd`; qualquer outra extensão é rejeitada com mensagem clara | Picker / Share Extension |
| Limite de rate GitHub anônimo | Requisição à Contents API sem login | 60 requisições/hora por IP; ao estourar, mostrar quando reseta usando o header `X-RateLimit-Reset` | App, ao consumir a resposta da API |
| Tamanho de arquivo grande | Arquivo > 5MB | Mostrar aviso "arquivo grande, renderização pode demorar" antes de processar | App, antes de enviar ao WKWebView |
| Favoritar não reordena Recentes | Favoritar um item | `favorito` muda, mas `aberto_em` não é alterado por essa ação — Recentes e Favoritos são independentes mesmo compartilhando a tabela | App |
| Repositório GitHub sem `path` | URL do tipo `github.com/{owner}/{repo}` | Busca `README.md` da raiz do branch padrão | App (montagem da chamada à API) |
| Trial de 1 documento | `compra_desbloqueada = false` e usuário tenta abrir um documento diferente do primeiro já registrado em `documentos` | Bloqueia a abertura e mostra a tela de Paywall (épico 8.9) | App |
| Documento do trial sempre acessível | Documento já aberto durante o trial, mesmo sem compra | Continua abrível/relível para sempre a partir de Recentes/Favoritos | App |
| Nome de Skill do Claude | Exportação para `.skill` (épico 8.7) | `name` do frontmatter é sempre convertido para `kebab-case` (minúsculas, hífens, sem acento/caractere especial) antes de gerar o arquivo, mesmo que o usuário digite diferente | App, na tela de exportação |

Nada nesta lista é derivado automaticamente além do que está escrito aqui — não há, por exemplo, nenhum cálculo de "relevância" ou pontuação de documentos.

---

## 12. Máquinas de estado e tratamento de erro

**Estado de importação de um documento:** `ocioso` → `buscando` (baixando do provider/API) → `renderizando` (processando no WebView) → `pronto` | `erro`.

Estados de erro possíveis e tratamento:

| Erro | Mensagem ao usuário |
|---|---|
| Bookmark de segurança não resolve mais (arquivo movido/apagado) | "Não foi possível abrir este arquivo. Ele pode ter sido movido ou apagado." + opção de re-selecionar |
| Rate limit do GitHub estourado | "Limite de acesso ao GitHub atingido. Tente novamente às [hora do reset]." |
| Repositório/arquivo do GitHub não encontrado ou privado | "Repositório ou arquivo não encontrado (ou é privado — login chegando em breve)." |
| Extensão de arquivo não suportada | "Este app só abre arquivos Markdown (.md, .markdown, .mdown, .mkd)." |
| Falha genérica de rede (Google Drive/iCloud indisponível) | "Não foi possível baixar o arquivo agora. Verifique sua conexão e tente de novo." |

---

## 13. Contratos de API

Único contrato externo do MVP: **GitHub REST API — Contents**.

- `GET https://api.github.com/repos/{owner}/{repo}/contents/{path}`
- Sem autenticação no MVP (60 req/hora/IP).
- Resposta 200: JSON com `content` (base64) e `encoding` — o app decodifica para exibir.
- Resposta 403 com corpo indicando rate limit: tratar conforme seção 11/12.
- Resposta 404: repositório, caminho ou branch inexistente, ou repositório privado sem autenticação — tratar conforme seção 12.
- Sem paginação necessária (busca de um arquivo por vez); sem idempotência a garantir (é `GET`, sem efeito colateral).

**Roadmap v1.1** adiciona: `POST https://github.com/login/device/code` e `POST https://github.com/login/login/oauth/access_token` para o Device Flow (seção 6), e chamadas à Contents API autenticadas (header `Authorization: Bearer {token}`) para repositórios privados e rate limit de 5.000/hora.

---

## 14. Relatórios, exportação e importação

O MVP exporta em quatro formatos, todos acessíveis pelo mesmo botão "Exportar" (épico 8.7):

**PDF**
- Nome do arquivo: `{titulo-do-documento}.pdf` (título sanitizado para nome de arquivo válido).
- Gerado a partir do HTML já renderizado no WKWebView (API `createPDF` do WebKit).
- Tamanho de papel: A4.
- Tema fixo **claro** no PDF, independente do tema de leitura ativo na tela — decisão para favorecer impressão/leitura em outros contextos.
- Inclui o documento inteiro (não paginado pela tela, o WebView renderiza a altura total antes de gerar o PDF).
- Sem opção de customizar cabeçalho/rodapé/numeração no MVP.

**HTML**
- Nome do arquivo: `{titulo-do-documento}.html`.
- Autocontido: CSS inline no próprio arquivo, sem referência a nenhum recurso externo (fonte, script, imagem remota) — precisa abrir corretamente offline, em qualquer navegador.
- Usa o mesmo tema/fonte que estava ativo na tela de leitura no momento da exportação (diferente do PDF, que é sempre em tema claro).
- Encoding: UTF-8.

**DOCX (best-effort — não obrigatório para a release 1, ver seção 24)**
- Nome do arquivo: `{titulo-do-documento}.docx`.
- Preserva estrutura (títulos, negrito/itálico, listas numeradas/com marcador, tabelas, blocos de código como texto monoespaçado simples) — não precisa preservar realce de sintaxe colorido nem diagramas Mermaid/fórmulas KaTeX renderizados como imagem (documentar como limitação conhecida na tela de exportação, não como bug).
- Gerado via biblioteca de terceiros (seção 4) — não via impressão/PDF-para-DOCX, que perderia a edição de texto real no Word.

**Skill do Claude (`.skill`)**
- Nome do arquivo: `{nome-do-skill-em-kebab-case}.skill` (um arquivo zip).
- Conteúdo do zip: um único `SKILL.md`, com frontmatter YAML no topo (`name` e `description`, preenchidos na tela de exportação do épico 8.7) seguido do corpo do documento original sem alteração de conteúdo.
- `name` sanitizado para `kebab-case` (minúsculas, hífens, sem acentuação/caracteres especiais) — ver regra de negócio da seção 11.
- Esta é a única exportação em que o usuário digita algo antes de gerar o arquivo (nome/descrição) — não conflita com o princípio 0.1 (o app não edita o *conteúdo* do documento, só anexa metadado ao redor dele).

Não há importação de dados estruturados (planilha, CSV) neste produto — fora de escopo.

---

## 15. Copy e tom de voz

Tom: direto, sem jargão técnico desnecessário, sempre em português do Brasil natural (não tradução literal do inglês). Alguns textos-âncora:

| Contexto | Texto |
|---|---|
| Estado vazio de Recentes | "Nenhum documento aberto ainda. Toque em Abrir para começar." |
| Estado vazio de Favoritos | "Seus documentos favoritos aparecem aqui." |
| Botão principal da Início | "Abrir arquivo" |
| Botão do fluxo GitHub | "Abrir do GitHub" |
| Onboarding, tela 1 | "Leia seus arquivos Markdown com qualidade de verdade." |
| Onboarding, tela 2 | "Abra direto do iCloud, Google Drive, GitHub ou de qualquer outro app." |
| Onboarding, tela 3 | "Sem edição, sem distração — só leitura, do jeito que devia ser." |
| Tela de exportação — campo nome (Skill do Claude) | "Nome do skill" (placeholder sugerido a partir do título do documento) |
| Tela de exportação — campo descrição (Skill do Claude) | "Descreva em poucas palavras quando esse skill deve ser usado" |

Estes são textos finais candidatos, não placeholder — ajustáveis em revisão de copy antes do lançamento, mas o agente de código deve usá-los como estão, não inventar substitutos.

---

## 16. Direção visual / design system

- Nome final confirmado: **Leitor.md**. **Ícone final aprovado** (não é mais pergunta aberta): wordmark "L.md" em serifada terracota sobre fundo creme, exatamente na paleta descrita abaixo — arquivo mestre em `icone-leitor-md-master.png` (2048×2048, RGB, sem canal alfa) e a versão já redimensionada para `icone-leitor-md-1024.png` (1024×1024), pronta para o App Icon do Asset Catalog do Xcode e para o ícone de marketing do App Store Connect.
- Referência de mercado usada para tom e preço: o concorrente "Md Preview" (App Store, R$ 19,90, categoria Utilidades) — ícone com fundo bege/creme quente e uma marca-d'água tipográfica (".md" serifado em tom terracota). A direção visual do Leitor.md se inspira na mesma família de cor (neutro quente, creme/off-white de fundo, sem branco puro) — paleta que também remete à estética atual de ferramentas de IA "modernas" (o Alexandre citou explicitamente a semelhança com a identidade visual do Claude).
  - **Ressalva importante:** recomendo tratar essa semelhança como *inspiração de família de cor* (tons neutros quentes, tipo "papel"), não como réplica da identidade visual da Anthropic — usar a paleta de marca da Anthropic de forma literal num produto comercial sem relação oficial com a empresa é um risco de imagem/possível rejeição de revisão da App Store por sugerir afiliação que não existe (ver risco na seção 23). O prompt de ícone da seção 25 já foi escrito respeitando essa distinção.
  - Paleta sugerida (ajustável na implementação, sem compromisso de hex exato): fundo neutro quente tipo creme/oat (tom próximo de `#F3EEE4`–`#F0EBDD`), texto principal em cinza-carvão quase preto (não preto puro), cor de destaque em terracota/ferrugem suave (tom próximo de `#C1673D`–`#D3805A`) usada com moderação (ações primárias, ícone do app), mantendo o resto da interface bem neutro.
- Base: Apple Human Interface Guidelines, SF Symbols para ícones de sistema, tipografia San Francisco por padrão no chrome do app (fora do conteúdo renderizado, que segue a preferência de fonte de leitura da seção 7.3).
- Densidade: listas (Recentes/Favoritos) em formato de linha com título + origem (ícone) + data relativa, sem thumbnails/preview de imagem no MVP.
- Modo escuro: suportado desde o dia 1 (não é um "extra"), tanto no chrome do app quanto no tema de leitura — nesse modo o "creme" vira um tom escuro quente (não preto puro), mantendo a mesma família de paleta.
- **Screenshots para a App Store:** capturar via iOS Simulator (não fotos de aparelho real), pelo menos para a maior classe de iPhone (atualmente 6.9", 1320×2868px) e a maior classe de iPad (atualmente 13", 2064×2752px) — a Apple aceita esses como o conjunto mínimo e escala para as demais classes na ficha da loja; confirmar o tamanho exato vigente em App Store Connect no momento da submissão, pois muda a cada geração de aparelho. Recomenda-se 5 a 7 screenshots por classe de dispositivo, cobrindo: tela de Leitura (destaque principal), Recentes/Favoritos, seletor de origem (mostrando iCloud/Google Drive/GitHub), tela de exportação, e modo escuro.

---

## 17. Requisitos não-funcionais

- Abertura de um arquivo típico (<200KB) renderizado em menos de 1 segundo, do toque até o conteúdo visível.
- Funcionamento 100% offline para qualquer conteúdo já baixado — sem exceção, incluindo abrir o app em modo avião.
- Acessibilidade: suporte a Dynamic Type no chrome do app; VoiceOver funcional no conteúdo renderizado dentro do WebView (testar especificamente, é o ponto mais frágil); contraste mínimo AA em todos os temas, inclusive nos temas de sintaxe de código.
- Tamanho do binário: meta abaixo de 30MB (as bibliotecas JS bundladas — parser, highlight, KaTeX, Mermaid — são leves).
- Compatibilidade: iPhone SE (tela pequena) até iPad Pro, com layout responsivo (não é multi-coluna interno, ver seção 3).
- Idiomas: português do Brasil (principal) e inglês (fallback) no MVP — outros idiomas ficam para depois.
- Consumo de dados: nenhuma chamada de rede não solicitada pelo usuário (sem telemetria "always-on" — ver seção 21 sobre analytics opcional).

---

## 18. Convenções de código, documentação e estrutura do repositório

- **Modelos de dados (SwiftData) em português**, `snake_case` nos nomes de tabela/enum conforme seção 7 (`documentos`, `preferencias_usuario`, `origem_documento`, etc.) — mesmo não havendo um banco relacional tradicional, a convenção de nomenclatura do domínio vale igual.
- Código, variáveis, funções, nomes de arquivo e de `struct`/`class` Swift em inglês, como é padrão da comunidade iOS — a fronteira de idioma fica nos nomes que espelham o modelo de dados da seção 7 (ex.: a `struct` Swift pode se chamar `Document`, mas o campo salvo mapeando `origem` continua `origem` se for feito via `@Attribute(originalName:)`, ou o time decide manter os nomes das properties Swift também em português para espelhar 1:1 — **decisão do time de implementação**, registrar em `DOCUMENTACAO-TECNICA.md` qual caminho foi seguido).
- Toda função, `ViewModel`, extensão de API e rotina de importação leva comentário de cabeçalho em português explicando o que faz, o que recebe, o que devolve e qual seção deste spec implementa (ex.: `// Busca o conteúdo de um arquivo no GitHub via Contents API (spec 13)`).
- Organização de pastas por feature: `Sources/Abertura` (pickers, share extension, fluxo GitHub), `Sources/Leitura` (WebView, renderização, TOC), `Sources/Biblioteca` (Recentes/Favoritos), `Sources/Configuracoes`, `Sources/ModeloDeDados` (SwiftData), `Sources/Compartilhado` (componentes/UI reutilizáveis).
- README na raiz com setup local, como rodar o app, e como popular dados de exemplo para teste manual.
- Variáveis de ambiente/segredos: `GITHUB_CLIENT_ID` (público, usado só no roadmap v1.1) — nenhum segredo de servidor, pois não há servidor.

---

## 19. Documento de documentação técnica

Ao fim da implementação, gerar `DOCUMENTACAO-TECNICA.md` na raiz do repositório, em português, descrevendo o sistema como implementado de fato (não como planejado), com:

1. Modelo de dados explicado em português — cada tabela SwiftData, para que serve, o que cada campo significa em linguagem de negócio, valores de cada enum.
2. Relacionamento entre as tabelas (mesmo sendo só duas, e independentes — documentar isso explicitamente).
3. Lógica que roda fora da UI (ex.: resolução de bookmark de segurança, montagem de chamada à API do GitHub, geração de PDF) — onde vive cada uma, o que dispara.
4. Mapa tela → dados: para cada tela da seção 10, o que ela lê e escreve de fato no código implementado.
5. Lógica das principais funcionalidades por tela: o que é validado, o que é salvo, o que é calculado e onde.
6. Divergências em relação a este spec — o que saiu diferente do especificado e por quê.

Toda mudança relevante em modelo de dados ou lógica de tela atualiza este documento no mesmo commit.

---

## 20. Privacidade, segurança e conformidade

- **Dados coletados por servidor próprio: nenhum** — não há servidor. O app não envia o conteúdo dos documentos do usuário para lugar nenhum além do necessário para buscá-lo (ex.: chamada à API pública do GitHub para o arquivo que o próprio usuário pediu).
- Recentes/Favoritos/Preferências sincronizam via CloudKit **privado** do usuário — os dados ficam na conta iCloud dele, na infraestrutura da Apple, sem acesso do desenvolvedor.
- Token OAuth do GitHub (v1.1) fica exclusivamente no Keychain do aparelho — nunca sincroniza, nunca é enviado a nenhum servidor além do próprio GitHub.
- LGPD: como não há coleta/processamento de dados pessoais por servidor próprio do desenvolvedor, a exposição é mínima; ainda assim, publicar uma política de privacidade (exigência da App Store) explicando exatamente isso — inclusive o uso do CloudKit privado da Apple.
- App Store Privacy Nutrition Label: declarar o mínimo necessário — se nenhum analytics for adicionado (ver seção 21), a declaração correta é "Dados não coletados".
- Sem dados sensíveis por natureza do produto (não há categoria de saúde, financeiro, menores, biometria envolvida).

---

## 21. Métricas de sucesso e telemetria

Métricas de produto (sem depender de analytics de terceiros, coletáveis via App Store Connect):
- Taxa de conclusão do onboarding.
- Nota média e volume de avaliações na App Store.
- Retenção D7/D30 (App Store Connect já fornece isso nativamente).

Se o time decidir adicionar uma ferramenta de analytics própria (ex.: TelemetryDeck, orientada a privacidade), isso é uma **pergunta aberta** (seção 25) — não está decidido no MVP, e qualquer evento coletado deve respeitar a seção 20 (nunca carregar conteúdo do documento do usuário).

---

## 22. Estratégia de teste

- Fluxos de picker (iCloud Drive, Google Drive) **precisam ser testados em device real** — o simulador não simula bem Document Providers de terceiros como o do Google Drive.
- Teste de carga do WKWebView com documento grande (>50 mil caracteres) e com múltiplos diagramas Mermaid — valida a premissa técnica da seção 4 antes de travar a arquitetura de renderização.
- Teste manual de rate limit do GitHub: forçar 60+ requisições e confirmar que a mensagem de erro da seção 12 aparece corretamente.
- Teste de VoiceOver no conteúdo renderizado dentro do WebView (ponto mais frágil de acessibilidade do produto).
- Teste de sync CloudKit entre dois aparelhos reais logados no mesmo Apple ID (favoritar em um, confirmar que aparece no outro).
- Teste de exportação PDF com documento contendo tabela, código, LaTeX e Mermaid ao mesmo tempo, conferindo se tudo aparece corretamente no PDF gerado.
- Regras de negócio da seção 11 (ordenação de Recentes, limite de 50 itens, extensões aceitas) merecem teste automatizado por serem lógica pura, fácil de isolar.

---

## 23. Riscos e mitigação

| Risco | Impacto | Probabilidade | Mitigação |
|---|---|---|---|
| Rate limit do GitHub anônimo (60/h) frustra uso mais pesado | Médio | Médio (uso individual raramente bate isso, mas testes automatizados/uso intenso podem) | Priorizar login Device Flow (v1.1) cedo no roadmap; cachear localmente a última resposta de cada arquivo já aberto |
| Conflito de UTI com outro app de markdown instalado (seção 4) | Baixo | Médio | Share Extension e picker continuam funcionando mesmo sem ser o "handler padrão" exclusivo |
| Desempenho do WKWebView em documentos muito grandes/Mermaid complexo | Médio | Médio | Validar cedo com teste de carga (seção 22) antes de fechar a arquitetura de renderização em definitivo |
| Usuário não tem o app Google Drive instalado | Baixo (falha graciosa — a origem simplesmente não aparece) | Médio | Nenhuma ação necessária além do comportamento nativo já descrito no épico 8.2 |
| Apple mudar política de Share Extension/UTI em versão futura do iOS | Baixo | Baixo | Acompanhar release notes de cada beta anual do iOS |
| Preço único (sem trial) reduzir conversão de download | Médio | Médio | Reavaliar após lançamento com dados reais de conversão; trial é uma pergunta aberta (seção 25) |
| API nativa (`NSAttributedString`/`officeOpenXML`) não escrever `.docx` de forma confiável em iOS (só documentada com certeza para macOS) | Baixo (DOCX agora é best-effort, seção 24 — não bloqueia o lançamento) | Médio | Validar cedo com uma prova de conceito; se não escrever nem a biblioteca de terceiros resolver a tempo, adiar DOCX para a v1.1 sem afetar a data de lançamento |
| Paleta visual (seção 16) ser confundida com a identidade oficial da Anthropic, por semelhança de família de cor | Baixo-médio (imagem de marca, possível atrito em revisão da App Store) | Baixo | Tratar a referência como inspiração de tom (neutro quente), não replicar hex/logotipo oficiais; deixar claro nos metadados da loja que não há afiliação com a Anthropic |
| App rejeitado na revisão da App Store por não ter botão "Restaurar compra" acessível (exigência do guideline de pagamentos/IAP) | Alto se ignorado (rejeição bloqueia o lançamento) | Baixo (mitigação simples) | Botão de restaurar compra sempre visível no Paywall e nas Configurações (já especificado no épico 8.9) |
| Formato/campos exigidos do `SKILL.md` (frontmatter) mudarem, por ser um recurso relativamente novo da Anthropic | Baixo | Médio | Conferir a convenção vigente de frontmatter (`name`, `description`, e quaisquer campos adicionais) na documentação oficial da Anthropic antes de implementar o épico 8.7, não confiar só neste spec (ver seção 25) |

---

## 24. Assunções declaradas

> Assunção não revisada vira verdade no minuto em que o agente de código começa a implementar. Revise esta seção antes de gerar qualquer código.

- **Nome confirmado (não é mais assunção, é decisão):** "Leitor.md", com subtítulo de App Store "Leitor de Markdown" (para cobertura de ASO em português).
- **Monetização confirmada:** download gratuito + trial de leitura de 1 documento + compra única (IAP não-consumível via StoreKit 2) para desbloquear documentos ilimitados — **preço-alvo em torno de R$ 20** (referência direta: o concorrente "Md Preview" cobra R$ 19,90 pela mesma categoria de produto — ver seção 16). Valor final exato ainda pode ser ajustado dentro dos tiers de preço da Apple, mas R$ 19,90/R$ 20,90 são os candidatos naturais. Isso substitui a ideia inicial de "app pago sem trial" — decisão revisada nesta versão do documento.
- **Escopo do trial:** limitado à quantidade de documentos distintos (1 grátis, ilimitado após compra) — não há limitação de funcionalidade (exportação, temas, favoritar funcionam normalmente no documento do trial). Se preferir limitar também alguma funcionalidade durante o trial (ex.: exportação só depois de comprar), é uma mudança pequena no épico 8.9 — é só avisar.
- **DOCX é best-effort, não obrigatório para a release 1** — dentro do MVP funcional, mas sem bloquear o lançamento se a implementação (biblioteca de terceiros) tomar mais tempo do que o esperado. Se sair da release 1, vira o primeiro item da v1.1 (seção 28).
- **Conta GitHub para o OAuth App (v1.1):** `asiqueira1973`, a mesma já usada em outros projetos do Alexandre — não é mais uma pergunta em aberto (ver seção 27).
- **iPad:** só layout adaptado (tipografia/espaçamento maiores) — sem suporte dedicado a Split View/Slide Over lado a lado no MVP.
- **Escopo do GitHub no MVP:** só abrir um arquivo/README por vez via URL, sem navegar a árvore do repositório nem exigir login — dado que "ler do GitHub" foi pedido como feature importante, mas navegação completa de repositório é um produto bem mais complexo (Listagem de pastas, múltiplos arquivos, cache) que merece ser v1.1 depois de validar a demanda pela versão simples.
- **Extensões de arquivo aceitas:** `.md`, `.markdown`, `.mdown`, `.mkd` — cobre praticamente tudo que existe por aí.
- **iOS mínimo:** 17.0, pela dependência do SwiftData (seção 4).
- **Sem analytics de terceiros no MVP** — métricas vêm só do App Store Connect (seção 21).
- **Sem trial gratuito** antes do pagamento único — decisão simples para o MVP; pode ser revisitada com dados reais depois do lançamento.
- **Exportação "Skill do Claude" sempre gera um `.skill` (zip)**, mesmo quando um `SKILL.md` solto já seria suficiente — escolhido por consistência (um único tipo de arquivo de saída para essa exportação) e porque zip é mais fácil de compartilhar como anexo único. Se preferir que o app ofereça as duas opções (zip ou `SKILL.md` solto), é só avisar.
- **DOCX não preserva realce de sintaxe colorido nem renderiza Mermaid/KaTeX como imagem** no MVP — vira texto monoespaçado simples e um aviso na tela de exportação. Se isso for essencial, é uma extensão de escopo a discutir (provavelmente exigindo renderizar e embutir imagens no `.docx`, mais complexo).

---

## 25. Perguntas abertas

O agente de código deve **perguntar em vez de assumir** ao esbarrar em qualquer um destes pontos:

- Tier de preço exato na Apple (R$ 19,90 vs R$ 20,90, por exemplo) — quem decide: Alexandre, dentro da faixa "em torno de R$ 20" já definida (seção 24). Prazo: antes do lançamento.
- Se haverá alguma ferramenta de analytics de produto além do App Store Connect, e qual — quem decide: Alexandre. Prazo: antes do lançamento, não bloqueia o MVP.
- Formato exato do frontmatter do `SKILL.md` (campos obrigatórios/opcionais além de `name` e `description`, limites de caracteres, regras de nomenclatura) — quem decide: conferir a documentação oficial vigente da Anthropic no início da implementação do épico 8.7, pois é um recurso relativamente novo e este spec não deve ser tratado como fonte definitiva desse formato. Prazo: antes de implementar o épico 8.7, não bloqueia o restante do MVP.

---

## 26. Definition of Done

- [ ] Todos os épicos da seção 8 implementados e validados contra seus critérios de aceite.
- [ ] Testado em device real (não só simulador) para os fluxos de picker de iCloud Drive e Google Drive.
- [ ] Sync CloudKit testado e funcionando entre dois aparelhos reais.
- [ ] Exportação em PDF testada com documento contendo tabela + código + LaTeX + Mermaid simultaneamente.
- [ ] Exportação em HTML e em Skill do Claude testadas de ponta a ponta; DOCX incluído **somente se** tiver saído do best-effort a tempo (seção 24) — release 1 não fica bloqueada por ele.
- [ ] Screenshots da App Store gerados via iOS Simulator para a maior classe de iPhone e a maior classe de iPad (seção 16), cobrindo Leitura, Recentes/Favoritos, seletor de origem, exportação, Paywall e modo escuro.
- [ ] Trial testado de ponta a ponta: primeiro documento livre, segundo documento bloqueado pelo Paywall, compra via sandbox do StoreKit libera corretamente, "Restaurar compra" testado num aparelho/instalação diferente com o mesmo Apple ID.
- [ ] Produto de IAP não-consumível criado e configurado no App Store Connect, com preço no tier definido (seção 25).
- [ ] App Icon (`icone-leitor-md-1024.png`) importado no Asset Catalog do Xcode e enviado como ícone de marketing no App Store Connect.
- [ ] Localização em pt-BR revisada por fonte nativa antes do lançamento (nenhuma string solta em inglês).
- [ ] Modelos de dados (SwiftData) em português conforme a convenção da seção 7, sem tabela/enum fora do padrão.
- [ ] Todas as funções, rotinas de importação e lógica de renderização comentadas conforme seção 18.
- [ ] `DOCUMENTACAO-TECNICA.md` gerado e conferido contra o sistema implementado de fato.
- [ ] Política de privacidade publicada e Privacy Nutrition Label preenchido na App Store Connect.
- [ ] Acessibilidade validada: Dynamic Type no chrome, VoiceOver no conteúdo renderizado, contraste AA nos temas.
- [ ] Seção 24 (Assunções) revisada e confirmada por Alexandre antes da submissão à App Store.

---

## 27. Próximos passos operacionais

1. Revisar as seções 24 (Assunções) e 25 (Perguntas abertas) deste documento.
2. Criar o App ID / bundle identifier e habilitar as capacidades necessárias (iCloud/CloudKit, In-App Purchase) no Apple Developer.
2.1. Criar o produto de IAP não-consumível no App Store Connect (ex.: identificador `leitor_md_desbloqueio_completo`) antes de implementar o épico 8.9, para já testar contra um produto real em sandbox.
3. Registrar o OAuth App no GitHub (mesmo que só usado a partir da v1.1) na conta `asiqueira1973` — vale registrar cedo para já ter o `client_id`.
4. Implementar primeiro o modelo de dados (seção 7), depois as telas (seção 10), seguindo a ordem dos épicos (8.1 → 8.8), deixando o DOCX (dentro do 8.7) como o último a implementar, exatamente por ser best-effort.
5. Rodar o teste de carga do WKWebView (risco da seção 23) antes de considerar a arquitetura de renderização fechada em definitivo.
6. ~~Gerar o ícone~~ — feito: `icone-leitor-md-1024.png` já aprovado (seção 16). Falta só importar no Asset Catalog do Xcode (App Icon) e enviar como ícone de marketing no App Store Connect.
7. Rodar o app no iOS Simulator (classe de iPhone e de iPad maiores) para capturar os screenshots da App Store (seção 16) assim que as telas principais estiverem estáveis — não precisa esperar 100% do MVP pronto, mas precisa dos épicos 8.1, 8.5, 8.6 e 8.7 (ou ao menos PDF/HTML/Skill) implementados.

---

## 28. Roadmap: próximas releases

**v1.1**
- Exportação DOCX, **caso tenha ficado de fora da release 1** por complexidade da implementação (seção 24) — primeiro item da lista, por já ter sido tentado e ter usuários esperando.
- Login GitHub via OAuth Device Flow (client_id público, sem client_secret, conta `asiqueira1973`) — habilita repositórios privados e rate limit de 5.000 req/hora em vez de 60.
- Navegação completa de repositório GitHub: árvore de pastas, múltiplos arquivos, não só um arquivo/README por vez.

**v2**
- Anotações/marcações (highlight) dentro do documento, sem alterar o arquivo original (guardado à parte, associado ao `documento` na seção 7).
- Widget de tela de bloqueio/Hoje com o último documento lido ou os Favoritos.
- Avaliar Mac Catalyst, se a demanda justificar sair do escopo "iOS-only" definido para o MVP.

---

## 29. Protocolo de mudanças incrementais

Depois que a v1 estiver pronta e publicada, para qualquer ajuste pequeno:

1. Faça um commit de checkpoint antes de qualquer mudança, para ter um `git diff` confiável depois.
2. Não cole este spec inteiro de novo — cole só o trecho novo ou alterado, ou escreva um spec adicional específico da feature.
3. Escreva a instrução como diff sobre o que já existe, não como um recomeço — deixe explícito que o projeto já existe e funciona.
4. Diga nominalmente o que **não** deve mudar.
5. Peça a lista de arquivos que serão criados/alterados **antes** de qualquer código, e aprove antes de deixar o agente prosseguir.
6. Revise o `git diff` contra o que foi aprovado; reverta qualquer arquivo que passou do escopo combinado e refaça o pedido de forma mais específica.
7. Exija a atualização do `DOCUMENTACAO-TECNICA.md` no mesmo commit da mudança.

**Modelo de prompt para colar:**

```
O projeto Leitor.md já existe e está funcionando (não é um projeto novo).
Mudança pontual: [descreva a mudança].
Não altere nada fora de: [liste os arquivos/telas esperados].
Antes de codar, monte o plano e a lista de arquivos que vai criar/alterar e me mostre para aprovação.
Depois de implementar, atualize o DOCUMENTACAO-TECNICA.md refletindo essa mudança.
```

---

## Anexo — Fontes

Pesquisa técnica realizada em 2026-08-01:

- [UIDocumentPickerViewController — Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller)
- [App Extension Programming Guide: Document Provider — Apple](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/FileProvider.html)
- [Drive UI integration overview — Google Developers](https://developers.google.com/drive/api/guides/about-apps?authuser=5)
- [Google Drive for iOS updated to make stored documents accessible in Files app — AppleInsider](https://appleinsider.com/articles/17/09/29/google-drive-for-ios-updated-to-make-stored-documents-accessible-in-files-app)
- [swift-markdown-ui — GitHub (gonzalezreal)](https://github.com/gonzalezreal/swift-markdown-ui)
- [UTI Conflicts, iOS — Apple Developer Forums](https://developer.apple.com/forums/thread/755822)
- [Rate limits for the REST API — GitHub Docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)
- [Authorizing OAuth apps (Device Flow) — GitHub Docs](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)
- [How to open a .md file on iPhone (or iPad) — Vela Docs](https://docs.vela.partners/blog/how-to-open-md-file-on-iphone)
- [iOS 26 — Wikipedia](https://en.wikipedia.org/wiki/IOS_26)
- [How to sync SwiftData with iCloud — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)
- [DocX-Swift — biblioteca pure-Swift para leitura/escrita de .docx (CocoaPods/GitHub)](https://libraries.io/cocoapods/DocX-Swift)

Pesquisa de mercado (features de concorrentes) — ver documento "pesquisa-mercado-apps-leitores-markdown.md" no projeto "Leitor de Markdown", consultado na mesma sessão.
