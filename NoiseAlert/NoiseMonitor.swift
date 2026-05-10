import AVFoundation
import Combine
import UIKit

class NoiseMonitor: ObservableObject {
    @Published var decibelLevel: Double = 0
    @Published var peakLevel: Double = 0
    @Published var isOverLimit: Bool = false
    @Published var isRunning: Bool = false

    private let audioEngine = AVAudioEngine()
    private let limit: Double = 85.0
    private var wasOverLimit = false

    func start() {
        if audioEngine.isRunning { return }

        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            guard granted, let self else { return }
            do {
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true)
                self.startEngine()
            } catch {
                print("Audio session error:", error)
            }
        }
    }

    private func startEngine() {
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self, let data = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            var rms: Float = 0
            for i in 0..<count { rms += data[i] * data[i] }
            rms = sqrt(rms / Float(count))
            let db = rms > 0 ? Double(20 * log10(rms)) + 120 : 0
            let clamped = max(0, min(130, db))
            DispatchQueue.main.async {
                self.decibelLevel = clamped
                if clamped > self.peakLevel { self.peakLevel = clamped }
                let over = clamped >= self.limit
                self.isOverLimit = over

                if over && !self.wasOverLimit {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.warning)
                }
                self.wasOverLimit = over
            }
        }

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRunning = true
                self.peakLevel = 0
            }
        } catch {
            print("Audio engine error:", error)
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        isOverLimit = false
        wasOverLimit = false
    }

    func resetPeak() {
        peakLevel = decibelLevel
    }
}
