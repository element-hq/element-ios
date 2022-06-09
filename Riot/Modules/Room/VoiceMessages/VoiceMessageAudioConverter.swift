// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftOGG

enum VoiceMessageAudioConverterError: Error {
    case conversionFailed(Error?)
    case getdurationFailed(Error?)
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
                completion(.failure(.conversionFailed(error)))
            }
        }
    }
    
    static func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: destinationURL)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                completion(.failure(.conversionFailed(error)))
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
                completion(.success(durationInSeconds))
            case .failed:
                completion(.failure(.conversionFailed(error)))
            case .cancelled:
                completion(.failure(.cancelled))
            default: break
            }
        }
    }
}
