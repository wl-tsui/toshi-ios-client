//
//  Shell.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
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
