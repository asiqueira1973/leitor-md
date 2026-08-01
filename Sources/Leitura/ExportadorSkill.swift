// ExportadorSkill.swift — exportação como Skill do Claude (spec 8.7 / 14).
//
// Gera um arquivo `.skill` (zip) contendo um `SKILL.md`: frontmatter YAML com
// `name` (kebab-case, spec 11) e `description`, seguido do corpo do documento sem
// alteração de conteúdo (spec 14). Formato confirmado com o Alexandre: só
// name + description.

import Foundation

enum ExportadorSkill {

    // Monta o conteúdo do SKILL.md (função pura, testável — spec 22). Recebe o nome
    // (será convertido para kebab-case), a descrição e o corpo do documento.
    static func montarSkillMd(nome: String, descricao: String, corpo: String) -> String {
        let nomeKebab = RegrasDeNegocio.kebabCase(nome)
        let descricaoLimpa = descricao
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        ---
        name: \(nomeKebab)
        description: "\(descricaoLimpa)"
        ---

        \(corpo)
        """
    }

    // Gera o arquivo `.skill` (zip) e devolve sua URL temporária (spec 14). Recebe
    // o nome, a descrição e o corpo; empacota `<nome>/SKILL.md`.
    static func exportar(nome: String, descricao: String, corpo: String) -> URL? {
        let nomeKebab = RegrasDeNegocio.kebabCase(nome)
        let seguro = nomeKebab.isEmpty ? "skill" : nomeKebab
        let conteudo = montarSkillMd(nome: seguro, descricao: descricao, corpo: corpo)

        // Estrutura temporária <nome>/SKILL.md para o zip conter a pasta da skill.
        let raiz = URL.temporaryDirectory.appendingPathComponent("skill-\(UUID().uuidString)", isDirectory: true)
        let pastaSkill = raiz.appendingPathComponent(seguro, isDirectory: true)
        try? FileManager.default.createDirectory(at: pastaSkill, withIntermediateDirectories: true)
        guard (try? conteudo.data(using: .utf8)?.write(to: pastaSkill.appendingPathComponent("SKILL.md"))) != nil else {
            return nil
        }

        // Zip sem dependência externa via NSFileCoordinator (.forUploading).
        var destino: URL?
        var erro: NSError?
        NSFileCoordinator().coordinate(readingItemAt: pastaSkill, options: .forUploading, error: &erro) { zipTemp in
            let alvo = URL.temporaryDirectory.appendingPathComponent("\(seguro).skill")
            try? FileManager.default.removeItem(at: alvo)
            if (try? FileManager.default.copyItem(at: zipTemp, to: alvo)) != nil {
                destino = alvo
            }
        }
        return destino
    }
}
