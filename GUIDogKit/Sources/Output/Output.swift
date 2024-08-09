import AVFoundation
import ApplicationServices
import OSLog

private let logger = Logger(subsystem: #fileID, category: "Output")

/// Output conveyer.
@MainActor
public final class Output: NSObject {
    /// Speech synthesizer.
    private let synthesizer = AVSpeechSynthesizer()
    /// Queued output.
    private var queued = [OutputSemantic]()
    /// Whether the synthesizer is currently announcing something.
    private var isAnnouncing = false
    /// Whether output is enabled or not
    public var isEnabled: Bool = true
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
        synthesizer.stopSpeaking(at: .immediate)
        isAnnouncing = true
        synthesize(announcement)
    }

    /// Conveys the semantic accessibility output to the user.
    /// - Parameter content: Content to output.
    public func convey(_ content: [OutputSemantic]) {
        if isAnnouncing {
            queued.append(contentsOf: content)
            return
        }
        queued = []
        synthesizer.stopSpeaking(at: .immediate)
        for expression in content {
            let description = expression.description
            guard !description.isEmpty else { continue }

            synthesize(description)
        }
    }

    /// Interrupts speech.
    public func interrupt() {
        isAnnouncing = false
        queued = []
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Speaks something through the synthesizer
    private func synthesize(_ string: String) {
        logger.info("\(self.isEnabled ? "Synthesizing" : "Quietly synthesizing"): \(string)")

        guard isEnabled else { return }
        let utterance = AVSpeechUtterance(string: string)
        utterance.rate = 0.7
        synthesizer.speak(utterance)
    }
}

extension Output: AVSpeechSynthesizerDelegate {
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor in
            logger.info("Speech finished!")
            if isAnnouncing {
                logger.info("Conveying remaining info: \(self.queued.description)")
                isAnnouncing = false
                convey(queued)
            }
        }
    }
}
