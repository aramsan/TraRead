//
//  TraReadApp.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import SwiftUI

@main
struct TraReadApp: App {
    // Instantiate the ViewModel here once for the entire app lifecycle
    @StateObject private var viewModel = TraReadViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel) // Inject the ViewModel into the environment
        }
    }
}
