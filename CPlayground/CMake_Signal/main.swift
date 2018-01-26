#!/usr/bin/swift

//
//  main.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/24/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

@discardableResult
func shell(launchPath: String = "/usr/bin/env", _ args: String...) -> Int32 {
    return shell(launchPath: launchPath, args)
}

@discardableResult
func shell(launchPath: String = "/usr/bin/env", _ args: [String]) -> Int32 {

    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

enum ExitCode: Int, Error {
    case
    success,
    couldntDeleteFolder,
    couldntFindSourceRoot,
    couldntGetContentsOfFolder,
    errorCreatingFolder,
    errorReplacingFile

    func bail() {
        exit(Int32(self.rawValue))
    }
}

enum BuildType: String {
    case
    Debug,
    Release

    var folder: Folder {
        switch self {
        case .Debug:
            return .debug
        case .Release:
            return .release
        }
    }
}

enum Platform: String {
    case
    iOS = "OS",
    simulator32Bit = "SIMULATOR",
    simulator64Bit = "SIMULATOR64"

    var folder: Folder {
        switch self {
        case .iOS:
            return .iOS
        case .simulator32Bit:
            return .simulator32Bit
        case .simulator64Bit:
            return .simulator64Bit

        }
    }
}

struct BuildFlavor {
    let buildType: BuildType
    let platform: Platform

    @discardableResult
    func createFolder(sourceRoot root: String) -> String {
        let path = folderPath(sourceRoot: root)

        do {
            try FileManager.default.createDirectory(atPath: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch let error {
            print("Error creating folder at \(path): \(error.localizedDescription)")
            ExitCode.errorCreatingFolder.bail()
        }

        return path
    }

    private func folderPath(sourceRoot root: String) -> String {
        return [
            root,
            Folder.protocolC.rawValue,
            Folder.build.rawValue,
            platform.folder.rawValue,
            buildType.folder.rawValue,
        ].joined(separator: "/")
    }

    func outputPath(sourceRoot root: String) -> String {
        return [
            root,
            Folder.protocolC.rawValue,
            Folder.build.rawValue,
            platform.folder.rawValue,
            buildType.folder.rawValue,
            Folder.outputFileName,
        ].joined(separator: "/")
    }
}

enum Folder: String {
    case
    protocolC = "libsignal_protocol_c",
    headers = "libsignal-protocol-c",
    rawCode = "checkout",
    iOS = "os",
    simulator32Bit = "sim",
    simulator64Bit = "sim64",
    fatBinary = "fat",
    src,
    build,
    debug,
    release

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

        do {
            try FileManager.default.createDirectory(atPath: fullPath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch let error {
            print("Error creating \(fullPath): \(error.localizedDescription)")
            ExitCode.errorCreatingFolder.bail()
        }

        return fullPath
    }

    func deleteIfExists(within root: String) {
        let fullPath = path(within: root)

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fullPath) else {
            return
        }

        do {
            try FileManager.default.removeItem(atPath: fullPath)
        } catch let error {
            print("error nuking folder: \(error)")
            ExitCode.couldntDeleteFolder.bail()
        }

    }
}


func checkoutGit(from gitURLString: String = "https://github.com/signalapp/libsignal-protocol-c.git",
                 to destinationPath: String) {
    let gitArg = "git"
    let directoryArg = "--git-dir=\(destinationPath)/.git"
    let workTreeArg = "--work-tree=\(destinationPath)/"

    shell(gitArg, directoryArg, "init")
    shell(gitArg, directoryArg, "remote", "add", "origin", gitURLString)
    shell(gitArg, directoryArg, "fetch", "origin")
    shell(gitArg, directoryArg, workTreeArg,  "checkout", "-b", "master")
    shell(gitArg, directoryArg, workTreeArg, "pull", "origin", "master")
}

func replaceiOSToolchainFile(sourceRoot: String, checkoutRoot: String) {
    let toolchainFileName = "iOS.toolchain.cmake"

    let sourceFilePath = sourceRoot + "/\(toolchainFileName)"
    let destinationFilePath = checkoutRoot + "/CMakeModules/\(toolchainFileName)"

    do {
        let fileManager = FileManager.default
        try fileManager.removeItem(atPath: destinationFilePath)
        try _ = FileManager
            .default
            .copyItem(atPath: sourceFilePath,
                      toPath: destinationFilePath)
    } catch let error {
        print("Error moving file into place: \(error.localizedDescription)")
        ExitCode.errorReplacingFile.bail()
    }
}

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

    // Move to output
    let workingDir = ProcessInfo.processInfo.environment["PWD"]!
    let fileToCopy = [
        workingDir,
        Folder.src.rawValue,
        Folder.outputFileName,
    ].joined(separator: "/")

    print("Copying \(fileToCopy)")

    let fileManager = FileManager.default
    try? fileManager.copyItem(atPath: fileToCopy, toPath: flavor.outputPath(sourceRoot: root))

    // Remove the files in the working directory for the next run.
    guard let filesInWorkingDir = try? fileManager.contentsOfDirectory(atPath: workingDir) else {
        ExitCode.couldntGetContentsOfFolder.bail()
        return
    }

    let filesToRemove = filesInWorkingDir.filter { !$0.contains("CMake_Signal") }
    for file in filesToRemove {
        let path = "\(workingDir)/\(file)"
        try? fileManager.removeItem(atPath: path)
    }
}

func lipo(relativePaths: [String], outputPath: String) {
    var params = [ "-create" ]
    params.append(contentsOf: relativePaths)
    params.append("-output")
    params.append(outputPath)

    shell(launchPath: "/usr/bin/lipo", params)
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

        try? FileManager.default.copyItem(atPath: source, toPath: destination)
    }
}

// MARK: - Actual Script

// Use an env variable in the scheme to pass in the folder where this project lives.
guard let sourceRoot = ProcessInfo.processInfo.environment["PROJECT_ROOT"] else {
    throw ExitCode.couldntFindSourceRoot
}

// Remove any existing folder so we get a clean build
Folder.protocolC.deleteIfExists(within: sourceRoot)
let rootForCMaking = Folder.protocolC.create(within: sourceRoot)
let rawCodePath = Folder.rawCode.create(within: rootForCMaking)

// Checkout directly from git
checkoutGit(to: rawCodePath)

// The toolchain file that comes with this lib is outdated - replace it with
// the more maintained one from https://github.com/leetal/ios-cmake
replaceiOSToolchainFile(sourceRoot: sourceRoot, checkoutRoot: rawCodePath)

// Actually build the library for the various flavors of debug
let buildFolder = Folder.build.create(within: rootForCMaking)

let debugFlavors = [
    BuildFlavor(buildType: .Debug, platform: .iOS),
    BuildFlavor(buildType: .Debug, platform: .simulator32Bit),
    BuildFlavor(buildType: .Debug, platform: .simulator64Bit),
]

debugFlavors.forEach { flavor in
    flavor.createFolder(sourceRoot: sourceRoot)
    runCMake(for: flavor, rawCodePath: rawCodePath, sourceRoot: sourceRoot)
}

// Get all the different architectures lipo'd into a single fat binary
let outputFolder = Folder.fatBinary.create(within: buildFolder)
let outputPath = Folder.fatBinary.path(within: buildFolder, fileName: Folder.outputFileName)

lipo(relativePaths: debugFlavors.map { $0.outputPath(sourceRoot: sourceRoot) },
     outputPath: outputPath)

// Copy all the headers so that we can actually import stuff.
copyHeaders(from: rawCodePath, to: outputFolder)

print("Success! Your binary and headers are in \(outputFolder)!")
print("Note: Remember to add the headers folder to the \"Header Search Paths\" of your project!")

//TODO: Figure out if we need to build something separate for release, or if we can just use the fat binary
//let releaseFlavor = BuildFlavor(buildType: .Release, platform: .iOS)
//releaseFlavor.createFolder(sourceRoot: String)


