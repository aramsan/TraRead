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
    @Published var translations: [Int: String] = [:] // 各文の日本語翻訳を保持
    
    private var speechSynthesizer: AVSpeechSynthesizer? // Made optional
    private var utterance: AVSpeechUtterance?
    private var tokenizer: NLTokenizer // Initialize in init
    
    override init() {
        print("TraReadViewModel: Initializing...")
        tokenizer = NLTokenizer(unit: .sentence) // Initialize tokenizer first
        
        // Conditionally initialize AVSpeechSynthesizer only if not running tests
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            // Not running in a test environment, so initialize AVSpeechSynthesizer
            self.speechSynthesizer = AVSpeechSynthesizer()
        } else {
            // Running in a test environment, do not initialize AVSpeechSynthesizer
            self.speechSynthesizer = nil // Explicitly nil if testing
        }

        super.init() // Call super.init()
        
        // If speechSynthesizer was initialized, set its delegate
        if let synthesizer = speechSynthesizer {
            synthesizer.delegate = self
        }
        print("TraReadViewModel: Initialized.")
    }
    
    // Processes the input text, splits it into sentences, and updates the UI.
    func processInputText(loadedText: String? = nil) { // Added optional loadedText parameter
        print("processInputText: Starting...")
        isProcessing = true
        sentences = []
        currentSentenceIndex = 0
        japaneseTranslation = "" // Clear previous translation
        translationTrigger = nil // Clear trigger
        translations = [:] // Clear all stored translations

        if let loadedText = loadedText {
            self.inputText = loadedText // Update inputText with loaded content
            print("processInputText: Loaded text from file. New inputText: \(self.inputText.prefix(50))...")
        }
        
        // Only process if inputText is not empty
        guard !inputText.isEmpty else {
            currentSentence = "No text to process. Please enter text or load a file."
            isProcessing = false
            print("processInputText: No text to process.")
            return
        }

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
            speakCurrentSentence() // Re-enabled speech
        } else {
            currentSentence = "No sentences found in the provided text."
        }
        isProcessing = false
        print("processInputText: Finished. currentSentence: \(currentSentence)")
    }
    
    // Speaks the current sentence.
    func speakCurrentSentence() {
        print("speakCurrentSentence: Starting for '\(currentSentence)'")
        if let synthesizer = speechSynthesizer {
            utterance = AVSpeechUtterance(string: currentSentence)
            utterance?.voice = AVSpeechSynthesisVoice(language: "en-US") // English voice
            synthesizer.speak(utterance!)
            isSpeaking = true
            currentSpeakingLanguage = .english
        } else {
            print("speakCurrentSentence: AVSpeechSynthesizer is nil. Skipping speech.")
        }
    }
    
    // Speaks the current Japanese translation.
    func speakJapaneseTranslation() {
        print("speakJapaneseTranslation: Starting for '\(japaneseTranslation)'")
        if let synthesizer = speechSynthesizer, !japaneseTranslation.isEmpty {
            utterance = AVSpeechUtterance(string: japaneseTranslation)
            utterance?.voice = AVSpeechSynthesisVoice(language: "ja-JP") // Japanese voice
            synthesizer.speak(utterance!)
            isSpeaking = true
            currentSpeakingLanguage = .japanese
        } else {
            print("speakJapaneseTranslation: AVSpeechSynthesizer is nil or japaneseTranslation is empty. Skipping speech.")
        }
    }
    
    // Advances to the next sentence and speaks it.
    func nextSentence() {
        print("nextSentence: Starting...")
        
        saveCurrentTranslation() // 現在の翻訳を保存してから次へ
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
    
    // Goes back to the previous sentence and speaks it.
    func prevSentence() {
        print("prevSentence: Starting...")
        
        saveCurrentTranslation() // 現在の翻訳を保存してから戻る
        japaneseTranslation = "" // Clear previous translation
        translationTrigger = nil // Clear trigger
        
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            currentSentence = sentences[currentSentenceIndex]
            // 保存済みの翻訳があれば復元
            if let savedTranslation = translations[currentSentenceIndex] {
                japaneseTranslation = savedTranslation
            }
            print("prevSentence: Moving to previous English sentence: '\(currentSentence)'")
            speakCurrentSentence()
        } else {
            print("prevSentence: Already at the first sentence. Cannot go back further.")
            speakCurrentSentence()
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
        translations = [:]
    }

    /// 現在の文の翻訳を保存する
    func saveCurrentTranslation() {
        if !japaneseTranslation.isEmpty {
            translations[currentSentenceIndex] = japaneseTranslation
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TraReadViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // This delegate method will only be called if speechSynthesizer was initialized
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
        // This delegate method will only be called if speechSynthesizer was initialized
        print("speechSynthesizer:didCancel: Speech cancelled. currentSpeakingLanguage: \(currentSpeakingLanguage)")
        isSpeaking = false
        currentSpeakingLanguage = .none
        translationTrigger = nil // Clear trigger if speech is cancelled
    }
}
