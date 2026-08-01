// LojaStoreKit.swift — compra única via StoreKit 2 (spec 8.9 / 4).
//
// Produto não-consumível que desbloqueia documentos ilimitados. A FONTE DE VERDADE
// é o StoreKit (Transaction.currentEntitlements), não o banco — o campo
// `compra_desbloqueada` da spec 7.3 é só cache local para checagem offline.
// Sincroniza entre aparelhos do mesmo Apple ID automaticamente (spec 4).

import StoreKit

@Observable
@MainActor
final class LojaStoreKit {

    private let idProduto = IdentificadoresApp.produtoIAPDesbloqueio

    var produto: Product?
    var desbloqueado = false
    var ocupado = false

    /// Preço localizado para exibir no Paywall (ex.: "R$ 19,90").
    var precoTexto: String? { produto?.displayPrice }

    // Carrega o produto de IAP e o estado de compra atual (spec 8.9).
    func carregar() async {
        produto = try? await Product.products(for: [idProduto]).first
        await atualizarEntitlements()
    }

    // Consulta o StoreKit se a compra está ativa (fonte de verdade — spec 8.9).
    func atualizarEntitlements() async {
        for await resultado in Transaction.currentEntitlements {
            if case .verified(let t) = resultado,
               t.productID == idProduto, t.revocationDate == nil {
                desbloqueado = true
                return
            }
        }
        desbloqueado = false
    }

    // Compra o desbloqueio (spec 8.9). Devolve true se concluída/verificada.
    func comprar() async -> Bool {
        guard let produto else { return false }
        ocupado = true
        defer { ocupado = false }
        do {
            switch try await produto.purchase() {
            case .success(let verificacao):
                if case .verified(let transacao) = verificacao {
                    await transacao.finish()
                    desbloqueado = true
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false      // cancelar não repete o paywall (spec 8.9)
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    // Restaura a compra em outra instalação/aparelho (spec 8.9 — guideline §23).
    func restaurar() async -> Bool {
        ocupado = true
        defer { ocupado = false }
        try? await AppStore.sync()
        await atualizarEntitlements()
        return desbloqueado
    }
}
