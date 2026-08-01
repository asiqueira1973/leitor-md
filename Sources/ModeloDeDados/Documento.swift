// Documento.swift — tabela `documentos` do modelo de dados (spec 7.2).
//
// Guarda o histórico (Recentes) e os Favoritos do usuário. Recentes e Favoritos
// são a MESMA tabela, diferenciados pela flag `favorito` (trade-off declarado na
// spec 7.2). O app nunca é dono do arquivo — só de uma referência a ele (spec 0.3).
//
// Convenções (spec 18): nome da classe = nome da tabela (`Documento`), properties
// em português espelhando 1:1 os campos da spec 7.2.
//
// Compatibilidade com CloudKit (spec 4 / 8.6): todas as properties têm valor
// default e nenhuma usa `@Attribute(.unique)` — CloudKit não suporta constraint
// de unicidade. A unicidade de `identificadorLocal`/`identificadorRemoto`
// (spec 7.2) é garantida em código no momento da inserção (ver RegrasDeNegocio /
// repositório), não pelo store.

import Foundation
import SwiftData

@Model
final class Documento {

    /// Chave primária (spec 7.2 — `id`).
    var id: UUID = UUID()

    /// Nome do arquivo/documento exibido nas listas (spec 7.2 — `titulo`).
    var titulo: String = ""

    /// De onde o documento veio (spec 7.2 — `origem`).
    var origem: OrigemDocumento = OrigemDocumento.arquivoLocal

    /// Bookmark de segurança do `URL` (`URL.bookmarkData`) para reabrir sem novo
    /// picker (spec 7.2 — `identificador_local`). Nulo quando `origem == .github`.
    var identificadorLocal: Data?

    /// `owner/repo/path` da API do GitHub (spec 7.2 — `identificador_remoto`).
    /// Nulo em qualquer origem que não seja `.github`.
    var identificadorRemoto: String?

    /// Se está na lista de Favoritos (spec 7.2 — `favorito`).
    var favorito: Bool = false

    /// Quando foi favoritado (spec 7.2 — `favoritado_em`). Nulo enquanto `favorito == false`.
    var favoritadoEm: Date?

    /// Data/hora da última abertura — usada para ordenar Recentes (spec 7.2 / 11 — `aberto_em`).
    var abertoEm: Date = Date()

    /// Quando o registro foi criado, na primeira abertura (spec 7.2 — `criado_em`).
    var criadoEm: Date = Date()

    /// Tamanho do arquivo em bytes (spec 7.2 — `tamanho_bytes`). Nulo quando não
    /// pôde ser determinado (ex.: GitHub antes do primeiro download).
    var tamanhoBytes: Int?

    // Cria um novo registro de documento. Recebe título, origem e (conforme a
    // origem) o bookmark local ou o identificador remoto; devolve a instância
    // pronta para inserir no ModelContext (spec 7.2).
    init(
        titulo: String,
        origem: OrigemDocumento,
        identificadorLocal: Data? = nil,
        identificadorRemoto: String? = nil,
        tamanhoBytes: Int? = nil,
        abertoEm: Date = Date()
    ) {
        self.id = UUID()
        self.titulo = titulo
        self.origem = origem
        self.identificadorLocal = identificadorLocal
        self.identificadorRemoto = identificadorRemoto
        self.favorito = false
        self.favoritadoEm = nil
        self.abertoEm = abertoEm
        self.criadoEm = Date()
        self.tamanhoBytes = tamanhoBytes
    }
}
