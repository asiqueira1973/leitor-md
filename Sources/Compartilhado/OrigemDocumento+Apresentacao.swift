// OrigemDocumento+Apresentacao.swift — apresentação da origem na UI (spec 16 / 10).
//
// Mapeia cada origem (spec 7.4) para um ícone SF Symbol e um rótulo curto, usados
// nas linhas de Recentes/Favoritos (spec 16 — linha com título + origem + data).

import SwiftUI

extension OrigemDocumento {

    /// Ícone SF Symbol representando a origem.
    var simbolo: String {
        switch self {
        case .arquivoLocal: return "folder"
        case .icloudDrive:  return "icloud"
        case .googleDrive:  return "externaldrive"
        case .github:       return "chevron.left.forwardslash.chevron.right"
        case .compartilhado: return "square.and.arrow.up"
        }
    }

    /// Rótulo curto da origem para exibição.
    var rotulo: String {
        switch self {
        case .arquivoLocal: return "Arquivo"
        case .icloudDrive:  return "iCloud Drive"
        case .googleDrive:  return "Google Drive"
        case .github:       return "GitHub"
        case .compartilhado: return "Compartilhado"
        }
    }
}
