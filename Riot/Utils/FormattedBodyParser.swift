/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation

@objcMembers
final class FormattedBodyParser: NSObject {

    private struct HTMLURLAnchor {
        let link: URL
        let content: String
    }

    private enum Constants {
        static let htmlURLAnchorTagRegexPattern = "<a href=\"(.*?)\">([^<]*)</a>"
    }

    private lazy var htmlURLAnchorRegex: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: Constants.htmlURLAnchorTagRegexPattern, options: .caseInsensitive)
    }()

    private func getHTMLURLAnchors(forURL url: URL, inFormattedBody formattedBody: String) -> [HTMLURLAnchor] {
        // Use regex here self.htmlURLAnchorRegex
        // build and return list with `HTMLURLAnchor`
        
        guard let regex = htmlURLAnchorRegex else {
            return []
        }

        return regex.matches(in: formattedBody, options: [], range: NSRange(formattedBody.startIndex..., in: formattedBody)).compactMap { (result) -> HTMLURLAnchor? in
            guard result.numberOfRanges > 2 else { return nil }
            guard let urlRange = Range(result.range(at: 1), in: formattedBody) else {
                return nil
            }
            let urlString = String(formattedBody[urlRange])
            guard let contentRange = Range(result.range(at: 2), in: formattedBody) else {
                return nil
            }
            let content = String(formattedBody[contentRange])
            //  ignore invalid urls
            guard let link = URL(string: urlString) else { return nil }
            //  ignore other links
            guard link == url else { return nil }
            return HTMLURLAnchor(link: link, content: content)
        }
    }

    /// Gets visible url for a given url. Assumes formattedBody has one or more links like: '<a href="https://example.com/given">https://example.com/visible</a>'
    /// - Parameter url: the url given as target
    /// - Parameter formattedBody: html formatted body
    /// - Returns: visible url if found, otherwise nil
    func getVisibleURL(forURL url: URL, inFormattedBody formattedBody: String) -> URL? {
        //  TODO: returning first link here. Get url range in formattedBody to detect which link is actually tapped.
        return self.getHTMLURLAnchors(forURL: url, inFormattedBody: formattedBody).compactMap { URL(string: $0.content) }.first
    }
    
}
