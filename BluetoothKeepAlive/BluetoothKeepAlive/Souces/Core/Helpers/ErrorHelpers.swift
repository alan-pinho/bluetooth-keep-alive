// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Alan Pinho

//
//  ErrorHelpers.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/02/26.
//

enum ErrorHelpers: Error {
    case recordNotFound(String)
    case invalidValue(reason: String)
    case insetionFailed(reason: String)
    case updateFailed(reason: String)
    case deletionFailed(reason: String)
    
    func reason() -> String {
        switch self {
        case .invalidValue(let reason):
            return reason
        case .recordNotFound(let reason):
            return reason
        case .insetionFailed(reason: let reason):
            return reason
        case .updateFailed(reason: let reason):
            return reason
        case .deletionFailed(reason: let reason):
            return reason
        }
    }
}
