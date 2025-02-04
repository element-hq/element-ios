// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Parameters describing a universal link
@objcMembers
class UniversalLinkParameters: NSObject {
        
    // MARK: - Properties
        
    /// The universal link
    let universalLink: UniversalLink
    
    /// The fragment part of the universal link
    let fragment: String
        
    /// Presentation parameters
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(fragment: String,
         universalLink: UniversalLink,
         presentationParameters: ScreenPresentationParameters) {
        self.fragment = fragment
        self.universalLink = universalLink
        self.presentationParameters = presentationParameters
        
        super.init()
    }
    
    convenience init?(universalLink: UniversalLink,
                      presentationParameters: ScreenPresentationParameters) {
        
        guard let fixedURL = Tools.fixURL(withSeveralHashKeys: universalLink.url), let fragment = fixedURL.fragment else {
            return nil
        }
        
        self.init(fragment: fragment, universalLink: universalLink, presentationParameters: presentationParameters)
    }

    convenience init?(url: URL,
                      presentationParameters: ScreenPresentationParameters) {

        guard let fixedURL = Tools.fixURL(withSeveralHashKeys: url), let fragment = fixedURL.fragment else {
            return nil
        }
        let universalLink = UniversalLink(url: fixedURL)

        self.init(fragment: fragment, universalLink: universalLink, presentationParameters: presentationParameters)
    }
}
