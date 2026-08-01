// GitHubAberturaViewModel.swift — estado da tela "Abrir do GitHub" (spec 8.4 / 12).
//
// Orquestra: resolver a URL (ResolvedorURLGitHub) → buscar (GitHubContentsAPI) →
// cachear (CacheGitHub) → registrar o Documento (DocumentoRepositorio). Traduz os
// erros para as mensagens da spec 12.

import SwiftUI
import SwiftData

@Observable
final class GitHubAberturaViewModel {

    enum Estado: Equatable {
        case ocioso
        case buscando
        case erro(String)
    }

    var urlTexto: String = ""
    var estado: Estado = .ocioso

    // Resolve e busca a URL digitada/compartilhada (spec 8.4). Devolve o conteúdo
    // buscado (a Início aplica o portão de trial e registra — spec 8.9) ou nil em
    // caso de erro (a mensagem fica em `estado`). Já cacheia para leitura offline.
    @MainActor
    func abrir() async -> ConteudoGitHub? {
        let entrada = urlTexto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: entrada), let destino = ResolvedorURLGitHub.resolver(url) else {
            estado = .erro(String(localized: "erro.github.nao_encontrado"))
            return nil
        }

        estado = .buscando
        do {
            let conteudo = try await GitHubContentsAPI.buscar(destino)
            CacheGitHub.salvar(conteudo.identificadorRemoto, texto: conteudo.texto)
            estado = .ocioso
            return conteudo
        } catch ErroGitHub.rateLimit(let resetEm) {
            estado = .erro(mensagemRateLimit(resetEm))
            return nil
        } catch ErroGitHub.naoEncontrado {
            estado = .erro(String(localized: "erro.github.nao_encontrado"))
            return nil
        } catch {
            estado = .erro(String(localized: "erro.rede"))
            return nil
        }
    }

    // Monta a mensagem de rate limit com a hora do reset (spec 11/12).
    private func mensagemRateLimit(_ resetEm: Date) -> String {
        let hora = resetEm.formatted(date: .omitted, time: .shortened)
        return String(format: String(localized: "erro.github.rate_limit"), hora)
    }
}
