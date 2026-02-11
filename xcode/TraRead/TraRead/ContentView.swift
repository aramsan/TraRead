//
//  ContentView.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import SwiftUI
import Translation // Import Translation framework for .translationTask

struct ContentView: View {
    @EnvironmentObject var viewModel: TraReadViewModel
    // Removed @State private var translationConfiguration: TranslationSession.Configuration? = nil

    // Color Palette from Design Doc
    let primaryColor = Color(hex: "FFD700") // Tiger Gold
    let secondaryColor = Color(hex: "FF8C00") // Accent Orange - New
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
                    .padding(.horizontal) // Apply horizontal padding to English sentence
                
                if !viewModel.japaneseTranslation.isEmpty {
                    Text(viewModel.japaneseTranslation)
                        .font(.title2)
                        .foregroundColor(secondaryColor) // Apply secondary color
                        .multilineTextAlignment(.center)
                        .padding(.horizontal) // Apply horizontal padding to Japanese translation
                        .padding(.top, 5)
                }

                // New HStack for navigation buttons
                HStack {
                    Button("Prev") {
                        print("ContentView: Prev button tapped.")
                        viewModel.prevSentence()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryColor)
                    .foregroundColor(surfaceColor)
                    .disabled(viewModel.isSpeaking || viewModel.currentSentenceIndex == 0) // Disable if speaking or at first sentence

                    Spacer() // Pushes Prev and Next buttons apart

                    Button("Next") {
                        print("ContentView: Next button tapped.")
                        viewModel.nextSentence()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(primaryColor)
                    .foregroundColor(surfaceColor)
                    .disabled(viewModel.isSpeaking || viewModel.currentSentenceIndex == viewModel.sentences.count - 1) // Disable if speaking or at last sentence
                }
                .padding(.horizontal) // Add horizontal padding to the HStack
                .padding(.bottom, 20) // Add padding from the bottom of the screen


                // Removed hidden button to capture Enter key for next sentence
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Make VStack fill available space
        }
        .onAppear {
            // Optional: Process initial text if any, or just show welcome message
        }
        .onChange(of: viewModel.translationTrigger) { oldValue, newValue in
            print("ContentView: onChange - translationTrigger changed to: \(newValue ?? "nil")")
            if let textToTranslate = newValue {
                // Ensure availability of translation service
                guard #available(macOS 12.0, iOS 15.0, *) else {
                    viewModel.japaneseTranslation = "Translation not available on this OS version."
                    return
                }
                
                // Define source and target languages directly
                let sourceLanguage = Locale.Language(identifier: "en-US")
                let targetLanguage = Locale.Language(identifier: "ja-JP")
                
                // Then immediately create and run the Task
                Task {
                    do {
                        // Initialize TranslationSession using the correct initializer signature
                        let session = TranslationSession(
                            installedSource: sourceLanguage,
                            target: targetLanguage
                        )
                        print("ContentView: translationTask (triggered by onChange) - Attempting to translate: '\(textToTranslate)'")
                        let response = try await session.translate(textToTranslate)
                        print("ContentView: translationTask (triggered by onChange) - Translation successful. TargetText: '\(response.targetText)'")
                        
                        await MainActor.run { [weak viewModel] in
                            viewModel?.japaneseTranslation = response.targetText // Direct assignment
                            viewModel?.speakJapaneseTranslation()
                            print("ContentView: translationTask (triggered by onChange) - ViewModel updated and Japanese speech initiated.")
                        }
                    } catch {
                        await MainActor.run { [weak viewModel] in
                            viewModel?.japaneseTranslation = "Translation error: \(error.localizedDescription)"
                            viewModel?.isSpeaking = false // Stop speaking if translation fails
                            viewModel?.currentSpeakingLanguage = .none
                            print("ContentView: translationTask (triggered by onChange) - Translation error: \(error.localizedDescription)")
                        }
                    }
                    await MainActor.run { [weak viewModel] in
                        viewModel?.translationTrigger = nil // Reset original trigger
                        print("ContentView: translationTask (triggered by onChange) - translationTrigger reset to nil.")
                    }
                }
            } else {
                print("ContentView: onChange - translationTrigger is nil, no translation task triggered.")
            }
        }
        // Removed .translationTask modifier, replaced by direct Task in onChange
    }
}

#Preview {
    ContentView()
        .environmentObject(TraReadViewModel()) // Provide a ViewModel for preview
}
