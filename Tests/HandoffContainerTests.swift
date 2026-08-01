// HandoffContainerTests.swift — round-trip do handoff (spec 8.3 / 22).
//
// A folha de compartilhamento em si exige device (spec 22), mas a gravação/leitura
// do container é lógica pura e fica coberta aqui usando um diretório temporário
// como base (no lugar do container real do App Group).

import XCTest
@testable import LeitorMd

final class HandoffContainerTests: XCTestCase {

    private var base: URL!

    override func setUpWithError() throws {
        base = URL.temporaryDirectory.appendingPathComponent("handoff-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: base)
    }

    func testGravarELerArquivo() throws {
        let dados = Data("# Olá".utf8)
        try HandoffContainer.gravarArquivo(nome: "nota.md", dados: dados, base: base)

        let pendentes = HandoffContainer.pendentes(base: base)
        XCTAssertEqual(pendentes.count, 1)
        XCTAssertEqual(pendentes.first?.manifest.tipo, .arquivo)
        XCTAssertEqual(pendentes.first?.manifest.nomeArquivo, "nota.md")
        XCTAssertEqual(pendentes.first?.dados, dados)
    }

    func testGravarELerURL() throws {
        try HandoffContainer.gravarURL("https://github.com/dablab/leitor", base: base)

        let pendentes = HandoffContainer.pendentes(base: base)
        XCTAssertEqual(pendentes.count, 1)
        XCTAssertEqual(pendentes.first?.manifest.tipo, .url)
        XCTAssertEqual(pendentes.first?.manifest.urlString, "https://github.com/dablab/leitor")
        XCTAssertNil(pendentes.first?.dados)
    }

    func testRemoverItemConsumido() throws {
        let m = try HandoffContainer.gravarArquivo(nome: "a.md", dados: Data("x".utf8), base: base)
        try HandoffContainer.gravarURL("https://github.com/x/y", base: base)
        XCTAssertEqual(HandoffContainer.pendentes(base: base).count, 2)

        HandoffContainer.remover(id: m.id, base: base)
        let restantes = HandoffContainer.pendentes(base: base)
        XCTAssertEqual(restantes.count, 1)
        XCTAssertEqual(restantes.first?.manifest.tipo, .url)
    }

    func testPendentesOrdenadosPorCriacao() throws {
        let primeiro = try HandoffContainer.gravarURL("https://github.com/1/1", base: base)
        Thread.sleep(forTimeInterval: 0.01)
        let segundo = try HandoffContainer.gravarURL("https://github.com/2/2", base: base)

        let ids = HandoffContainer.pendentes(base: base).map(\.manifest.id)
        XCTAssertEqual(ids, [primeiro.id, segundo.id])
    }
}
