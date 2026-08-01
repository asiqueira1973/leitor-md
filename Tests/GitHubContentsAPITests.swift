// GitHubContentsAPITests.swift — testes da interpretação da resposta (spec 8.4 / 12 / 22).
//
// A chamada de rede em si precisa de integração; aqui cobrimos a lógica pura de
// interpretar status/headers/JSON, que é onde moram as regras da spec 11/12.

import XCTest
@testable import LeitorMd

final class GitHubContentsAPITests: XCTestCase {

    private let destino = DestinoGitHub(owner: "dablab", repo: "leitor",
                                        caminho: "README.md", ref: nil)

    // Monta um JSON de arquivo da Contents API com o conteúdo em base64.
    private func jsonArquivo(texto: String, nome: String = "README.md") -> Data {
        let base64 = Data(texto.utf8).base64EncodedString()
        return Data("""
        {"name":"\(nome)","encoding":"base64","size":\(texto.utf8.count),"content":"\(base64)"}
        """.utf8)
    }

    func testStatus200DecodificaConteudo() throws {
        let conteudo = try GitHubContentsAPI.interpretar(
            status: 200, rateLimitRemaining: "59", rateLimitReset: nil,
            dados: jsonArquivo(texto: "# Olá mundo"), destino: destino)
        XCTAssertEqual(conteudo.texto, "# Olá mundo")
        XCTAssertEqual(conteudo.titulo, "README.md")
        XCTAssertEqual(conteudo.identificadorRemoto, "dablab/leitor/README.md")
    }

    func testStatus404LancaNaoEncontrado() {
        XCTAssertThrowsError(try GitHubContentsAPI.interpretar(
            status: 404, rateLimitRemaining: "59", rateLimitReset: nil,
            dados: Data("{}".utf8), destino: destino)) { erro in
            XCTAssertEqual(erro as? ErroGitHub, .naoEncontrado)
        }
    }

    func testRateLimitEstouradoLancaComReset() {
        let reset = 1_900_000_000.0 // epoch fixo
        XCTAssertThrowsError(try GitHubContentsAPI.interpretar(
            status: 403, rateLimitRemaining: "0", rateLimitReset: "\(Int(reset))",
            dados: Data("{}".utf8), destino: destino)) { erro in
            XCTAssertEqual(erro as? ErroGitHub, .rateLimit(resetEm: Date(timeIntervalSince1970: reset)))
        }
    }

    func testForbiddenSemLimiteEhNaoEncontrado() {
        // 403 sem rate limit estourado (ex.: repo privado) → não encontrado (spec 12).
        XCTAssertThrowsError(try GitHubContentsAPI.interpretar(
            status: 403, rateLimitRemaining: "50", rateLimitReset: nil,
            dados: Data("{}".utf8), destino: destino)) { erro in
            XCTAssertEqual(erro as? ErroGitHub, .naoEncontrado)
        }
    }

    func testDiretorioOuCorpoInesperadoEhNaoEncontrado() {
        // A Contents API devolve um array para diretórios; não é um arquivo (spec 3).
        XCTAssertThrowsError(try GitHubContentsAPI.interpretar(
            status: 200, rateLimitRemaining: "59", rateLimitReset: nil,
            dados: Data("[]".utf8), destino: destino)) { erro in
            XCTAssertEqual(erro as? ErroGitHub, .naoEncontrado)
        }
    }

    func testMontarURLComRef() {
        let d = DestinoGitHub(owner: "a", repo: "b", caminho: "docs/x.md", ref: "main")
        let url = GitHubContentsAPI.montarURL(d)
        XCTAssertEqual(url?.absoluteString, "https://api.github.com/repos/a/b/contents/docs/x.md?ref=main")
    }
}
