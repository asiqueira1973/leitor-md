// InicioView.swift — tela Início (spec 8.6 / 10 / 15).
//
// Ponto de partida do app: atalho para abrir arquivo, lista de Recentes e de
// Favoritos. No épico 8.1 já traz a abertura local/iCloud funcionando e o fluxo
// de bookmark quebrado (spec 8.1/12). O botão "Abrir do GitHub" entra no 8.4;
// favoritar e o sync completo, no 8.6.

import SwiftUI
import SwiftData

struct InicioView: View {

    @Environment(\.modelContext) private var contexto
    @Environment(\.scenePhase) private var faseCena

    // Todos os documentos ordenados por última abertura (spec 11); a lista de
    // Recentes aplica o teto de 50 (spec 11) via `recentes`.
    @Query(sort: \Documento.abertoEm, order: .reverse) private var documentos: [Documento]
    @Query private var prefsLista: [PreferenciasUsuario]

    @State private var mostrarPicker = false
    @State private var githubSheet: GitHubSheetContexto?
    @State private var destino: Documento?
    @State private var idsComBookmarkQuebrado: Set<UUID> = []
    @State private var mostrarErroExtensao = false
    @State private var mostrarConfiguracoes = false
    @State private var loja = LojaStoreKit()
    @State private var mostrarPaywall = false
    @State private var pendenteAposCompra: (@MainActor () -> Void)?
    /// Onboarding só aparece na primeira abertura (spec 8.8), por instalação.
    @AppStorage("onboarding_visto") private var onboardingVisto = false

    private var compraDesbloqueada: Bool { prefsLista.first?.compraDesbloqueada ?? false }

