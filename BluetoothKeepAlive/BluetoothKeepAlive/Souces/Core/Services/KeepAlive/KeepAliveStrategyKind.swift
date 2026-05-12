//
//  KeepAliveStrategyKind.swift
//  BluetoothKeepAlive
//

import Foundation

/// Persisted in `routines.keepAliveStrategy`. `nil` means auto-detect.
enum KeepAliveStrategyKind: String, Codable, CaseIterable {
    case sdp
    case audio

    var label: String {
        switch self {
        case .sdp: return "SDP query"
        case .audio: return "Audio blip"
        }
    }
}
