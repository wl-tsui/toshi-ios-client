//
//  BuildFlavor.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

enum BuildType: String {
    case
    Debug,
    Release

    var folderName: String {
        switch self {
        case .Debug:
            return "debug"
        case .Release:
            return "release"
        }
    }
}

enum Platform: String {
    case
    iOS = "OS",
    simulator32Bit = "SIMULATOR",
    simulator64Bit = "SIMULATOR64"

    var folderName: String {
        switch self {
        case .iOS:
            return "ios"
        case .simulator32Bit:
            return "sim"
        case .simulator64Bit:
            return "sim64"
        }
    }
}

struct BuildFlavor {
    let buildType: BuildType
    let platform: Platform

    @discardableResult
    func createFolder(sourceRoot root: String) -> String {
        let path = folderPath(sourceRoot: root)
        FileManager.createFolder(at: path)
        return path
    }

    private func folderPath(sourceRoot root: String) -> String {
        return [
            root,
            Folder.protocolC.rawValue,
            Folder.build.rawValue,
            platform.folderName,
            buildType.folderName,
        ].joined(separator: "/")
    }

    func outputPath(sourceRoot root: String) -> String {
        return [
            root,
            Folder.protocolC.rawValue,
            Folder.build.rawValue,
            platform.folderName,
            buildType.folderName,
            Folder.outputFileName,
        ].joined(separator: "/")
    }
}
