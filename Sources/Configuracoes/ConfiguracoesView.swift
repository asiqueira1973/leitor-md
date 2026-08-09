// ConfiguracoesView.swift — tela de Configurações (spec 10 / 8.5 / 8.9).
//
// Lê e escreve o singleton PreferenciasUsuario (spec 7.3): tema, fonte, tamanho e
// "abrir último arquivo ao iniciar", além de "Sobre". Na seção Compra oferece
// abrir o Paywall manualmente ("Desbloquear leitura ilimitada" — acesso previsto
// no inventário de telas da spec 10) e "Restaurar compra" (spec 8.9/23).

import SwiftUI
import SwiftData

struct ConfiguracoesView: View {

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var dismiss
    @State private var prefs: PreferenciasUsuario?
    @State private var loja = LojaStoreKit()
    @State private var restaurando = false
    @State private var mostrarPaywall = false

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
                        // Acesso manual ao Paywall (spec 10) — torna a compra fácil de
                        // encontrar (exigência da revisão da App Store).
                        Button {
                            mostrarPaywall = true
                        } label: {
                            Label("Desbloquear leitura ilimitada", systemImage: "lock.open")
                                .foregroundStyle(Paleta.destaque)
                        }
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
            .sheet(isPresented: $mostrarPaywall) {
                PaywallView(loja: loja) { marcarComprado() }
            }
        }
    }

    // Marca a compra no cache local após comprar/restaurar pelo Paywall (spec 7.3/8.9).
    private func marcarComprado() {
        guard let prefs else { return }
        prefs.compraDesbloqueada = true
        prefs.dataCompra = Date()
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
