/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension UILabel {
    
    @objc func vc_setText(_ text: String, withLineSpacing lineSpacing: CGFloat, alignement: NSTextAlignment) {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = alignement
        
        let attributeString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        self.attributedText = attributeString
    }
    
    // Fix multiline label height with auto layout. After performing orientation multiline label text appears on one line.
    // For more information see https://www.objc.io/issues/3-views/advanced-auto-layout-toolbox/#intrinsic-content-size-of-multi-line-text
    @objc func vc_fixMultilineHeight() {
        let width = self.frame.size.width
        
        if self.preferredMaxLayoutWidth != width {
           self.preferredMaxLayoutWidth = width
        }
    }

    /// Sets an HTML string into the receiver. Does not support custom fonts but considers receiver's font size.
    /// - Parameter htmlText: HTML text to be rendered.
    @objc func setHTMLFromString(_ htmlText: String) {
        let html = "<html><body>\(htmlText)</body></html>"

        self.attributedText = HTMLFormatter.formatHTML(html,
                                                       withAllowedTags: ["b", "p", "br", "body"],
                                                       font: UIFont.systemFont(ofSize: font.pointSize))
    }

}
