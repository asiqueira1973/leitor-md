// PortaoTrialTests.swift — regra do trial de 1 documento (spec 8.9 / 22).

import XCTest
@testable import LeitorMd

final class PortaoTrialTests: XCTestCase {

    func testPrimeiroDocumentoEhLivre() {
        // Instalação nova (0 documentos) → o primeiro é livre (spec 8.9).
        XCTAssertFalse(PortaoTrial.precisaComprar(
            jaExiste: false, totalDocumentos: 0, compraDesbloqueada: false))
    }

    func testSegundoDocumentoDistintoExigeCompra() {
        // Já há 1 documento e este é novo → Paywall (spec 8.9).
        XCTAssertTrue(PortaoTrial.precisaComprar(
            jaExiste: false, totalDocumentos: 1, compraDesbloqueada: false))
    }

    func testReabrirDocumentoJaLiberadoEhSempreLivre() {
        // Reabrir um documento existente nunca exige compra (spec 8.9).
        XCTAssertFalse(PortaoTrial.precisaComprar(
            jaExiste: true, totalDocumentos: 5, compraDesbloqueada: false))
    }

    func testComCompraTudoLiberado() {
        XCTAssertFalse(PortaoTrial.precisaComprar(
            jaExiste: false, totalDocumentos: 10, compraDesbloqueada: true))
    }
}
