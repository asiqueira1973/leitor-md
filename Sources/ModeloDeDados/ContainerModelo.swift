// ContainerModelo.swift — construção do ModelContainer do SwiftData (spec 4 / 7).
//
// DECISÃO DE SEQUENCIAMENTO (registrada no plano e na DOCUMENTACAO-TECNICA):
// o app nasce LOCAL-FIRST. O container é criado com armazenamento local simples,
// para rodar no Simulator sem depender do setup de App Group/CloudKit no portal
// Apple (que fica para os épicos 8.3 e 8.6). Quando esses forem habilitados,
// basta trocar a `ModelConfiguration` para a variante CloudKit documentada em
// `configuracaoCloudKit()` abaixo — o resto do app não muda (spec 0.4 / 8.6).

import Foundation
import SwiftData

enum ContainerModelo {

    /// Schema com as duas tabelas do modelo (spec 7.1).
    static let schema = Schema([Documento.self, PreferenciasUsuario.self])

    // Cria o container do app (spec 7 / 8.6). Recebe opção de memória (testes/
    // preview); devolve o ModelContainer. Tenta CloudKit + App Group (sync entre
    // aparelhos do mesmo iCloud, spec 8.6) e, se indisponível — ex.: Simulador sem
    // provisionamento ou aparelho sem conta iCloud —, cai para armazenamento local
    // no MESMO container do App Group, sem erro (spec 6 / 8.6). O app funciona
    // 100% offline em qualquer caso (spec 0.4).
    static func criar(emMemoria: Bool = false) throws -> ModelContainer {
        if emMemoria {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }

        let grupo = ModelConfiguration.GroupContainer.identifier(IdentificadoresApp.appGroup)

        // 1ª tentativa: CloudKit automático (sync via iCloud privado, spec 4/8.6).
        let cloudKit = ModelConfiguration(
            schema: schema,
            groupContainer: grupo,
            cloudKitDatabase: .automatic
        )
        if let container = try? ModelContainer(for: schema, configurations: [cloudKit]) {
            return container
        }

        // Fallback local: mesmo store no App Group, sem CloudKit (spec 6/8.6).
        let local = ModelConfiguration(
            schema: schema,
            groupContainer: grupo,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [local])
    }
}
