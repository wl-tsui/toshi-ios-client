//
//  FileMovement.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

extension FileManager {

    static func createFolder(at folderPath: String) {
        do {
            try FileManager.default.createDirectory(atPath: folderPath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch let error {
            print("Error creating folder at \(folderPath): \(error.localizedDescription)")
            ExitCode.errorCreatingFolder.bail()
        }
    }

    static func replaceFile(at toPath: String, with fromPath: String) {
        deleteIfExists(at: toPath)
        copyFile(from: fromPath, to: toPath)
    }

    static func deleteIfExists(at fullPath: String) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fullPath) else {
            return
        }

        do {
            try fileManager.removeItem(atPath: fullPath)
        } catch let error {
            print("error nuking file or folder: \(error)")
            ExitCode.couldntDeleteFolder.bail()
        }
    }

    static func copyFile(from fromPath: String, to toPath: String) {
        do {
            try FileManager.default.copyItem(atPath: fromPath, toPath: toPath)
        } catch let error {
            print("Error copying file: \(error)")
            ExitCode.couldntCopyFile.bail()
        }
    }

    static func contentsOfFolder(at folderPath: String) -> [String] {
        do {
            let filesInFolder = try FileManager.default.contentsOfDirectory(atPath: folderPath)
            return filesInFolder
        } catch let error {
            print("Error getting contents of folder: \(error)")
            ExitCode.couldntGetContentsOfFolder.bail()
            return []
        }
    }
}

func copyHeaders(from checkoutPath: String, to outputPath: String) {
    let headerFiles = [
        "curve",
        "device_consistency",
        "fingerprint",
        "group_cipher",
        "group_session_builder",
        "hkdf",
        "key_helper",
        "protocol",
        "ratchet",
        "sender_key_record",
        "sender_key_state",
        "sender_key",
        "session_builder",
        "session_cipher",
        "session_pre_key",
        "session_record",
        "session_state",
        "signal_protocol_types",
        "signal_protocol",
        ].map { $0 + ".h" }

    let folderPath = Folder.headers.create(within: outputPath)
    for file in headerFiles {
        let source = "\(checkoutPath)/\(Folder.src.rawValue)/\(file)"
        let destination = "\(folderPath)/\(file)"
        FileManager.copyFile(from: source, to: destination)
    }
}

func replaceiOSToolchainFile(sourceRoot: String, checkoutRoot: String) {
    let toolchainFileName = "iOS.toolchain.cmake"

    let sourceFilePath = sourceRoot + "/\(toolchainFileName)"
    let destinationFilePath = checkoutRoot + "/CMakeModules/\(toolchainFileName)"

    FileManager.replaceFile(at: destinationFilePath, with: sourceFilePath)
}

