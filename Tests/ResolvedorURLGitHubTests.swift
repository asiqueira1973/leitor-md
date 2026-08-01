// ResolvedorURLGitHubTests.swift — testes do parsing de URL do GitHub (spec 8.4 / 22).

import XCTest
@testable import LeitorMd

final class ResolvedorURLGitHubTests: XCTestCase {

    private func resolver(_ s: String) -> DestinoGitHub? {
        guard let url = URL(string: s) else { return nil }
        return ResolvedorURLGitHub.resolver(url)
    }

    func testBlobResolveArquivoComBranch() {
        let d = resolver("https://github.com/dablab/leitor/blob/main/docs/guia.md")
        XCTAssertEqual(d, DestinoGitHub(owner: "dablab", repo: "leitor",
                                        caminho: "docs/guia.md", ref: "main"))
    }

    func testRawResolveArquivo() {
        let d = resolver("https://raw.githubusercontent.com/dablab/leitor/main/README.md")
        XCTAssertEqual(d, DestinoGitHub(owner: "dablab", repo: "leitor",
                                        caminho: "README.md", ref: "main"))
    }

    func testRaizDoRepoBuscaReadme() {
        let d = resolver("https://github.com/dablab/leitor")
        XCTAssertEqual(d, DestinoGitHub(owner: "dablab", repo: "leitor",
                                        caminho: "README.md", ref: nil))
    }

    func testTreeSemSubcaminhoBuscaReadmeDoBranch() {
        let d = resolver("https://github.com/dablab/leitor/tree/dev")
        XCTAssertEqual(d, DestinoGitHub(owner: "dablab", repo: "leitor",
                                        caminho: "README.md", ref: "dev"))
    }

    func testTreeComSubcaminhoNaoSuportado() {
        // Navegação de diretório é v1.1 (spec 3) → nil.
        XCTAssertNil(resolver("https://github.com/dablab/leitor/tree/main/docs"))
    }

    func testSufixoGitRemovido() {
        let d = resolver("https://github.com/dablab/leitor.git")
        XCTAssertEqual(d?.repo, "leitor")
    }

    func testHostInvalidoDevolveNil() {
        XCTAssertNil(resolver("https://gitlab.com/dablab/leitor/blob/main/x.md"))
        XCTAssertNil(resolver("https://example.com/qualquer/coisa"))
    }
}
