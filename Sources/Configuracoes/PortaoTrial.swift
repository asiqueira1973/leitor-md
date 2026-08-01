// PortaoTrial.swift — regra do trial de 1 documento (spec 8.9 / 11).
//
// Portão (gate) que intercepta a abertura de um documento NOVO e distinto quando
// o usuário ainda não comprou. Lógica pura, testável (spec 22): a contagem de
// documentos e o estado de compra entram como parâmetros.

import Foundation

enum PortaoTrial {

    // Diz se a abertura deve ser interrompida pelo Paywall (spec 8.9). Recebe:
    //  - jaExiste: o documento já está em `documentos` (reabrir é sempre livre);
    //  - totalDocumentos: quantos documentos já existem;
    //  - compraDesbloqueada: se a compra única já foi feita.
    // Regra (spec 8.9/11): o 1º documento é livre; a partir do 2º documento
    // distinto, sem compra, mostra o Paywall.
    static func precisaComprar(jaExiste: Bool, totalDocumentos: Int, compraDesbloqueada: Bool) -> Bool {
        if compraDesbloqueada { return false }
        if jaExiste { return false }          // reabrir documento já liberado (spec 8.9)
        return totalDocumentos >= 1           // 2º documento distinto → Paywall
    }
}
