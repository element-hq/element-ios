// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import DSWaveformImage

enum VoiceMessageAttachmentCacheManagerError: Error {
    case invalidEventId
    case invalidAttachmentType
    case decryptionError(Error)
    case preparationError(Error)
    case conversionError(Error)
    case durationError(Error?)
    case invalidNumberOfSamples
    case samplingError
    case cancelled
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

@objc class VoiceMessageAttachmentCacheManagerBridge: NSObject {
    @objc static func clearCache() {
        VoiceMessageAttachmentCacheManager.sharedManager.clearCache()
    }
}

class VoiceMessageAttachmentCacheManager {
    
    private struct Constants {
        static let taskSemaphoreTimeout = 5.0
    }
    
    static let sharedManager = VoiceMessageAttachmentCacheManager()
    
    private var completionCallbacks = [CompletionCallbackKey: [CompletionWrapper]]()
    private var samples = [String: [Int: [Float]]]()
    private var durations = [String: TimeInterval]()
    private var finalURLs = [String: URL]()
    
    private let workQueue: DispatchQueue
    private let operationQueue: OperationQueue
    
    private var temporaryFilesFolderURL: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("VoiceMessages")
    }
    
    private init() {
        workQueue = DispatchQueue(label: "io.element.VoiceMessageAttachmentCacheManager.queue", qos: .userInitiated)
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    func loadAttachment(_ attachment: MXKAttachment, numberOfSamples: Int, completion: @escaping (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void) {
        guard attachment.type == .voiceMessage || attachment.type == .audio else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidAttachmentType))
            MXLog.error("[VoiceMessageAttachmentCacheManager] Invalid attachment type, ignoring request.")
            return
        }
        
