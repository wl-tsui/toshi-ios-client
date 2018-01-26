//
//  Folder.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

enum Folder: String {
    case
    protocolC = "libsignal_protocol_c",
    headers = "libsignal-protocol-c",
    rawCode = "checkout",
    fatBinary = "fat",
    src,
    build

    static let outputFileName = "libsignal-protocol-c.a"

    func path(within root: String, fileName: String? = nil) -> String {
        var pathComponents = [
            root,
            self.rawValue,
            ]

        if let file = fileName {
            pathComponents.append(file)
        }

        return pathComponents.joined(separator: "/")
    }

    func create(within root: String) -> String {
        let fullPath = path(within: root)
        FileManager.createFolder(at: fullPath)
        return fullPath
    }

    func deleteIfExists(within root: String) {
        let fullPath = path(within: root)
        FileManager.deleteIfExists(at: fullPath)
    }
}
