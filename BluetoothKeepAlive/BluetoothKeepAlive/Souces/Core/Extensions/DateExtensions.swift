//
//  DateExtensions.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 19/01/26.
//

import Foundation

extension Date {
    var isoFormatter: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: self)
    }
}
