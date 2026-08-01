// SumarioTOCView.swift — sumário (TOC) do documento (spec 8.5).
//
// Lista todos os headings e navega até a seção ao tocar (spec 8.5). No iPhone
// aparece em folha; o recuo por nível dá a hierarquia dos títulos.

import SwiftUI

struct SumarioTOCView: View {

    let itens: [ItemTOC]
    let aoTocar: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if itens.isEmpty {
                    ContentUnavailableView("Sem seções", systemImage: "list.bullet",
                                           description: Text("Este documento não tem títulos."))
                } else {
                    List(itens) { item in
                        Button {
                            aoTocar(item.id)
                            dismiss()
                        } label: {
                            Text(item.texto)
                                .foregroundStyle(Paleta.texto)
                                .padding(.leading, CGFloat(max(0, item.nivel - 1)) * 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("Sumário")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
