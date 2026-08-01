// PreferenciasSnapshot.swift — preferências de leitura para a ponte JS (spec 8.5 / 7.3).
//
// Valor imutável e Codable derivado de PreferenciasUsuario, enviado ao
// renderizador (window.aplicarPreferencias) como JSON. Só carrega o que o CSS/JS
// precisa (tema efetivo, tema de código, fonte, tamanho).

import Foundation

struct PreferenciasSnapshot: Codable, Equatable {
    let tema: String          // "sistema" | "claro" | "escuro"
    let temaSintaxe: String   // github | dracula | monokai | solarized
    let fonteLeitura: String  // sistema | serifada | mono
    let tamanhoFonte: Int

    init(_ p: PreferenciasUsuario) {
        self.tema = p.tema.rawValue
        self.temaSintaxe = p.temaSintaxe.rawValue
        self.fonteLeitura = p.fonteLeitura.rawValue
        self.tamanhoFonte = p.tamanhoFonte
    }

    private init(tema: String, temaSintaxe: String, fonteLeitura: String, tamanhoFonte: Int) {
        self.tema = tema; self.temaSintaxe = temaSintaxe
        self.fonteLeitura = fonteLeitura; self.tamanhoFonte = tamanhoFonte
    }

    /// Padrões da spec 7.3 — usado até o singleton de preferências carregar.
    static let padrao = PreferenciasSnapshot(
        tema: "sistema", temaSintaxe: "github", fonteLeitura: "sistema", tamanhoFonte: 17)

    /// Variante em tema claro — o PDF é sempre exportado no claro (spec 14).
    var claro: PreferenciasSnapshot {
        PreferenciasSnapshot(tema: "claro", temaSintaxe: temaSintaxe,
                             fonteLeitura: fonteLeitura, tamanhoFonte: tamanhoFonte)
    }
}
