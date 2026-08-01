// FavoritoTests.swift — regra de favoritar (spec 8.6 / 11).

import XCTest
@testable import LeitorMd

@MainActor
final class FavoritoTests: XCTestCase {

    func testFavoritarNaoAlteraAbertoEm() {
        let abertura = Date(timeIntervalSince1970: 1000)
        let doc = Documento(titulo: "x", origem: .arquivoLocal, abertoEm: abertura)

        DocumentoRepositorio.alternarFavorito(doc)

        XCTAssertTrue(doc.favorito)
        XCTAssertNotNil(doc.favoritadoEm)
        XCTAssertEqual(doc.abertoEm, abertura, "favoritar não pode reordenar Recentes (spec 11)")
    }

    func testDesfavoritarLimpaData() {
        let doc = Documento(titulo: "x", origem: .arquivoLocal)
        DocumentoRepositorio.alternarFavorito(doc)   // favorita
        DocumentoRepositorio.alternarFavorito(doc)   // desfavorita

        XCTAssertFalse(doc.favorito)
        XCTAssertNil(doc.favoritadoEm)
    }
}
