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
