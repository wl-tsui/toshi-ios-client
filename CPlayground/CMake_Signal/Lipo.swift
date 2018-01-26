//
//  Lipo.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

func lipo(relativePaths: [String], outputPath: String) {
    var params = [ "-create" ]
    params.append(contentsOf: relativePaths)
    params.append("-output")
    params.append(outputPath)

    shell(launchPath: "/usr/bin/lipo", params)
}
