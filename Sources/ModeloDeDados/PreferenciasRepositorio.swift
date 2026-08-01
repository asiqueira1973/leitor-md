// PreferenciasRepositorio.swift — acesso ao singleton de preferências (spec 7.3 / 7.5).
//
// A unicidade da linha de `preferencias_usuario` é garantida em código (spec 7.5),
// não pelo store. Esta função busca a linha do singleton pelo `id` fixo e a cria
// se ainda não existir.

import Foundation
import SwiftData

enum PreferenciasRepositorio {

    // Busca a linha única de preferências, criando-a se não existir. Recebe o
    // ModelContext; devolve a instância persistida (spec 7.3).
    @MainActor
    static func buscarOuCriar(em contexto: ModelContext) -> PreferenciasUsuario {
        let idFixo = PreferenciasUsuario.idFixo
        var descritor = FetchDescriptor<PreferenciasUsuario>(
            predicate: #Predicate { $0.id == idFixo }
        )
        descritor.fetchLimit = 1

        if let existente = try? contexto.fetch(descritor).first {
            return existente
        }

        let nova = PreferenciasUsuario()
        contexto.insert(nova)
        return nova
    }
}
