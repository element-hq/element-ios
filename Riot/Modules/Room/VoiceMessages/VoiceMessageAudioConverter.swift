//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftOGG

enum VoiceMessageAudioConverterError: Error {
    case conversionFailed(Error?)
    case getDurationFailed(Error?)
    case cancelled
}

struct VoiceMessageAudioConverter {
    static func convertToOpusOgg(sourceURL: URL, destinationURL: URL, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try OGGConverter.convertM4aFileToOpusOGG(src: sourceURL, dest: destinationURL)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.conversionFailed(error)))
                }
            }
        }
    }
    
    static func convertToMPEG4AACIfNeeded(sourceURL: URL, destinationURL: URL, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if sourceURL.hasSupportedAudioExtension {
                    try FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationURL.path)
                } else {
                    try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: destinationURL)
                }
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.conversionFailed(error)))
                }
            }
        }
    }
    
    static func mediaDurationAt(_ sourceURL: URL, completion: @escaping (Result<TimeInterval, VoiceMessageAudioConverterError>) -> Void) {
        let audioAsset = AVURLAsset(url: sourceURL, options: nil)

        audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
            
            switch status {
            case .loaded:
                let duration = audioAsset.duration
                let durationInSeconds = CMTimeGetSeconds(duration)
                DispatchQueue.main.async {
                    completion(.success(durationInSeconds))
                }
            case .failed:
                DispatchQueue.main.async {
                    completion(.failure(.getDurationFailed(error)))
                }
            case .cancelled:
                DispatchQueue.main.async {
                    completion(.failure(.cancelled))
                }
            default: break
            }
        }
    }
}

extension URL {
    /// Returns true if the URL has a supported audio extension
    var hasSupportedAudioExtension: Bool {
        let supportedExtensions = ["mp3", "mp4", "m4a", "wav", "aac"]
        return supportedExtensions.contains(pathExtension.lowercased())
    }
}
