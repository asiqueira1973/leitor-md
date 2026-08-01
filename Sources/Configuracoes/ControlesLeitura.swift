// ControlesLeitura.swift — controles de tema/fonte/tamanho (spec 8.5 / 7.3).
//
// Editam o singleton PreferenciasUsuario via @Bindable; as mudanças persistem no
// SwiftData e refletem ao vivo na Leitura (spec 8.5). Reutilizado na folha de
// leitura (botão "Aa") e nas Configurações.

import SwiftUI
import SwiftData

struct ControlesLeitura: View {

    @Bindable var prefs: PreferenciasUsuario

    var body: some View {
        Group {
            Picker("Tema", selection: $prefs.tema) {
                ForEach(TemaApp.allCases, id: \.self) { Text($0.rotulo).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Fonte", selection: $prefs.fonteLeitura) {
                ForEach(FonteLeitura.allCases, id: \.self) { Text($0.rotulo).tag($0) }
            }

            Picker("Tema do código", selection: $prefs.temaSintaxe) {
                ForEach(TemaSintaxeCodigo.allCases, id: \.self) { Text($0.rotulo).tag($0) }
            }

            Stepper("Tamanho: \(prefs.tamanhoFonte) pt", value: $prefs.tamanhoFonte, in: 12...28)
        }
        .onChange(of: preferenciasMudaram) { prefs.atualizadoEm = Date() }
    }

    // Chave que muda quando qualquer preferência de leitura muda (registra `atualizadoEm`).
    private var preferenciasMudaram: String {
        "\(prefs.tema.rawValue)\(prefs.fonteLeitura.rawValue)\(prefs.temaSintaxe.rawValue)\(prefs.tamanhoFonte)"
    }
}
