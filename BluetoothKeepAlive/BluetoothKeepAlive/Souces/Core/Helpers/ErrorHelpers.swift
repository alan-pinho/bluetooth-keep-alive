//
//  ErrorHelpers.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 12/02/26.
//

enum ErrorHelpers: Error {
    case recordNotFound(String)
    case invalidValue(reason: String)
    
    func reason() -> String {
        switch self {
        case .invalidValue(let reason):
            return reason
        case .recordNotFound(let reason):
            return reason
        }
    }
}
