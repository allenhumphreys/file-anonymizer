//
//  Anonymizer.swift
//  file-anonymizer
//
//  Created by Allen Humphreys on 5/24/18.
//  Copyright © 2018 Allen. All rights reserved.
//

import Foundation

struct Config {
    static let sourceDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    static let anonymizedDirectoryURL = sourceDirectory.appendingPathComponent("Blinded")
    static let decoderRingURL = sourceDirectory.appendingPathComponent("DecoderRing.csv")
    static let fileExtensionOfInterest = arguments[1]
}

struct Anonymizer {

    static func newUniqueFilename(from url: URL, uniqueIn existing: [URL]) -> URL {

        var proposedURL: URL
        repeat {
            let proposedFileName = String(format: "%05d.\(url.pathExtension)", arc4random_uniform(99999))
            proposedURL = Config.anonymizedDirectoryURL.appendingPathComponent(proposedFileName)

        } while existing.contains(proposedURL)

        return proposedURL
    }

    static func ensureGoodStartState() {
        do {
            _ = try Data(contentsOf: Config.decoderRingURL, options: .alwaysMapped)
            print("Decoder ring already exists")
            exit(EXIT_FAILURE)
        } catch {
            // We want this to throw
        }

        do {
            try fileManager.createDirectory(at: Config.anonymizedDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("Failed to create directory for anonymized files, probably already exists")
            exit(EXIT_FAILURE)
        }
    }

    static func anonymizeFiles() {

        ensureGoodStartState()

        var urls: [URL]

        // Get the list of files we're going to anonymize
        do {
            urls = try fileManager.contentsOfDirectory(at: Config.sourceDirectory,
                                                        includingPropertiesForKeys: nil,
                                                        options: .skipsSubdirectoryDescendants)
            urls = urls.filter { $0.pathExtension == Config.fileExtensionOfInterest }

            guard !urls.isEmpty else {
                print("Found no files of type: \(Config.fileExtensionOfInterest)")
                exit(EXIT_FAILURE)
            }

        } catch {
            print("Failed to get a file listing")
            exit(EXIT_FAILURE)
        }

        // Now copy them

        var filenameMap = [URL: URL]()

        for url in urls {

            let destinationURL = newUniqueFilename(from: url, uniqueIn: Array(filenameMap.values))

            do {
                try fileManager.copyItem(at: url, to: destinationURL)
                filenameMap[url] = destinationURL
            } catch {
                print("Failed to copy a file\n\(error)")
            }
        }

        var csvString = "Original,Blinded\n"
        for (k, v) in filenameMap.sorted(by: { $0.key.lastPathComponent < $1.key.lastPathComponent }) {
            csvString += "\(k.lastPathComponent),\(v.lastPathComponent)\n"
        }

        do {
            try csvString.write(to: Config.decoderRingURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write decoder ring to a file: \(error)")
            print("Here's the decoder ring:")
            print(csvString)
        }
    }
}
