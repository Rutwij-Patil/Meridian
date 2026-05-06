//
//  RootView.swift
//  Meridian
//

import SwiftUI

struct RootView: View {
    @State private var app = AppModel()

    var body: some View {
        Group {
            switch app.phase {
            case .coldStart:
                SplashView(llm: app.llmProgress, embedder: app.embedderProgress)
            case .ready:
                MainView(app: app)
            case .error(let message):
                ErrorView(message: message) { app.retry() }
            }
        }
        .preferredColorScheme(.dark)
        .background(Theme.bgPrimary)
        .task { app.loadModels() }
    }
}

private struct MainView: View {
    @Bindable var app: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView(app: app)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            if let session = app.activeSession {
                ChatView(session: session)
            } else {
                NewSessionView(app: app)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct SplashView: View {
    let llm: String
    let embedder: String

    var body: some View {
        VStack(spacing: 28) {
            Text("Meridian")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 8) {
                progressRow("Language model", status: llm)
                progressRow("Embedder", status: embedder)
            }
            .frame(width: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    private func progressRow(_ label: String, status: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(status.isEmpty ? "—" : status)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .monospacedDigit()
        }
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Something went wrong")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button("Retry", action: retry)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
