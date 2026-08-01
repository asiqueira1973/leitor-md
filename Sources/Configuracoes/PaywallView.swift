// PaywallView.swift — tela de compra única (spec 8.9 / 10).
//
// Aparece ao tentar abrir um 2º documento sem compra (portão da spec 8.9) ou
// manualmente. Mostra o preço, o botão de comprar e o de "Restaurar compra"
// (sempre acessível — guideline §23). Ao concluir, chama `aoDesbloquear` para a
// Início liberar a abertura pendente.

import SwiftUI

struct PaywallView: View {

    let loja: LojaStoreKit
    /// Chamado quando a compra/restauração desbloqueia (spec 8.9).
    let aoDesbloquear: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Paleta.fundo.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "book.pages")
                        .font(.system(size: 56))
                        .foregroundStyle(Paleta.destaque)
                    Text("Leitura ilimitada")
                        .font(.system(.title, design: .serif).weight(.semibold))
                        .foregroundStyle(Paleta.texto)
                    Text("Você leu seu primeiro documento de graça. Desbloqueie a leitura de quantos documentos quiser, com uma compra única.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Paleta.texto.opacity(0.8))
                        .padding(.horizontal)

                    Spacer()

                    Button {
                        Task { await comprar() }
                    } label: {
                        Group {
                            if loja.ocupado {
                                ProgressView()
                            } else {
                                Text(textoBotaoComprar)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Paleta.destaque)
                    .controlSize(.large)
                    .disabled(loja.produto == nil || loja.ocupado)

                    Button("Restaurar compra") {
                        Task { await restaurar() }
                    }
                    .foregroundStyle(Paleta.destaque)
                    .disabled(loja.ocupado)
                }
                .padding()
                .padding(.bottom)
            }
            .navigationTitle("Desbloquear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Agora não") { dismiss() }
                }
            }
            .task { await loja.carregar() }
        }
    }

    private var textoBotaoComprar: String {
        if let preco = loja.precoTexto { return "Desbloquear por \(preco)" }
        return "Desbloquear"
    }

    private func comprar() async {
        if await loja.comprar() {
            aoDesbloquear()
            dismiss()
        }
    }

    private func restaurar() async {
        if await loja.restaurar() {
            aoDesbloquear()
            dismiss()
        }
    }
}
