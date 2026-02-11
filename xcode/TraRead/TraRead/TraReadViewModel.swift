//
//  TraReadViewModel.swift
//  TraRead
//
//  Created by aram.mine on 2026/02/11.
//

import Foundation
import Combine
import AVFoundation
import NaturalLanguage
import Translation // Import the Translation framework
import SwiftUI // For Color (though not directly used in VM, good practice for cross-cutting concerns if colors were dynamic)

enum SpeakingLanguage: String { // Changed to String for easy printing
    case english
    case japanese
    case none
}

class TraReadViewModel: NSObject, ObservableObject {
    @Published var inputText: String = ""
    @Published var currentSentence: String = "Welcome to TraRead! Enter your text above to begin."
    @Published var japaneseTranslation: String = "" // New published property
    @Published var sentences: [String] = []
    @Published var currentSentenceIndex: Int = 0
    @Published var isSpeaking: Bool = false
    @Published var isProcessing: Bool = false // To indicate text processing
    @Published var currentSpeakingLanguage: SpeakingLanguage = .none // Track current speaking language
    @Published var translationTrigger: String? = nil // New property to trigger translation from View
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private var tokenizer: NLTokenizer // Initialize in init
    
    override init() {
        print("TraReadViewModel: Initializing...")
        tokenizer = NLTokenizer(unit: .sentence) // Initialize tokenizer first
        super.init() // Call super.init()
        speechSynthesizer.delegate = self
        print("TraReadViewModel: Initialized.")
    }
    
    // Processes the input text, splits it into sentences, and updates the UI.
    func processInputText() {
        print("processInputText: Starting...")
        isProcessing = true
        sentences = []
        currentSentenceIndex = 0
        japaneseTranslation = "" // Clear previous translation
        translationTrigger = nil // Clear trigger
        
        tokenizer.string = inputText
        // NLTokenizer doesn't directly return a simple array, so we enumerate
        tokenizer.enumerateTokens(in: inputText.startIndex..<inputText.endIndex) { tokenRange, _ in
            let sentence = String(inputText[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                self.sentences.append(sentence)
            }
            return true // Continue enumeration
        }
        
        if let firstSentence = sentences.first {
            currentSentence = firstSentence
            speakCurrentSentence()
        } else {
            currentSentence = "No sentences found. Please enter some text."
        }
        isProcessing = false
        print("processInputText: Finished. currentSentence: \(currentSentence)")
    }
    
    // Speaks the current sentence.
    func speakCurrentSentence() {
        print("speakCurrentSentence: Starting for '\(currentSentence)'")
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            print("speakCurrentSentence: Stopped previous speech.")
        }
        
        guard !currentSentence.isEmpty && currentSentence != "No sentences found. Please enter some text." else {
            print("speakCurrentSentence: No sentence to speak.")
            return
        }
        
        utterance = AVSpeechUtterance(string: currentSentence)
        utterance?.voice = AVSpeechSynthesisVoice(language: "en-US") // English for now
        utterance?.rate = 0.5 // Adjust rate for better listening
        utterance?.pitchMultiplier = 1.0 // Standard pitch
        
        if let utterance = utterance {
            speechSynthesizer.speak(utterance)
            isSpeaking = true
            currentSpeakingLanguage = .english // Set language to English
            print("speakCurrentSentence: Started English speech. isSpeaking: \(isSpeaking), currentSpeakingLanguage: \(currentSpeakingLanguage)")
        }
    }
    
    // Speaks the current Japanese translation.
    func speakJapaneseTranslation() {
        print("speakJapaneseTranslation: Starting for '\(japaneseTranslation)'")
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            print("speakJapaneseTranslation: Stopped previous speech.")
        }
        
        guard !japaneseTranslation.isEmpty else {
            print("speakJapaneseTranslation: No Japanese translation to speak.")
            return
        }
        
        utterance = AVSpeechUtterance(string: japaneseTranslation)
        utterance?.voice = AVSpeechSynthesisVoice(language: "ja-JP") // Japanese voice
        utterance?.rate = 0.5 // Adjust rate for better listening
        utterance?.pitchMultiplier = 1.0 // Standard pitch
        
        if let utterance = utterance {
            speechSynthesizer.speak(utterance)
            isSpeaking = true
            currentSpeakingLanguage = .japanese // Set language to Japanese
            print("speakJapaneseTranslation: Started Japanese speech. isSpeaking: \(isSpeaking), currentSpeakingLanguage: \(currentSpeakingLanguage)")
        }
    }
    
    // Advances to the next sentence and speaks it.
    func nextSentence() {
        print("nextSentence: Starting...")
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            print("nextSentence: Stopped previous speech.")
        }
        
        japaneseTranslation = "" // Clear previous translation
        translationTrigger = nil // Clear trigger
        
        if currentSentenceIndex < sentences.count - 1 {
            currentSentenceIndex += 1
            currentSentence = sentences[currentSentenceIndex]
            print("nextSentence: Moving to next English sentence: '\(currentSentence)'")
            speakCurrentSentence()
        } else {
            currentSentence = "End of text. Please enter new text or reprocess."
            isSpeaking = false
            currentSpeakingLanguage = .none
            print("nextSentence: End of text. isSpeaking: \(isSpeaking), currentSpeakingLanguage: \(currentSpeakingLanguage)")
        }
    }
    
    // Resets the view model state.
    func reset() {
        print("reset: Resetting view model state.")
        inputText = ""
        currentSentence = "Welcome to TraRead! Enter your text above to begin."
        japaneseTranslation = ""
        sentences = []
        currentSentenceIndex = 0
        isSpeaking = false
        isProcessing = false
        currentSpeakingLanguage = .none
        translationTrigger = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TraReadViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("speechSynthesizer:didFinish: Speech finished. currentSpeakingLanguage: \(currentSpeakingLanguage)")
        switch currentSpeakingLanguage {
        case .english:
            // English speech finished, now trigger translation from the View
            translationTrigger = currentSentence // Set the trigger
            currentSpeakingLanguage = .none // Reset language state, translation will set it back to japanese
            print("speechSynthesizer:didFinish: English speech done. Translation triggered. currentSpeakingLanguage reset to \(currentSpeakingLanguage).")
        case .japanese:
            // Japanese speech finished, now wait for user input
            isSpeaking = false
            currentSpeakingLanguage = .none
            print("speechSynthesizer:didFinish: Japanese speech done. isSpeaking: \(isSpeaking), currentSpeakingLanguage: \(currentSpeakingLanguage). Waiting for user input.")
        case .none:
            // Should not happen, but reset if it does
            isSpeaking = false
            print("speechSynthesizer:didFinish: Unknown speech finished. isSpeaking: \(isSpeaking).")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("speechSynthesizer:didCancel: Speech cancelled. currentSpeakingLanguage: \(currentSpeakingLanguage)")
        isSpeaking = false
        currentSpeakingLanguage = .none
        translationTrigger = nil // Clear trigger if speech is cancelled
    }
}
