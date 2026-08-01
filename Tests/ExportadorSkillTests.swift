// ExportadorSkillTests.swift — geração do SKILL.md (spec 8.7 / 14 / 22).

import XCTest
@testable import LeitorMd

final class ExportadorSkillTests: XCTestCase {

    func testFrontmatterComNomeKebabEDescricao() {
        let md = ExportadorSkill.montarSkillMd(
            nome: "Meu Ótimo Guia!", descricao: "Explica o processo.", corpo: "# Título\n\nCorpo.")

        XCTAssertTrue(md.hasPrefix("---\n"))
        XCTAssertTrue(md.contains("name: meu-otimo-guia"), "name deve ser kebab-case (spec 11)")
        XCTAssertTrue(md.contains("description: \"Explica o processo.\""))
        XCTAssertTrue(md.contains("# Título\n\nCorpo."), "corpo do documento vai sem alteração (spec 14)")
    }

    func testDescricaoComAspasEQuebrasEhSanitizada() {
        let md = ExportadorSkill.montarSkillMd(
            nome: "x", descricao: "Linha 1\nusa \"aspas\"", corpo: "corpo")
        // Sem quebra de linha na descrição e aspas escapadas (YAML válido).
        XCTAssertTrue(md.contains("description: \"Linha 1 usa \\\"aspas\\\"\""))
        XCTAssertFalse(md.contains("Linha 1\nusa"))
    }
}
