// 
// Copyright 2022 New Vector Ltd
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
import MatrixSDK

@objcMembers
/// URL validation result object
class URLValidationResult: NSObject {

    /// Should confirm the tapped url
    let shouldShowConfirmationAlert: Bool
    /// User visible string the user tapped
    let visibleURLString: String?

    init(shouldShowConfirmationAlert: Bool,
         visibleURLString: String?) {
        self.shouldShowConfirmationAlert = shouldShowConfirmationAlert
        self.visibleURLString = visibleURLString
        super.init()
    }

    static let passed = URLValidationResult(shouldShowConfirmationAlert: false,
                                            visibleURLString: nil)
}

@objcMembers
class URLValidator: NSObject {

    /// Validated tapped url in the given event
    /// - Parameters:
    ///   - url: User tapped URL
    ///   - event: Event containing the link
    /// - Returns: Validation result
    static func validateTappedURL(_ url: URL, in event: MXEvent) -> URLValidationResult {
        guard let content = event.content else {
            return .passed
        }
        
        if let format = content["format"] as? String,
           let formattedBody = content["formatted_body"] as? String {
            if format == kMXRoomMessageFormatHTML {
                if let visibleURL = FormattedBodyParser().getVisibleURL(forURL: url, inFormattedBody: formattedBody),
                   url != visibleURL {
                    //  urls are different, show confirmation alert
                    return .init(shouldShowConfirmationAlert: true,
                                 visibleURLString: visibleURL.absoluteString)
                }
            }
        }
        
        if let body = event.content[kMXMessageBodyKey] as? String,
           body.vc_containsRTLOverride(),
           body != url.absoluteString {
            //  we don't know where the url is in the body, assuming visibleString is just a reverse of the url
            return .init(shouldShowConfirmationAlert: true,
                         visibleURLString: url.absoluteString.vc_reversed())
        }
        
        return .passed
    }

}
