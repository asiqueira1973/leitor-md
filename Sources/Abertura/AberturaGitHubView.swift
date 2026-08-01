// AberturaGitHubView.swift — tela "Abrir do GitHub" (spec 8.4 / 10 / 15).
//
// Campo de URL (ou já vem preenchido de um compartilhamento — spec 8.4), estado
// de busca/erro e ação de abrir. Ao concluir, entrega o Documento criado e fecha.

import SwiftUI
import SwiftData

/// Contexto de apresentação da tela "Abrir do GitHub" (spec 8.4). Carrega a URL
/// inicial junto do item do sheet, evitando corrida de estado na Início.
struct GitHubSheetContexto: Identifiable {
    let id = UUID()
    let urlInicial: String?
}

struct AberturaGitHubView: View {

    /// URL inicial (ex.: vinda do handoff da Share Extension). Dispara busca automática.
    var urlInicial: String?
    /// Chamado com o conteúdo buscado; a Início aplica o portão de trial e registra.
    let aoAbrir: (ConteudoGitHub) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var vm = GitHubAberturaViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://github.com/owner/repo", text: $vm.urlTexto, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .onSubmit { Task { await abrir() } }
                } header: {
                    Text("botao.abrir_github")
                } footer: {
                    if case .erro(let mensagem) = vm.estado {
                        Text(mensagem).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("botao.abrir_github")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if vm.estado == .buscando {
                        ProgressView()
                    } else {
                        Button("Abrir") { Task { await abrir() } }
                            .disabled(vm.urlTexto.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .task {
                // Abertura automática quando veio de compartilhamento (spec 8.3/8.4).
                if let inicial = urlInicial, vm.urlTexto.isEmpty {
                    vm.urlTexto = inicial
                    await abrir()
                }
            }
        }
    }

    private func abrir() async {
        if let conteudo = await vm.abrir() {
            aoAbrir(conteudo)
            dismiss()
        }
    }
}
