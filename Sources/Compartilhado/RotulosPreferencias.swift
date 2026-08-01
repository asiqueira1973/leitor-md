// RotulosPreferencias.swift — rótulos pt-BR das enums de preferência (spec 15 / 8.5).
//
// Nomes de exibição das opções de tema/fonte usados nos controles de leitura e nas
// Configurações. Mantém a apresentação separada do modelo (spec 7.4).

import Foundation

extension TemaApp {
    var rotulo: String {
        switch self {
        case .sistema: return "Sistema"
        case .claro:   return "Claro"
        case .escuro:  return "Escuro"
        }
    }
}

extension TemaSintaxeCodigo {
    var rotulo: String {
        switch self {
        case .github:    return "GitHub"
        case .dracula:   return "Dracula"
        case .monokai:   return "Monokai"
        case .solarized: return "Solarized"
        }
    }
}

extension FonteLeitura {
    var rotulo: String {
        switch self {
        case .sistema:  return "Sistema"
        case .serifada: return "Serifada"
        case .mono:     return "Monoespaçada"
        }
    }
}