    private var recentes: [Documento] {
        Array(documentos.prefix(IdentificadoresApp.tetoRecentes))
    }
    private var favoritos: [Documento] {
        documentos.filter(\.favorito)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundo.ignoresSafeArea()
                if documentos.isEmpty {
                    estadoVazio
                } else {
                    listas
                }
            }
            .navigationTitle("app.nome")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        mostrarConfiguracoes = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Paleta.destaque)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            mostrarPicker = true
                        } label: {
                            Label("botao.abrir_arquivo", systemImage: "folder")
                        }
                        Button {
                            githubSheet = GitHubSheetContexto(urlInicial: nil)
                        } label: {
                            Label("botao.abrir_github", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Paleta.destaque)
                }
            }
            .navigationDestination(item: $destino) { doc in
                LeituraView(documento: doc)
            }
            .sheet(isPresented: $mostrarPicker) {
                SeletorDocumento { url in
                    mostrarPicker = false
                    abrirNovo(url: url)
                }
            }
            .sheet(item: $githubSheet) { ctx in
                AberturaGitHubView(urlInicial: ctx.urlInicial) { conteudo in
                    abrirGitHub(conteudo)
                }
            }
            .sheet(isPresented: $mostrarConfiguracoes) {
                ConfiguracoesView()
            }
            .sheet(isPresented: $mostrarPaywall, onDismiss: { pendenteAposCompra = nil }) {
                PaywallView(loja: loja) { marcarComprado() }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !onboardingVisto },
                set: { mostrar in if !mostrar { onboardingVisto = true } }
            )) {
                OnboardingView { onboardingVisto = true }
            }
            .alert("Extensão não suportada", isPresented: $mostrarErroExtensao) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("erro.extensao_invalida")
            }
            .task { _ = PreferenciasRepositorio.buscarOuCriar(em: contexto) }
            .task(id: documentos.count) { await revalidarBookmarks() }
            .task { prepararDebugSeNecessario() }
            .task { consumirHandoff() }
            .task {
                // Reflete no cache local uma compra já feita (outra instalação/
                // aparelho via StoreKit) — fonte de verdade é o StoreKit (spec 8.9).
                await loja.carregar()
                if loja.desbloqueado { marcarComprado() }
            }
            .onChange(of: faseCena) { _, nova in
                if nova == .active { consumirHandoff() }
            }
        }
    }

    // Consome o handoff da Share Extension (spec 8.3): abre o arquivo recebido
    // (passando pelo portão de trial — spec 8.9) e/ou dispara o fluxo GitHub (8.4).
    private func consumirHandoff() {
        let resultado = HandoffServico.consumir()
        if let conteudo = resultado.arquivoPendente {
            let jaExiste = DocumentoRepositorio.existeLocal(caminho: conteudo.caminho, em: contexto)
            abrirComPortao(jaExiste: jaExiste) {
                DocumentoRepositorio.registrarAberturaLocal(conteudo, em: contexto)
            }
        }
        if let url = resultado.urlGitHubPendente {
            githubSheet = GitHubSheetContexto(urlInicial: url)
        }
    }

    // Semeadura/abertura automática de exemplo — só em DEBUG e sob variável de
    // ambiente (spec 18). Sem efeito em produção.
    private func prepararDebugSeNecessario() {
        #if DEBUG
        if SeedDebug.deveSemear {
            SeedDebug.semear(em: contexto)
        }
        if SeedDebug.deveSemearHandoff {
            SeedDebug.semearHandoff()
            consumirHandoff()
        }
        if let urlGitHub = SeedDebug.urlGitHubSeed {
            SeedDebug.semearHandoffURL(urlGitHub)
            consumirHandoff()
        }
        if SeedDebug.deveTestarExportacao {
            Task { await SeedDebug.testarExportacao() }
        }
        if ProcessInfo.processInfo.environment["OPEN_EXEMPLO"] == "1" {
            let descritor = FetchDescriptor<Documento>(
                sortBy: [SortDescriptor(\.abertoEm, order: .reverse)]
            )
            destino = try? contexto.fetch(descritor).first
        }
        #endif
    }

    // MARK: - Estado vazio (spec 15)

    private var estadoVazio: some View {
        VStack(spacing: 20) {
            Text("app.nome")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Paleta.destaque)
            Text("recentes.vazio")
                .multilineTextAlignment(.center)
                .foregroundStyle(Paleta.texto.opacity(0.8))
            Button {
                mostrarPicker = true
            } label: {
                Label("botao.abrir_arquivo", systemImage: "folder")
                    .frame(maxWidth: 260)
            }
            .buttonStyle(.borderedProminent)
            .tint(Paleta.destaque)

            Button {
                githubSheet = GitHubSheetContexto(urlInicial: nil)
            } label: {
                Label("botao.abrir_github", systemImage: "chevron.left.forwardslash.chevron.right")
                    .frame(maxWidth: 260)
            }
            .buttonStyle(.bordered)
            .tint(Paleta.destaque)
        }
        .padding()
    }

    // MARK: - Listas de Recentes/Favoritos (spec 10)

    private var listas: some View {
        List {
            if !favoritos.isEmpty {
                Section("secao.favoritos") {
                    ForEach(favoritos) { linha($0) }
                }
            }
            Section("secao.recentes") {
                if recentes.isEmpty {
                    Text("recentes.vazio").foregroundStyle(.secondary)
                } else {
                    ForEach(recentes) { linha($0) }
                        .onDelete { apagar(recentes, em: $0) }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Paleta.fundo)
    }

    // Linha de documento: origem + título + data relativa + indicador de erro
    // quando o bookmark não resolve mais (spec 8.1/16).
    private func linha(_ doc: Documento) -> some View {
        Button {
            destino = doc
        } label: {
            HStack(spacing: 12) {
                Image(systemName: doc.origem.simbolo)
                    .foregroundStyle(Paleta.destaque)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.titulo).lineLimit(1).foregroundStyle(Paleta.texto)
                    Text(doc.abertoEm, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if doc.favorito {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Paleta.destaque)
                }
                if idsComBookmarkQuebrado.contains(doc.id) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                DocumentoRepositorio.alternarFavorito(doc)
            } label: {
                Label(doc.favorito ? "Desfavoritar" : "Favoritar",
                      systemImage: doc.favorito ? "star.slash" : "star")
            }
            .tint(Paleta.destaque)
        }
    }

    // MARK: - Ações

    // Abre um arquivo novo pelo picker (spec 8.1): lê e, passando pelo portão de
    // trial (spec 8.9), registra e navega para a Leitura.
    private func abrirNovo(url: URL) {
        do {
            let conteudo = try AberturaArquivoServico.abrir(url: url)
            let jaExiste = DocumentoRepositorio.existeLocal(caminho: conteudo.caminho, em: contexto)
            abrirComPortao(jaExiste: jaExiste) {
                DocumentoRepositorio.registrarAberturaLocal(conteudo, em: contexto)
            }
        } catch {
            mostrarErroExtensao = true
        }
    }

    // Registra e abre um arquivo do GitHub buscado (spec 8.4), pelo portão de
    // trial (spec 8.9).
    private func abrirGitHub(_ conteudo: ConteudoGitHub) {
        let jaExiste = DocumentoRepositorio.existeGitHub(remoto: conteudo.identificadorRemoto, em: contexto)
        abrirComPortao(jaExiste: jaExiste) {
            DocumentoRepositorio.registrarAberturaGitHub(conteudo, em: contexto)
        }
    }

    // Portão de trial (spec 8.9): se puder abrir, registra e navega; senão guarda a
    // abertura pendente e mostra o Paywall, concluindo após a compra.
    @MainActor
    private func abrirComPortao(jaExiste: Bool, registrar: @escaping @MainActor () -> Documento) {
        let precisa = PortaoTrial.precisaComprar(
            jaExiste: jaExiste,
            totalDocumentos: DocumentoRepositorio.total(em: contexto),
            compraDesbloqueada: compraDesbloqueada
        )
        if precisa {
            pendenteAposCompra = { destino = registrar() }
            mostrarPaywall = true
        } else {
            destino = registrar()
        }
    }

    // Marca a compra como desbloqueada no cache local (spec 7.3/8.9) e conclui a
    // abertura que estava pendente, se houver (spec 8.9).
    @MainActor
    private func marcarComprado() {
        let prefs = PreferenciasRepositorio.buscarOuCriar(em: contexto)
        if !prefs.compraDesbloqueada {
            prefs.compraDesbloqueada = true
            prefs.dataCompra = Date()
        }
        pendenteAposCompra?()
        pendenteAposCompra = nil
    }

    private func apagar(_ lista: [Documento], em indices: IndexSet) {
        for i in indices { DocumentoRepositorio.apagar(lista[i], em: contexto) }
    }

    // Revalida quais bookmarks ainda resolvem, fora da main thread, para marcar as
    // linhas com erro (spec 8.1). Só processa documentos locais (com bookmark).
    private func revalidarBookmarks() async {
        let pares: [(UUID, Data)] = recentes.compactMap { doc in
            doc.identificadorLocal.map { (doc.id, $0) }
        }
        let quebrados = await Task.detached { () -> Set<UUID> in
            var conjunto: Set<UUID> = []
            for (id, bookmark) in pares where AberturaArquivoServico.caminhoResolvido(bookmark) == nil {
                conjunto.insert(id)
            }
            return conjunto
        }.value
        idsComBookmarkQuebrado = quebrados
    }
}
