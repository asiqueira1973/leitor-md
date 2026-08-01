// RenderizadorExportacao.swift — render fora da tela para exportar (spec 8.7).
//
// Carrega o mesmo bundle da Leitura num WKWebView escondido, aplica as
// preferências pedidas e renderiza (aguardando o Mermaid). A partir daí gera o
// PDF (spec 14 — sempre tema claro) e/ou entrega o HTML do conteúdo para o
// exportador de HTML autocontido.

import UIKit
import WebKit

@MainActor
final class RenderizadorExportacao: NSObject, WKNavigationDelegate {

    private let webView: WKWebView
    private var continuacaoCarga: CheckedContinuation<Void, Never>?

    // Largura de layout em pontos (~A4). O createPDF captura a altura total.
    init(largura: CGFloat = 595) {
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: largura, height: 800))
        super.init()
        webView.navigationDelegate = self
    }

    // Carrega o bundle de renderização (spec 8.5). Adiciona o WebView escondido à
    // janela para o layout acontecer (necessário ao createPDF).
    func preparar() async {
        webView.alpha = 0
        janelaChave()?.addSubview(webView)
        await withCheckedContinuation { cont in
            continuacaoCarga = cont
            if let html = Bundle.main.url(forResource: "render", withExtension: "html", subdirectory: "WebBundle") {
                webView.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
            } else {
                cont.resume(); continuacaoCarga = nil
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuacaoCarga?.resume()
        continuacaoCarga = nil
    }

    // Aplica as preferências e renderiza o markdown, aguardando o Mermaid (spec 8.7).
    // Devolve o HTML do conteúdo renderizado.
    @discardableResult
    func renderizar(_ markdown: String, prefs: PreferenciasSnapshot) async -> String {
        let dict: [String: Any] = [
            "tema": prefs.tema, "temaSintaxe": prefs.temaSintaxe,
            "fonteLeitura": prefs.fonteLeitura, "tamanhoFonte": prefs.tamanhoFonte
        ]
        _ = try? await webView.callAsyncJavaScript(
            "window.aplicarPreferencias(prefs);", arguments: ["prefs": dict],
            in: nil, contentWorld: .page)
        let html = try? await webView.callAsyncJavaScript(
            "return await window.renderParaExportacao(md);", arguments: ["md": markdown],
            in: nil, contentWorld: .page)
        return (html as? String) ?? ""
    }

    // Gera o PDF do documento renderizado (spec 14). Recebe o título; devolve a URL
    // do arquivo temporário `{titulo}.pdf` (A4, documento inteiro).
    func gerarPDF(titulo: String) async -> URL? {
        let dados: Data? = await withCheckedContinuation { cont in
            webView.createPDF(configuration: WKPDFConfiguration()) { resultado in
                cont.resume(returning: try? resultado.get())
            }
        }
        guard let dados else { return nil }
        let url = URL.temporaryDirectory.appendingPathComponent("\(NomeArquivo.sanitizar(titulo)).pdf")
        try? dados.write(to: url)
        return url
    }

    // Libera o WebView escondido.
    func encerrar() {
        webView.removeFromSuperview()
    }

    private func janelaChave() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
