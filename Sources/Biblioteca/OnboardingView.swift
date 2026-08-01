// OnboardingView.swift — onboarding de 3 telas na primeira abertura (spec 8.8 / 15).
//
// Explica as origens suportadas, com opção de pular. Aparece só na primeira
// abertura (rastreado por AppStorage na Início). Textos finais da spec 15.

import SwiftUI

struct OnboardingView: View {

    /// Chamado ao pular ou concluir (marca o onboarding como visto).
    let aoConcluir: () -> Void

    @State private var pagina = 0

    private struct Passo {
        let simbolo: String
        let textoChave: LocalizedStringKey
    }

    private let passos: [Passo] = [
        Passo(simbolo: "textformat.size", textoChave: "onboarding.1"),
        Passo(simbolo: "square.and.arrow.down.on.square", textoChave: "onboarding.2"),
        Passo(simbolo: "eye", textoChave: "onboarding.3")
    ]

    var body: some View {
        ZStack {
            Paleta.fundo.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button("onboarding.pular") { aoConcluir() }
                        .foregroundStyle(Paleta.destaque)
                        .padding()
                }

                TabView(selection: $pagina) {
                    ForEach(passos.indices, id: \.self) { i in
                        VStack(spacing: 28) {
                            Image(systemName: passos[i].simbolo)
                                .font(.system(size: 72))
                                .foregroundStyle(Paleta.destaque)
                            Text(passos[i].textoChave)
                                .font(.system(.title2, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Paleta.texto)
                                .padding(.horizontal, 32)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if pagina < passos.count - 1 {
                        withAnimation { pagina += 1 }
                    } else {
                        aoConcluir()
                    }
                } label: {
                    Text(pagina < passos.count - 1 ? "onboarding.comecar" : "onboarding.comecar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Paleta.destaque)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .opacity(pagina == passos.count - 1 ? 1 : 0)   // "Começar" só na última tela
            }
        }
    }
}
