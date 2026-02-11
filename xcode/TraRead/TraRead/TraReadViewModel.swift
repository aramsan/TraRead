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
import SwiftUI // For Color (though not directly used in VM, good practice for cross-cutting concerns if colors were dynamic)

class TraReadViewModel: NSObject, ObservableObject {
    @Published var inputText: String = ""
    @Published var currentSentence: String = "Welcome to TraRead! Enter your text above to begin."
    @Published var sentences: [String] = []
    @Published var currentSentenceIndex: Int = 0
    @Published var isSpeaking: Bool = false
    @Published var isProcessing: Bool = false // To indicate text processing
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance?
    private var tokenizer: NLTokenizer // Initialize in init
    
    override init() {
        tokenizer = NLTokenizer(unit: .sentence) // Initialize tokenizer first
        super.init() // Call super.init()
        speechSynthesizer.delegate = self
    }
    
    // Processes the input text, splits it into sentences, and updates the UI.
    func processInputText() {
        isProcessing = true
        sentences = []
        currentSentenceIndex = 0
        
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
    }
    
    // Speaks the current sentence.
    func speakCurrentSentence() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        guard !currentSentence.isEmpty && currentSentence != "No sentences found. Please enter some text." else { return }
        
        utterance = AVSpeechUtterance(string: currentSentence)
        utterance?.voice = AVSpeechSynthesisVoice(language: "en-US") // English for now
        utterance?.rate = 0.5 // Adjust rate for better listening
        utterance?.pitchMultiplier = 1.0 // Standard pitch
        
        if let utterance = utterance {
            speechSynthesizer.speak(utterance)
            isSpeaking = true
        }
    }
    
    // Advances to the next sentence and speaks it.
    func nextSentence() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        if currentSentenceIndex < sentences.count - 1 {
            currentSentenceIndex += 1
            currentSentence = sentences[currentSentenceIndex]
            speakCurrentSentence()
        } else {
            currentSentence = "End of text. Please enter new text or reprocess."
            isSpeaking = false
        }
    }
    
    // Resets the view model state.
    func reset() {
        inputText = ""
        currentSentence = "Welcome to TraRead! Enter your text above to begin."
        sentences = []
        currentSentenceIndex = 0
        isSpeaking = false
        isProcessing = false
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TraReadViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // This is crucial: after speaking, wait for user input (Enter key)
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
