//
//  ContentView.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TraReadViewModel

    // Color Palette from Design Doc
    let primaryColor = Color(hex: "FFD700") // Tiger Gold
    let surfaceColor = Color(hex: "121212") // Almost Black
    let backgroundColor = Color(hex: "FFFBE6") // Warm Off-White

    var body: some View {
        ZStack { // Use ZStack for background color
            backgroundColor.edgesIgnoringSafeArea(.all) // Apply background color

            VStack {
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 100)
                    .border(primaryColor, width: 2)
                    .padding()
                    .foregroundColor(surfaceColor)
                    .background(Color.white) // Make text editor background white for contrast
                    .font(.body)

                Button("Process Text") {
                    viewModel.processInputText()
                }
                .buttonStyle(.borderedProminent)
                .tint(primaryColor)
                .foregroundColor(surfaceColor) // Text color for the button
                .padding(.bottom)

                Spacer()

                Text(viewModel.currentSentence)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(surfaceColor)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()

                // Hidden button to capture Enter key for next sentence
                Button("") {
                    if !viewModel.isSpeaking { // Only advance if not currently speaking
                        viewModel.nextSentence()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .hidden() // Keep it hidden
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make VStack fill available space
        }
        .onAppear {
            // Optional: Process initial text if any, or just show welcome message
        }
    }
}

#Preview {
    ContentView()
}
