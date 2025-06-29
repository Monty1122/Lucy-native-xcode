// ContentView.swift

import SwiftUI
import CoreAudio
import Combine

struct ContentView: View {
    @StateObject private var assistant = Assistant()
    
    @State private var isEngaged = false
    @State private var isSpaceBarPressed = false

    var body: some View {
        VStack {
            HStack {
                Picker("Backend:", selection: $assistant.selectedBackend) {
                    ForEach(AIBackend.allCases) { backend in Text(backend.rawValue).tag(backend) }
                }
                if assistant.selectedBackend == .ollama {
                    Picker("Model:", selection: $assistant.selectedOllamaModel) {
                        ForEach(assistant.availableOllamaModels, id: \.self) { modelName in Text(modelName).tag(modelName as String?) }
                    }
                }
            }.padding(.horizontal)
            
            Picker("Microphone:", selection: $assistant.selectedInputID) {
                ForEach(assistant.availableInputs, id: \.self) { device in Text(device.name).tag(device.id as AudioDeviceID?) }
            }.padding(.horizontal)

            Picker("Voice:", selection: $assistant.selectedVoiceID) {
                ForEach(assistant.availableVoices) { voice in
                    Text(voice.name).tag(voice.id as String?)
                }
            }
            .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(assistant.displayedText)
                        .font(.title)
                        .padding()
                        .id(1)
                }
                .onChange(of: assistant.displayedText) {
                    proxy.scrollTo(1, anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Circle()
                .fill(assistant.isListening ? .red : (assistant.isSpeaking ? .orange : .blue))
                .frame(width: 100, height: 100)
                .overlay(Text(buttonLabel).foregroundColor(.white).font(.headline))
                // The gesture now only controls the 'isEngaged' state.
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isEngaged = true }
                        .onEnded { _ in isEngaged = false }
                )
                .padding()
            
            HStack(spacing: 5) {
                Text(assistant.status)
                    .font(.body)
                
                if assistant.status == "Thinking..." {
                    Text(String(format: "%.1fs", assistant.thinkingTimeElapsed))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in }
                }
            }
            .padding(.bottom)
        }
        .frame(minWidth: 500, minHeight: 550)
        .onAppear(perform: setupKeyboardMonitoring)
        // This .onChange is the single place where actions are triggered for both mouse and keyboard.
        .onChange(of: isEngaged) { oldValue, newValue in
            if newValue {
                assistant.startListening()
            } else {
                if assistant.isListening {
                    assistant.stopListeningAndProcess()
                }
            }
        }
    }
    
    private var buttonLabel: String {
        if assistant.isSpeaking { return "Stop" }
        if assistant.isListening { return "Listening..." }
        return "Press & Hold"
    }
    
    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 49 { // Space bar
                if !isEngaged { isEngaged = true }
                return nil
            }
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            if event.keyCode == 49 {
                if isEngaged { isEngaged = false }
                return nil
            }
            return event
        }
    }
}
