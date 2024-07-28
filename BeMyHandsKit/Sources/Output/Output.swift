import AVFoundation
import ApplicationServices

/// Output conveyer.
@MainActor
public final class Output: NSObject {
    /// Speech synthesizer.
    private let synthesizer = AVSpeechSynthesizer()
    /// Queued output.
    private var queued = [OutputSemantic]()
    /// Whether the synthesizer is currently announcing something.
    private var isAnnouncing = false
    /// Shared singleton.
    public static let shared = Output()

    /// Creates a new output.
    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Announces a high priority event.
    /// - Parameter announcement: Event to announce.
    public func announce(_ announcement: String) {
        let announcement = AVSpeechUtterance(string: announcement)
        synthesizer.stopSpeaking(at: .immediate)
        isAnnouncing = true
        synthesizer.speak(announcement)
    }

    /// Conveys the semantic accessibility output to the user.
    /// - Parameter content: Content to output.
    public func convey(_ content: [OutputSemantic]) {
        if isAnnouncing {
            queued = content
            return
        }
        queued = []
        synthesizer.stopSpeaking(at: .immediate)
        for expression in content {
            let description = expression.description
            guard !description.isEmpty else { continue }

            let utterance = AVSpeechUtterance(string: description)
            synthesizer.speak(utterance)
        }
    }

    /// Interrupts speech.
    public func interrupt() {
        isAnnouncing = false
        queued = []
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension Output: AVSpeechSynthesizerDelegate {
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor in
            if isAnnouncing {
                isAnnouncing = false
                convey(queued)
            }
        }
    }
}
