// HandoffServico.swift — consumo do handoff da Share Extension pelo app (spec 8.3).
//
// Lê os itens que a Share Extension deixou no container do App Group e os devolve
// como pendências (arquivo ou URL do GitHub) — a Início aplica o portão de trial
// (spec 8.9) e registra/abre. Não insere no banco direto (para o arquivo
// compartilhado também respeitar o trial).

import Foundation

/// Resultado de um consumo de handoff (spec 8.3 / 9).
struct ResultadoHandoff {
    /// Arquivo recém-recebido, pronto para o portão de trial e registro (spec 8.9).
    var arquivoPendente: ConteudoArquivo?
    /// URL do GitHub recebida por compartilhamento, a resolver no fluxo 8.4.
    var urlGitHubPendente: String?
}

enum HandoffServico {

    // Consome os itens pendentes do handoff (spec 8.3). Devolve o arquivo e/ou a
    // URL do GitHub para a Início tratar. Remove cada item após processar.
    static func consumir() -> ResultadoHandoff {
        guard let base = HandoffContainer.urlAppGroup() else { return ResultadoHandoff() }

        var resultado = ResultadoHandoff()
        for (manifest, dados) in HandoffContainer.pendentes(base: base) {
            switch manifest.tipo {
            case .arquivo:
                if let dados, let nome = manifest.nomeArquivo {
                    resultado.arquivoPendente = materializarArquivo(nome: nome, dados: dados)
                }
            case .url:
                resultado.urlGitHubPendente = manifest.urlString
            }
            HandoffContainer.remover(id: manifest.id, base: base)
        }
        return resultado
    }

    // Grava o arquivo recebido no container do app e monta o ConteudoArquivo com
    // origem `compartilhado` (spec 7.4/8.3), sem inserir no banco (o registro é da
    // Início, após o portão de trial da spec 8.9).
    private static func materializarArquivo(nome: String, dados: Data) -> ConteudoArquivo? {
        let destino = URL.documentsDirectory.appendingPathComponent("\(UUID().uuidString.prefix(8))-\(nome)")
        guard (try? dados.write(to: destino)) != nil,
              let bookmark = try? destino.bookmarkData() else { return nil }
        let texto = String(data: dados, encoding: .utf8)
            ?? String(data: dados, encoding: .isoLatin1) ?? ""
        return ConteudoArquivo(
            titulo: nome, texto: texto, bookmark: bookmark,
            origem: .compartilhado, tamanhoBytes: dados.count,
            caminho: destino.standardizedFileURL.path
        )
    }
}
