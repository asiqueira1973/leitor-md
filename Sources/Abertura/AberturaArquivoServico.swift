// AberturaArquivoServico.swift — abertura de arquivos locais/iCloud (spec 8.1 / 8.2).
//
// Lida com o acesso security-scoped e o bookmark que permite reabrir sem novo
// picker (spec 8.1). Não grava no arquivo fonte — só lê (spec 0.3). A montagem
// da tela e a persistência do Documento ficam na camada de UI/repositório; aqui
// mora só a lógica de arquivo.

import Foundation

/// Erros de abertura de arquivo, mapeados para as mensagens da spec 12.
enum ErroAbertura: Error {
    case extensaoInvalida        // spec 12 — "só abre arquivos Markdown..."
    case bookmarkInvalido        // spec 12 — "arquivo movido ou apagado" (spec 8.1)
    case leituraFalhou
}

/// Conteúdo lido de um arquivo, pronto para renderizar e persistir (spec 8.1).
struct ConteudoArquivo {
    let titulo: String
    let texto: String
    let bookmark: Data
    let origem: OrigemDocumento
    let tamanhoBytes: Int
    /// Caminho absoluto padronizado — usado para deduplicar Recentes pelo arquivo
    /// em si (spec 7.2), não pelos bytes do bookmark (que variam entre seleções).
    let caminho: String
    /// True quando o arquivo passa de 5MB (spec 11 — aviso antes de processar).
    var arquivoGrande: Bool { tamanhoBytes > AberturaArquivoServico.limiteArquivoGrande }
}

enum AberturaArquivoServico {

    /// Limite de "arquivo grande" da spec 11 (5MB).
    static let limiteArquivoGrande = 5 * 1024 * 1024

    // Abre uma URL vinda do document picker (spec 8.1/8.2). Valida a extensão
    // (spec 11), lê o conteúdo, cria o bookmark de segurança e detecta a origem
    // (local vs iCloud). Recebe a URL selecionada; devolve o ConteudoArquivo.
    static func abrir(url: URL) throws -> ConteudoArquivo {
        guard RegrasDeNegocio.extensaoAceita(url.lastPathComponent) else {
            throw ErroAbertura.extensaoInvalida
        }

        let acessou = url.startAccessingSecurityScopedResource()
        defer { if acessou { url.stopAccessingSecurityScopedResource() } }

        let dados: Data
        do {
            dados = try Data(contentsOf: url)
        } catch {
            throw ErroAbertura.leituraFalhou
        }

        let bookmark: Data
        do {
            bookmark = try url.bookmarkData()
        } catch {
            throw ErroAbertura.leituraFalhou
        }

        return ConteudoArquivo(
            titulo: url.lastPathComponent,
            texto: decodificar(dados),
            bookmark: bookmark,
            origem: detectarOrigem(url),
            tamanhoBytes: dados.count,
            caminho: url.standardizedFileURL.path
        )
    }

    // Resolve um bookmark apenas para obter o caminho do arquivo (dedup da spec
    // 7.2). Devolve nil se o bookmark não resolve mais. Não mantém o escopo.
    static func caminhoResolvido(_ bookmark: Data) -> String? {
        var obsoleto = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: [],
                                 relativeTo: nil, bookmarkDataIsStale: &obsoleto) else {
            return nil
        }
        return url.standardizedFileURL.path
    }

    // Reabre um documento a partir do bookmark salvo, sem novo picker (spec 8.1).
    // Recebe o bookmark; devolve o texto e, se o bookmark ficou obsoleto, um
    // bookmark atualizado para regravar. Lança `bookmarkInvalido` se o arquivo
    // não resolve mais (movido/apagado — spec 8.1/12).
    static func reabrir(bookmark: Data) throws -> (texto: String, bookmarkAtualizado: Data?) {
        var obsoleto = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &obsoleto
        ) else {
            throw ErroAbertura.bookmarkInvalido
        }

        let acessou = url.startAccessingSecurityScopedResource()
        defer { if acessou { url.stopAccessingSecurityScopedResource() } }

        guard let dados = try? Data(contentsOf: url) else {
            throw ErroAbertura.bookmarkInvalido
        }

        let novoBookmark = obsoleto ? try? url.bookmarkData() : nil
        return (decodificar(dados), novoBookmark)
    }

    // MARK: - Apoio

    // Detecta a origem da URL (spec 7.4 / 8.2). Consulta a flag de item ubíquo
    // (iCloud) e delega a classificação para uma função pura testável.
    private static func detectarOrigem(_ url: URL) -> OrigemDocumento {
        let ubiquo = (try? url.resourceValues(forKeys: [.isUbiquitousItemKey]))?.isUbiquitousItem ?? false
        return classificarOrigem(caminho: url.path, ehUbiquo: ubiquo)
    }

    // Classifica a origem a partir do caminho e da flag ubíqua (spec 7.4 / 8.2).
    // Best-effort: o provider do Google Drive é reconhecido pelo marcador "google"
    // no caminho do File Provider; iCloud pela flag ubíqua ou pelo caminho do
    // CloudDocs; o resto é tratado como arquivo local.
    //
    // LIMITAÇÃO CONHECIDA (documentar): a detecção precisa de provider de terceiros
    // depende do caminho do File Provider e só é confiável em device real (spec 22).
    // Um arquivo do Google Drive cujo caminho não traga o marcador cai em
    // `arquivo_local` — não quebra nenhum critério de aceite (a reabertura offline
    // via bookmark funciona igual, spec 8.2). Rótulo preciso via NSFileProvider
    // manager (assíncrono) fica como melhoria se necessário.
    static func classificarOrigem(caminho: String, ehUbiquo: Bool) -> OrigemDocumento {
        let baixo = caminho.lowercased()
        if baixo.contains("google") || baixo.contains("com.google") {
            return .googleDrive
        }
        if ehUbiquo || baixo.contains("mobile documents") || baixo.contains("com~apple~clouddocs") {
            return .icloudDrive
        }
        return .arquivoLocal
    }

    // Decodifica os bytes como texto: UTF-8 e, se falhar, ISO Latin-1 (fallback).
    private static func decodificar(_ dados: Data) -> String {
        String(data: dados, encoding: .utf8)
            ?? String(data: dados, encoding: .isoLatin1)
            ?? ""
    }
}
