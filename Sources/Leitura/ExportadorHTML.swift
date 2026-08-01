// ExportadorHTML.swift — exportação em HTML autocontido (spec 8.7 / 14).
//
// Gera um `.html` que abre offline em qualquer navegador: CSS embutido inline e
// as fontes do KaTeX embutidas como data: URI (sem nenhuma dependência externa —
// spec 14). Usa o mesmo tema/fonte que estava ativo na Leitura (spec 14).

import UIKit

enum ExportadorHTML {

    // Monta o HTML autocontido a partir do conteúdo já renderizado (spec 8.7).
    // Recebe o HTML do conteúdo (#conteudo), o título e as preferências ativas;
    // devolve a URL do arquivo temporário `{titulo}.html`.
    static func exportar(conteudo: String, titulo: String, prefs: PreferenciasSnapshot) -> URL? {
        let escuro = ehEscuro(prefs.tema)
        let css = [cssBundle("render"),
                   katexCSSComFontes(),
                   cssTemaCodigo(prefs.temaSintaxe, escuro: escuro)]
            .compactMap { $0 }.joined(separator: "\n")

        let html = """
        <!DOCTYPE html>
        <html lang="pt-BR" data-tema="\(escuro ? "escuro" : "claro")" data-fonte="\(prefs.fonteLeitura)" style="--tamanho-fonte:\(prefs.tamanhoFonte)px">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(escaparHTML(NomeArquivo.sanitizar(titulo)))</title>
        <style>\n\(css)\n</style>
        </head>
        <body>
        <main class="markdown-body">\(conteudo)</main>
        </body>
        </html>
        """

        let url = URL.temporaryDirectory.appendingPathComponent("\(NomeArquivo.sanitizar(titulo)).html")
        do { try html.data(using: .utf8)?.write(to: url); return url } catch { return nil }
    }

    // MARK: - Apoio

    private static func ehEscuro(_ tema: String) -> Bool {
        switch tema {
        case "escuro": return true
        case "claro": return false
        default: return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    private static func cssBundle(_ nome: String) -> String? {
        guard let url = Bundle.main.url(forResource: nome, withExtension: "css", subdirectory: "WebBundle") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    // Nome do arquivo de tema de código conforme a preferência e o modo (igual ao bridge.js).
    private static func cssTemaCodigo(_ tema: String, escuro: Bool) -> String? {
        let arquivo: String
        switch tema {
        case "solarized": arquivo = escuro ? "solarized-dark" : "solarized-light"
        case "dracula": arquivo = "dracula"
        case "monokai": arquivo = "monokai"
        default: arquivo = escuro ? "github-dark" : "github"
        }
        guard let url = Bundle.main.url(forResource: arquivo, withExtension: "css",
                                        subdirectory: "WebBundle/vendor/hljs-themes") else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    // Lê o katex.min.css e embute cada fonte woff2 como data: URI (spec 14).
    private static func katexCSSComFontes() -> String? {
        guard let cssURL = Bundle.main.url(forResource: "katex.min", withExtension: "css",
                                           subdirectory: "WebBundle/vendor/katex"),
              var css = try? String(contentsOf: cssURL, encoding: .utf8) else { return nil }

        let padrao = try! NSRegularExpression(pattern: "url\\(fonts/(KaTeX_[A-Za-z0-9]+-[A-Za-z]+)\\.woff2\\)")
        let matches = padrao.matches(in: css, range: NSRange(css.startIndex..., in: css)).reversed()
        for m in matches {
            guard let rangeFonte = Range(m.range(at: 1), in: css),
                  let rangeTodo = Range(m.range, in: css) else { continue }
            let nomeFonte = String(css[rangeFonte])
            guard let fonteURL = Bundle.main.url(forResource: nomeFonte, withExtension: "woff2",
                                                 subdirectory: "WebBundle/vendor/katex/fonts"),
                  let dados = try? Data(contentsOf: fonteURL) else { continue }
            let base64 = dados.base64EncodedString()
            css.replaceSubrange(rangeTodo, with: "url(data:font/woff2;base64,\(base64)) format(\"woff2\")")
        }
        return css
    }

    private static func escaparHTML(_ texto: String) -> String {
        texto.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
    }
}
