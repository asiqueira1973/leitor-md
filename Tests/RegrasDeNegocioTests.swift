// RegrasDeNegocioTests.swift — testes das regras puras da spec 11 (spec 22).

import XCTest
@testable import LeitorMd

final class RegrasDeNegocioTests: XCTestCase {

    // MARK: - Extensões aceitas (spec 11)

    func testExtensoesAceitas() {
        for nome in ["leia.md", "LEIA.MD", "doc.markdown", "notas.mdown", "x.mkd", "a.b.c.md"] {
            XCTAssertTrue(RegrasDeNegocio.extensaoAceita(nome), "deveria aceitar \(nome)")
        }
    }

    func testExtensoesRejeitadas() {
        for nome in ["arquivo.txt", "imagem.png", "sem-extensao", "doc.mdx", "README"] {
            XCTAssertFalse(RegrasDeNegocio.extensaoAceita(nome), "deveria rejeitar \(nome)")
        }
    }

    // MARK: - Ordenação e teto de Recentes (spec 11)

    func testRecentesOrdenadosPorAberturaDecrescente() {
        let antigo = Documento(titulo: "antigo", origem: .arquivoLocal,
                               abertoEm: Date(timeIntervalSince1970: 100))
        let recente = Documento(titulo: "recente", origem: .arquivoLocal,
                                abertoEm: Date(timeIntervalSince1970: 300))
        let meio = Documento(titulo: "meio", origem: .arquivoLocal,
                             abertoEm: Date(timeIntervalSince1970: 200))

        let ordenados = RegrasDeNegocio.ordenarRecentes([antigo, recente, meio])

        XCTAssertEqual(ordenados.map(\.titulo), ["recente", "meio", "antigo"])
    }

    func testRecentesRespeitaTetoDe50() {
        let docs = (0..<60).map {
            Documento(titulo: "doc\($0)", origem: .arquivoLocal,
                      abertoEm: Date(timeIntervalSince1970: Double($0)))
        }

        let ordenados = RegrasDeNegocio.ordenarRecentes(docs)

        XCTAssertEqual(ordenados.count, 50)
        XCTAssertEqual(ordenados.first?.titulo, "doc59") // mais recente primeiro
        XCTAssertEqual(ordenados.last?.titulo, "doc10")  // 50º item a partir do topo
    }

    // MARK: - kebab-case do nome de Skill (spec 11 / 8.7)

    func testKebabCaseRemoveAcentoEPontuacao() {
        XCTAssertEqual(RegrasDeNegocio.kebabCase("Meu Ótimo Documento!"), "meu-otimo-documento")
    }

    func testKebabCaseColapsaEAparaHifens() {
        XCTAssertEqual(RegrasDeNegocio.kebabCase("  Olá,  Mundo  "), "ola-mundo")
        XCTAssertEqual(RegrasDeNegocio.kebabCase("C++ & Swift"), "c-swift")
    }

    func testKebabCasePreservaJaFormatado() {
        XCTAssertEqual(RegrasDeNegocio.kebabCase("guia-de-estilo"), "guia-de-estilo")
    }
}
