//
//  TraReadApp.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import SwiftUI
import AppKit

@main
struct TraReadApp: App {
    // Instantiate the ViewModel here once for the entire app lifecycle
    @StateObject private var viewModel = TraReadViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel) // Inject the ViewModel into the environment
        }
        .commands {
            CommandGroup(replacing: .pasteboard) {
                Button("Paste") {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        DispatchQueue.main.async {
                            viewModel.processInputText(loadedText: string)
                        }
                    }
                }
                .keyboardShortcut("v", modifiers: .command)
            }
        }
    }
}
