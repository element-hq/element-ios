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
import DTCoreText
import UIKit

@objcMembers
class HTMLFormatter: NSObject {
    /// Builds an attributed string from a string containing html.
    ///
    /// - Parameters:
    ///   - htmlString: The html string to use.
    ///   - allowedTags: The html tags that should be allowed.
    ///   - font: The default font to use.
    ///   - imageHandler: The image handler for the formatted string
    ///   - extraOptions: Extra (or override) options to apply for the format. See DTCoreText's documentation for available options.
    ///   - postFormatOperations: Optional block to provide operations to apply
    /// - Returns: The built `NSAttributedString`.
    /// - Note: It is recommended to include "p" and "body" tags in `allowedTags` as these are often added when parsing.
    static func formatHTML(_ htmlString: String,
                           withAllowedTags allowedTags: [String],
                           font: UIFont,
                           andImageHandler imageHandler: DTHTMLElement.ImageHandler? = nil,
                           extraOptions: [AnyHashable: Any] = [:],
                           postFormatOperations: ((NSMutableAttributedString) -> Void)? = nil) -> NSAttributedString {
        guard let data = htmlString.data(using: .utf8) else {
            return NSAttributedString(string: htmlString)
        }

        let sanitizeCallback: DTHTMLAttributedStringBuilderWillFlushCallback = { [allowedTags, font, imageHandler] (element: DTHTMLElement?) in
            element?.sanitize(with: allowedTags, bodyFont: font, imageHandler: imageHandler)
        }

        var options: [AnyHashable: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: font.familyName,
            DTDefaultFontName: font.fontName,
            DTDefaultFontSize: font.pointSize,
            DTDefaultLinkDecoration: false,
            DTWillFlushBlockCallBack: sanitizeCallback
        ]
        options.merge(extraOptions) { (_, new) in new }

        guard let string = self.formatHTML(data, options: options) else {
            return NSAttributedString(string: htmlString)
        }

        let mutableString = NSMutableAttributedString(attributedString: string)
        MXKTools.removeDTCoreTextArtifacts(mutableString)
        postFormatOperations?(mutableString)

        return mutableString
    }

    /// Builds an attributed string by replacing a `%@` placeholder with the supplied link text and URL.
    /// - Parameters:
    ///   - string: The string to be formatted.
    ///   - link: The link text to be inserted.
    ///   - url: The URL to be linked to.
    /// - Returns: An attributed string.
    static func format(_ string: String, with link: String, using url: URL) -> NSAttributedString {
        let baseString = NSMutableAttributedString(string: string)
        let attributedLink = NSAttributedString(string: link, attributes: [.link: url])
        
        let linkRange = (baseString.string as NSString).range(of: "%@")
        baseString.replaceCharacters(in: linkRange, with: attributedLink)
        
        return baseString
    }
}

extension HTMLFormatter {
    /// This replicates DTCoreText's NSAttributedString `initWithHTMLData`.
    /// It sets the sanitize callback on the builder from Swift to avoid EXC_BAD_ACCESS crashes.
    ///
    /// - Parameters:
    ///   - data: The data in HTML format from which to create the attributed string.
    ///   - options: Specifies how the document should be loaded.
    /// - Returns: Returns an initialized object, or `nil` if the data can’t be decoded.
    @objc static func formatHTML(_ data: Data,
                                 options: [AnyHashable: Any]) -> NSAttributedString? {
        guard !data.isEmpty else {
            return nil
        }

        let stringBuilder = DTHTMLAttributedStringBuilder(html: data,
                                                          options: options,
                                                          // DTCoreText doesn't use document attributes anyway
                                                          documentAttributes: nil)

        if let willFlushCallback = options[DTWillFlushBlockCallBack] as? DTHTMLAttributedStringBuilderWillFlushCallback {
            stringBuilder?.willFlushCallback = willFlushCallback
        }

        return stringBuilder?.generatedAttributedString()
    }
}
