/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
        let htmlTemplate = """
        <!doctype html>
        <html>
          <head>
            <style>
              body {
                font-family: -apple-system;
                font-size: \(font.pointSize)px;
              }
              p:last-child { display: inline; }
            </style>
          </head>
          <body>
            \(htmlText)
          </body>
        </html>
        """

        guard let data = htmlTemplate.data(using: .utf8),
              let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) else {
            return
        }

        self.attributedText = attributedString
    }

}
