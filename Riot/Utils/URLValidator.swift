// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