        guard let identifier = attachment.eventId else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidEventId))
            MXLog.error("[VoiceMessageAttachmentCacheManager] Invalid event id, ignoring request.")
            return
        }
        
        guard numberOfSamples > 0 else {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.invalidNumberOfSamples))
            MXLog.error("[VoiceMessageAttachmentCacheManager] Invalid number of samples, ignoring request.")
            return
        }
        
        do {
            try setupTemporaryFilesFolder()
        } catch {
            completion(Result.failure(VoiceMessageAttachmentCacheManagerError.preparationError(error)))
            MXLog.error("[VoiceMessageAttachmentCacheManager] Failed creating temporary files folder", context: error)
            return
        }
        
        operationQueue.addOperation {
            MXLog.debug("[VoiceMessageAttachmentCacheManager] Started task")
            
            if let finalURL = self.finalURLs[identifier], let duration = self.durations[identifier], let samples = self.samples[identifier]?[numberOfSamples] {
                MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished task - using cached results")
                let result = VoiceMessageAttachmentCacheManagerLoadResult(eventIdentifier: identifier, url: finalURL, duration: duration, samples: samples)
                DispatchQueue.main.async {
                    completion(Result.success(result))
                }
                return
            }
            
            self.enqueueLoadAttachment(attachment, identifier: identifier, numberOfSamples: numberOfSamples, completion: completion)
        }
    }
    
    func clearCache() {
        for key in completionCallbacks.keys {
            invokeFailureCallbacksForIdentifier(key.eventIdentifier, requiredNumberOfSamples: key.requiredNumberOfSamples, error: VoiceMessageAttachmentCacheManagerError.cancelled)
        }
        
        operationQueue.cancelAllOperations()
        samples.removeAll()
        durations.removeAll()
        finalURLs.removeAll()
        
        if FileManager.default.fileExists(atPath: temporaryFilesFolderURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFilesFolderURL)
            } catch {
                MXLog.error("[VoiceMessageAttachmentCacheManager] Failed clearing cached disk files", context: error)
            }
        }
    }
    
    private func enqueueLoadAttachment(_ attachment: MXKAttachment, identifier: String, numberOfSamples: Int, completion: @escaping (Result<VoiceMessageAttachmentCacheManagerLoadResult, Error>) -> Void) {
        let callbackKey = CompletionCallbackKey(eventIdentifier: identifier, requiredNumberOfSamples: numberOfSamples)
        
        if var callbacks = completionCallbacks[callbackKey] {
            MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished task - cached completion callback")
            callbacks.append(CompletionWrapper(completion))
            completionCallbacks[callbackKey] = callbacks
            return
        } else {
            completionCallbacks[callbackKey] = [CompletionWrapper(completion)]
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        if let finalURL = finalURLs[identifier], let duration = durations[identifier] {
            sampleFileAtURL(finalURL, duration: duration, numberOfSamples: numberOfSamples, identifier: identifier, semaphore: semaphore)
            let result = semaphore.wait(timeout: .now() + Constants.taskSemaphoreTimeout)
            if case DispatchTimeoutResult.timedOut = result {
                MXLog.error("[VoiceMessageAttachmentCacheManager] Timed out waiting for tasks to finish.")
            }
            return
        }
        
        DispatchQueue.main.async { // These don't behave accordingly if called from a background thread
            if attachment.isEncrypted {
                attachment.decrypt(toTempFile: { filePath in
                    self.workQueue.async {
                        self.convertFileAtPath(filePath, numberOfSamples: numberOfSamples, identifier: identifier, semaphore: semaphore)
                    }
                }, failure: { error in
                    // A nil error in this case is a cancellation on the MXMediaLoader
                    if let error = error {
                        MXLog.error("[VoiceMessageAttachmentCacheManager] Failed decrypting attachment", context: error)
                        self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.decryptionError(error))
                    }
                    semaphore.signal()
                })
            } else {
                attachment.prepare({
                    self.workQueue.async {
                        self.convertFileAtPath(attachment.cacheFilePath, numberOfSamples: numberOfSamples, identifier: identifier, semaphore: semaphore)
                    }
                }, failure: { error in
                    // A nil error in this case is a cancellation on the MXMediaLoader
                    if let error = error {
                        MXLog.error("[VoiceMessageAttachmentCacheManager] Failed preparing attachment", context: error)
                        self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.preparationError(error))
                    }
                    semaphore.signal()
                })
            }
        }
        
        let result = semaphore.wait(timeout: .now() + Constants.taskSemaphoreTimeout)
        if case DispatchTimeoutResult.timedOut = result {
            MXLog.error("[VoiceMessageAttachmentCacheManager] Timed out waiting for tasks to finish.")
        }
    }
    
    private func convertFileAtPath(_ path: String?, numberOfSamples: Int, identifier: String, semaphore: DispatchSemaphore) {
        guard let path else {
            return
        }

        let filePath = URL(fileURLWithPath: path)
        let fileExtension = filePath.hasSupportedAudioExtension ? filePath.pathExtension : "m4a"
        let newURL = temporaryFilesFolderURL.appendingPathComponent(identifier).appendingPathExtension(fileExtension)
        
        let conversionCompletion: (Result<Void, VoiceMessageAudioConverterError>) -> Void = { result in
            self.workQueue.async {
                switch result {
                case .success:
                    MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished converting voice message")
                    self.finalURLs[identifier] = newURL
                    
                    VoiceMessageAudioConverter.mediaDurationAt(newURL) { result in
                        self.workQueue.async {
                            MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished retrieving media duration")
                            
                            switch result {
                            case .success:
                                if let duration = try? result.get() {
                                    self.durations[identifier] = duration
                                    self.sampleFileAtURL(newURL, duration: duration, numberOfSamples: numberOfSamples, identifier: identifier, semaphore: semaphore)
                                } else {
                                    MXLog.error("[VoiceMessageAttachmentCacheManager] Failed retrieving media duration")
                                    self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.durationError(nil))
                                    semaphore.signal()
                                }
                            case .failure(let error):
                                MXLog.error("[VoiceMessageAttachmentCacheManager] Failed retrieving audio duration", context: error)
                                self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.durationError(error))
                                semaphore.signal()
                            }
                        }
                    }
                case .failure(let error):
                    MXLog.error("[VoiceMessageAttachmentCacheManager] Failed converting voice message", context: error)
                    self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.conversionError(error))
                    semaphore.signal()
                }
            }
        }
        
        if FileManager.default.fileExists(atPath: newURL.path) {
            conversionCompletion(Result.success(()))
        } else {
            VoiceMessageAudioConverter.convertToMPEG4AACIfNeeded(sourceURL: filePath, destinationURL: newURL, completion: conversionCompletion)
        }
    }
    
    private func sampleFileAtURL(_ url: URL, duration: TimeInterval, numberOfSamples: Int, identifier: String, semaphore: DispatchSemaphore) {
        let analyser = WaveformAnalyzer(audioAssetURL: url)
        
        analyser?.samples(count: numberOfSamples, completionHandler: { samples in
            self.workQueue.async {
                guard let samples = samples else {
                    MXLog.debug("[VoiceMessageAttachmentCacheManager] Failed sampling voice message")
                    self.invokeFailureCallbacksForIdentifier(identifier, requiredNumberOfSamples: numberOfSamples, error: VoiceMessageAttachmentCacheManagerError.samplingError)
                    semaphore.signal()
                    return
                }
                
                MXLog.debug("[VoiceMessageAttachmentCacheManager] Finished sampling voice message")
                
                if var existingSamples = self.samples[identifier] {
                    existingSamples[numberOfSamples] = samples
                    self.samples[identifier] = existingSamples
                } else {
                    self.samples[identifier] = [numberOfSamples: samples]
                }
                
                self.invokeSuccessCallbacksForIdentifier(identifier, url: url, duration: duration, samples: samples)
                semaphore.signal()
            }
        })
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
        
        MXLog.debug("[VoiceMessageAttachmentCacheManager] Successfully finished task")
    }
    
    private func invokeFailureCallbacksForIdentifier(_ identifier: String, requiredNumberOfSamples: Int, error: Error) {
        let callbackKey = CompletionCallbackKey(eventIdentifier: identifier, requiredNumberOfSamples: requiredNumberOfSamples)
        
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
        
        MXLog.debug("[VoiceMessageAttachmentCacheManager] Failed task with error: \(error)")
    }
    
    private func setupTemporaryFilesFolder() throws {
        let url = temporaryFilesFolderURL
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}
