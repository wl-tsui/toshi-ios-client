//
//  CMake.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

func runCMake(for flavor: BuildFlavor, rawCodePath: String, sourceRoot root: String) {
    let toolchainFilePath = "\(rawCodePath)/CMakeModules/iOS.toolchain.cmake"
    let localCMakePath = "/usr/local/bin/cmake"

    // Generate the cmake files
    shell(launchPath: localCMakePath,
          // Make sure the toolchain filepath is in your path
        "PATH=\(toolchainFilePath):$PATH",
        "--clean-first",
        // Tell CMake to use the iOS toolchain file it now knows about,
        "-DCMAKE_TOOLCHAIN_FILE=\(toolchainFilePath)",
        // Build appropriate type
        "-DCMAKE_BUILD_TYPE=\(flavor.buildType.rawValue)",
        // For appropriate platform
        "-DIOS_PLATFORM=\(flavor.platform.rawValue)",
        "\(rawCodePath)"
    )

    // Actually make
    shell("make")

    // Move binary from working directory to output directory
    let workingDir = ProcessInfo.processInfo.environment["PWD"]!
    let fileToCopy = [
        workingDir,
        Folder.src.rawValue,
        Folder.outputFileName,
    ].joined(separator: "/")

    FileManager.copyFile(from: fileToCopy, to: flavor.outputPath(sourceRoot: root))

    // Remove the files in the working directory for the next run.
    let filesInWorkingDir = FileManager.contentsOfFolder(at: workingDir)
    let filesToRemove = filesInWorkingDir.filter { !$0.contains("CMake_Signal") }
    for file in filesToRemove {
        let path = "\(workingDir)/\(file)"
        FileManager.deleteIfExists(at: path)
    }
}
