//
//  ReportSheetView.swift
//  smmp
//

import SwiftUI

struct ReportSheetView: View {
    let isOffline: Bool
    let onSubmit: (ReportReason) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason = .spam
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.localizedTitle)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if reason == selectedReason {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }

                if isOffline {
                    Text(.reportErrorOffline)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Text(.reportTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text(.commonCancel)
                    }
                    .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(.reportSubmit)
                        }
                    }
                    .disabled(isOffline || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        guard !isOffline, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await onSubmit(selectedReason)
        dismiss()
    }
}
