// NomeArquivo.swift — sanitização de nome de arquivo para exportação (spec 14).
//
// Remove caracteres inválidos do título do documento para formar um nome de
// arquivo válido (PDF/HTML/Skill).

import Foundation

enum NomeArquivo {

    // Converte um título em um nome de arquivo válido (spec 14). Recebe o título;
    // devolve algo seguro, com fallback "documento".
    static func sanitizar(_ titulo: String) -> String {
        // Remove extensão de markdown do título, se houver (ex.: "notas.md" → "notas").
        var base = titulo
        for ext in IdentificadoresApp.extensoesAceitas {
            if base.lowercased().hasSuffix("." + ext) {
                base = String(base.dropLast(ext.count + 1))
                break
            }
        }
        let invalidos = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.newlines)
        let limpo = base.components(separatedBy: invalidos).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return limpo.isEmpty ? "documento" : limpo
    }
}
