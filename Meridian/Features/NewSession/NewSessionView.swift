//
//  NewSessionView.swift
//  Meridian
//

import SwiftUI

struct NewSessionView: View {
    @Bindable var app: AppModel
    @State private var query: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Spacer()

            Text("What do you want to know?")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 24)

            HStack(spacing: 10) {
                TextField("Ask anything…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .onSubmit { submit() }

                Button(action: submit) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(query.isEmpty ? Theme.bgTertiary : Theme.accent)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(query.isEmpty ? Theme.textTertiary : Theme.bgPrimary)
                        }
                }
                .buttonStyle(.plain)
                .disabled(query.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.bgInput)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.borderStrong, lineWidth: 0.5)
                    )
            )
            .frame(maxWidth: 420)

            if !app.newSessionProgress.isEmpty {
                Text(app.newSessionProgress)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 16)
            } else {
                Text("Everything stays on this device.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 16)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
        .onAppear { isFocused = true }
    }

    private func submit() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        app.newSession(query: trimmed)
        query = ""
    }
}
