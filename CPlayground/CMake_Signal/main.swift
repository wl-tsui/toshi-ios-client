//
//  main.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/24/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

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


