// Handoff.swift — troca de conteúdo entre a Share Extension e o app (spec 8.3).
//
// Código PURO (Foundation, sem SwiftData/UIKit) compartilhado pelos dois targets.
// A extensão grava o arquivo/URL recebido no container do App Group; o app
// principal consome no foreground, cria o registro e abre (Fluxo A, spec 9).
// Decisão de design (plano): a extensão não abre o ModelContainer — mantém a
// extensão leve e centraliza a criação do Documento no app.

import Foundation

/// Descreve um item recebido via compartilhamento, aguardando consumo pelo app.
struct HandoffManifest: Codable {
    enum Tipo: String, Codable {
        case arquivo   // arquivo .md recebido (spec 8.3)
        case url       // URL de texto (ex.: link do GitHub → fluxo 8.4)
    }
    let id: String
    let tipo: Tipo
    let nomeArquivo: String?   // preenchido quando tipo == .arquivo
    let urlString: String?     // preenchido quando tipo == .url
    let criadoEm: Date
}

enum HandoffContainer {

    /// Container do App Group compartilhado (spec 8.3). Nil se o App Group não
    /// estiver habilitado (ex.: entitlement ausente).
    static func urlAppGroup() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: IdentificadoresApp.appGroup)
    }

    /// Pasta de entrada do handoff dentro de um container base.
    static func pastaEntrada(base: URL) -> URL {
        base.appendingPathComponent("Handoff", isDirectory: true)
    }

    // Grava um arquivo recebido (extensão, spec 8.3). Recebe nome, bytes e a base
    // do container; devolve o manifesto gravado.
    @discardableResult
    static func gravarArquivo(nome: String, dados: Data, base: URL) throws -> HandoffManifest {
        let id = UUID().uuidString
        let pasta = pastaEntrada(base: base)
        try FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        try dados.write(to: pasta.appendingPathComponent("\(id).data"))

        let manifest = HandoffManifest(id: id, tipo: .arquivo, nomeArquivo: nome,
                                       urlString: nil, criadoEm: Date())
        try gravarManifesto(manifest, em: pasta)
        return manifest
    }

    // Grava uma URL recebida (extensão, spec 8.3 → 8.4). Recebe a URL como texto
    // e a base do container; devolve o manifesto gravado.
    @discardableResult
    static func gravarURL(_ urlString: String, base: URL) throws -> HandoffManifest {
        let id = UUID().uuidString
        let pasta = pastaEntrada(base: base)
        try FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)

        let manifest = HandoffManifest(id: id, tipo: .url, nomeArquivo: nil,
                                       urlString: urlString, criadoEm: Date())
        try gravarManifesto(manifest, em: pasta)
        return manifest
    }

    // Lista os itens pendentes de consumo, mais antigos primeiro (app, spec 8.3).
    // Recebe a base do container; devolve os manifestos e, para arquivos, os bytes.
    static func pendentes(base: URL) -> [(manifest: HandoffManifest, dados: Data?)] {
        let pasta = pastaEntrada(base: base)
        let manifestos = (try? FileManager.default.contentsOfDirectory(at: pasta,
            includingPropertiesForKeys: nil)) ?? []

        return manifestos
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> HandoffManifest? in
                guard let dados = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder.handoff.decode(HandoffManifest.self, from: dados)
            }
            .sorted { $0.criadoEm < $1.criadoEm }
            .map { manifest in
                let arquivo = pasta.appendingPathComponent("\(manifest.id).data")
                let dados = manifest.tipo == .arquivo ? try? Data(contentsOf: arquivo) : nil
                return (manifest, dados)
            }
    }

    // Remove um item já consumido (app, spec 8.3). Recebe o id e a base.
    static func remover(id: String, base: URL) {
        let pasta = pastaEntrada(base: base)
        try? FileManager.default.removeItem(at: pasta.appendingPathComponent("\(id).json"))
        try? FileManager.default.removeItem(at: pasta.appendingPathComponent("\(id).data"))
    }

    // MARK: - Apoio

    private static func gravarManifesto(_ manifest: HandoffManifest, em pasta: URL) throws {
        let dados = try JSONEncoder.handoff.encode(manifest)
        try dados.write(to: pasta.appendingPathComponent("\(manifest.id).json"))
    }
}

private extension JSONEncoder {
    // secondsSince1970 preserva a fração de segundo — essencial para ordenar itens
    // criados no mesmo segundo (spec 8.3). iso8601 padrão truncaria para segundos.
    static let handoff: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()
}

private extension JSONDecoder {
    static let handoff: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
}
