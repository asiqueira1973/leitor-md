// SeletorDocumento.swift — UIDocumentPickerViewController em SwiftUI (spec 8.1 / 8.2).
//
// Abre o picker nativo filtrado só pelas extensões aceitas (spec 11), de forma
// que arquivos de outros tipos não fiquem selecionáveis (critério de aceite da
// spec 8.1). O mesmo picker cobre iCloud Drive e Google Drive, que aparecem como
// locais/providers dentro dele (spec 8.2) — sem código extra por provedor.

import SwiftUI
import UniformTypeIdentifiers

struct SeletorDocumento: UIViewControllerRepresentable {

    /// Chamado com a URL escolhida (ou nada, se o usuário cancelar).
    let aoSelecionar: (URL) -> Void

    func makeCoordinator() -> Coordenador {
        Coordenador(aoSelecionar: aoSelecionar)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.tiposAceitos())
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    // Monta os UTTypes aceitos a partir das extensões da spec 11, de modo que só
    // arquivos markdown fiquem selecionáveis no picker.
    private static func tiposAceitos() -> [UTType] {
        var tipos: [UTType] = []
        if let md = UTType("net.daringfireball.markdown") {
            tipos.append(md)
        }
        for ext in IdentificadoresApp.extensoesAceitas {
            if let tipo = UTType(filenameExtension: ext) {
                tipos.append(tipo)
            }
        }
        return tipos.isEmpty ? [.plainText] : tipos
    }

    final class Coordenador: NSObject, UIDocumentPickerDelegate {
        let aoSelecionar: (URL) -> Void

        init(aoSelecionar: @escaping (URL) -> Void) {
            self.aoSelecionar = aoSelecionar
        }

        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            aoSelecionar(url)
        }
    }
}
