// SeedDebug.swift — semeadura de dados de exemplo para teste (spec 18).
//
// SÓ EM DEBUG e só quando a variável de ambiente de lançamento pede. Não afeta a
// build de produção. Copia `exemplo.md` (do bundle) para o container do app e
// registra um Documento apontando para ele, para exercitar a leitura local
// (spec 8.1) sem depender de tocar no picker do sistema.
//
// Variáveis de ambiente de lançamento:
//   SEED_EXEMPLO=1  → garante o documento de exemplo em Recentes.

#if DEBUG
import Foundation
import SwiftData

enum SeedDebug {

    static var deveSemear: Bool {
        ProcessInfo.processInfo.environment["SEED_EXEMPLO"] == "1"
    }

    static var deveSemearHandoff: Bool {
        ProcessInfo.processInfo.environment["SEED_HANDOFF"] == "1"
    }

    // Simula um item recebido pela Share Extension escrevendo um handoff no
    // container do App Group (spec 8.3). Serve para verificar o consumo no
    // Simulador sem depender da folha de compartilhamento (spec 22).
    @MainActor
    static func semearHandoff() {
        guard let base = HandoffContainer.urlAppGroup() else {
            NSLog("[Seed] App Group indisponível — handoff não semeado")
            return
        }
        let md = "# Recebido via compartilhamento\n\nEste documento chegou pela Share Extension (spec 8.3)."
        try? HandoffContainer.gravarArquivo(nome: "compartilhado.md", dados: Data(md.utf8), base: base)
    }

    static var urlGitHubSeed: String? {
        ProcessInfo.processInfo.environment["SEED_GITHUB"]
    }

    static var deveTestarExportacao: Bool {
        ProcessInfo.processInfo.environment["EXPORT_TEST"] == "1"
    }

    // Gera PDF/HTML/Skill do exemplo.md e copia PDF/HTML para Documents, logando
    // os tamanhos — verificação da exportação (spec 8.7) sem tocar na UI.
    @MainActor
    static func testarExportacao() async {
        guard let url = Bundle.main.url(forResource: "exemplo", withExtension: "md"),
              let md = try? String(contentsOf: url, encoding: .utf8) else { return }
        let prefs = PreferenciasSnapshot.padrao

        let render = RenderizadorExportacao()
        await render.preparar()

        await render.renderizar(md, prefs: prefs.claro)
        if let pdf = await render.gerarPDF(titulo: "export-test") {
            copiar(pdf, para: "export-test.pdf")
            NSLog("[Export] PDF %d bytes", (try? Data(contentsOf: pdf).count) ?? -1)
        }

        let conteudo = await render.renderizar(md, prefs: prefs)
        render.encerrar()
        if let html = ExportadorHTML.exportar(conteudo: conteudo, titulo: "export-test", prefs: prefs) {
            copiar(html, para: "export-test.html")
            NSLog("[Export] HTML %d bytes", (try? Data(contentsOf: html).count) ?? -1)
        }
        if let skill = ExportadorSkill.exportar(nome: "exemplo", descricao: "teste de skill", corpo: md) {
            let dados = (try? Data(contentsOf: skill)) ?? Data()
            let zip = dados.starts(with: [0x50, 0x4B]) // "PK"
            NSLog("[Export] SKILL %d bytes, zip=%@", dados.count, zip ? "sim" : "nao")
        }
    }

    private static func copiar(_ origem: URL, para nome: String) {
        let dest = URL.documentsDirectory.appendingPathComponent(nome)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: origem, to: dest)
    }

    // Simula o compartilhamento de uma URL do GitHub, escrevendo um handoff de URL
    // no App Group (spec 8.3 → 8.4). Serve para testar o fluxo GitHub ao vivo no
    // Simulador sem a folha de compartilhamento (spec 22).
    @MainActor
    static func semearHandoffURL(_ urlString: String) {
        guard let base = HandoffContainer.urlAppGroup() else { return }
        try? HandoffContainer.gravarURL(urlString, base: base)
    }

    // Garante o documento de exemplo em `documentos`. Recebe o contexto; idempotente.
    @MainActor
    static func semear(em contexto: ModelContext) {
        guard let origem = Bundle.main.url(forResource: "exemplo", withExtension: "md") else { return }

        // Copia para o container do app (Documents) para ter uma URL estável de leitura.
        let destino = URL.documentsDirectory.appendingPathComponent("exemplo.md")
        if !FileManager.default.fileExists(atPath: destino.path) {
            try? FileManager.default.copyItem(at: origem, to: destino)
        }

        do {
            let conteudo = try AberturaArquivoServico.abrir(url: destino)
            let doc = DocumentoRepositorio.registrarAberturaLocal(conteudo, em: contexto)
            if ProcessInfo.processInfo.environment["SEED_FAV"] == "1", !doc.favorito {
                DocumentoRepositorio.alternarFavorito(doc)
            }
        } catch {
            // Falha de seed não é relevante para produção — silencia em DEBUG.
        }
    }
}
#endif
