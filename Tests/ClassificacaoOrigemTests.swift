// ClassificacaoOrigemTests.swift — testes da detecção de origem (spec 7.4 / 8.2 / 22).
//
// O picker em si precisa de device (spec 22), mas a classificação da origem é
// lógica pura e fica coberta aqui.

import XCTest
@testable import LeitorMd

final class ClassificacaoOrigemTests: XCTestCase {

    func testItemUbiquoEhICloud() {
        let origem = AberturaArquivoServico.classificarOrigem(
            caminho: "/qualquer/caminho/nota.md", ehUbiquo: true)
        XCTAssertEqual(origem, .icloudDrive)
    }

    func testCaminhoCloudDocsEhICloud() {
        let origem = AberturaArquivoServico.classificarOrigem(
            caminho: "/private/var/mobile/Library/Mobile Documents/com~apple~CloudDocs/nota.md",
            ehUbiquo: false)
        XCTAssertEqual(origem, .icloudDrive)
    }

    func testProviderGoogleEhGoogleDrive() {
        let origem = AberturaArquivoServico.classificarOrigem(
            caminho: "/private/var/mobile/.../com.google.Drive/File Provider Storage/nota.md",
            ehUbiquo: false)
        XCTAssertEqual(origem, .googleDrive)
    }

    func testCaminhoLocalEhArquivoLocal() {
        let origem = AberturaArquivoServico.classificarOrigem(
            caminho: "/private/var/mobile/Containers/Data/Application/ABC/Documents/nota.md",
            ehUbiquo: false)
        XCTAssertEqual(origem, .arquivoLocal)
    }
}
