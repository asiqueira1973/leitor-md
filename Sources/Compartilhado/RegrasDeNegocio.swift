// RegrasDeNegocio.swift — regras de negócio puras da spec 11.
//
// Lógica sem dependência de UI nem de rede, fácil de isolar e testar (spec 22).
// Cada função implementa uma linha da tabela de regras da spec 11.

import Foundation

enum RegrasDeNegocio {

    // Diz se um nome de arquivo tem extensão aceita (spec 11 — extensões aceitas).
    // Recebe o nome/URL do arquivo; devolve true só para .md/.markdown/.mdown/.mkd.
    static func extensaoAceita(_ nomeArquivo: String) -> Bool {
        let ext = (nomeArquivo as NSString).pathExtension.lowercased()
        return IdentificadoresApp.extensoesAceitas.contains(ext)
    }

    // Ordena documentos para a lista de Recentes (spec 11 — ordenação de Recentes):
    // por `abertoEm` decrescente, no máximo `tetoRecentes` itens. Recebe todos os
    // documentos; devolve a fatia visível na lista.
    static func ordenarRecentes(_ documentos: [Documento]) -> [Documento] {
        let ordenados = documentos.sorted { $0.abertoEm > $1.abertoEm }
        return Array(ordenados.prefix(IdentificadoresApp.tetoRecentes))
    }

    // Converte um nome livre para o `name` do frontmatter da Skill do Claude
    // (spec 11 — nome de Skill): minúsculas, sem acento, só letras/números ASCII e
    // hífens, sem hífens nas pontas nem repetidos. Recebe o texto digitado;
    // devolve o kebab-case.
    static func kebabCase(_ texto: String) -> String {
        let semAcento = texto.folding(options: .diacriticInsensitive,
                                      locale: Locale(identifier: "pt_BR"))
        let minusculo = semAcento.lowercased()
        let normalizado = minusculo.map { caractere -> Character in
            let ehLetraASCII = caractere.isLetter && caractere.isASCII
            let ehNumeroASCII = caractere.isNumber && caractere.isASCII
            return (ehLetraASCII || ehNumeroASCII) ? caractere : "-"
        }
        let partes = String(normalizado).split(separator: "-", omittingEmptySubsequences: true)
        return partes.joined(separator: "-")
    }
}
