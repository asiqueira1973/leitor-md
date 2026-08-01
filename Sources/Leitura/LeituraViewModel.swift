// LeituraViewModel.swift — estado da tela de Leitura (spec 8.1 / 8.5 / 12).
//
// Implementa a máquina de estados de importação da spec 12
// (ocioso → buscando/renderizando → pronto | erro) para arquivos locais/iCloud,
// mais o portão de aviso de arquivo grande (>5MB, spec 11) antes de renderizar.
// A carga de conteúdo do GitHub (origem .github) entra no épico 8.4.

import SwiftUI
import SwiftData

@Observable
final class LeituraViewModel {

    enum Estado {
        case carregando   // spec 12 — buscando/renderizando
        case pronto
        case erro
    }

    var estado: Estado = .carregando
    var texto: String = ""
    /// Quando true, a view mostra o aviso de arquivo grande antes de renderizar (spec 11).
    var precisaConfirmarGrande = false

    private var confirmadoGrande = false

    // Carrega o conteúdo de um documento conforme a origem (spec 8.1/8.4). Arquivo
    // local/iCloud/compartilhado usa o bookmark; GitHub usa o cache (offline) ou
    // a Contents API.
    @MainActor
    func carregar(_ documento: Documento) async {
        estado = .carregando

        if documento.identificadorLocal != nil {
            carregarArquivo(documento)
        } else if let remoto = documento.identificadorRemoto {
            await carregarGitHub(remoto)
        } else {
            estado = .erro
        }
    }

    // Carrega um documento local pelo bookmark (spec 8.1). Atualiza o bookmark se
    // ficou obsoleto e aplica o portão de arquivo grande (spec 11).
    @MainActor
    private func carregarArquivo(_ documento: Documento) {
        guard let bookmark = documento.identificadorLocal else { estado = .erro; return }
        do {
            let resultado = try AberturaArquivoServico.reabrir(bookmark: bookmark)
            if let novoBookmark = resultado.bookmarkAtualizado {
                DocumentoRepositorio.atualizarBookmark(documento, bookmark: novoBookmark)
            }
            texto = resultado.texto

            let grande = resultado.texto.utf8.count > AberturaArquivoServico.limiteArquivoGrande
            if grande && !confirmadoGrande {
                precisaConfirmarGrande = true   // segura a renderização até confirmar (spec 11)
                return
            }
            estado = .pronto
        } catch {
            estado = .erro
        }
    }

    // Carrega um documento do GitHub (spec 8.4): cache primeiro (offline, spec 17)
    // e, se não houver, busca na Contents API. Recebe o `identificador_remoto`.
    @MainActor
    private func carregarGitHub(_ remoto: String) async {
        if let cache = CacheGitHub.ler(remoto) {
            texto = cache
            estado = .pronto
            return
        }
        guard let destino = destinoDe(remoto) else { estado = .erro; return }
        do {
            let conteudo = try await GitHubContentsAPI.buscar(destino)
            CacheGitHub.salvar(remoto, texto: conteudo.texto)
            texto = conteudo.texto
            estado = .pronto
        } catch {
            estado = .erro
        }
    }

    // Reconstrói o destino do GitHub a partir de `owner/repo/path` (spec 8.4).
    private func destinoDe(_ remoto: String) -> DestinoGitHub? {
        let partes = remoto.split(separator: "/", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
        guard partes.count == 3 else { return nil }
        return DestinoGitHub(owner: partes[0], repo: partes[1], caminho: partes[2], ref: nil)
    }

    // Usuário confirmou renderizar o arquivo grande (spec 11).
    @MainActor
    func confirmarGrande() {
        confirmadoGrande = true
        precisaConfirmarGrande = false
        estado = .pronto
    }

    // Re-seleciona o arquivo via picker quando o bookmark não resolve mais
    // (spec 8.1/12). Atualiza o documento com a nova referência e recarrega.
    @MainActor
    func reselecionar(_ documento: Documento, url: URL) {
        do {
            let conteudo = try AberturaArquivoServico.abrir(url: url)
            documento.identificadorLocal = conteudo.bookmark
            documento.titulo = conteudo.titulo
            documento.tamanhoBytes = conteudo.tamanhoBytes
            documento.abertoEm = Date()
            confirmadoGrande = false
            Task { await carregar(documento) }
        } catch {
            estado = .erro
        }
    }
}
