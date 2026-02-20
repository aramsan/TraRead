import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

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
                    pasteFromClipboard()
                }
                .keyboardShortcut("v", modifiers: .command)
            }
        }
    }

    private func pasteFromClipboard() {
        #if os(macOS)
        if let string = NSPasteboard.general.string(forType: .string) {
            viewModel.processInputText(loadedText: string)
        }
        #elseif os(iOS)
        if let string = UIPasteboard.general.string {
            viewModel.processInputText(loadedText: string)
        }
        #endif
    }
}
