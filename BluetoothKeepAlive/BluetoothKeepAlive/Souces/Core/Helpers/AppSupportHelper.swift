//
//  AppSupportHelper.swift
//  BluetoothKeepAlive
//
//  Created by Alan Pinho on 15/01/26.
//

import Foundation

class AppSupportHelper {
    
   static func appSupportURL() -> URL {
        let fm = FileManager.default

        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        let bundleID = Bundle.main.bundleIdentifier ?? "com.bluetooth-keep-alive"

        let appDir = base.appendingPathComponent(bundleID, isDirectory: true)

        if !fm.fileExists(atPath: appDir.path) {
            if let seed = Bundle.main.url(forResource: "seed", withExtension: "sqlite3"){
                try? fm.copyItem(at: seed, to: appDir)
            }
        }

        return appDir
    }
}
