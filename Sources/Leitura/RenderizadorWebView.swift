// RenderizadorWebView.swift — WKWebView que renderiza o markdown (spec 8.5).
//
// Carrega o bundle local `WebBundle/render.html` (sem rede — spec 0.4/4) e injeta:
//   - o conteúdo markdown (window.renderMarkdown), quando o texto muda;
//   - as preferências (window.aplicarPreferencias), quando o tema/fonte muda —
//     ao vivo, sem re-renderizar nem perder a posição de rolagem (spec 8.5).
// Expõe também o TOC (window.obterTOC / window.irPara) via `controlador`.

import SwiftUI
import WebKit

/// Permite à tela de Leitura pedir o TOC e navegar até uma seção (spec 8.5).
@MainActor
final class RenderizadorControlador {
    fileprivate weak var webView: WKWebView?

    // Busca o sumário do documento renderizado (spec 8.5). Devolve os headings.
    func obterTOC() async -> [ItemTOC] {
        guard let webView else { return [] }
        let json = try? await webView.evaluateJavaScript("window.obterTOC();") as? String
        guard let json, let dados = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([ItemTOC].self, from: dados)) ?? []
    }

    // Rola até a seção indicada pelo TOC (spec 8.5).
    func irPara(_ id: String) {
        guard let dados = try? JSONEncoder().encode(id),
              let json = String(data: dados, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.irPara(\(json));")
    }
}

/// Um item do sumário (heading) do documento (spec 8.5).
struct ItemTOC: Codable, Identifiable, Hashable {
    let nivel: Int
    let texto: String
    let id: String
}

struct RenderizadorWebView: UIViewRepresentable {

    let markdown: String
    let preferencias: PreferenciasSnapshot
    var controlador: RenderizadorControlador?

    func makeCoordinator() -> Coordenador {
        Coordenador()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        controlador?.webView = webView

        if let html = Bundle.main.url(forResource: "render", withExtension: "html", subdirectory: "WebBundle") {
            webView.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controlador?.webView = webView
        context.coordinator.markdownPendente = markdown
        context.coordinator.prefsPendentes = preferencias
        context.coordinator.sincronizar(webView)
    }

    // Coordena a injeção: aplica preferências e renderiza só quando muda cada um,
    // preservando a rolagem em trocas de tema/fonte (spec 8.5).
    final class Coordenador: NSObject, WKNavigationDelegate {
        var carregado = false
        var markdownPendente: String?
        var prefsPendentes: PreferenciasSnapshot?
        private var markdownInjetado: String?
        private var prefsInjetadas: PreferenciasSnapshot?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            carregado = true
            sincronizar(webView)
        }

        // Aplica preferências (se mudaram) e renderiza (se o texto mudou). A ordem
        // — preferências antes do render — garante o tema certo no Mermaid (spec 8.5).
        func sincronizar(_ webView: WKWebView) {
            guard carregado else { return }

            if let prefs = prefsPendentes, prefs != prefsInjetadas {
                if let json = codificar(prefs) {
                    webView.evaluateJavaScript("window.aplicarPreferencias(\(json));")
                }
                prefsInjetadas = prefs
            }

            if let texto = markdownPendente, texto != markdownInjetado {
                if let json = codificar(texto) {
                    webView.evaluateJavaScript("window.renderMarkdown(\(json));")
                }
                markdownInjetado = texto
            }
        }

        private func codificar<T: Encodable>(_ valor: T) -> String? {
            guard let dados = try? JSONEncoder().encode(valor) else { return nil }
            return String(data: dados, encoding: .utf8)
        }
    }
}
