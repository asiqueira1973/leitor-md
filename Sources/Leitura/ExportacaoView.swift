// ExportacaoView.swift — tela de exportação (spec 8.7 / 10 / 14).
//
// Escolha de formato (PDF/HTML/Skill do Claude) → gera o arquivo → abre a folha de
// compartilhamento nativa do iOS (spec 8.7). Só a Skill pede dados antes (nome e
// descrição). DOCX fica para a v1.1 (best-effort, spec 24).

import SwiftUI

struct ExportacaoView: View {

    let titulo: String
    let markdown: String
    let prefs: PreferenciasSnapshot

    @Environment(\.dismiss) private var dismiss
    @State private var gerando = false
    @State private var arquivo: ArquivoExport?

    var body: some View {
        NavigationStack {
            List {
                Section("Formato") {
                    Button { Task { await gerar { await gerarPDF() } } } label: {
                        rotulo("PDF", "doc.richtext")
                    }
                    Button { Task { await gerar { await gerarHTML() } } } label: {
                        rotulo("HTML", "chevron.left.forwardslash.chevron.right")
                    }
                    NavigationLink {
                        ExportacaoSkillView(titulo: titulo, markdown: markdown) { url in
                            if let url { arquivo = ArquivoExport(url: url) }
                        }
                    } label: {
                        rotulo("Skill do Claude", "sparkles")
                    }
                }
            }
            .navigationTitle("Exportar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
            }
            .overlay { if gerando { ProgressView().controlSize(.large) } }
            .sheet(item: $arquivo) { item in
                FolhaCompartilhamento(itens: [item.url])
            }
        }
    }

    private func rotulo(_ texto: String, _ simbolo: String) -> some View {
        Label(texto, systemImage: simbolo).foregroundStyle(Paleta.texto)
    }

    // Executa uma geração assíncrona mostrando progresso e abre a folha ao concluir.
    private func gerar(_ acao: @escaping () async -> URL?) async {
        gerando = true
        let url = await acao()
        gerando = false
        if let url { arquivo = ArquivoExport(url: url) }
    }

    // PDF: sempre tema claro, documento inteiro (spec 14).
    private func gerarPDF() async -> URL? {
        let render = RenderizadorExportacao()
        await render.preparar()
        await render.renderizar(markdown, prefs: prefs.claro)
        let url = await render.gerarPDF(titulo: titulo)
        render.encerrar()
        return url
    }

    // HTML autocontido no tema/fonte ativos (spec 14).
    private func gerarHTML() async -> URL? {
        let render = RenderizadorExportacao()
        await render.preparar()
        let conteudo = await render.renderizar(markdown, prefs: prefs)
        render.encerrar()
        return ExportadorHTML.exportar(conteudo: conteudo, titulo: titulo, prefs: prefs)
    }
}

/// Arquivo gerado, pronto para a folha de compartilhamento (spec 8.7).
private struct ArquivoExport: Identifiable {
    let id = UUID()
    let url: URL
}

// Tela de exportação de Skill do Claude: nome e descrição (spec 8.7 / 14).
private struct ExportacaoSkillView: View {
    let titulo: String
    let markdown: String
    let aoGerar: (URL?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nome: String = ""
    @State private var descricao: String = ""

    var body: some View {
        Form {
            Section {
                TextField("exportar.skill.nome", text: $nome)
                    .autocorrectionDisabled()
            } footer: {
                Text("O nome vira minúsculas com hífens (ex.: \(RegrasDeNegocio.kebabCase(nome.isEmpty ? "meu-skill" : nome))).")
            }
            Section("Descrição") {
                TextField("exportar.skill.descricao", text: $descricao, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section {
                Button("Gerar .skill") {
                    aoGerar(ExportadorSkill.exportar(nome: nome, descricao: descricao, corpo: markdown))
                    dismiss()
                }
                .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .navigationTitle("Skill do Claude")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if nome.isEmpty { nome = RegrasDeNegocio.kebabCase(NomeArquivo.sanitizar(titulo)) }
            if descricao.isEmpty { descricao = descricaoSugerida(de: markdown) }
        }
    }

    // Sugere a descrição a partir do primeiro parágrafo/heading (spec 8.7).
    private func descricaoSugerida(de markdown: String) -> String {
        for linha in markdown.split(separator: "\n", omittingEmptySubsequences: true) {
            let t = linha.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#> -*"))
            if !t.isEmpty { return String(t.prefix(200)) }
        }
        return ""
    }
}

// Folha de compartilhamento nativa (UIActivityViewController) — spec 8.7.
private struct FolhaCompartilhamento: UIViewControllerRepresentable {
    let itens: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: itens, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
