// ShareViewController.swift — ponto de entrada da Share Extension (spec 8.3).
//
// Recebe o item compartilhado de outro app (ChatGPT/Notion/GitHub/WhatsApp/Mail),
// grava-o no container do App Group (handoff) e completa a requisição. O app
// principal consome o handoff e abre na Leitura (Fluxo A, spec 9). A extensão
// NÃO abre o ModelContainer — decisão de design do plano (mantém a extensão leve).
//
// Tipos tratados (spec 8.3):
//   - Arquivo .md/.markdown/.mdown/.mkd → handoff de arquivo.
//   - URL web (link do GitHub) ou texto que seja URL → handoff de URL (→ fluxo 8.4).
//   - Qualquer outro tipo: a extensão nem deveria ativar (NSExtensionActivationRule),
//     mas por segurança apenas completa sem gravar.

import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        processar()
    }

    // Percorre os anexos do item compartilhado e grava o primeiro suportado.
    private func processar() {
        guard let base = HandoffContainer.urlAppGroup(),
              let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let anexos = item.attachments else {
            return finalizar()
        }

        for anexo in anexos {
            if anexo.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                carregarArquivo(anexo, base: base); return
            }
            if anexo.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                carregarURL(anexo, base: base); return
            }
            if anexo.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                carregarTexto(anexo, base: base); return
            }
        }
        finalizar()
    }

    // Carrega um arquivo recebido e grava o handoff se a extensão for aceita (spec 11).
    private func carregarArquivo(_ anexo: NSItemProvider, base: URL) {
        anexo.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
            defer { self?.finalizar() }
            guard let self else { return }
            var url: URL?
            if let u = item as? URL { url = u }
            else if let dados = item as? Data { url = URL(dataRepresentation: dados, relativeTo: nil) }
            guard let fileURL = url,
                  self.extensaoAceita(fileURL.lastPathComponent),
                  let dados = try? Data(contentsOf: fileURL) else { return }
            try? HandoffContainer.gravarArquivo(nome: fileURL.lastPathComponent, dados: dados, base: base)
        }
    }

    // Carrega uma URL web e grava o handoff de URL (→ fluxo 8.4).
    private func carregarURL(_ anexo: NSItemProvider, base: URL) {
        anexo.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
            defer { self?.finalizar() }
            guard let url = item as? URL, !url.isFileURL else { return }
            try? HandoffContainer.gravarURL(url.absoluteString, base: base)
        }
    }

    // Carrega texto simples; se for uma URL, grava handoff de URL (spec 8.3).
    private func carregarTexto(_ anexo: NSItemProvider, base: URL) {
        anexo.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
            defer { self?.finalizar() }
            guard let texto = item as? String else { return }
            let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: limpo), url.scheme?.hasPrefix("http") == true else { return }
            try? HandoffContainer.gravarURL(limpo, base: base)
        }
    }

    private func extensaoAceita(_ nome: String) -> Bool {
        IdentificadoresApp.extensoesAceitas.contains((nome as NSString).pathExtension.lowercased())
    }

    private func finalizar() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
