//
//  OSLog.swift
//  AdlerScope
//
//  Created by adlerflow on 21/03/22.
//

import Foundation
import OSLog

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "org.advison.AdlerScope"

    static let rendering = OSLog(subsystem: subsystem, category: "Rendering")
    static let settings = OSLog(subsystem: subsystem, category: "Settings")
    static let document = OSLog(subsystem: subsystem, category: "Document")
    static let window = OSLog(subsystem: subsystem, category: "Window")
}
