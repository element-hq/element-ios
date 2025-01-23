//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

struct MockAnalyticsPromptStrings: AnalyticsPromptStringsProtocol {
    let point1: NSAttributedString
    let point2: NSAttributedString
    
    let shortString = NSAttributedString(string: "This is a short string.")
    let longString = NSAttributedString(string: "This is a very long string that will be used to test the layout over multiple lines of text to ensure everything is correct.")
    
    init() {
        let point1 = NSMutableAttributedString(string: "We ")
        point1.append(NSAttributedString(string: "don't", attributes: [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]))
        point1.append(NSAttributedString(string: " record or profile any account data"))
        self.point1 = point1
        
        let point2 = NSMutableAttributedString(string: "We ")
        point2.append(NSAttributedString(string: "don't", attributes: [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]))
        point2.append(NSAttributedString(string: " share information with third parties"))
        self.point2 = point2
    }
}
