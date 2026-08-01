// LeitorMdApp.swift — ponto de entrada do app (spec 4).
//
// Cria o ModelContainer local-first (ContainerModelo) e injeta no ambiente
// SwiftUI. As telas reais (Início/Leitura/Configurações) entram nos épicos
// seguintes; por ora a raiz é um placeholder que confirma o modelo carregando.

import SwiftUI
import SwiftData

@main
struct LeitorMdApp: App {

    let container: ModelContainer

    init() {
        do {
            container = try ContainerModelo.criar()
        } catch {
            // Falha ao subir o store local é um erro de programação/ambiente,
            // não um estado de usuário — travar cedo facilita diagnosticar.
            fatalError("Falha ao criar o ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            InicioView()
        }
        .modelContainer(container)
    }
}
