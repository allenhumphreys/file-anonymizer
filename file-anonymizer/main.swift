//
//  main.swift
//  file-anonymizer
//
//  Created by Allen Humphreys on 5/24/18.
//  Copyright © 2018 Allen. All rights reserved.
//

import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 2 else {
    print("Usage: \((arguments[0] as NSString).lastPathComponent) <file-extension>")
    exit(EXIT_FAILURE)
}

let fileManager = FileManager.default

Anonymizer.anonymizeFiles()
