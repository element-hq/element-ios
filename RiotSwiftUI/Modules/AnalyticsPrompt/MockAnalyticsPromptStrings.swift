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
