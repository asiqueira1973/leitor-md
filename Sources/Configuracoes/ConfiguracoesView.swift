// ConfiguracoesView.swift — tela de Configurações (spec 10 / 8.5).
//
// Lê e escreve o singleton PreferenciasUsuario (spec 7.3): tema, fonte, tamanho e
// "abrir último arquivo ao iniciar", além de "Sobre". "Restaurar compra" entra no
// épico 8.9.

import SwiftUI
import SwiftData

struct ConfiguracoesView: View {

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var dismiss
    @State private var prefs: PreferenciasUsuario?
    @State private var loja = LojaStoreKit()
    @State private var restaurando = false

    var body: some View {
        NavigationStack {
            Form {
                if let prefs {
                    ConteudoConfiguracoes(prefs: prefs)
                }
                Section("Compra") {
                    if prefs?.compraDesbloqueada == true {
                        Label("Leitura ilimitada ativa", systemImage: "checkmark.seal")
                            .foregroundStyle(Paleta.destaque)
                    } else {
                        // "Restaurar compra" sempre acessível — guideline de revisão (spec 8.9/23).
                        Button {
                            Task { await restaurar() }
                        } label: {
                            HStack {
                                Text("Restaurar compra")
                                if restaurando { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(restaurando)
                    }
                }
                Section("Sobre") {
                    LabeledContent("Versão", value: Self.versaoApp)
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { dismiss() }
                }
            }
            .task {
                if prefs == nil { prefs = PreferenciasRepositorio.buscarOuCriar(em: contexto) }
            }
        }
    }

    // Restaura a compra via StoreKit e atualiza o cache local (spec 8.9).
    private func restaurar() async {
        restaurando = true
        defer { restaurando = false }
        if await loja.restaurar(), let prefs {
            prefs.compraDesbloqueada = true
            prefs.dataCompra = Date()
        }
    }

    // Versão do app (CFBundleShortVersionString) para a seção "Sobre" (spec 10).
    static var versaoApp: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// Seções editáveis das Configurações — @Bindable no singleton (spec 7.3).
private struct ConteudoConfiguracoes: View {
    @Bindable var prefs: PreferenciasUsuario

    var body: some View {
        Section("Leitura") {
            ControlesLeitura(prefs: prefs)
        }
        Section {
            Toggle("Abrir o último arquivo ao iniciar", isOn: $prefs.abrirUltimoArquivoAoIniciar)
        }
    }
}
