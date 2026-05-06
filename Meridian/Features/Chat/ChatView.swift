//
//  ChatView.swift
//  Meridian
//

import SwiftUI

struct ChatView: View {
    let session: Session
    @State private var input: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(session.chat.messages) { msg in
                            messageRow(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                }
                .scrollContentBackground(.hidden)
                .onChange(of: session.chat.messages.last?.text) { _, _ in
                    if let last = session.chat.messages.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
        .background(Theme.bgPrimary)
        .onAppear { isFocused = true }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.query)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text(formattedDate(session.createdAt))
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.borderSubtle)
                .frame(height: 0.5)
        }
    }

    // MARK: - Messages

    private func messageRow(_ msg: ChatViewModel.Message) -> some View {
        HStack(alignment: .top, spacing: 10) {
            avatar(for: msg.role)
            VStack(alignment: .leading, spacing: 3) {
                Text(label(for: msg.role))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(msg.role == .assistant ? Theme.accent : Theme.textQuiet)
                Text(msg.text.isEmpty && msg.role == .assistant ? "…" : msg.text)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func avatar(for role: ChatViewModel.Role) -> some View {
        let isAssistant = role == .assistant
        return Circle()
            .fill(isAssistant ? Theme.accentMuted : Theme.bgInput)
            .frame(width: 22, height: 22)
            .overlay(
                Circle()
                    .stroke(isAssistant ? Theme.accentBorder : Theme.borderStrong, lineWidth: 0.5)
            )
            .overlay(
                Text(isAssistant ? "M" : "N")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isAssistant ? Theme.accent : Theme.textSecondary)
            )
    }

    private func label(for role: ChatViewModel.Role) -> String {
        switch role {
        case .user: return "You"
        case .assistant: return "Meridian"
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask a follow-up…", text: $input)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
                .focused($isFocused)
                .onSubmit { primaryAction() }

            Button(action: primaryAction) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(buttonFill)
                    .frame(width: 26, height: 26)
                    .overlay { buttonGlyph }
            }
            .buttonStyle(.plain)
            .disabled(input.isEmpty && !isStreaming)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.bgInput)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.borderStrong, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var isStreaming: Bool {
        switch session.chat.state {
        case .thinking, .streaming: return true
        default: return false
        }
    }

    private var buttonFill: Color {
        if isStreaming { return Theme.accent }
        return input.isEmpty ? Theme.bgTertiary : Theme.accent
    }

    @ViewBuilder
    private var buttonGlyph: some View {
        if isStreaming {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.bgPrimary)
                .frame(width: 9, height: 9)
        } else {
            Image(systemName: "arrow.up")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(input.isEmpty ? Theme.textTertiary : Theme.bgPrimary)
        }
    }

    private func primaryAction() {
        if isStreaming {
            session.chat.cancel()
        } else {
            submit()
        }
    }

    private func submit() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        session.chat.send(trimmed)
        input = ""
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
