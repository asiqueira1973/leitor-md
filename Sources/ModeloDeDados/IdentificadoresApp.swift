// IdentificadoresApp.swift — identificadores e constantes de configuração do app.
//
// Centraliza os IDs de infraestrutura (App Group, container CloudKit, produto de
// IAP) e as constantes de regra de negócio (extensões aceitas, teto de Recentes)
// para não espalhar strings mágicas pelo código. Implementa apoio às spec 4, 7,
// 8.9 e 11.

import Foundation

enum IdentificadoresApp {

    /// App Group compartilhado entre o app e a Share Extension (spec 8.3).
    /// Habilitado no portal Apple no épico 8.3.
    static let appGroup = "group.com.dablab.leitormd"

    /// Container CloudKit privado do usuário para sync de Recentes/Favoritos/
    /// preferências (spec 4 / 8.6). Habilitado no portal Apple no épico 8.6.
    static let cloudKitContainer = "iCloud.com.dablab.leitormd"

    /// Produto de IAP não-consumível que desbloqueia documentos ilimitados
    /// (spec 8.9 / 27.2.1).
    static let produtoIAPDesbloqueio = "leitor_md_desbloqueio_completo"

    /// Extensões de arquivo aceitas em qualquer picker / Share Extension (spec 11).
    static let extensoesAceitas: Set<String> = ["md", "markdown", "mdown", "mkd"]

    /// Máximo de itens exibidos na lista de Recentes (spec 11). Itens além disso
    /// continuam no banco, só não aparecem na lista.
    static let tetoRecentes = 50
}
