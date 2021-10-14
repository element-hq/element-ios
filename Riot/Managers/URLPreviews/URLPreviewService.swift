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
import AFNetworking

enum URLPreviewServiceError: Error {
    case missingResponse
}

@objcMembers
/// A service for URL preview data that handles fetching, caching and clean-up
/// as well as remembering which previews have been closed by the user.
class URLPreviewService: NSObject {
    
    // MARK: - Properties
    
    /// The shared service object.
    static let shared = URLPreviewService()
    
    /// A persistent store backed by Core Data to reduce network requests
    private let store = URLPreviewStore()
    
    // MARK: - Public
    
    /// Generates preview data for a URL to be previewed as part of the supplied event,
    /// first checking the cache, and if necessary making a request to the homeserver.
    /// You should call `hasClosedPreview` first to ensure that a preview is required.
    /// - Parameters:
    ///   - url: The URL to generate the preview for.
    ///   - event: The event that the preview is for.
    ///   - session: The session to use to contact the homeserver.
    ///   - success: The closure called when the operation complete. The generated preview data is passed in.
    ///   - failure: The closure called when something goes wrong. The error that occured is passed in.
    func preview(for url: URL,
                 and event: MXEvent,
                 with session: MXSession,
                 success: @escaping (URLPreviewData) -> Void,
                 failure: @escaping (Error?) -> Void) {
        // Sanitize the URL before checking the store or performing lookup
        let sanitizedURL = sanitize(url)
        
        // Check for a valid preview in the store, and use this if found
        if let preview = store.preview(for: sanitizedURL, and: event) {
            MXLog.debug("[URLPreviewService] Using cached preview.")
            success(preview)
            return
        }
        
        // Otherwise make a request to the homeserver to generate a preview
        session.matrixRestClient.preview(for: sanitizedURL, success: { previewResponse in
            MXLog.debug("[URLPreviewService] Cached preview not found. Requesting from homeserver.")
            
            guard let previewResponse = previewResponse else {
                failure(URLPreviewServiceError.missingResponse)
                return
            }
            
            // Convert the response to preview data, fetching the image if provided.
            self.makePreviewData(from: previewResponse, for: sanitizedURL, and: event, with: session) { previewData in
                self.store.cache(previewData)
                success(previewData)
            }
            
        }, failure: { error in
            self.checkForDisabledAPI(in: error)
            failure(error)
        })
    }
    
    /// Removes any cached preview data that has expired.
    func removeExpiredCacheData() {
        store.removeExpiredItems()
    }
    
    /// Deletes all cached preview data and closed previews from the store,
    /// re-enabling URL previews if they have been disabled by `checkForDisabledAPI`.
    func clearStore() {
        store.deleteAll()
        MXKAppSettings.standard().enableBubbleComponentLinkDetection = true
    }
    
    /// Store the `eventId` and `roomId` of a closed preview.
    func closePreview(for eventId: String, in roomId: String) {
        store.closePreview(for: eventId, in: roomId)
    }
    
    /// Whether a preview for the given event should be shown or not.
    func shouldShowPreview(for event: MXEvent) -> Bool {
        !store.hasClosedPreview(for: event.eventId, in: event.roomId)
    }
    
    // MARK: - Private
    
    /// Convert an `MXURLPreview` object into `URLPreviewData` whilst also getting the image via the media manager.
    /// - Parameters:
    ///   - previewResponse: The `MXURLPreview` object to convert.
    ///   - url: The URL that response was for.
    ///   - event: The event that the URL preview is for.
    ///   - session: The session to use to for media management.
    ///   - completion: A closure called when the operation completes. This contains the preview data.
    private func makePreviewData(from previewResponse: MXURLPreview,
                         for url: URL,
                         and event: MXEvent,
                         with session: MXSession,
                         completion: @escaping (URLPreviewData) -> Void) {
        // Create the preview data and return if no image is needed.
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
        
        // Check for an image in the media cache and use this if found.
        if let cachePath = MXMediaManager.cachePath(forMatrixContentURI: imageURL, andType: previewResponse.imageType, inFolder: nil),
           let image = MXMediaManager.loadThroughCache(withFilePath: cachePath) {
            previewData.image = image
            completion(previewData)
            return
        }
        
        // Don't de-dupe image downloads as the service should de-dupe preview generation.
        
        // Otherwise download the image from the homeserver, treating an error as a preview without an image.
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
    
    /// Returns a URL created from the URL passed in, with sanitizations applied to reduce
    /// queries and duplicate cache data for URLs that will return the same preview data.
    private func sanitize(_ url: URL) -> URL {
        // Remove the fragment from the URL.
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        
        return components?.url ?? url
    }
    
    /// Checks an error returned from `MXRestClient` to see whether the previews API
    /// has been disabled on the homeserver. If this is true, link detection will be disabled
    /// to prevent further requests being made and stop any previews loaders being presented.
    private func checkForDisabledAPI(in error: Error?) {
        // The error we're looking for is a generic 404 and not a matrix error.
        guard
            !MXError.isMXError(error),
            let response = MXHTTPOperation.urlResponse(fromError: error)
        else { return }
        
        if response.statusCode == 404 {
            MXLog.debug("[URLPreviewService] Disabling link detection as homeserver does not support URL previews.")
            MXKAppSettings.standard().enableBubbleComponentLinkDetection = false
        }
    }
}
