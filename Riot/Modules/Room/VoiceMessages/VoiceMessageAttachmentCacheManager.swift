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
import DSWaveformImage

enum VoiceMessageAttachmentCacheManagerError: Error {
    case invalidEventId
    case invalidAttachmentType
    case decryptionError(Error)
    case preparationError(Error)
    case conversionError(Error)
    case invalidNumberOfSamples
    case samplingError
}

/**
 Swift optimizes the callbacks to be the same instance. Wrap them so we can store them in an array.
 */
private class CompletionWrapper {
    let completion: (Result<(URL, [Float]), Error>) -> Void
    
    init(_ completion: @escaping (Result<(URL, [Float]), Error>) -> Void) {
        self.completion = completion
    }
}

class VoiceMessageAttachmentCacheManager {
    
    static let sharedManager = VoiceMessageAttachmentCacheManager()
    
    private let workQueue: DispatchQueue
    
    private var completionCallbacks = [String: [CompletionWrapper]]()
    private var samples = [String: [Int: [Float]]]()
    private var finalURLs = [String: URL]()
    
    private init() {
        workQueue = DispatchQueue(label: "io.element.VoiceMessageAttachmentCacheManager.queue", qos: .userInitiated)
    }
    
    func loadAttachment(_ attachment: MXKAttachment, numberOfSamples: Int, completion: @escaping (Result<(URL, [Float]), Error>) -> Void) {
        guard attachment.type == MXKAttachmentTypeVoiceMessage else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidAttachmentType))
            return
        }
        
        guard let identifier = attachment.eventId else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidEventId))
            return
        }
        
        guard numberOfSamples > 0 else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidNumberOfSamples))
            return
        }
        
        if let finalURL = finalURLs[identifier], let samples = samples[identifier]?[numberOfSamples] {
            completion(Result.success((finalURL, samples)))
            return
        }
        
        workQueue.async {
            self.enqueueLoadAttachment(attachment, identifier: identifier, numberOfSamples: numberOfSamples, completion: completion)
        }
    }
    
    private func enqueueLoadAttachment(_ attachment: MXKAttachment, identifier: String, numberOfSamples: Int, completion: @escaping (Result<(URL, [Float]), Error>) -> Void) {
        if var callbacks = completionCallbacks[identifier] {
            callbacks.append(CompletionWrapper(completion))
            completionCallbacks[identifier] = callbacks
            return
        } else {
            completionCallbacks[identifier] = [CompletionWrapper(completion)]
        }
        
        func sampleFileAtURL(_ url: URL) {
            let analyser = WaveformAnalyzer(audioAssetURL: url)
            analyser?.samples(count: numberOfSamples, completionHandler: { samples in
                self.workQueue.async {
                    guard let samples = samples else {
                        self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.samplingError)
                        return
                    }
                    
                    if var existingSamples = self.samples[identifier] {
                        existingSamples[numberOfSamples] = samples
                    } else {
                        self.samples[identifier] = [numberOfSamples: samples]
                    }
                    
                    self.invokeSuccessCallbacksForIdentifier(identifier, url: url, samples: samples)
                }
            })
        }
        
        if let finalURL = finalURLs[identifier] {
            sampleFileAtURL(finalURL)
            return
        }
        
        func convertFileAtPath(_ path: String?) {
            guard let filePath = path else {
                return
            }
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let newURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString).appendingPathExtension("m4a")
            
            VoiceMessageAudioConverter.convertToMPEG4AAC(sourceURL: URL(fileURLWithPath: filePath), destinationURL: newURL) { result in
                switch result {
                case .success:
                    self.finalURLs[identifier] = newURL
                    sampleFileAtURL(newURL)
                case .failure(let error):
                    self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.conversionError(error))
                    MXLog.error("Failed failed decoding audio message with: \(error)")
                }
            }
        }
        
        if attachment.isEncrypted {
            attachment.decrypt(toTempFile: { filePath in
                convertFileAtPath(filePath)
            }, failure: { error in
                // A nil error in this case is a cancellation on the MXMediaLoader
                if let error = error {
                    MXLog.error("Failed decrypting attachment with error: \(String(describing: error))")
                    self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.decryptionError(error))
                }
            })
        } else {
            attachment.prepare({
                convertFileAtPath(attachment.cacheFilePath)
            }, failure: { error in
                // A nil error in this case is a cancellation on the MXMediaLoader
                if let error = error {
                    MXLog.error("Failed preparing attachment with error: \(String(describing: error))")
                    self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.preparationError(error))
                }
            })
        }
    }
    
    private func invokeSuccessCallbacksForIdentifier(_ identifier: String, url: URL, samples: [Float]) {
        guard let callbacks = completionCallbacks[identifier] else {
            return
        }
        
        let copy = callbacks.map { $0 }
        DispatchQueue.main.async {
            for wrapper in copy {
                wrapper.completion(Result.success((url, samples)))
            }
        }
        
        self.completionCallbacks[identifier] = nil
    }
    
    private func invokeFailureCallbacksForIdentifier(_ identifier: String, error: Error) {
        guard let callbacks = completionCallbacks[identifier] else {
            return
        }
        
        let copy = callbacks.map { $0 }
        DispatchQueue.main.async {
            for wrapper in copy {
                wrapper.completion(Result.failure(error))
            }
        }
        
        self.completionCallbacks[identifier] = nil
    }
}
