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
class PreviewManager: NSObject {
    private let restClient: MXRestClient
    private let mediaManager: MXMediaManager
    
    // Core Data cache to reduce network requests
    private let cache = URLPreviewCache()
    
    init(restClient: MXRestClient, mediaManager: MXMediaManager) {
        self.restClient = restClient
        self.mediaManager = mediaManager
    }
    
    func preview(for url: URL, and event: MXEvent, success: @escaping (URLPreviewViewData) -> Void, failure: @escaping (Error?) -> Void) {
        // Sanitize the URL before checking cache or performing lookup
        let sanitizedURL = sanitize(url)
        
        if let preview = cache.preview(for: sanitizedURL, and: event) {
            MXLog.debug("[PreviewManager] Using preview from cache")
            success(preview)
            return
        }
        
        restClient.preview(for: sanitizedURL, success: { preview in
            MXLog.debug("[PreviewManager] Preview not found in cache. Requesting from homeserver.")
            
            if let preview = preview {
                self.makePreviewData(for: sanitizedURL, and: event, from: preview) { previewData in
                    self.cache.store(previewData)
                    success(previewData)
                }
            }
            
        }, failure: failure)
    }
    
    func makePreviewData(for url: URL, and event: MXEvent, from preview: MXURLPreview, completion: @escaping (URLPreviewViewData) -> Void) {
        let previewData = URLPreviewViewData(url: url,
                                             eventID: event.eventId,
                                             roomID: event.roomId,
                                             siteName: preview.siteName,
                                             title: preview.title,
                                             text: preview.text)
        
        guard let imageURL = preview.imageURL else {
            completion(previewData)
            return
        }
        
        if let cachePath = MXMediaManager.cachePath(forMatrixContentURI: imageURL, andType: preview.imageType, inFolder: nil),
           let image = MXMediaManager.loadThroughCache(withFilePath: cachePath) {
            previewData.image = image
            completion(previewData)
            return
        }
        
        // Don't de-dupe image downloads as the manager should de-dupe preview generation.
        
        mediaManager.downloadMedia(fromMatrixContentURI: imageURL, withType: preview.imageType, inFolder: nil) { path in
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
    
    func removeExpiredItemsFromCache() {
        cache.removeExpiredItems()
    }
    
    func clearCache() {
        cache.clear()
    }
    
    func closePreview(for eventID: String, in roomID: String) {
        cache.closePreview(for: eventID, in: roomID)
    }
    
    func hasClosedPreview(from event: MXEvent) -> Bool {
        cache.hasClosedPreview(for: event.eventId, in: event.roomId)
    }
    
    private func sanitize(_ url: URL) -> URL {
        // Remove the fragment from the URL.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        
        return components?.url ?? url
    }
}
