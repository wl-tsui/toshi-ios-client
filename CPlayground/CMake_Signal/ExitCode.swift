//
//  ExitCode.swift
//  CMake_Signal
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

import Foundation

enum ExitCode: Int, Error {
    case
    success,
    couldntCopyFile,
    couldntCopyFolder,
    couldntDeleteFile,
    couldntDeleteFolder,
    couldntFindSourceRoot,
    couldntGetContentsOfFolder,
    errorCreatingFolder,
    errorReplacingFile

    func bail() {
        exit(Int32(self.rawValue))
    }
}
