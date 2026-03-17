import SwiftUI

struct SpeechButton: View {
    let textToSpeak: String
    @ObservedObject var synthesizer = SpeechSynthesizer.shared

    var body: some View {
        Button(action: {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking()
            } else {
                synthesizer.speak(textToSpeak)
            }
        }) {
            Image(systemName: synthesizer.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.system(size: 24))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(10)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))
        }
        .accessibilityLabel(synthesizer.isSpeaking ? "Stop speaking" : "Read aloud")
        .accessibilityAddTraits(.isButton)
    }
}
