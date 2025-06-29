import Combine
import Foundation
import FoundationModels
import SwiftUI

@MainActor
class Assistant: ObservableObject {
    @Published var conversation: [GenerativeAIService.Message] = []
    @Published var displayedText: String = "Welcome to Lucy! Press and hold the space bar to talk."
    @Published var isListening: Bool = false
    @Published var status: String = "Idle"

    private let speechRecognitionService = SpeechRecognitionService()
    private let generativeAIService = GenerativeAIService()
    private let speechService = SpeechService()

    private var transcriptionTask: Task<Void, Never>?
    private var sentenceBuffer = ""

    init() {
        speechRecognitionService.requestPermission()
    }

    func startListening() {
        if speechService.isSpeaking {
            speechService.stop()
            status = "Idle"
            return
        }
        isListening = true
        status = "Listening..."
        displayedText = ""
        transcriptionTask = Task {
            do {
                let stream = speechRecognitionService.startTranscribing()
                for try await transcription in stream {
                    displayedText = transcription
                }
            } catch {
                displayedText = "Error during transcription: \(error.localizedDescription)"
                isListening = false
                status = "Error"
            }
        }
    }

    func stopListeningAndProcess() {
        isListening = false
        status = "Thinking..."
        speechRecognitionService.stopTranscribing()
        transcriptionTask?.cancel()
        let userPrompt = displayedText
        guard !userPrompt.isEmpty else {
            status = "Idle"
            displayedText = "I didn't hear anything. Try again."
            return
        }
        conversation.append(.init(role: "user", content: userPrompt))
        Task {
            do {
                let responseStream = try await generativeAIService.generateResponse(prompt: userPrompt, history: conversation)
                var fullResponse = ""
                for try await token in responseStream {
                    fullResponse += token
                    sentenceBuffer += token
                    displayedText = fullResponse
                    if ".!?".contains(sentenceBuffer.last ?? " ") {
                        speechService.speak(text: sentenceBuffer)
                        sentenceBuffer = ""
                    }
                }
                if !sentenceBuffer.isEmpty {
                    speechService.speak(text: sentenceBuffer)
                    sentenceBuffer = ""
                }
                conversation.append(.init(role: "assistant", content: fullResponse))
                status = "Idle"
            } catch {
                displayedText = "Error generating response: \(error.localizedDescription)"
                status = "Error"
            }
        }
    }
}
