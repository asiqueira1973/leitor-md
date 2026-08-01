// PreferenciasUsuario.swift — tabela singleton `preferencias_usuario` (spec 7.3).
//
// Uma única linha por instalação/iCloud: preferências de leitura/exibição e o
// cache local do estado de compra (spec 8.9). A fonte de verdade da compra é o
// StoreKit/Apple (`Transaction.currentEntitlements`), não este registro — aqui é
// só cache para checagem offline (spec 7.3 / 8.9).
//
// Convenções (spec 18): properties em português espelhando 1:1 os campos da
// spec 7.3. Todas com default para compatibilidade com CloudKit (spec 4 / 8.6).
// O singleton é garantido em código (`buscarOuCriar`), pois SwiftData+CloudKit
// não impõe unicidade no store (spec 7.5).

import Foundation
import SwiftData

@Model
final class PreferenciasUsuario {

    /// ID fixo constante que garante uma única linha (spec 7.3 — `id`).
    var id: UUID = PreferenciasUsuario.idFixo

    /// Claro/escuro/segue o sistema (spec 7.3 — `tema`).
    var tema: TemaApp = TemaApp.sistema

    /// Tema de realce de código no preview (spec 7.3 — `tema_sintaxe`).
    var temaSintaxe: TemaSintaxeCodigo = TemaSintaxeCodigo.github

    /// Família tipográfica do corpo do texto (spec 7.3 — `fonte_leitura`).
    var fonteLeitura: FonteLeitura = FonteLeitura.sistema

    /// Tamanho base da fonte, em pontos (spec 7.3 — `tamanho_fonte`).
    var tamanhoFonte: Int = 17

    /// Se o app deve reabrir o último documento lido ao iniciar (spec 7.3 —
    /// `abrir_ultimo_arquivo_ao_iniciar`).
    var abrirUltimoArquivoAoIniciar: Bool = false

    /// Se a compra única (IAP não-consumível) já foi feita (spec 7.3 / 8.9 —
    /// `compra_desbloqueada`). Cache local; fonte de verdade é o StoreKit.
    var compraDesbloqueada: Bool = false

    /// Data da compra (spec 7.3 — `data_compra`). Nulo enquanto não comprado.
    /// Também cache local, não fonte de verdade.
    var dataCompra: Date?

    /// Última vez que alguma preferência mudou (spec 7.3 — `atualizado_em`).
    var atualizadoEm: Date = Date()

    /// Valor constante do `id` do singleton (spec 7.3).
    static let idFixo = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    init() {
        self.id = PreferenciasUsuario.idFixo
        self.atualizadoEm = Date()
    }
}
