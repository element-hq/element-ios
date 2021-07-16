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
    let completion: (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void
    
    init(_ completion: @escaping (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void) {
        self.completion = completion
    }
}

private struct CompletionCallbackKey: Hashable {
    let eventIdentifier: String
    let requiredNumberOfSamples: Int
}

struct VoiceMessageAttachmentCacheManagerLoadResult {
    let eventIdentifier: String
    let url: URL
    let duration: TimeInterval
    let samples: [Float]
}

class VoiceMessageAttachmentCacheManager {
    
    static let sharedManager = VoiceMessageAttachmentCacheManager()
    
    private var completionCallbacks = [CompletionCallbackKey: [CompletionWrapper]]()
    private var samples = [String: [Int: [Float]]]()
    private var durations = [String: TimeInterval]()
    private var finalURLs = [String: URL]()
    
    private let workQueue: DispatchQueue
    
    private init() {
        workQueue = DispatchQueue(label: "io.element.VoiceMessageAttachmentCacheManager.queue", qos: .userInitiated)
    }
    
    func loadAttachment(_ attachment: MXKAttachment, numberOfSamples: Int, completion: @escaping (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void) {
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
        
        workQueue.async {
            // Run this in the work queue to preserve order
            if let finalURL = self.finalURLs[identifier], let duration = self.durations[identifier], let samples = self.samples[identifier]?[numberOfSamples] {
                let result = VoiceMessageAttachmentCacheManagerLoadResult(eventIdentifier: identifier, url: finalURL, duration: duration, samples: samples)
                DispatchQueue.main.async {
                    completion(Result.success(result))
                }
                return
            }
            
            self.enqueueLoadAttachment(attachment, identifier: identifier, numberOfSamples: numberOfSamples, completion: completion)
        }
    }
    
    private func enqueueLoadAttachment(_ attachment: MXKAttachment, identifier: String, numberOfSamples: Int, completion: @escaping (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void) {
        MXLog.debug("[VoiceMessageAttachmentCacheManager] Started task")
        
        let callbackKey = CompletionCallbackKey(eventIdentifier: identifier, requiredNumberOfSamples: numberOfSamples)
        
        if var callbacks = completionCallbacks[callbackKey] {
            MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished task - cached completion callback")
            callbacks.append(CompletionWrapper(completion))
            completionCallbacks[callbackKey] = callbacks
            return
        } else {
            completionCallbacks[callbackKey] = [CompletionWrapper(completion)]
        }
        
        let dispatchGroup = DispatchGroup()
        
        func sampleFileAtURL(_ url: URL, duration: TimeInterval) {
            let analyser = WaveformAnalyzer(audioAssetURL: url)
            
            dispatchGroup.enter()
            analyser?.samples(count: numberOfSamples, completionHandler: { samples in
                MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished sampling voice message")
                
                dispatchGroup.leave()
                
                guard let samples = samples else {
                    self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.samplingError)
                    return
                }
                
                if var existingSamples = self.samples[identifier] {
                    existingSamples[numberOfSamples] = samples
                    self.samples[identifier] = existingSamples
                } else {
                    self.samples[identifier] = [numberOfSamples: samples]
                }
                
                self.invokeSuccessCallbacksForIdentifier(identifier, url: url, duration: duration, samples: samples)
            })
        }
        
        if let finalURL = finalURLs[identifier], let duration = durations[identifier] {
            sampleFileAtURL(finalURL, duration: duration)
            dispatchGroup.wait()
            MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished task")
            return
        }
        
        func convertFileAtPath(_ path: String?) {
            guard let filePath = path else {
                return
            }
            
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let newURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo().globallyUniqueString).appendingPathExtension("m4a")
            
            dispatchGroup.enter()
            VoiceMessageAudioConverter.convertToMPEG4AAC(sourceURL: URL(fileURLWithPath: filePath), destinationURL: newURL) { result in
                switch result {
                case .success:
                    self.finalURLs[identifier] = newURL
                    VoiceMessageAudioConverter.mediaDurationAt(newURL) { result in
                        MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished converting voice message")
                        
                        switch result {
                        case .success:
                            if let duration = try? result.get() {
                                self.durations[identifier] = duration
                                sampleFileAtURL(newURL, duration: duration)
                            } else {
                                MXLog.error("[VoiceMessageAttachmentCacheManager] enqueueLoadAttachment: Failed to retrieve media duration")
                            }
                        case .failure(let error):
                            MXLog.error("[VoiceMessageAttachmentCacheManager] enqueueLoadAttachment: failed getting audio duration with: \(error)")
                        }
                        
                        dispatchGroup.leave()
                    }
                case .failure(let error):
                    self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.conversionError(error))
                    MXLog.error("[VoiceMessageAttachmentCacheManager] enqueueLoadAttachment: failed decoding audio message with: \(error)")
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.enter()
        DispatchQueue.main.async { // These don't behave accordingly if called from a background thread
            if attachment.isEncrypted {
                attachment.decrypt(toTempFile: { filePath in
                    convertFileAtPath(filePath)
                    dispatchGroup.leave()
                }, failure: { error in
                    // A nil error in this case is a cancellation on the MXMediaLoader
                    if let error = error {
                        MXLog.error("Failed decrypting attachment with error: \(String(describing: error))")
                        self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.decryptionError(error))
                    }
                    dispatchGroup.leave()
                })
            } else {
                attachment.prepare({
                    convertFileAtPath(attachment.cacheFilePath)
                    dispatchGroup.leave()
                }, failure: { error in
                    // A nil error in this case is a cancellation on the MXMediaLoader
                    if let error = error {
                        MXLog.error("Failed preparing attachment with error: \(String(describing: error))")
                        self.invokeFailureCallbacksForIdentifier(identifier, error: VoiceMessageAttachmentCacheManagerError.preparationError(error))
                    }
                    dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.wait()
        
        MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished task")
    }
    
    private func invokeSuccessCallbacksForIdentifier(_ identifier: String, url: URL, duration: TimeInterval, samples: [Float]) {
        let callbackKey = CompletionCallbackKey(eventIdentifier: identifier, requiredNumberOfSamples: samples.count)
        
        guard let callbacks = completionCallbacks[callbackKey] else {
            return
        }
        
        let result = VoiceMessageAttachmentCacheManagerLoadResult(eventIdentifier: identifier, url: url, duration: duration, samples: samples)
        
        let copy = callbacks.map { $0 }
        DispatchQueue.main.async {
            for wrapper in copy {
                wrapper.completion(Result.success(result))
            }
        }
        
        self.completionCallbacks[callbackKey] = nil
    }
    
    private func invokeFailureCallbacksForIdentifier(_ identifier: String, error: Error) {
        let callbackKey = CompletionCallbackKey(eventIdentifier: identifier, requiredNumberOfSamples: samples.count)
        
        guard let callbacks = completionCallbacks[callbackKey] else {
            return
        }
        
        let copy = callbacks.map { $0 }
        DispatchQueue.main.async {
            for wrapper in copy {
                wrapper.completion(Result.failure(error))
            }
        }
        
        self.completionCallbacks[callbackKey] = nil
    }
}
