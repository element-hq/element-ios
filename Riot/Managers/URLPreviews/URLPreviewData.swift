// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class URLPreviewData: NSObject, MXKURLPreviewDataProtocol {
    /// The URL that's represented by the preview data. This may have been sanitized.
    /// Note: The original URL, can be found in the bubble components with `eventID` and `roomID`.
    let url: URL
    
    /// The ID of the event that created this preview.
    let eventID: String
    
    /// The ID of the room that this preview is from.
    let roomID: String
    
    /// The OpenGraph site name for the URL.
    let siteName: String?
    
    /// The OpenGraph title for the URL.
    let title: String?
    
    /// The OpenGraph description for the URL.
    let text: String?
    
    /// The OpenGraph image for the URL.
    var image: UIImage?
    
    init(url: URL, eventID: String, roomID: String, siteName: String?, title: String?, text: String?) {
        self.url = url
        self.eventID = eventID
        self.roomID = roomID
        self.siteName = siteName
        self.title = title
        // Remove line breaks from the description text
        self.text = text?.components(separatedBy: .newlines).joined(separator: " ")
    }
}
