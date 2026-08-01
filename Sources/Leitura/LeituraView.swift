// LeituraView.swift — tela de Leitura/Preview (spec 8.5 / 10).
//
// Renderiza o documento no WKWebView (RenderizadorWebView) com as preferências do
// usuário aplicadas ao vivo (spec 8.5). Barra de ferramentas: sumário (TOC) e
// aparência (tema/fonte/tamanho). Trata os estados da spec 12, o aviso de arquivo
// grande (spec 11) e a re-seleção de bookmark quebrado (spec 8.1). Favoritar entra
// no 8.6 e exportar no 8.7.

import SwiftUI
import SwiftData

struct LeituraView: View {

    let documento: Documento

    @Environment(\.modelContext) private var contexto
    @State private var vm = LeituraViewModel()
    @State private var controlador = RenderizadorControlador()
    @State private var prefs: PreferenciasUsuario?
    @State private var mostrarPicker = false
    @State private var mostrarTOC = false
    @State private var mostrarAparencia = false
    @State private var mostrarExportacao = false
    @State private var toc: [ItemTOC] = []

    private var snapshot: PreferenciasSnapshot {
        prefs.map(PreferenciasSnapshot.init) ?? .padrao
    }

    var body: some View {
        conteudo
            .navigationTitle(documento.titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { barraFerramentas }
            .task {
                if prefs == nil { prefs = PreferenciasRepositorio.buscarOuCriar(em: contexto) }
                await vm.carregar(documento)
            }
            .alert("Arquivo grande", isPresented: bindingAvisoGrande) {
                Button("Continuar") { vm.confirmarGrande() }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Arquivo grande, a renderização pode demorar.") // spec 11
            }
            .sheet(isPresented: $mostrarPicker) {
                SeletorDocumento { url in
                    mostrarPicker = false
                    vm.reselecionar(documento, url: url)
                }
            }
            .sheet(isPresented: $mostrarTOC) {
                SumarioTOCView(itens: toc) { id in controlador.irPara(id) }
            }
            .sheet(isPresented: $mostrarAparencia) {
                if let prefs {
                    aparenciaSheet(prefs)
                }
            }
            .sheet(isPresented: $mostrarExportacao) {
                ExportacaoView(titulo: documento.titulo, markdown: vm.texto, prefs: snapshot)
            }
    }

    @ViewBuilder
    private var conteudo: some View {
        switch vm.estado {
        case .carregando:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Paleta.fundo)

        case .pronto:
            RenderizadorWebView(markdown: vm.texto, preferencias: snapshot, controlador: controlador)
                .ignoresSafeArea(edges: .bottom)

        case .erro:
            erroView
        }
    }

    // Barra de ferramentas de leitura: sumário e aparência (spec 8.5).
    @ToolbarContentBuilder
    private var barraFerramentas: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                DocumentoRepositorio.alternarFavorito(documento)
            } label: {
                Image(systemName: documento.favorito ? "star.fill" : "star")
            }
            .tint(Paleta.destaque)

            Button {
                Task { toc = await controlador.obterTOC(); mostrarTOC = true }
            } label: {
                Image(systemName: "list.bullet")
            }
            .disabled(vm.estado != .pronto)

            Button {
                mostrarAparencia = true
            } label: {
                Image(systemName: "textformat.size")
            }

            Button {
                mostrarExportacao = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(vm.estado != .pronto)
        }
    }

    // Folha de aparência (tema/fonte/tamanho) — reflete ao vivo na Leitura (spec 8.5).
    private func aparenciaSheet(_ prefs: PreferenciasUsuario) -> some View {
        NavigationStack {
            Form {
                Section("Aparência") { ControlesLeitura(prefs: prefs) }
            }
            .navigationTitle("Aparência")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { mostrarAparencia = false }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // Estado de erro de bookmark (spec 8.1/12): mensagem clara + re-selecionar.
    private var erroView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Paleta.destaque)
            Text("Não foi possível abrir este arquivo. Ele pode ter sido movido ou apagado.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Paleta.texto)
            Button("Reselecionar arquivo") { mostrarPicker = true }
                .buttonStyle(.borderedProminent)
                .tint(Paleta.destaque)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Paleta.fundo)
    }

    private var bindingAvisoGrande: Binding<Bool> {
        Binding(get: { vm.precisaConfirmarGrande }, set: { novo in vm.precisaConfirmarGrande = novo })
    }
}
