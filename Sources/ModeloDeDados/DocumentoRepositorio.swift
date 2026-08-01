// DocumentoRepositorio.swift — escrita na tabela `documentos` (spec 7.2 / 8.1 / 8.6).
//
// Concentra as operações que criam/atualizam/removem documentos, aplicando em
// código as regras que o store não impõe (unicidade da spec 7.2, spec 7.5). As
// leituras (Recentes/Favoritos) ficam nas telas via @Query (spec 8.6 / 11).

import Foundation
import SwiftData

enum DocumentoRepositorio {

    // Registra a abertura de um arquivo local/iCloud (spec 8.1/8.2). Se o mesmo
    // arquivo já existe em `documentos` (mesmo caminho resolvido — spec 7.2),
    // atualiza `abertoEm`/bookmark em vez de duplicar; senão insere. Recebe o
    // conteúdo lido e o contexto; devolve o Documento persistido.
    @MainActor
    static func registrarAberturaLocal(_ conteudo: ConteudoArquivo,
                                       em contexto: ModelContext) -> Documento {
        let locais = (try? contexto.fetch(descritorLocais())) ?? []
        if let existente = locais.first(where: { mesmoArquivo($0, conteudo.caminho) }) {
            existente.abertoEm = Date()
            existente.identificadorLocal = conteudo.bookmark
            existente.tamanhoBytes = conteudo.tamanhoBytes
            return existente
        }

        let novo = Documento(
            titulo: conteudo.titulo,
            origem: conteudo.origem,
            identificadorLocal: conteudo.bookmark,
            tamanhoBytes: conteudo.tamanhoBytes
        )
        contexto.insert(novo)
        return novo
    }

    // Registra a abertura de um arquivo do GitHub (spec 8.4). Deduplica pelo
    // `identificador_remoto` (spec 7.2): se já existe, atualiza `abertoEm`; senão
    // insere. Recebe o conteúdo buscado e o contexto; devolve o Documento.
    @MainActor
    static func registrarAberturaGitHub(_ conteudo: ConteudoGitHub,
                                        em contexto: ModelContext) -> Documento {
        let remoto = conteudo.identificadorRemoto
        var descritor = FetchDescriptor<Documento>(
            predicate: #Predicate { $0.identificadorRemoto == remoto }
        )
        descritor.fetchLimit = 1

        if let existente = try? contexto.fetch(descritor).first {
            existente.abertoEm = Date()
            existente.titulo = conteudo.titulo
            existente.tamanhoBytes = conteudo.tamanhoBytes
            return existente
        }

        let novo = Documento(
            titulo: conteudo.titulo,
            origem: .github,
            identificadorRemoto: remoto,
            tamanhoBytes: conteudo.tamanhoBytes
        )
        contexto.insert(novo)
        return novo
    }

    // Atualiza o bookmark de um documento (ex.: após reabrir com bookmark
    // obsoleto — spec 8.1). Recebe o documento e o novo bookmark.
    @MainActor
    static func atualizarBookmark(_ documento: Documento, bookmark: Data) {
        documento.identificadorLocal = bookmark
    }

    // Alterna o favorito de um documento (spec 8.6). Ajusta `favorito` e
    // `favoritado_em`, mas NÃO altera `aberto_em` — favoritar não reordena
    // Recentes (regra da spec 11). Recebe o documento.
    @MainActor
    static func alternarFavorito(_ documento: Documento) {
        documento.favorito.toggle()
        documento.favoritadoEm = documento.favorito ? Date() : nil
    }

    // Remove um documento de Recentes/Favoritos (hard delete — spec 7.2). Não
    // afeta o arquivo fonte (spec 0.3). Recebe o documento e o contexto.
    @MainActor
    static func apagar(_ documento: Documento, em contexto: ModelContext) {
        contexto.delete(documento)
    }

    // MARK: - Consultas para o portão de trial (spec 8.9)

    // Total de documentos já registrados (spec 8.9). Recebe o contexto.
    @MainActor
    static func total(em contexto: ModelContext) -> Int {
        (try? contexto.fetchCount(FetchDescriptor<Documento>())) ?? 0
    }

    // Diz se já existe um documento local com determinado caminho (spec 8.9/7.2).
    @MainActor
    static func existeLocal(caminho: String, em contexto: ModelContext) -> Bool {
        let locais = (try? contexto.fetch(descritorLocais())) ?? []
        return locais.contains { mesmoArquivo($0, caminho) }
    }

    // Diz se já existe um documento do GitHub com determinado identificador (spec 8.9/7.2).
    @MainActor
    static func existeGitHub(remoto: String, em contexto: ModelContext) -> Bool {
        var descritor = FetchDescriptor<Documento>(predicate: #Predicate { $0.identificadorRemoto == remoto })
        descritor.fetchLimit = 1
        return ((try? contexto.fetch(descritor).first) ?? nil) != nil
    }

    // MARK: - Apoio

    // Descritor dos documentos de origem local/iCloud (têm bookmark).
    private static func descritorLocais() -> FetchDescriptor<Documento> {
        FetchDescriptor<Documento>(
            predicate: #Predicate { $0.identificadorLocal != nil }
        )
    }

    // Diz se um documento aponta para o arquivo de determinado caminho, resolvendo
    // seu bookmark (spec 7.2).
    private static func mesmoArquivo(_ documento: Documento, _ caminho: String) -> Bool {
        guard let bookmark = documento.identificadorLocal else { return false }
        return AberturaArquivoServico.caminhoResolvido(bookmark) == caminho
    }
}
