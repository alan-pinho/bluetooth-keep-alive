// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  AudioBlipStrategy.swift
//  BluetoothKeepAlive
//
//  Keeps audio devices (headphones, speakers) awake by routing a short
//  PCM buffer to the system's default output. The buffer carries a
//  sub-audible low-amplitude tone (not pure zeros) because macOS' A2DP
//  encoder suspends transmission when it detects digital silence — which
//  some headset firmwares interpret as idle and disconnect.
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
    private let tickleFrequency: Float = 20.0     // sub-audible
    private let tickleAmplitude: Float = 0.0001   // ~-80 dBFS, inaudible

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
        fillTickle(buffer: buffer, format: format)
        silentBuffer = buffer

        try engine.start()
        started = true
    }

    private func fillTickle(buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        guard let channels = buffer.floatChannelData else { return }
        let sampleRate = Float(format.sampleRate)
        let channelCount = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        let twoPiFOverSR = 2.0 * .pi * tickleFrequency / sampleRate
        for frame in 0..<frames {
            let value = tickleAmplitude * sin(twoPiFOverSR * Float(frame))
            for ch in 0..<channelCount {
                channels[ch][frame] = value
            }
        }
    }
}
