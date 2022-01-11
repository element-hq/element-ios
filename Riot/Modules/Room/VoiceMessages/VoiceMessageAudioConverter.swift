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
import ffmpegkit

enum VoiceMessageAudioConverterError: Error {
    case generic(String)
    case cancelled
}

struct VoiceMessageAudioConverter {
    static func convertToOpusOgg(sourceURL: URL, destinationURL: URL, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        let command = "-hide_banner -y -i \"\(sourceURL.path)\" -c:a libopus -b:a 24k \"\(destinationURL.path)\""
        executeCommand(command, completion: completion)
    }
    
    static func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        let command = "-hide_banner -y -i \"\(sourceURL.path)\" -c:a aac_at \"\(destinationURL.path)\""
        executeCommand(command, completion: completion)
    }
    
    static func mediaDurationAt(_ sourceURL: URL, completion: @escaping (Result<TimeInterval, VoiceMessageAudioConverterError>) -> Void) {
        FFprobeKit.getMediaInformationAsync(sourceURL.path) { session in
            guard let session = session else {
                completion(.failure(.generic("Invalid session")))
                return
            }
            
            guard let returnCode = session.getReturnCode() else {
                completion(.failure(.generic("Invalid return code")))
                return
            }
            
            DispatchQueue.main.async {
                if returnCode.isValueSuccess() {
                    let mediaInfo = session.getMediaInformation()
                    if let duration = try? TimeInterval(value: mediaInfo?.getDuration() ?? "0") {
                        completion(.success(duration))
                    } else {
                        completion(.failure(.generic("Failed to get media duration")))
                    }
                } else if returnCode.isValueCancel() {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.generic(String(returnCode.getValue()))))
                    MXLog.error("""
                        getMediaInformationAsync failed with state: \(String(describing: FFmpegKitConfig.sessionState(toString: session.getState()))), \
                        returnCode: \(String(describing: returnCode)), \
                        stackTrace: \(String(describing: session.getFailStackTrace()))
                        """)
                }
            }
        }
    }
    
    static private func executeCommand(_ command: String, completion: @escaping (Result<Void, VoiceMessageAudioConverterError>) -> Void) {
        FFmpegKitConfig.setLogLevel(0)
        
        FFmpegKit.executeAsync(command) { session in
            guard let session = session else {
                completion(.failure(.generic("Invalid session")))
                return
            }
            
            guard let returnCode = session.getReturnCode() else {
                completion(.failure(.generic("Invalid return code")))
                return
            }
            
            DispatchQueue.main.async {
                if returnCode.isValueSuccess() {
                    completion(.success(()))
                } else if returnCode.isValueCancel() {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.generic(String(returnCode.getValue()))))
                    MXLog.error("""
                        Failed converting voice message with state: \(String(describing: FFmpegKitConfig.sessionState(toString: session.getState()))), \
                        returnCode: \(String(describing: returnCode)), \
                        stackTrace: \(String(describing: session.getFailStackTrace()))
                        """)
                }
            }
        }
    }
}
