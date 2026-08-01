// Paleta.swift — cores da identidade visual (spec 16).
//
// Expõe as cores nomeadas do Asset Catalog (que já trazem variante clara/escura)
// como `Color` do SwiftUI, para o chrome do app. Família de cor: neutro quente
// tipo "papel" — creme de fundo, terracota de destaque usado com moderação,
// carvão quase-preto no texto (spec 16). Não replica a identidade da Anthropic.

import SwiftUI

enum Paleta {
    /// Fundo neutro quente (creme claro / escuro quente). Asset `FundoCreme`.
    static let fundo = Color("FundoCreme")
    /// Destaque terracota/ferrugem, usado com moderação (ações primárias, ícone).
    static let destaque = Color("Terracota")
    /// Texto principal em cinza-carvão quase preto (não preto puro).
    static let texto = Color("TextoCarvao")
}
