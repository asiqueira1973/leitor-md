// ResolvedorURLGitHub.swift — extrai owner/repo/path de uma URL do GitHub (spec 8.4 / 11).
//
// Lógica pura de parsing (sem rede), para ser testada isoladamente (spec 22). A
// busca de conteúdo em si, via Contents API, entra no épico 8.4 (GitHubContentsAPI).
//
// Cobre (spec 8.4):
//   - github.com/{owner}/{repo}/blob/{branch}/{path}      → arquivo naquele branch
//   - raw.githubusercontent.com/{owner}/{repo}/{branch}/{path} → arquivo "cru"
//   - github.com/{owner}/{repo}                            → README.md da raiz
//   - github.com/{owner}/{repo}/tree/{branch}             → README.md daquele branch
// Diretórios (tree com subcaminho) são v1.1 (spec 3) → devolve nil.

import Foundation

/// Destino resolvido de uma URL do GitHub para a Contents API (spec 13).
struct DestinoGitHub: Equatable {
    let owner: String
    let repo: String
    /// Caminho do arquivo; "README.md" quando a URL aponta para a raiz do repo.
    let caminho: String
    /// Branch/tag quando presente na URL; nil usa o branch padrão do repo.
    let ref: String?
}

enum ResolvedorURLGitHub {

    // Resolve uma URL do GitHub para um DestinoGitHub. Recebe a URL (colada ou
    // compartilhada, spec 8.4); devolve o destino ou nil se não for uma URL de
    // arquivo/README suportada.
    static func resolver(_ url: URL) -> DestinoGitHub? {
        guard let host = url.host?.lowercased() else { return nil }
        let segmentos = url.path.split(separator: "/").map(String.init)

        switch host {
        case "github.com", "www.github.com":
            return resolverGitHubCom(segmentos)
        case "raw.githubusercontent.com":
            return resolverRaw(segmentos)
        default:
            return nil
        }
    }

    // github.com/{owner}/{repo}[/blob|tree/{branch}/{path...}]
    private static func resolverGitHubCom(_ segmentos: [String]) -> DestinoGitHub? {
        guard segmentos.count >= 2 else { return nil }
        let owner = segmentos[0]
        let repo = removerSufixoGit(segmentos[1])
        guard !owner.isEmpty, !repo.isEmpty else { return nil }

        // Raiz do repo → README.md do branch padrão (spec 11).
        if segmentos.count == 2 {
            return DestinoGitHub(owner: owner, repo: repo, caminho: "README.md", ref: nil)
        }

        let tipo = segmentos[2]
        guard tipo == "blob" || tipo == "tree", segmentos.count >= 4 else { return nil }
        let ref = segmentos[3]
        let caminhoPartes = Array(segmentos.dropFirst(4))

        if caminhoPartes.isEmpty {
            // tree/{branch} sem subcaminho → README.md daquele branch.
            guard tipo == "tree" else { return nil }
            return DestinoGitHub(owner: owner, repo: repo, caminho: "README.md", ref: ref)
        }

        // tree com subcaminho é navegação de diretório → v1.1 (spec 3).
        guard tipo == "blob" else { return nil }
        return DestinoGitHub(owner: owner, repo: repo,
                             caminho: caminhoPartes.joined(separator: "/"), ref: ref)
    }

    // raw.githubusercontent.com/{owner}/{repo}/{branch}/{path...}
    private static func resolverRaw(_ segmentos: [String]) -> DestinoGitHub? {
        guard segmentos.count >= 4 else { return nil }
        let owner = segmentos[0]
        let repo = removerSufixoGit(segmentos[1])
        let ref = segmentos[2]
        let caminho = segmentos.dropFirst(3).joined(separator: "/")
        guard !owner.isEmpty, !repo.isEmpty, !caminho.isEmpty else { return nil }
        return DestinoGitHub(owner: owner, repo: repo, caminho: caminho, ref: ref)
    }

    private static func removerSufixoGit(_ repo: String) -> String {
        repo.hasSuffix(".git") ? String(repo.dropLast(4)) : repo
    }
}
