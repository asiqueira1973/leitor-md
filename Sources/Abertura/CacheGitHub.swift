// CacheGitHub.swift — cache local do conteúdo do GitHub (spec 17 / 23).
//
// Guarda o último conteúdo baixado de cada arquivo do GitHub para que a
// reabertura funcione offline (spec 17) e para amenizar o rate limit anônimo
// (mitigação da spec 23). Chave = `identificador_remoto` (owner/repo/path).

import Foundation
import CryptoKit

enum CacheGitHub {

    // Salva o conteúdo de um arquivo do GitHub (spec 23). Recebe o identificador
    // remoto e o texto; grava no diretório de caches do app.
    static func salvar(_ identificadorRemoto: String, texto: String) {
        guard let url = arquivo(para: identificadorRemoto) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? texto.data(using: .utf8)?.write(to: url)
    }

    // Lê o conteúdo cacheado de um arquivo do GitHub, se houver (spec 17). Recebe
    // o identificador remoto; devolve o texto ou nil.
    static func ler(_ identificadorRemoto: String) -> String? {
        guard let url = arquivo(para: identificadorRemoto),
              let dados = try? Data(contentsOf: url) else { return nil }
        return String(data: dados, encoding: .utf8)
    }

    // MARK: - Apoio

    // Caminho do arquivo de cache, derivado de um hash estável do identificador.
    private static func arquivo(para identificadorRemoto: String) -> URL? {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let base else { return nil }
        let hash = SHA256.hash(data: Data(identificadorRemoto.utf8))
            .map { String(format: "%02x", $0) }.joined()
        return base.appendingPathComponent("GitHub", isDirectory: true)
                   .appendingPathComponent("\(hash).md")
    }
}
