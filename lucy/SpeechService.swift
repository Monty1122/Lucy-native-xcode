// SpeechService.swift

import Foundation
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // ** REVERTED to the simpler, working version **
    func speak(text: String, voiceIdentifier: String?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        Task {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            
            isSpeaking = true
            let utterance = AVSpeechUtterance(string: text)
            
            // This logic correctly uses the selected voice ID, or falls back to enhanced.
            if let identifier = voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
                utterance.voice = voice
            } else {
                let enhancedVoice = AVSpeechSynthesisVoice.speechVoices().first { $0.language == "en-US" && $0.quality == .enhanced }
                utterance.voice = enhancedVoice ?? AVSpeechSynthesisVoice(language: "en-US")
            }
            
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
