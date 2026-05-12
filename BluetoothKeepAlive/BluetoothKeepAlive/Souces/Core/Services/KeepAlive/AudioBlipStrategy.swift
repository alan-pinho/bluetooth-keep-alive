//
//  AudioBlipStrategy.swift
//  BluetoothKeepAlive
//
//  Keeps audio devices (headphones, speakers) awake by routing a short
//  silent PCM buffer to the system's default output. As long as the
//  audio device is the active output, the buffered silence is enough to
//  keep the A2DP / HFP session alive past the device's idle timeout.
//

import Foundation
import AVFoundation
import IOBluetooth

final class AudioBlipStrategy: KeepAliveStrategy {

    let label = "Audio blip"

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var silentBuffer: AVAudioPCMBuffer?
    private var started = false
    private let blipDuration: TimeInterval = 0.2

    func perform(on device: IOBluetoothDevice) -> PingOutcome {
        do {
            try ensureStarted()
        } catch {
            return .failed("Audio engine could not start: \(error.localizedDescription)")
        }
        guard let buffer = silentBuffer else {
            return .failed("Silent buffer unavailable")
        }
        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        return .ok
    }

    private func ensureStarted() throws {
        if started { return }

        engine.attach(player)
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let frameCount = AVAudioFrameCount(format.sampleRate * blipDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioBlipStrategy", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not allocate PCM buffer"])
        }
        buffer.frameLength = frameCount
        // PCM buffer memory is zero-initialized by CoreAudio, so this is already silence.
        silentBuffer = buffer

        try engine.start()
        started = true
    }
}
