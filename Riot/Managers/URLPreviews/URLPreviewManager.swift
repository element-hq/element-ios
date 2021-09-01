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

@objcMembers
class URLPreviewManager: NSObject {
    static let shared = URLPreviewManager()
    
    // Core Data store to reduce network requests
    private let store = URLPreviewStore()
    
    private override init() { }
    
    func preview(for url: URL,
                 and event: MXEvent,
                 with session: MXSession,
                 success: @escaping (URLPreviewData) -> Void,
                 failure: @escaping (Error?) -> Void) {
        // Sanitize the URL before checking the store or performing lookup
        let sanitizedURL = sanitize(url)
        
        if let preview = store.preview(for: sanitizedURL, and: event) {
            MXLog.debug("[URLPreviewManager] Using cached preview.")
            success(preview)
            return
        }
        
        session.matrixRestClient.preview(for: sanitizedURL, success: { previewResponse in
            MXLog.debug("[URLPreviewManager] Cached preview not found. Requesting from homeserver.")
            
            if let previewResponse = previewResponse {
                self.makePreviewData(from: previewResponse, for: sanitizedURL, and: event, with: session) { previewData in
                    self.store.store(previewData)
                    success(previewData)
                }
            }
            
        }, failure: failure)
    }
    
    func makePreviewData(from previewResponse: MXURLPreview,
                         for url: URL,
                         and event: MXEvent,
                         with session: MXSession,
                         completion: @escaping (URLPreviewData) -> Void) {
        let previewData = URLPreviewData(url: url,
                                         eventID: event.eventId,
                                         roomID: event.roomId,
                                         siteName: previewResponse.siteName,
                                         title: previewResponse.title,
                                         text: previewResponse.text)
        
        guard let imageURL = previewResponse.imageURL else {
            completion(previewData)
            return
        }
        
        if let cachePath = MXMediaManager.cachePath(forMatrixContentURI: imageURL, andType: previewResponse.imageType, inFolder: nil),
           let image = MXMediaManager.loadThroughCache(withFilePath: cachePath) {
            previewData.image = image
            completion(previewData)
            return
        }
        
        // Don't de-dupe image downloads as the manager should de-dupe preview generation.
        
        session.mediaManager.downloadMedia(fromMatrixContentURI: imageURL, withType: previewResponse.imageType, inFolder: nil) { path in
            guard let image = MXMediaManager.loadThroughCache(withFilePath: path) else {
                completion(previewData)
                return
            }
            previewData.image = image
            completion(previewData)
        } failure: { error in
            completion(previewData)
        }
    }
    
    func removeExpiredCacheData() {
        store.removeExpiredItems()
    }
    
    func clearStore() {
        store.deleteAll()
    }
    
    func closePreview(for eventID: String, in roomID: String) {
        store.closePreview(for: eventID, in: roomID)
    }
    
    func hasClosedPreview(from event: MXEvent) -> Bool {
        store.hasClosedPreview(for: event.eventId, in: event.roomId)
    }
    
    private func sanitize(_ url: URL) -> URL {
        // Remove the fragment from the URL.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        
        return components?.url ?? url
    }
}
