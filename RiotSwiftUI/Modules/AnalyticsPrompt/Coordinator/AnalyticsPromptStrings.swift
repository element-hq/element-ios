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

import DTCoreText

@available(iOS 14.0, *)
struct AnalyticsPromptStrings: AnalyticsPromptStringsProtocol {
    let appDisplayName = AppInfo.current.displayName
    
    let point1: NSAttributedString
    let point2: NSAttributedString
    
    let termsNewUser: NSAttributedString
    let termsUpgrade: NSAttributedString
    
    init() {
        self.point1 = Self.parse(VectorL10n.analyticsPromptPoint1)
        self.point2 = Self.parse(VectorL10n.analyticsPromptPoint2)
        
        self.termsNewUser = Self.attach(VectorL10n.analyticsPromptTermsLinkNewUser,
                                        to: VectorL10n.analyticsPromptTermsNewUser("%@"))
        self.termsUpgrade = Self.attach(VectorL10n.analyticsPromptTermsLinkUpgrade,
                                        to: VectorL10n.analyticsPromptTermsUpgrade("%@"))
    }
    
    static func parse(_ htmlString: String) -> NSAttributedString {
        // Do some sanitisation before finalizing the string
//        let sanitizeCallback: DTHTMLAttributedStringBuilderWillFlushCallback = { element in
//            element?.sanitize(with: ["b"], bodyFont: .systemFont(ofSize: UIFont.systemFontSize), imageHandler: nil)
//            print("Hello")
//        }

        let options: [String: Any] = [
            DTUseiOS6Attributes: true,              // Enable it to be able to display the attributed string in a UITextView
            DTDefaultLinkDecoration: false,
//            DTWillFlushBlockCallBack: sanitizeCallback
        ]
        
        guard let attributedString = NSAttributedString(htmlData: htmlString.data(using: .utf8),
                                                        options: options,
                                                        documentAttributes: nil) else {
            return NSAttributedString(string: htmlString)
        }
        
        return MXKTools.removeDTCoreTextArtifacts(attributedString)
    }
    
    static func attach(_ link: String, to terms: String) -> NSAttributedString {
        let baseString = NSMutableAttributedString(string: terms)
        let linkRange = (baseString.string as NSString).range(of: "%@")
        let formattedLink = NSAttributedString(string: VectorL10n.analyticsPromptTermsLinkNewUser,
                                               attributes: [.analyticsPromptTermsTextLink: true])
        baseString.replaceCharacters(in: linkRange, with: formattedLink)
        
        return baseString
    }
}

