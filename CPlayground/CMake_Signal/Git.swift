//
//  Git.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

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
