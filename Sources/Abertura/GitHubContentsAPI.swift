// GitHubContentsAPI.swift — busca de conteúdo no GitHub (spec 8.4 / 13).
//
// Usa a Contents API pública, sem autenticação no MVP (60 req/hora/IP, spec 13).
// A interpretação de status/headers/JSON fica numa função pura (`interpretar`)
// para ser testada sem rede (spec 22); `buscar` só faz a chamada `URLSession` e
// delega. O login (v1.1) e o cache ficam fora daqui.

import Foundation

/// Erros da busca no GitHub, mapeados para as mensagens da spec 12.
enum ErroGitHub: Error, Equatable {
    case urlInvalida
    case naoEncontrado           // 404 — repositório/arquivo inexistente ou privado
    case rateLimit(resetEm: Date) // 403 com limite estourado (spec 11/12)
    case rede
}

/// Conteúdo de um arquivo buscado no GitHub (spec 8.4).
struct ConteudoGitHub: Equatable {
    let titulo: String
    let texto: String
    let tamanhoBytes: Int
    /// `owner/repo/path` — vai para `identificador_remoto` (spec 7.2).
    let identificadorRemoto: String
}

enum GitHubContentsAPI {

    // Busca o conteúdo de um arquivo no GitHub via Contents API (spec 13). Recebe
    // o destino resolvido (owner/repo/path/ref); devolve o ConteudoGitHub ou lança
    // um ErroGitHub tratável pela UI (spec 12).
    static func buscar(_ destino: DestinoGitHub) async throws -> ConteudoGitHub {
        guard let url = montarURL(destino) else { throw ErroGitHub.urlInvalida }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        // A API do GitHub exige User-Agent, senão responde 403 (spec 13).
        request.setValue("LeitorMd", forHTTPHeaderField: "User-Agent")

        let dados: Data
        let resposta: URLResponse
        do {
            (dados, resposta) = try await URLSession.shared.data(for: request)
        } catch {
            throw ErroGitHub.rede
        }
        guard let http = resposta as? HTTPURLResponse else { throw ErroGitHub.rede }

        return try interpretar(
            status: http.statusCode,
            rateLimitRemaining: http.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
            rateLimitReset: http.value(forHTTPHeaderField: "X-RateLimit-Reset"),
            dados: dados,
            destino: destino
        )
    }

    // Monta a URL da Contents API a partir do destino (spec 13).
    static func montarURL(_ destino: DestinoGitHub) -> URL? {
        var componentes = URLComponents()
        componentes.scheme = "https"
        componentes.host = "api.github.com"
        componentes.path = "/repos/\(destino.owner)/\(destino.repo)/contents/\(destino.caminho)"
        if let ref = destino.ref {
            componentes.queryItems = [URLQueryItem(name: "ref", value: ref)]
        }
        return componentes.url
    }

    // Interpreta a resposta HTTP (função pura, testável — spec 22). Recebe status,
    // headers de rate limit e o corpo; devolve o conteúdo ou lança o erro da spec 12.
    static func interpretar(status: Int, rateLimitRemaining: String?, rateLimitReset: String?,
                            dados: Data, destino: DestinoGitHub) throws -> ConteudoGitHub {
        switch status {
        case 200:
            guard let conteudo = decodificar(dados, destino: destino) else {
                // Corpo inesperado (ex.: diretório devolve array) — tratar como não encontrado.
                throw ErroGitHub.naoEncontrado
            }
            return conteudo

        case 403 where (rateLimitRemaining == "0"):
            let reset = Double(rateLimitReset ?? "").map { Date(timeIntervalSince1970: $0) } ?? Date()
            throw ErroGitHub.rateLimit(resetEm: reset)

        case 404, 403:
            // 403 sem limite estourado (ex.: repositório privado) cai como não encontrado (spec 12).
            throw ErroGitHub.naoEncontrado

        default:
            throw ErroGitHub.rede
        }
    }

    // MARK: - Apoio

    private struct RespostaConteudo: Decodable {
        let content: String?
        let encoding: String?
        let name: String?
        let size: Int?
    }

    // Decodifica o JSON de arquivo da Contents API em ConteudoGitHub (spec 13).
    private static func decodificar(_ dados: Data, destino: DestinoGitHub) -> ConteudoGitHub? {
        guard let resp = try? JSONDecoder().decode(RespostaConteudo.self, from: dados),
              resp.encoding == "base64",
              let base64 = resp.content,
              let bytes = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let texto = String(data: bytes, encoding: .utf8) else {
            return nil
        }
        let titulo = resp.name ?? (destino.caminho as NSString).lastPathComponent
        return ConteudoGitHub(
            titulo: titulo,
            texto: texto,
            tamanhoBytes: resp.size ?? bytes.count,
            identificadorRemoto: "\(destino.owner)/\(destino.repo)/\(destino.caminho)"
        )
    }
}
