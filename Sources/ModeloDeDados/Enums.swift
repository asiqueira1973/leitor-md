// Enums.swift — enumerações do modelo de dados (spec 7.4).
//
// Os nomes das enums e seus casos seguem a convenção não-negociável da spec 18:
// o valor persistido (rawValue) é exatamente o nome snake_case da spec 7.4
// (`arquivo_local`, `icloud_drive`, ...). O nome do case em Swift é a versão
// camelCase em português. String-backed + Codable para compatibilidade com
// SwiftData/CloudKit.

import Foundation

/// De onde o documento veio (spec 7.4 — enum `origem_documento`).
enum OrigemDocumento: String, Codable, CaseIterable {
    case arquivoLocal = "arquivo_local"
    case icloudDrive = "icloud_drive"
    case googleDrive = "google_drive"
    case github = "github"
    case compartilhado = "compartilhado"
}

/// Tema de aparência do app (spec 7.4 — enum `tema_app`).
enum TemaApp: String, Codable, CaseIterable {
    case sistema
    case claro
    case escuro
}

/// Tema de realce de sintaxe de código no preview (spec 7.4 — enum `tema_sintaxe_codigo`).
enum TemaSintaxeCodigo: String, Codable, CaseIterable {
    case github
    case dracula
    case monokai
    case solarized
}

/// Família tipográfica do corpo do texto de leitura (spec 7.4 — enum `fonte_leitura`).
enum FonteLeitura: String, Codable, CaseIterable {
    case sistema
    case serifada
    case mono
}
