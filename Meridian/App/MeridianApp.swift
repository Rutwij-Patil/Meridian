//
//  MeridianApp.swift
//  Meridian
//
//  Created by Rutwij on 14/04/26.
//

import SwiftUI

@main
struct MeridianApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}
