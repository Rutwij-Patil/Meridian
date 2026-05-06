//
//  SidebarView.swift
//  Meridian
//

import SwiftUI

struct SidebarView: View {
    @Bindable var app: AppModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    newChatButton
                        .padding(.horizontal, 8)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    if !app.sessions.isEmpty {
                        Text("RECENT")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                    }

                    ForEach(app.sessions) { session in
                        sessionRow(session)
                    }
                }
            }
            .scrollContentBackground(.hidden)

            statusFooter
        }
        .background(Theme.bgSecondary)
    }

    private var newChatButton: some View {
        Button {
            app.clearActiveSelection()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                Text("New chat")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.borderStrong, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func sessionRow(_ session: Session) -> some View {
        let isActive = app.activeSessionId == session.id
        return Button {
            app.selectSession(session.id)
        } label: {
            HStack {
                Text(session.query)
                    .font(.system(size: 12.5))
                    .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isActive ? Color.white.opacity(0.05) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .contextMenu {
            Button("Delete", role: .destructive) {
                app.deleteSession(session.id)
            }
        }
    }

    private var statusFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.statusOK)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 0) {
                Text("Gemma 2 9B")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                Text(app.newSessionProgress.isEmpty ? "Loaded" : app.newSessionProgress)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.borderSubtle)
                .frame(height: 0.5)
        }
    }
}
